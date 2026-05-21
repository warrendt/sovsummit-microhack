#!/usr/bin/env bash
# teardown-za.sh — undo a build-za.sh run.
#
# Mirrors the flag surface of build-za.sh so you can clean up an event
# subscription between cohorts. Designed to be idempotent and safe:
#   * skips anything that does not exist
#   * defaults to a DRY RUN — pass --apply to actually delete
#   * waits on async deletes by default; pass --no-wait to fire-and-forget
#   * leaves soft-deleted Key Vaults alone unless --purge-keyvault is given
#     (the sovereign foundation enables purge protection, so a purge will
#     fail until the retention window expires — typically 90 days)
#
# What it deletes:
#   * Subscription scope:
#       - Bicep foundation RG          : rg-<prefix>-foundation
#       - Sovereignty policy assignments : <prefix>-allowed-locations,
#                                          <prefix>-allowed-rg-locations
#       - Sovereignty initiative         : <prefix>-sovereignty-controls
#       - Per-attendee RGs               : <rg-prefix>01 .. <rg-prefix>NN
#       - Role assignments held by LabUsers + AdminUsers groups
#       - Custom 'Deployment Validator' role (if created by 3-rbac.ps1)
#   * Entra tenant scope (only with --remove-users):
#       - Users   : LabUser-01..NN, AdminLabUser-01..NN
#       - Groups  : LabUsers, AdminUsers
#
# Usage:
#   ./teardown-za.sh                                      # dry-run summary
#   ./teardown-za.sh --apply                              # delete sub-scope resources
#   ./teardown-za.sh --apply --attendees 30               # also delete labuser-01..30
#   ./teardown-za.sh --apply --attendees 30 --remove-users
#   ./teardown-za.sh --apply --purge-keyvault             # also try to purge soft-deleted KV
#
# Requirements:
#   - az CLI signed in (Owner + User Access Administrator on the target sub)
#   - For --remove-users: pwsh + Microsoft.Graph.{Users,Groups} modules,
#     OR a User Administrator role token (we use the az-CLI Graph token).

set -uo pipefail

SUBSCRIPTION=""
NAME_PREFIX="sovza"
LOCATION="${country.azure.primary_region}"

LAB_USERS_GROUP="LabUsers"
ADMIN_GROUP="AdminUsers"
ATTENDEES=0
RG_PREFIX="labuser-"
LAB_USER_PREFIX="LabUser-"
ADMIN_USER_PREFIX="AdminLabUser-"
ADMIN_USER_COUNT=0
CUSTOM_ROLE_NAME="Deployment Validator"

APPLY=0
NO_WAIT=0
REMOVE_USERS=0
PURGE_KEYVAULT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subscription)      SUBSCRIPTION="$2"; shift 2 ;;
    --name-prefix)       NAME_PREFIX="$2";  shift 2 ;;
    --location)          LOCATION="$2";     shift 2 ;;
    --lab-users-group)   LAB_USERS_GROUP="$2"; shift 2 ;;
    --admin-group)       ADMIN_GROUP="$2"; shift 2 ;;
    --attendees)         ATTENDEES="$2"; shift 2 ;;
    --admin-user-count)  ADMIN_USER_COUNT="$2"; shift 2 ;;
    --rg-prefix)         RG_PREFIX="$2"; shift 2 ;;
    --lab-user-prefix)   LAB_USER_PREFIX="$2"; shift 2 ;;
    --admin-user-prefix) ADMIN_USER_PREFIX="$2"; shift 2 ;;
    --custom-role-name)  CUSTOM_ROLE_NAME="$2"; shift 2 ;;
    --apply)             APPLY=1; shift ;;
    --no-wait)           NO_WAIT=1; shift ;;
    --remove-users)      REMOVE_USERS=1; shift ;;
    --purge-keyvault)    PURGE_KEYVAULT=1; shift ;;
    -h|--help)
      sed -n '1,40p' "$0"
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if ! command -v az >/dev/null 2>&1; then
  echo "az CLI not found. Install from https://learn.microsoft.com/cli/azure/install-azure-cli" >&2
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "Not logged in. Running 'az login --use-device-code'..."
  az login --use-device-code >/dev/null
fi

if [[ -n "$SUBSCRIPTION" ]]; then
  az account set --subscription "$SUBSCRIPTION"
fi

SUB_ID=$(az account show --query id -o tsv)
SUB_NAME=$(az account show --query name -o tsv)

cat <<EOF

