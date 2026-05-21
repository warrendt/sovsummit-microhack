# Bootstrap — Sovereignty Summit South Africa 2026

This folder stands up the **starting Azure environment** for the
South Africa edition of the Sovereignty Summit MicroHack with one command.
After it runs, every attendee has the same baseline so they can dive
straight into Challenge 1.

## What gets deployed

| Resource | Purpose |
|---|---|
| Resource group `rg-<prefix>-foundation` in `southafricanorth` | Workshop scope, easy cleanup |
| Log Analytics workspace in `southafricanorth` | All diagnostic data stays in-country (POPIA s.72) |
| User-assigned managed identity | Used by storage to reach Key Vault for CMK |
| Premium Key Vault | HSM-backed, RBAC, purge protection, soft-delete 90d |
| RSA-HSM key with rotation policy | The CMK for storage encryption (Challenge 2) |
| Storage account (GRS, TLS 1.2 min, no public blob) | Encrypted with the CMK above |
| Subscription-scope policy: Allowed locations | Pins resources to `southafricanorth` + `southafricawest` |
| Subscription-scope policy: Allowed locations for resource groups | Pins RGs to the same regions |

The deployment is **safe to re-run** — Bicep is idempotent and resource names
are deterministic from `(subscriptionId, namePrefix)`.

## Prerequisites

- Azure CLI 2.55+ with Bicep enabled (`az bicep install`).
- An Azure subscription where you have **Owner** (or
  Contributor + User Access Administrator + Resource Policy Contributor).
- For the policy assignments: rights at the subscription scope.
- For the workshop's later challenges (4 & 5): Confidential Compute vCPU
  quota in `southafricanorth`. Request it now if you don't
  have it — approval can take 24h.

## Two modes

### Engineer mode (default)
Single subscription, you become Key Vault Admin. Best for one-off testing
or following the challenges yourself.

```bash
./build-za.sh
pwsh ./build-za.ps1
```

### Coach mode (`--coach` / `-Coach`)
Adds the upstream multi-attendee prep before deploying the foundation:

1. **`2-vcpu-quotas.ps1`** — checks vCPU quota in
   `southafricanorth` against what `--attendees N` will need
   (ArcBox, LocalBox, Confidential VM DCasv5/DCadsv5). Add
   `--submit-quota-requests` to file requests via the Azure Quota REST API.
2. **`3-rbac.ps1`** — creates the custom `Deployment Validator` role and
   assigns it (plus `Security Reader` and `Resource Policy Contributor`) to
   the `LabUsers` Entra group (override with `--lab-users-group`).
3. **`4-resource-groups.ps1`** — creates `N` numbered attendee resource
   groups (`labuser-01`, `labuser-02`, …) and assigns Owner to each lab
   user.

```bash
./build-za.sh --coach --attendees 30
./build-za.sh --coach --lab-users-group LabUsers --attendees 30 --submit-quota-requests
pwsh ./build-za.ps1 -Coach -Attendees 30
```

Coach mode requires `pwsh` (PowerShell 7+) plus the `Az.Accounts`,
`Az.Resources` and `Microsoft.Graph.Groups` modules so the upstream
PS scripts can run. Coach mode also expects you to have **Owner +
User Access Administrator** at the subscription scope and an existing
Entra ID group containing the attendees.

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
az keyvault purge --name <kv-name> --location southafricanorth
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

- Both the primary (`southafricanorth`) and paired
  (`southafricawest`) regions are inside South Africa, so
  GRS replication does not breach POPIA s.72.
- Key Vault SKU is `Premium` and the key is `RSA-HSM`,
  satisfying the SARB Directive 3/2018 expectation that customer-managed
  keys live in an HSM.
- Soft delete + purge protection together provide the cryptographic-erase
  recovery window required by enterprise change-management policies.
- The storage account is GRS by default — flip it to ZRS or LRS in the
  parameter file if a workload must never leave a single region.
