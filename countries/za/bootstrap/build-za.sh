#!/usr/bin/env bash
# build-za.sh — one-shot bootstrap for the Sovereignty Summit South Africa 2026 workshop.
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
#   4. Deploys main.bicep at subscription scope into southafricanorth.
#   5. Prints the resource group, Key Vault, storage account and policy
#      assignment so you can jump straight into Challenge 1.
#
# What --coach adds (in this order, before step 4 above):
#   <<<INTERNAL_ONLY>>>
#   Create-MHUsers.ps1     - (--create-users) create N lab users in the
#                            LabUsers group and a 24-hour Temporary Access
#                            Pass per user, exported to an .xlsx file
#   Create-AdminUsers.ps1  - (--create-users) create N admin users in the
#                            AdminUsers group (password-based)
#   <<<END_INTERNAL_ONLY>>>
#   2-vcpu-quotas.ps1      - check current vCPU quota in southafricanorth
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
# <<<INTERNAL_ONLY>>>
#   ./build-za.sh --coach --create-users --attendees 30 \
#                 --admin-password '<pw>' --event-start-date 2026-02-10T00:00:00
# <<<END_INTERNAL_ONLY>>>
#
# Live-event flags (default ON under --coach):
#   --create-summit-group / --no-create-summit-group
#       Create parent group "Microhack Sovereignty Summit" (rename via
#       --summit-group "<name>") with LabUsers + AdminUsers nested.
#   --apply-ca-exclusion / --no-apply-ca-exclusion
#       Exclude the group from the Conditional Access policy named in
#       --ca-policy-name (default: "Security info registration for Microsoft
#       partners and vendors"). Falls back to manual portal steps on 403.
#
# ArcBox + LocalBox demo VMs for Challenges 5 & 6 (OFF by default — they
# cost real money and take 30 min / 4-6 h to deploy):
#   --deploy-arcbox     Deploy ArcBox-full into rg-arcbox (swedencentral, ~30m)
#   --deploy-localbox   Deploy LocalBox into rg-localbox (swedencentral shell
#                       + Azure Local in --azure-local-instance-location, ~4-6h)
#   --demo-admin-username <name>    Default: arcdemo
#   --demo-admin-password '<pw>'    Prompted if any --deploy-* flag is set
#   --arcbox-rg / --localbox-rg / --arcbox-location / --localbox-location
#       Region defaults (swedencentral) are HARDCODED by the upstream Bicep —
#       overriding will likely fail. Provided for completeness only.
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
#   Use ./teardown-za.sh — mirrors this script's flag surface (--apply,
#   --remove-users, --purge-keyvault) and idempotently removes RGs, policy
#   assignments, custom role, group role assignments, users + groups, and
#   soft-deleted Key Vaults.

set -euo pipefail

SUBSCRIPTION=""
NAME_PREFIX="sovza"
WHAT_IF=""
LOCATION="southafricanorth"

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

# Microhack Sovereignty Summit security group + Conditional Access exclusion
# (default ON whenever --coach is set; can be disabled per flag below)
SUMMIT_GROUP="Microhack Sovereignty Summit"
CREATE_SUMMIT_GROUP=1
APPLY_CA_EXCLUSION=1
CA_POLICY_NAME="Security info registration for Microsoft partners and vendors"

# ArcBox + LocalBox demo environments for Challenge 5 & 6 (off by default —
# they cost real money and take 30 min / 4-6 h to deploy).
DEPLOY_ARCBOX=0
DEPLOY_LOCALBOX=0
ARCBOX_RG="rg-arcbox"
LOCALBOX_RG="rg-localbox"
ARCBOX_LOCATION="swedencentral"           # ArcBox upstream-supported region; do NOT change
LOCALBOX_LOCATION="swedencentral"         # LocalBox host VM region
AZURE_LOCAL_INSTANCE_LOCATION="westeurope"  # subject to LocalBox ValidateSet
DEMO_ADMIN_USERNAME="arcdemo"
DEMO_ADMIN_PASSWORD=""

