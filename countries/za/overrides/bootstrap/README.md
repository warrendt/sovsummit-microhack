# Bootstrap — ${country.summit_edition}

This folder stands up the **starting Azure environment** for the
${country.name} edition of the Sovereignty Summit MicroHack with one command.
After it runs, every attendee has the same baseline so they can dive
straight into Challenge 1.

## What gets deployed

| Resource | Purpose |
|---|---|
| Resource group `rg-<prefix>-foundation` in `${country.azure.primary_region}` | Workshop scope, easy cleanup |
| Log Analytics workspace in `${country.azure.primary_region}` | All diagnostic data stays in-country (POPIA s.72) |
| User-assigned managed identity | Used by storage to reach Key Vault for CMK |
| Premium Key Vault | HSM-backed, RBAC, purge protection, soft-delete 90d |
| RSA-HSM key with rotation policy | The CMK for storage encryption (Challenge 2) |
| Storage account (GRS, TLS 1.2 min, no public blob) | Encrypted with the CMK above |
| Subscription-scope policy: Allowed locations | Pins resources to `${country.azure.primary_region}` + `${country.azure.paired_region}` |
| Subscription-scope policy: Allowed locations for resource groups | Pins RGs to the same regions |

The deployment is **safe to re-run** — Bicep is idempotent and resource names
are deterministic from `(subscriptionId, namePrefix)`.

## Prerequisites

- Azure CLI 2.55+ with Bicep enabled (`az bicep install`).
- An Azure subscription where you have **Owner** (or
  Contributor + User Access Administrator + Resource Policy Contributor).
- For the policy assignments: rights at the subscription scope.
- For the workshop's later challenges (4 & 5): Confidential Compute vCPU
  quota in `${country.azure.primary_region}`. Request it now if you don't
  have it — approval can take 24h.

## Run it

### bash / zsh

```bash
chmod +x build-za.sh
./build-za.sh                     # interactive
./build-za.sh --subscription <id> # explicit sub
./build-za.sh --what-if           # preview only
```

### PowerShell

```powershell
./build-za.ps1
./build-za.ps1 -SubscriptionId <guid>
./build-za.ps1 -WhatIf
```

Both wrappers:

1. Verify the az CLI is installed and Bicep is available.
2. Make sure you're signed in (`az login --use-device-code` if not).
3. Register the resource providers the hack relies on (parallel, idempotent).
4. Capture your signed-in user object ID and pass it as
   `adminObjectId` so you become Key Vault Administrator on day 1.
5. Run `az deployment sub create` with `main.bicep` + `main.bicepparam`.
6. Print the deployment outputs (RG, Key Vault, storage, policy IDs).

## Deployment outputs

After the script finishes you'll see:

```jsonc
{
  "resourceGroup":            { "value": "rg-sovza-foundation" },
  "keyVault":                 { "value": "kv-sovza-…" },
  "logAnalyticsWorkspace":    { "value": "law-sovza-…" },
  "storageAccount":           { "value": "stsovza…" },
  "managedIdentity":          { "value": "id-sovza-cmk" },
  "residencyPolicyAssignment":{ "value": "/subscriptions/…/policyAssignments/sovza-allowed-locations" }
}
```

## Cleanup

```bash
az group delete -n rg-<prefix>-foundation --yes --no-wait
az policy assignment delete --name <prefix>-allowed-locations
az policy assignment delete --name <prefix>-allowed-rg-locations
# Optional: purge the soft-deleted Key Vault
az keyvault purge --name <kv-name> --location ${country.azure.primary_region}
```

## Files

| File | What it is |
|---|---|
| `main.bicep` | Subscription-scope orchestrator |
| `main.bicepparam` | Parameter file (edit prefix here if you want) |
| `modules/foundation.bicep` | RG-scoped: LAW, KV, identity, key, storage |
| `modules/policy-residency.bicep` | Subscription-scope: allowed-locations assignments |
| `build-za.sh` / `build-za.ps1` | One-shot wrappers |

## Sovereignty notes

- Both the primary (`${country.azure.primary_region}`) and paired
  (`${country.azure.paired_region}`) regions are inside ${country.name}, so
  GRS replication does not breach POPIA s.72.
- Key Vault SKU is `${country.azure.cmk_hsm_sku}` and the key is `RSA-HSM`,
  satisfying the SARB Directive 3/2018 expectation that customer-managed
  keys live in an HSM.
- Soft delete + purge protection together provide the cryptographic-erase
  recovery window required by enterprise change-management policies.
- The storage account is GRS by default — flip it to ZRS or LRS in the
  parameter file if a workload must never leave a single region.
