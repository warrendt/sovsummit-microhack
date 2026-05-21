# Solution — Challenge KSA-01 (NCA CCC sovereign landing zone)

> Walkthrough for `Sovereignty Summit Saudi Arabia 2026` / Challenge KSA-01.
> Primary region: `saudiarabiaeast`.

## 1. Create the management-group structure

```bash
az account management-group create --name mg-sovsummit-ksa --display-name "Sovereignty Summit KSA"
az account management-group create --name mg-ksa-platform --display-name "KSA Platform" --parent mg-sovsummit-ksa
az account management-group create --name mg-ksa-workloads --display-name "KSA Workloads" --parent mg-sovsummit-ksa
az account management-group create --name mg-ksa-dr-exception --display-name "KSA DR Exception" --parent mg-sovsummit-ksa
```

Attach subscriptions so ordinary production subscriptions sit under
`mg-ksa-workloads`; only explicitly approved recovery subscriptions belong under
`mg-ksa-dr-exception`.

## 2. Create in-country logging and key-custody services

```bash
PLATFORM_RG=rg-ksa-platform
LAW_NAME=law-ksa-sovereign
KV_NAME=kv-ksa-sovereign-$RANDOM
KEY_NAME=cmk-ksa-platform

az group create -n $PLATFORM_RG -l saudiarabiaeast

az monitor log-analytics workspace create   -g $PLATFORM_RG   -n $LAW_NAME   -l saudiarabiaeast

az keyvault create   --name $KV_NAME   --resource-group $PLATFORM_RG   --location saudiarabiaeast   --sku Premium   --enable-rbac-authorization true   --enable-purge-protection true   --retention-days 90

az keyvault key create   --vault-name $KV_NAME   --name $KEY_NAME   --kty RSA-HSM   --size 3072
```

If the customer owns an on-prem HSM, swap the last step for a BYOK import and
capture the custody record in the evidence pack.

## 3. Define the Saudi-only and DR-exception policies

Use two layers:

1. **Normal workload scope** (`mg-sovsummit-ksa` or `mg-ksa-workloads`) that allows
   only `saudiarabiaeast`.
2. **DR exception scope** (`mg-ksa-dr-exception`) that additionally allows
   `qatarcentral`, but only with explicit approval metadata.

### Custom policy: `qatarcentral` requires approval tag

Create a policy definition such as `ksa-dr-approved-location.json`:

```json
{
  "mode": "Indexed",
  "parameters": {
    "drRegion": {
      "type": "String",
      "defaultValue": "qatarcentral"
    }
  },
  "policyRule": {
    "if": {
      "allOf": [
        { "field": "location", "equals": "[parameters('drRegion')]" },
        { "field": "tags['ksa-dr-approved']", "notEquals": "true" }
      ]
    },
    "then": {
      "effect": "deny"
    }
  }
}
```

### Initiative contents

| Policy | Scope | Effect |
|---|---|---|
| Allowed locations | Root / workloads | Deny |
| Allowed locations for resource groups | Root / workloads | Deny |
| Require `ksa-data-classification` | Root / workloads | Deny or Modify |
| Require `ksa-regulator` | Root / workloads | Deny or Modify |
| Require `ksa-service-owner` | Root / workloads | Deny or Modify |
| Storage accounts should use CMK | Root / workloads | Audit / DeployIfNotExists |
| SQL should use CMK | Root / workloads | Audit |
| Managed disks should use CMK via DES | Root / workloads | Audit |
| Key vaults should have purge protection enabled | Root / workloads | Deny |
| Deploy diagnostic settings to Log Analytics | Root / workloads | DeployIfNotExists |
| `qatarcentral` requires `ksa-dr-approved=true` | DR exception | Deny |

Create and assign the initiative:

```bash
az policy definition create   --name ksa-dr-approved-location   --display-name "KSA DR region requires explicit approval tag"   --management-group mg-sovsummit-ksa   --rules @ksa-dr-approved-location.json

az policy set-definition create   --name nca-ccc-sovereign-ksa   --display-name "NCA CCC Sovereign Landing Zone / KSA"   --management-group mg-sovsummit-ksa   --definitions @nca-ccc-sovereign-ksa.initiative.json

az policy assignment create   --name nca-ccc-sovereign-ksa-assignment   --policy-set-definition nca-ccc-sovereign-ksa   --scope /providers/Microsoft.Management/managementGroups/mg-sovsummit-ksa   --mi-system-assigned   --location saudiarabiaeast
```

Grant the assignment identity the minimum RBAC needed for tagging, diagnostics,
and encryption remediation.

## 4. Add managed-disk CMK with an HSM-backed key

For disk-backed workloads, create a Disk Encryption Set in
`saudiarabiaeast`:

```bash
KEY_ID=$(az keyvault key show --vault-name $KV_NAME --name $KEY_NAME --query key.kid -o tsv)
DES_NAME=des-ksa-platform

az disk-encryption-set create   --name $DES_NAME   --resource-group $PLATFORM_RG   --location saudiarabiaeast   --source-vault $KV_NAME   --key-url $KEY_ID
```

Use the DES for managed disks and feed its resource ID into landing-zone
modules for AKS, VMs, or SQL MI patterns.

## 5. Pin diagnostics to Saudi Arabia East

```bash
LAW_ID=$(az monitor log-analytics workspace show -g $PLATFORM_RG -n $LAW_NAME --query id -o tsv)
SUB_ID=$(az account show --query id -o tsv)

az monitor diagnostic-settings create   --name sub-activity-logs-sa   --resource /subscriptions/$SUB_ID   --workspace $LAW_ID   --logs '[{"category":"Administrative","enabled":true},{"category":"Security","enabled":true},{"category":"Policy","enabled":true}]'
```

Use policy remediation for resource-level diagnostics so new workloads inherit the
same sink automatically.

## 6. Validate deny paths

```bash
az group create -n rg-deny-test -l westeurope
# expect: RequestDisallowedByPolicy

az group create -n rg-dr-test -l qatarcentral
# expect: denied unless under mg-ksa-dr-exception and tagged ksa-dr-approved=true

az policy state list   --management-group mg-sovsummit-ksa   --filter "ComplianceState eq 'NonCompliant'"   -o table
```

## 7. Build the evidence pack

At minimum, export:

1. Management-group tree and assignment scopes.
2. Policy compliance CSV.
3. Key Vault location, SKU, purge-protection, and RBAC export.
4. Log Analytics location and diagnostic-settings export.
5. DR exception register with approver, expiry date, data class, and legal basis.

## 8. NCA CCC mapping to present to reviewers

| Guardrail | Review message |
|---|---|
| Saudi-only allowed locations | Default cloud geography is in-Kingdom; anything else is exceptional. |
| DR-exception scope | Cross-border recovery is isolated, tagged, and reviewable. |
| HSM-backed CMK | Key custody stays in `saudiarabiaeast` with auditable separation of duties. |
| In-country diagnostics | Audit, policy, and operational logs do not leave the Kingdom by default. |
| Classification and ownership tags | Every resource has an accountable owner and regulatory/data-classification context. |
| Evidence pack | Compliance is continuously demonstrable, not just described in design slides. |
