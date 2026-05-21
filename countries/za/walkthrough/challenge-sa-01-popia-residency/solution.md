# Solution — Challenge SA-01 (POPIA residency)

> Walkthrough for `Sovereignty Summit South Africa 2026` / Challenge SA-01.
> Primary region: `southafricanorth`.

## 1. Create the management-group scope

```bash
az account management-group create --name mg-sovsummit-za --display-name "Sovereignty Summit ZA"
az account management-group subscription add --name mg-sovsummit-za --subscription "$SUBSCRIPTION_ID"
```

## 2. Build the policy initiative

Bundle these policies and assign them at the MG scope:

| Policy | Effect | Why |
|---|---|---|
| Allowed locations | Deny | POPIA s.72 — no resources outside South Africa. |
| Allowed locations for resource groups | Deny | Catches RG-level drift. |
| Storage accounts should use customer-managed key | DeployIfNotExists | POPIA s.19 — appropriate technical measures. |
| Key vaults should have purge protection enabled | Deny | Prevents key destruction. |
| Diagnostic settings to a Log Analytics workspace in southafricanorth | DeployIfNotExists | Keeps telemetry in-country. |

```bash
az policy set-definition create \
  --name popia-residency \
  --display-name "Sovereignty Summit ZA / POPIA Residency" \
  --management-group mg-sovsummit-za \
  --definitions @popia-residency.initiative.json \
  --params '{"allowedLocations":{"value":["southafricanorth","southafricawest"]}}'
```

## 3. Assign with deny + remediation identity

```bash
az policy assignment create \
  --name popia-residency-assignment \
  --policy-set-definition popia-residency \
  --scope /providers/Microsoft.Management/managementGroups/mg-sovsummit-za \
  --mi-system-assigned \
  --location southafricanorth \
  --params '{"allowedLocations":{"value":["southafricanorth","southafricawest"]}}'
```

Grant the assignment identity `Contributor` + `Key Vault Administrator` so the
DINE remediations can run.

## 4. Provision the Premium Key Vault

```bash
az keyvault create \
  --name kv-sovsummit-za-$RANDOM \
  --resource-group rg-sovsummit-za-platform \
  --location southafricanorth \
  --sku Premium \
  --enable-purge-protection true \
  --enable-rbac-authorization true \
  --retention-days 90
```

## 5. Verify deny path and compliance

```bash
az group create -n rg-deny-test -l westeurope    # expect RequestDisallowedByPolicy
az policy state list --management-group mg-sovsummit-za \
  --filter "ComplianceState eq 'NonCompliant'" -o table
```

## 6. Evidence pack for the Information Regulator

```bash
az policy state list \
  --management-group mg-sovsummit-za \
  --query "[].{resource:resourceId, state:complianceState, policy:policyDefinitionName, timestamp:timestamp}" \
  -o tsv > popia-compliance-$(date +%F).tsv
```

Map each policy back to a POPIA section in your evidence README:
controls 1+4 → s.72 (cross-border), controls 2+3 → s.19 (security
safeguards), Key Vault soft-delete/purge → s.19 + s.20 (notification of
compromises).
