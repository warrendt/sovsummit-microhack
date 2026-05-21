#!/usr/bin/env bash
# build-za.sh — one-shot bootstrap for the ${country.summit_edition} workshop.
#
# What it does:
#   1. Verifies az CLI + Bicep are available.
#   2. Confirms you are logged in to the right subscription.
#   3. Registers the resource providers the hack relies on.
#   4. Deploys main.bicep at subscription scope into ${country.azure.primary_region}.
#   5. Prints the resource group, Key Vault, storage account and policy
#      assignment so you can jump straight into Challenge 1.
#
# Usage:
#   ./build-za.sh                          # interactive
#   ./build-za.sh --subscription <id>      # set target subscription
#   ./build-za.sh --name-prefix sov2026    # override the 6-char prefix
#   ./build-za.sh --what-if                # preview only, no changes
#
# Cleanup:
#   az group delete -n rg-<prefix>-foundation --yes --no-wait
#   az policy assignment delete --name <prefix>-allowed-locations
#   az policy assignment delete --name <prefix>-allowed-rg-locations

set -euo pipefail

SUBSCRIPTION=""
NAME_PREFIX="sovza"
WHAT_IF=""
LOCATION="${country.azure.primary_region}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subscription) SUBSCRIPTION="$2"; shift 2 ;;
    --name-prefix)  NAME_PREFIX="$2";  shift 2 ;;
    --location)     LOCATION="$2";     shift 2 ;;
    --what-if)      WHAT_IF="--what-if"; shift ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

command -v az >/dev/null || { echo "az CLI not found. Install: https://learn.microsoft.com/cli/azure/install-azure-cli"; exit 1; }
az bicep version >/dev/null 2>&1 || az bicep install >/dev/null

if ! az account show >/dev/null 2>&1; then
  echo "Not logged in. Running 'az login'..."
  az login --use-device-code
fi

if [[ -n "$SUBSCRIPTION" ]]; then
  az account set --subscription "$SUBSCRIPTION"
fi
SUB_ID="$(az account show --query id -o tsv)"
SUB_NAME="$(az account show --query name -o tsv)"
SIGNED_IN_OID="$(az ad signed-in-user show --query id -o tsv)"

echo
echo "==> Subscription : $SUB_NAME ($SUB_ID)"
echo "==> Region       : $LOCATION"
echo "==> Prefix       : $NAME_PREFIX"
echo "==> Admin OID    : $SIGNED_IN_OID"
echo

read -r -p "Proceed with the deployment? [y/N] " confirm
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

DEPLOY_NAME="${NAME_PREFIX}-bootstrap-$(date +%Y%m%d-%H%M%S)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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
