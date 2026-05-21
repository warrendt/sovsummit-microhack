#!/usr/bin/env bash
# build-za.sh — one-shot bootstrap for the ${country.summit_edition} workshop.
#
# Two modes:
#   * Default (engineer)  : stand up the sovereign foundation for a single
#                           engineer's subscription (you become Key Vault Admin).
#   * --coach             : ALSO run the multi-attendee prep scripts before the
#                           Bicep deployment — quota check, custom RBAC role
#                           for the LabUsers group, and N per-attendee resource
#                           groups. Use this when preparing a shared
#                           subscription that 5-60 attendees will share at
#                           the summit.
#
# What it does (engineer mode):
#   1. Verifies az CLI + Bicep are available.
#   2. Confirms you are logged in to the right subscription.
#   3. Registers the resource providers the hack relies on.
#   4. Deploys main.bicep at subscription scope into ${country.azure.primary_region}.
#   5. Prints the resource group, Key Vault, storage account and policy
#      assignment so you can jump straight into Challenge 1.
#
# What --coach adds (in this order, before step 4 above):
#   Create-MHUsers.ps1     - (--create-users) create N lab users in the
#                            LabUsers group and a 24-hour Temporary Access
#                            Pass per user, exported to an .xlsx file
#   Create-AdminUsers.ps1  - (--create-users) create N admin users in the
#                            AdminUsers group (password-based)
#   2-vcpu-quotas.ps1      - check current vCPU quota in ${country.azure.primary_region}
#                            and (if --submit-quota-requests) submit increase requests
#   3-rbac.ps1             - create the 'Deployment Validator' custom role and assign
#                            it (plus Security Reader + Resource Policy Contributor)
#                            to the configured LabUsers Entra group
#   4-resource-groups.ps1  - create N numbered resource groups (labuser-01 ...)
#                            and assign Owner to each lab user
#
# Usage:
#   ./build-za.sh                                # engineer mode, interactive
#   ./build-za.sh --subscription <id>            # set target subscription
#   ./build-za.sh --name-prefix sov2026          # override the 6-char prefix
#   ./build-za.sh --what-if                      # preview only, no changes
#   ./build-za.sh --coach --attendees 30         # coach mode for 30 attendees
#   ./build-za.sh --coach --lab-users-group LabUsers --attendees 30
#   ./build-za.sh --coach --submit-quota-requests
#   ./build-za.sh --coach --create-users --attendees 30 \
#                 --admin-password '<pw>' --event-start-date 2026-02-10T00:00:00
#
# Requirements for --coach:
#   - pwsh (PowerShell 7+) on PATH
#   - Az.Accounts, Az.Resources, Microsoft.Graph.Groups PowerShell modules
#   - For --create-users also: Microsoft.Graph.Users,
#       Microsoft.Graph.Identity.SignIns, ImportExcel; User Administrator +
#       Group Administrator roles in Entra ID; Entra ID Premium P2 for TAP
#   - Owner + User Access Administrator at the subscription scope
#
# Cleanup:
#   az group delete -n rg-<prefix>-foundation --yes --no-wait
#   az policy assignment delete --name <prefix>-allowed-locations
#   az policy assignment delete --name <prefix>-allowed-rg-locations
#   # If you ran --coach also delete the labuser-NN groups, custom role, and
#   # group role assignments (the prep scripts print their names on creation).

set -euo pipefail

SUBSCRIPTION=""
NAME_PREFIX="sovza"
WHAT_IF=""
LOCATION="${country.azure.primary_region}"

COACH=0
LAB_USERS_GROUP="LabUsers"
ATTENDEES=10
RG_PREFIX="labuser-"
SUBMIT_QUOTA=0
CREATE_USERS=0
LAB_USER_COUNT=""
ADMIN_USER_COUNT=5
ADMIN_GROUP="AdminUsers"
ADMIN_PASSWORD=""
EVENT_START_DATE=""
TAP_EXPORT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subscription) SUBSCRIPTION="$2"; shift 2 ;;
    --name-prefix)  NAME_PREFIX="$2";  shift 2 ;;
    --location)     LOCATION="$2";     shift 2 ;;
    --what-if)      WHAT_IF="--what-if"; shift ;;
    --coach)              COACH=1; shift ;;
    --lab-users-group)    LAB_USERS_GROUP="$2"; shift 2 ;;
    --attendees)          ATTENDEES="$2"; shift 2 ;;
    --rg-prefix)          RG_PREFIX="$2"; shift 2 ;;
    --submit-quota-requests) SUBMIT_QUOTA=1; shift ;;
    --create-users)       CREATE_USERS=1; shift ;;
    --lab-user-count)     LAB_USER_COUNT="$2"; shift 2 ;;
    --admin-user-count)   ADMIN_USER_COUNT="$2"; shift 2 ;;
    --admin-group)        ADMIN_GROUP="$2"; shift 2 ;;
    --admin-password)     ADMIN_PASSWORD="$2"; shift 2 ;;
    --event-start-date)   EVENT_START_DATE="$2"; shift 2 ;;
    --tap-export)         TAP_EXPORT_PATH="$2"; shift 2 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