# Microsoft-internal coach helpers (Create-MHUsers, Create-AdminUsers,
# Repair-LabUsers, Retry-TAPs, New-SummitSecurityGroup, Set-CAExclusion).
# These do NOT ship with the public repo. Discovery order:
#   1. --internal-helpers-path <dir>            (CLI flag)
#   2. $SOVSUMMIT_INTERNAL_HELPERS              (env var)
#   3. ~/Repos/SovSummit-Internal/preparation-helpers   (default)
# Only required when --create-users / --create-summit-group / --apply-ca-exclusion is set.
INTERNAL_HELPERS_PATH=""

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
    # <<<INTERNAL_ONLY>>>
    --create-users)       CREATE_USERS=1; shift ;;
    --lab-user-count)     LAB_USER_COUNT="$2"; shift 2 ;;
    --admin-user-count)   ADMIN_USER_COUNT="$2"; shift 2 ;;
    --admin-group)        ADMIN_GROUP="$2"; shift 2 ;;
    --admin-password)     ADMIN_PASSWORD="$2"; shift 2 ;;
    --event-start-date)   EVENT_START_DATE="$2"; shift 2 ;;
    --tap-export)         TAP_EXPORT_PATH="$2"; shift 2 ;;
    # <<<END_INTERNAL_ONLY>>>
    --summit-group)         SUMMIT_GROUP="$2"; shift 2 ;;
    --no-create-summit-group) CREATE_SUMMIT_GROUP=0; shift ;;
    --create-summit-group)    CREATE_SUMMIT_GROUP=1; shift ;;
    --no-apply-ca-exclusion)  APPLY_CA_EXCLUSION=0; shift ;;
    --apply-ca-exclusion)     APPLY_CA_EXCLUSION=1; shift ;;
    --ca-policy-name)         CA_POLICY_NAME="$2"; shift 2 ;;
    --deploy-arcbox)        DEPLOY_ARCBOX=1; shift ;;
    --deploy-localbox)      DEPLOY_LOCALBOX=1; shift ;;
    --arcbox-rg)            ARCBOX_RG="$2"; shift 2 ;;
    --localbox-rg)          LOCALBOX_RG="$2"; shift 2 ;;
    --arcbox-location)      ARCBOX_LOCATION="$2"; shift 2 ;;
    --localbox-location)    LOCALBOX_LOCATION="$2"; shift 2 ;;
    --azure-local-instance-location) AZURE_LOCAL_INSTANCE_LOCATION="$2"; shift 2 ;;
    --demo-admin-username)  DEMO_ADMIN_USERNAME="$2"; shift 2 ;;
    --demo-admin-password)  DEMO_ADMIN_PASSWORD="$2"; shift 2 ;;
    --internal-helpers-path) INTERNAL_HELPERS_PATH="$2"; shift 2 ;;
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
# New self-contained layout: countries/za/{bootstrap,subscription-prep,demo-vms,...}
COUNTRY_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PREP_DIR="$COUNTRY_ROOT/subscription-prep"
DEMO_DIR="$COUNTRY_ROOT/demo-vms"

# Resolve internal helpers (Microsoft-internal, out-of-repo).
if [[ -n "$INTERNAL_HELPERS_PATH" ]]; then
  HELPERS_DIR="$INTERNAL_HELPERS_PATH"
elif [[ -n "${SOVSUMMIT_INTERNAL_HELPERS:-}" ]]; then
  HELPERS_DIR="$SOVSUMMIT_INTERNAL_HELPERS"
else
  HELPERS_DIR="$HOME/Repos/SovSummit-Internal/preparation-helpers"
fi