==> Subscription : $SUB_NAME ($SUB_ID)
==> Region       : $LOCATION
==> Prefix       : $NAME_PREFIX
==> Mode         : $( [[ $APPLY -eq 1 ]] && echo 'APPLY (will delete)' || echo 'DRY-RUN (use --apply to actually delete)' )
==> Foundation RG: rg-$NAME_PREFIX-foundation
==> Attendee RGs : ${ATTENDEES} (${RG_PREFIX}01 .. ${RG_PREFIX}$(printf "%02d" "$ATTENDEES"))
==> Lab group    : $LAB_USERS_GROUP
==> Admin group  : $ADMIN_GROUP
==> Remove users : $( [[ $REMOVE_USERS -eq 1 ]] && echo 'yes' || echo 'no (use --remove-users)' )
==> Purge KV     : $( [[ $PURGE_KEYVAULT -eq 1 ]] && echo 'yes (will fail if purge protection is on)' || echo 'no' )

EOF

if [[ $APPLY -eq 0 ]]; then
  echo "Dry-run only. Re-run with --apply to perform the deletions above."
  exit 0
fi

read -r -p "Proceed with deletions? [y/N] " confirm
[[ "$confirm" =~ ^[yY]$ ]] || { echo "Aborted."; exit 1; }

WAIT_FLAG=""
[[ $NO_WAIT -eq 1 ]] && WAIT_FLAG="--no-wait"

# ---------------------------------------------------------------------------
# 1. Policy assignments (sub scope)
# ---------------------------------------------------------------------------
echo ""
echo "==> Deleting policy assignments..."
for p in "${NAME_PREFIX}-allowed-locations" "${NAME_PREFIX}-allowed-rg-locations"; do
  if az policy assignment show --name "$p" >/dev/null 2>&1; then
    az policy assignment delete --name "$p" >/dev/null && echo "    deleted: $p"
  else
    echo "    not present, skipping: $p"
  fi
done

# Optional initiative (set definition) that may have been created
if az policy set-definition show --name "${NAME_PREFIX}-sovereignty-controls" >/dev/null 2>&1; then
  az policy set-definition delete --name "${NAME_PREFIX}-sovereignty-controls" >/dev/null && \
    echo "    deleted initiative: ${NAME_PREFIX}-sovereignty-controls"
fi

# ---------------------------------------------------------------------------
# 2. Role assignments at sub scope for our groups
# ---------------------------------------------------------------------------
echo ""
echo "==> Deleting role assignments for groups '${LAB_USERS_GROUP}' and '${ADMIN_GROUP}'..."
for grp in "$LAB_USERS_GROUP" "$ADMIN_GROUP"; do
  gid=$(az ad group show --group "$grp" --query id -o tsv 2>/dev/null || true)
  if [[ -z "$gid" ]]; then
    echo "    group not found, skipping: $grp"
    continue
  fi
  ids=$(az role assignment list --assignee "$gid" --all --query "[].id" -o tsv 2>/dev/null || true)
  if [[ -z "$ids" ]]; then
    echo "    no role assignments for: $grp"
    continue
  fi
  while IFS= read -r ra; do
    [[ -z "$ra" ]] && continue
    az role assignment delete --ids "$ra" >/dev/null && echo "    deleted ra for $grp : $ra"
  done <<< "$ids"
done

# ---------------------------------------------------------------------------
# 3. Custom RBAC role (Deployment Validator)
# ---------------------------------------------------------------------------
echo ""
echo "==> Deleting custom role '${CUSTOM_ROLE_NAME}' (if defined on this sub)..."
role_id=$(az role definition list --name "$CUSTOM_ROLE_NAME" --scope "/subscriptions/$SUB_ID" --query "[0].name" -o tsv 2>/dev/null || true)
if [[ -n "$role_id" ]]; then
  az role definition delete --name "$CUSTOM_ROLE_NAME" --scope "/subscriptions/$SUB_ID" 2>/dev/null && \
    echo "    deleted: $CUSTOM_ROLE_NAME ($role_id)" || echo "    delete failed (role may still have assignments at other scopes)"
else
  echo "    not present, skipping."
fi

# ---------------------------------------------------------------------------
# 4. Per-attendee resource groups
# ---------------------------------------------------------------------------
if [[ "$ATTENDEES" -gt 0 ]]; then
  echo ""
  echo "==> Deleting ${ATTENDEES} attendee resource groups..."
  for i in $(seq 1 "$ATTENDEES"); do
    rg=$(printf "%s%02d" "$RG_PREFIX" "$i")
    if az group exists --name "$rg" | grep -q true; then
      az group delete --name "$rg" --yes $WAIT_FLAG >/dev/null && echo "    delete kicked off: $rg"
    else
      echo "    not present, skipping: $rg"
    fi
  done