command -v az >/dev/null || { echo "az CLI not found. Install: https://learn.microsoft.com/cli/azure/install-azure-cli"; exit 1; }
az bicep version >/dev/null 2>&1 || az bicep install >/dev/null
if [[ $COACH -eq 1 ]]; then
  command -v pwsh >/dev/null || { echo "pwsh (PowerShell 7+) is required for --coach mode."; exit 1; }
fi

if ! az account show >/dev/null 2>&1; then
  echo "Not logged in. Running 'az login'..."
  az login --use-device-code
fi

if [[ -n "$SUBSCRIPTION" ]]; then
  az account set --subscription "$SUBSCRIPTION"
fi
SUB_ID="$(az account show --query id -o tsv)"
SUB_NAME="$(az account show --query name -o tsv)"
SUB_OBJ_NAME="$SUB_NAME"
SIGNED_IN_OID="$(az ad signed-in-user show --query id -o tsv)"

echo
echo "==> Mode         : $([[ $COACH -eq 1 ]] && echo 'coach (multi-attendee)' || echo 'engineer (single subscription)')"
echo "==> Subscription : $SUB_NAME ($SUB_ID)"
echo "==> Region       : $LOCATION"
echo "==> Prefix       : $NAME_PREFIX"
echo "==> Admin OID    : $SIGNED_IN_OID"
if [[ $COACH -eq 1 ]]; then
  echo "==> Group        : $LAB_USERS_GROUP"
  echo "==> Attendees    : $ATTENDEES (resource groups: ${RG_PREFIX}01 .. ${RG_PREFIX}$(printf '%02d' $ATTENDEES))"
  echo "==> Submit quota : $([[ $SUBMIT_QUOTA -eq 1 ]] && echo yes || echo 'no (check only)')"
fi
echo

read -r -p "Proceed? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

echo
echo "==> Registering resource providers (idempotent, may take a few minutes)..."
for rp in Microsoft.HybridCompute Microsoft.GuestConfiguration \
          Microsoft.HybridConnectivity Microsoft.AzureArcData \
          Microsoft.AzureStackHCI Microsoft.ResourceConnector \
          Microsoft.HybridContainerService Microsoft.Compute \
          Microsoft.ConfidentialLedger Microsoft.Security \
          Microsoft.PolicyInsights Microsoft.Advisor \
          Microsoft.OperationsManagement Microsoft.OperationalInsights \
          Microsoft.Insights Microsoft.Monitor Microsoft.KeyVault \
          Microsoft.ManagedIdentity Microsoft.Network Microsoft.Storage \
          Microsoft.Attestation Microsoft.Kubernetes \
          Microsoft.KubernetesConfiguration Microsoft.ContainerService \
          Microsoft.ExtendedLocation; do
  az provider register --namespace "$rp" --wait >/dev/null &
done
wait
echo "    providers registered."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Walk back up to the rendered bundle root so we can find the upstream prep
# scripts. In the rendered tree that's: <bundle>/bootstrap/.. == <bundle>/
BUNDLE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PREP_DIR="$BUNDLE_ROOT/resources/subscription-preparations"
HELPERS_DIR="$BUNDLE_ROOT/resources/preparation-helpers"