if [[ $COACH -eq 1 ]]; then
  if [[ ! -d "$PREP_DIR" ]]; then
    echo "ERROR: expected subscription-prep scripts at $PREP_DIR but did not find them." >&2
    echo "       Make sure you are running build-za.sh from countries/za/bootstrap/." >&2
    exit 1
  fi
  needs_helpers=0
  [[ $CREATE_USERS -eq 1 || $CREATE_SUMMIT_GROUP -eq 1 || $APPLY_CA_EXCLUSION -eq 1 ]] && needs_helpers=1
  if [[ $needs_helpers -eq 1 && ! -d "$HELPERS_DIR" ]]; then
    echo "ERROR: --create-users / --create-summit-group / --apply-ca-exclusion require the" >&2
    echo "       Microsoft-internal preparation helpers, expected at:" >&2
    echo "         $HELPERS_DIR" >&2
    echo "       Override with --internal-helpers-path <dir> or \$SOVSUMMIT_INTERNAL_HELPERS." >&2
    echo "       See https://github.com/warrendt/sovsummit-microhack/blob/main/README.md for details." >&2
    exit 1
  fi
  if [[ $CREATE_USERS -eq 1 && -z "$ADMIN_PASSWORD" ]]; then
    read -r -s -p "Enter password for admin lab users: " ADMIN_PASSWORD; echo
    [[ -n "$ADMIN_PASSWORD" ]] || { echo "Admin password is required." >&2; exit 1; }
  fi

  # Prompt for demo VM password if any ArcBox/LocalBox flag is set and none given.
  if [[ ( $DEPLOY_ARCBOX -eq 1 || $DEPLOY_LOCALBOX -eq 1 ) && -z "$DEMO_ADMIN_PASSWORD" ]]; then
    read -r -s -p "Enter password for ArcBox/LocalBox VM admin ($DEMO_ADMIN_USERNAME): " DEMO_ADMIN_PASSWORD; echo
    [[ -n "$DEMO_ADMIN_PASSWORD" ]] || { echo "Demo VM admin password is required for --deploy-arcbox/--deploy-localbox." >&2; exit 1; }
  fi

  LU_COUNT="${LAB_USER_COUNT:-$ATTENDEES}"
  # <<<INTERNAL_ONLY>>>
  : "${TAP_EXPORT_PATH:=$COUNTRY_ROOT/TemporaryAccessPasses.xlsx}"
  # <<<END_INTERNAL_ONLY>>>

  TENANT_ID="$(az account show --query tenantId -o tsv)"
  ACCOUNT_ID="$(az account show --query user.name -o tsv)"

  echo
  echo "==> [coach] Running all preparation in ONE pwsh session (reuses az CLI sign-in — no second login):"
  # <<<INTERNAL_ONLY>>>
  [[ $CREATE_USERS -eq 1 ]] && echo "    1) Create-MHUsers.ps1     ($LU_COUNT users in '$LAB_USERS_GROUP')"
  [[ $CREATE_USERS -eq 1 ]] && echo "    2) Create-AdminUsers.ps1  ($ADMIN_USER_COUNT users in '$ADMIN_GROUP')"
  # <<<END_INTERNAL_ONLY>>>
  echo "    3) 2-vcpu-quotas.ps1      ($LOCATION, $ATTENDEES attendees$( [[ $SUBMIT_QUOTA -eq 1 ]] && echo ', submit requests' ))"
  echo "    4) 3-rbac.ps1             (group '$LAB_USERS_GROUP' on $SUB_ID)"
  echo "    5) 4-resource-groups.ps1  (${ATTENDEES}x ${RG_PREFIX}NN in $LOCATION)"
  [[ $CREATE_SUMMIT_GROUP -eq 1 ]] && echo "    6) New-SummitSecurityGroup.ps1 (parent group '$SUMMIT_GROUP' over '$LAB_USERS_GROUP' + '$ADMIN_GROUP')"
  [[ $APPLY_CA_EXCLUSION -eq 1 ]] && echo "    7) Set-CAExclusion.ps1     (exclude '$SUMMIT_GROUP' from CA policy '$CA_POLICY_NAME')"
  [[ $DEPLOY_ARCBOX -eq 1 ]]      && echo "    8) deploy-arcbox.ps1       (rg '$ARCBOX_RG' in $ARCBOX_LOCATION, ~30 min, CostControl=Ignore)"
  [[ $DEPLOY_LOCALBOX -eq 1 ]]    && echo "    9) deploy-localbox.ps1     (rg '$LOCALBOX_RG' in $LOCALBOX_LOCATION + Azure Local in $AZURE_LOCAL_INSTANCE_LOCATION, ~4-6 h)"

  CREATE_USERS_FLAG="$CREATE_USERS" \
  ADMIN_PASSWORD="$ADMIN_PASSWORD" \
  LU_COUNT="$LU_COUNT" \
  LAB_USERS_GROUP="$LAB_USERS_GROUP" \
  TAP_EXPORT_PATH="$TAP_EXPORT_PATH" \
  ADMIN_USER_COUNT="$ADMIN_USER_COUNT" \
  ADMIN_GROUP="$ADMIN_GROUP" \
  HELPERS_DIR="$HELPERS_DIR" \
  PREP_DIR="$PREP_DIR" \
  DEMO_DIR="$DEMO_DIR" \
  COUNTRY_ROOT="$COUNTRY_ROOT" \
  EVENT_START_DATE="$EVENT_START_DATE" \
  SUB_ID="$SUB_ID" \
  SUB_NAME="$SUB_NAME" \
  TENANT_ID="$TENANT_ID" \
  ACCOUNT_ID="$ACCOUNT_ID" \
  LOCATION="$LOCATION" \
  ATTENDEES="$ATTENDEES" \
  RG_PREFIX="$RG_PREFIX" \
  SUBMIT_QUOTA="$SUBMIT_QUOTA" \
  SUMMIT_GROUP="$SUMMIT_GROUP" \
  CREATE_SUMMIT_GROUP_FLAG="$CREATE_SUMMIT_GROUP" \
  APPLY_CA_EXCLUSION_FLAG="$APPLY_CA_EXCLUSION" \
  CA_POLICY_NAME="$CA_POLICY_NAME" \
  DEPLOY_ARCBOX_FLAG="$DEPLOY_ARCBOX" \
  DEPLOY_LOCALBOX_FLAG="$DEPLOY_LOCALBOX" \
  ARCBOX_RG="$ARCBOX_RG" \
  LOCALBOX_RG="$LOCALBOX_RG" \
  ARCBOX_LOCATION="$ARCBOX_LOCATION" \
  LOCALBOX_LOCATION="$LOCALBOX_LOCATION" \
  AZURE_LOCAL_INSTANCE_LOCATION="$AZURE_LOCAL_INSTANCE_LOCATION" \
  DEMO_ADMIN_USERNAME="$DEMO_ADMIN_USERNAME" \
  DEMO_ADMIN_PASSWORD="$DEMO_ADMIN_PASSWORD" \
  pwsh -NoLogo -Command '
    $ErrorActionPreference = "Stop"

    # ------------------------------------------------------------
    # 1. Ensure required modules (idempotent install)
    # ------------------------------------------------------------
    $needed = @("Az.Accounts","Az.Resources","Microsoft.Graph.Users",
                "Microsoft.Graph.Groups","Microsoft.Graph.Identity.SignIns","ImportExcel")
    foreach ($m in $needed) {
      if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing $m ..." -ForegroundColor DarkGray
        Install-PSResource -Name $m -TrustRepository -Scope CurrentUser -Quiet
      }
    }

    # ------------------------------------------------------------
    # 2. Connect Az PowerShell (interactive device code, ONCE).
    #    Reusing az CLI''s ARM token isn''t reliable with Az.Accounts 5.x,
    #    so we sign in to Az PowerShell directly. Subsequent runs reuse
    #    the cached token from ~/.Azure.
    # ------------------------------------------------------------
    $ctx = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $ctx -or $ctx.Subscription.Id -ne $env:SUB_ID) {
      Write-Host ""
      Write-Host "Connecting Az PowerShell (device code) — sign in ONCE, both Az + Graph tokens come from this..." -ForegroundColor Yellow
      Connect-AzAccount -Tenant $env:TENANT_ID -SubscriptionId $env:SUB_ID -DeviceCode | Out-Null
    } else {
      Write-Host "Reusing cached Az PowerShell context: $($ctx.Subscription.Name)" -ForegroundColor Green
    }
    Set-AzContext -SubscriptionId $env:SUB_ID -Tenant $env:TENANT_ID | Out-Null
    Write-Host ("Az context : {0}  ({1})" -f (Get-AzContext).Subscription.Name, (Get-AzContext).Subscription.Id) -ForegroundColor Green

    # ------------------------------------------------------------
    # 3. Connect Microsoft Graph — derive token from Az context (no second login)
    # ------------------------------------------------------------
    $mgTok = (Get-AzAccessToken -ResourceTypeName MSGraph -AsSecureString -WarningAction SilentlyContinue).Token
    Connect-MgGraph -AccessToken $mgTok -NoWelcome
    Write-Host ("Mg context : {0}" -f (Get-MgContext).Account) -ForegroundColor Green

    # ------------------------------------------------------------
    # 4. Create lab + admin users (optional)
    # ------------------------------------------------------------
    # <<<INTERNAL_ONLY>>>
    if ($env:CREATE_USERS_FLAG -eq "1") {
      Write-Host ""
      Write-Host "==> Create-MHUsers.ps1 ..." -ForegroundColor Cyan
      $mhArgs = @{
        UserCount         = [int]$env:LU_COUNT
        GroupName         = $env:LAB_USERS_GROUP
        ExportPath        = $env:TAP_EXPORT_PATH
        NonInteractive    = $true
        SkipModuleInstall = $true
      }
      if ($env:EVENT_START_DATE) { $mhArgs.EventStartDate = [datetime]$env:EVENT_START_DATE }
      & (Join-Path $env:HELPERS_DIR "Create-MHUsers.ps1") @mhArgs

      Write-Host ""
      Write-Host "==> Create-AdminUsers.ps1 ..." -ForegroundColor Cyan
      $pw = ConvertTo-SecureString -String $env:ADMIN_PASSWORD -AsPlainText -Force
      & (Join-Path $env:HELPERS_DIR "Create-AdminUsers.ps1") `
          -UserCount ([int]$env:ADMIN_USER_COUNT) `
          -GroupName $env:ADMIN_GROUP `
          -Password $pw `
          -SkipModuleInstall
    }
    # <<<END_INTERNAL_ONLY>>>

    # ------------------------------------------------------------
    # 5. 2-vcpu-quotas.ps1 — feed Enter to its Read-Host prompt
    # ------------------------------------------------------------
    Write-Host ""
    Write-Host "==> 2-vcpu-quotas.ps1 ..." -ForegroundColor Cyan
    $quotaArgs = @("-Region", $env:LOCATION, "-NumberOfLabUsers", [int]$env:ATTENDEES)
    if ($env:SUBMIT_QUOTA -eq "1") { $quotaArgs += "-SubmitQuotaRequests" }
    try {
      "" | & (Join-Path $env:PREP_DIR "2-vcpu-quotas.ps1") @quotaArgs
    } catch {
      Write-Warning "Quota step returned a non-zero exit code (often expected when a request was filed). Continuing."
    }

    # ------------------------------------------------------------
    # 6. 3-rbac.ps1
    # ------------------------------------------------------------
    Write-Host ""
    Write-Host "==> 3-rbac.ps1 ..." -ForegroundColor Cyan
    & (Join-Path $env:PREP_DIR "3-rbac.ps1") -GroupName $env:LAB_USERS_GROUP -SubscriptionId $env:SUB_ID

    # ------------------------------------------------------------
    # 7. 4-resource-groups.ps1
    # ------------------------------------------------------------
    Write-Host ""
    Write-Host "==> 4-resource-groups.ps1 ..." -ForegroundColor Cyan
    & (Join-Path $env:PREP_DIR "4-resource-groups.ps1") `
        -SubscriptionName $env:SUB_NAME `
        -Location $env:LOCATION `
        -ResourceGroupPrefix $env:RG_PREFIX `
        -ResourceGroupCount ([int]$env:ATTENDEES) `
        -StartIndex 0

    # ------------------------------------------------------------
    # 8. Microhack Sovereignty Summit security group
    # ------------------------------------------------------------
    $summitGroupId = $null
    if ($env:CREATE_SUMMIT_GROUP_FLAG -eq "1") {
      Write-Host ""
      Write-Host "==> New-SummitSecurityGroup.ps1 ..." -ForegroundColor Cyan
      $summitGroupId = & (Join-Path $env:HELPERS_DIR "New-SummitSecurityGroup.ps1") `
          -GroupName     $env:SUMMIT_GROUP `
          -LabUsersGroup $env:LAB_USERS_GROUP `
          -AdminGroup    $env:ADMIN_GROUP `
          -SkipModuleInstall
    }

    # ------------------------------------------------------------
    # 9. Conditional Access policy exclusion
    # ------------------------------------------------------------
    if ($env:APPLY_CA_EXCLUSION_FLAG -eq "1") {
      Write-Host ""
      Write-Host "==> Set-CAExclusion.ps1 ..." -ForegroundColor Cyan
      try {
        & (Join-Path $env:HELPERS_DIR "Set-CAExclusion.ps1") `
            -PolicyName  $env:CA_POLICY_NAME `
            -GroupName   $env:SUMMIT_GROUP `
            -SkipModuleInstall
      } catch {
        Write-Warning "Set-CAExclusion.ps1 failed: $($_.Exception.Message). Follow the manual portal steps printed above."
      }
    }

    # ------------------------------------------------------------
    # 10. ArcBox / LocalBox demo VMs (Challenge 5 & 6)
    #     Region is HARDCODED per script (swedencentral / ValidateSet) —
    #     do NOT pass the country region; deployment will fail elsewhere.
    # ------------------------------------------------------------
    if ($env:DEPLOY_ARCBOX_FLAG -eq "1" -or $env:DEPLOY_LOCALBOX_FLAG -eq "1") {
      $demoPw = ConvertTo-SecureString -String $env:DEMO_ADMIN_PASSWORD -AsPlainText -Force
      $demoDir = $env:DEMO_DIR

      if ($env:DEPLOY_ARCBOX_FLAG -eq "1") {
        Write-Host ""
        Write-Host "==> deploy-arcbox.ps1 (rg $($env:ARCBOX_RG) in $($env:ARCBOX_LOCATION)) ..." -ForegroundColor Cyan
        & (Join-Path $demoDir "deploy-arcbox.ps1") `
            -ResourceGroupName     $env:ARCBOX_RG `
            -Location              $env:ARCBOX_LOCATION `
            -WindowsAdminUsername  $env:DEMO_ADMIN_USERNAME `
            -WindowsAdminPassword  $demoPw `
            -TagCostControlIgnore  $true
      }

      if ($env:DEPLOY_LOCALBOX_FLAG -eq "1") {
        Write-Host ""
        Write-Host "==> deploy-localbox.ps1 (rg $($env:LOCALBOX_RG) in $($env:LOCALBOX_LOCATION)) ..." -ForegroundColor Cyan
        & (Join-Path $demoDir "deploy-localbox.ps1") `
            -ResourceGroupName            $env:LOCALBOX_RG `
            -Location                     $env:LOCALBOX_LOCATION `
            -AzureLocalInstanceLocation   $env:AZURE_LOCAL_INSTANCE_LOCATION `
            -WindowsAdminPassword         $demoPw `
            -TagCostControlIgnore         $true `
            -NonInteractive
      }
    }
  '
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
 Sovereignty Summit South Africa 2026 foundation is up.
 Next: open countries/za/challenges/challenge-01.md and start enforcing
       the Sovereignty initiative.
=========================================================================
EOF