fi

# ---------------------------------------------------------------------------
# 5. Foundation resource group (Bicep deployment target)
# ---------------------------------------------------------------------------
echo ""
echo "==> Deleting foundation resource group..."
FOUNDATION_RG="rg-${NAME_PREFIX}-foundation"
if az group exists --name "$FOUNDATION_RG" | grep -q true; then
  az group delete --name "$FOUNDATION_RG" --yes $WAIT_FLAG >/dev/null && echo "    delete kicked off: $FOUNDATION_RG"
else
  echo "    not present, skipping: $FOUNDATION_RG"
fi

# ---------------------------------------------------------------------------
# 6. Optional: purge soft-deleted Key Vaults for this prefix
# ---------------------------------------------------------------------------
if [[ $PURGE_KEYVAULT -eq 1 ]]; then
  echo ""
  echo "==> Purging soft-deleted Key Vaults matching 'kv-${NAME_PREFIX}-*'..."
  # Wait briefly for the RG delete to register the soft-delete
  [[ $NO_WAIT -eq 0 ]] && sleep 5
  kvs=$(az keyvault list-deleted --query "[?starts_with(name,'kv-${NAME_PREFIX}-')].name" -o tsv 2>/dev/null || true)
  if [[ -z "$kvs" ]]; then
    echo "    no soft-deleted vaults found yet (RG delete may still be in flight)."
  else
    while IFS= read -r kv; do
      [[ -z "$kv" ]] && continue
      if az keyvault purge --name "$kv" --location "$LOCATION" 2>/dev/null; then
        echo "    purged: $kv"
      else
        echo "    purge blocked (purge protection on): $kv — will auto-delete after the retention window."
      fi
    done <<< "$kvs"
  fi
fi

# ---------------------------------------------------------------------------
# 7. Optional: remove Entra users + groups
# ---------------------------------------------------------------------------
if [[ $REMOVE_USERS -eq 1 ]]; then
  echo ""
  echo "==> Removing Entra users and groups..."
  TOKEN=$(az account get-access-token --resource-type ms-graph --query accessToken -o tsv 2>/dev/null || true)
  if [[ -z "$TOKEN" ]]; then
    echo "    could not obtain a Microsoft Graph token; skipping." >&2
  else
    SIGNED_UPN=$(az account show --query user.name -o tsv)
    TENANT_DOMAIN="${SIGNED_UPN##*@}"

    delete_users() {
      local prefix="$1" count="$2"
      [[ "$count" -lt 1 ]] && return 0
      for i in $(seq 1 "$count"); do
        local upn
        upn=$(printf "%s%02d@%s" "$prefix" "$i" "$TENANT_DOMAIN")
        local code
        code=$(curl -sS -o /dev/null -w "%{http_code}" \
          -X DELETE "https://graph.microsoft.com/v1.0/users/$upn" \
          -H "Authorization: Bearer $TOKEN")
        case "$code" in
          204) echo "    user deleted : $upn" ;;
          404) echo "    user missing : $upn" ;;
          *)   echo "    user $code on : $upn" ;;
        esac
      done
    }

    delete_users "$LAB_USER_PREFIX"   "$ATTENDEES"
    delete_users "$ADMIN_USER_PREFIX" "$ADMIN_USER_COUNT"

    for g in "$LAB_USERS_GROUP" "$ADMIN_GROUP"; do
      gid=$(curl -sS \
        "https://graph.microsoft.com/v1.0/groups?\$filter=displayName%20eq%20'${g}'&\$select=id" \
        -H "Authorization: Bearer $TOKEN" \
        | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['value'][0]['id'] if d.get('value') else '')" 2>/dev/null)
      if [[ -n "$gid" ]]; then
        code=$(curl -sS -o /dev/null -w "%{http_code}" \
          -X DELETE "https://graph.microsoft.com/v1.0/groups/$gid" \
          -H "Authorization: Bearer $TOKEN")
        echo "    group $code on : $g ($gid)"
      else
        echo "    group missing  : $g"
      fi
    done
  fi
fi

echo ""
echo "========================================================================="
echo " Teardown complete for prefix '$NAME_PREFIX' on $SUB_NAME."
[[ $REMOVE_USERS -eq 0 ]] && echo " (Lab users and groups left intact — pass --remove-users to delete them too.)"
[[ $PURGE_KEYVAULT -eq 0 ]] && echo " (Soft-deleted Key Vaults left intact — pass --purge-keyvault to attempt purge.)"
echo "========================================================================="