if [[ $COACH -eq 1 ]]; then
  if [[ ! -d "$PREP_DIR" ]]; then
    echo "ERROR: expected coach prep scripts at $PREP_DIR but did not find them." >&2
    echo "       Make sure you are running build-za.sh from a rendered build/za/bootstrap/ folder." >&2
    exit 1
  fi

  if [[ $CREATE_USERS -eq 1 ]]; then
    if [[ ! -d "$HELPERS_DIR" ]]; then
      echo "ERROR: --create-users requires preparation helpers at $HELPERS_DIR." >&2
      exit 1
    fi
    if [[ -z "$ADMIN_PASSWORD" ]]; then
      read -r -s -p "Enter password for admin lab users: " ADMIN_PASSWORD; echo
      [[ -n "$ADMIN_PASSWORD" ]] || { echo "Admin password is required." >&2; exit 1; }
    fi

    LU_COUNT="${LAB_USER_COUNT:-$ATTENDEES}"
    : "${TAP_EXPORT_PATH:=$BUNDLE_ROOT/TemporaryAccessPasses.xlsx}"

    echo
    echo "==> [coach] Create-MHUsers.ps1 — creating $LU_COUNT lab users in group '$LAB_USERS_GROUP' (tenant scope)..."
    MH_ARGS=(-UserCount "$LU_COUNT" -GroupName "$LAB_USERS_GROUP" -ExportPath "$TAP_EXPORT_PATH" -NonInteractive)
    [[ -n "$EVENT_START_DATE" ]] && MH_ARGS+=(-EventStartDate "$EVENT_START_DATE")
    pwsh -NoLogo -NonInteractive -File "$HELPERS_DIR/Create-MHUsers.ps1" "${MH_ARGS[@]}"

    echo
    echo "==> [coach] Create-AdminUsers.ps1 — creating $ADMIN_USER_COUNT admin users in group '$ADMIN_GROUP' (tenant scope)..."
    pwsh -NoLogo -NonInteractive -Command "
      \$pw = ConvertTo-SecureString -String '$ADMIN_PASSWORD' -AsPlainText -Force
      & '$HELPERS_DIR/Create-AdminUsers.ps1' -UserCount $ADMIN_USER_COUNT -GroupName '$ADMIN_GROUP' -Password \$pw
    "
  fi

  echo
  echo "==> [coach] 2-vcpu-quotas.ps1 — checking vCPU quota in $LOCATION for $ATTENDEES attendees..."
  QUOTA_ARGS=(-Region "$LOCATION" -NumberOfLabUsers "$ATTENDEES")
  [[ $SUBMIT_QUOTA -eq 1 ]] && QUOTA_ARGS+=(-SubmitQuotaRequests)
  pwsh -NoLogo -NonInteractive -File "$PREP_DIR/2-vcpu-quotas.ps1" "${QUOTA_ARGS[@]}" || {
    echo "    quota check returned a non-zero exit code (often expected if a request was filed); continuing."
  }

  echo
  echo "==> [coach] 3-rbac.ps1 — custom 'Deployment Validator' role + group RBAC for '$LAB_USERS_GROUP'..."
  pwsh -NoLogo -NonInteractive -File "$PREP_DIR/3-rbac.ps1" \
    -GroupName "$LAB_USERS_GROUP" -SubscriptionId "$SUB_ID"

  echo
  echo "==> [coach] 4-resource-groups.ps1 — creating $ATTENDEES attendee resource groups in $LOCATION..."
  pwsh -NoLogo -NonInteractive -File "$PREP_DIR/4-resource-groups.ps1" \
    -SubscriptionName "$SUB_OBJ_NAME" \
    -Location "$LOCATION" \
    -ResourceGroupPrefix "$RG_PREFIX" \
    -ResourceGroupCount "$ATTENDEES" \
    -StartIndex 1
fi

DEPLOY_NAME="${NAME_PREFIX}-bootstrap-$(date +%Y%m%d-%H%M%S)"

echo
echo "==> Deploying main.bicep at subscription scope (${WHAT_IF:-real})..."
az deployment sub create \
  --name "$DEPLOY_NAME" \
  --location "$LOCATION" \
  --template-file "$SCRIPT_DIR/main.bicep" \
  --parameters "$SCRIPT_DIR/main.bicepparam" \
  --parameters adminObjectId="$SIGNED_IN_OID" namePrefix="$NAME_PREFIX" \
  $WHAT_IF

if [[ -n "$WHAT_IF" ]]; then
  echo "What-if complete. Re-run without --what-if to deploy."
  exit 0
fi

echo
echo "==> Deployment outputs"
az deployment sub show -n "$DEPLOY_NAME" \
  --query "properties.outputs" -o json

cat <<EOF

=========================================================================
 ${country.summit_edition} foundation is up.
 Next: open countries/za/overrides/challenges/challenge-01.md (or
       build/za/challenges/challenge-01.md in the rendered bundle) and
       start enforcing the Sovereignty initiative.
=========================================================================
EOF
