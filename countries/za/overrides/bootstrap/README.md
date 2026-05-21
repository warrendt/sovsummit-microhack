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
   `${country.azure.primary_region}` against what `--attendees N` will need
   (ArcBox, LocalBox, Confidential VM DCasv5/DCadsv5). Add
   `--submit-quota-requests` to file requests via the Azure Quota REST API.
2. **`3-rbac.ps1`** — creates the custom `Deployment Validator` role and
   assigns it (plus `Security Reader` and `Resource Policy Contributor`) to
   the `LabUsers` Entra group (override with `--lab-users-group`).
3. **`4-resource-groups.ps1`** — creates `N` numbered attendee resource
   groups (`labuser-01`, `labuser-02`, …) and assigns Owner to each lab
   user.

<!-- <<<INTERNAL_ONLY>>> -->
#### Optional: also create the lab users (`--create-users` / `-CreateUsers`)

Adds two more upstream steps **before** the three above:

- **`Create-MHUsers.ps1`** — creates `N` lab users in the `LabUsers`
  group and a 24-hour Temporary Access Pass per user, exported to
  `<bundle>/TemporaryAccessPasses.xlsx`. Requires Entra ID Premium P2
  for TAP and User/Group Administrator roles in Entra.
- **`Create-AdminUsers.ps1`** — creates `N` admin users in the
  `AdminUsers` group (password-based; pass via `--admin-password`).

```bash
./build-za.sh --coach --create-users --attendees 30 \
              --admin-password '<password>' \
              --event-start-date 2026-02-10T00:00:00
pwsh ./build-za.ps1 -Coach -CreateUsers -Attendees 30 `
              -AdminPassword (Read-Host -AsSecureString) `
              -EventStartDate '2026-02-10'
```

Extra modules required for `--create-users`: `Microsoft.Graph.Users`,
`Microsoft.Graph.Identity.SignIns`, `ImportExcel`.
<!-- <<<END_INTERNAL_ONLY>>> -->

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

#### Optional: Sovereignty Summit security group + Conditional Access exclusion

Default **on** under `--coach` (disable with `--no-create-summit-group`
and/or `--no-apply-ca-exclusion`):

- `--create-summit-group` — runs `New-SummitSecurityGroup.ps1` to create the
  parent group **"Microhack Sovereignty Summit"** with `LabUsers` + `AdminUsers`
  nested as members (rename with `--summit-group "<custom name>"`).
- `--apply-ca-exclusion` — runs `Set-CAExclusion.ps1` to add that group to the
  **Security info registration for Microsoft partners and vendors** Conditional
  Access policy's `excludeGroups`. If your Graph token lacks
  `Policy.ReadWrite.ConditionalAccess`, the helper prints exact portal steps.

#### Optional: ArcBox + LocalBox demo VMs (Challenges 5 & 6)

Off by default (they cost real money):

```bash
./build-za.sh --coach --create-users --attendees 30 \
              --admin-password '<pw>' \
              --deploy-arcbox --deploy-localbox \
              --demo-admin-password '<vm-admin-pw>'
```

| Flag | Default | Notes |
|---|---|---|
| `--deploy-arcbox` | off | Deploys ArcBox-full (~30 min) into `rg-arcbox` (`swedencentral`). Override with `--arcbox-rg`/`--arcbox-location` only if you know what you're doing — region is fixed by the upstream Bicep. |
| `--deploy-localbox` | off | Deploys LocalBox (~4-6 h async) into `rg-localbox` (`swedencentral` shell + Azure Local in `${country.azure.azure_local_instance_location}`). `--azure-local-instance-location` must stay in the LocalBox ValidateSet. |
| `--demo-admin-username` | `arcdemo` | Local VM admin username for both. |
| `--demo-admin-password` | (prompt) | Local VM admin password for both. |

Both deploy scripts apply `CostControl=Ignore` at the resource-group scope
automatically. **After the ~30 min ArcBox deploy completes**, copy-paste the
two commands the script prints to tag `ArcBox-Client` and delete its DevTestLab
auto-shutdown schedule (LocalBox prints the same for `LocalBox-Client`).

<!-- <<<INTERNAL_ONLY>>> -->
## Microhack prep guide cross-walk

| PDF page | Step | Wired here? |
|---|---|---|
| 1-4 | MCAPS subscription request | Manual (see `common/LOCAL_LAB.md` §1) |
| 5 | Security group "Microhack AVS Group" → renamed to **Microhack Sovereignty Summit** | ✅ `--create-summit-group` |
| 5-6 | Exclude group from Conditional Access "Security info registration for Microsoft partners and vendors" | ✅ `--apply-ca-exclusion` (auto + manual fallback) |
| 7 | Create-MH-Users + TAP | ✅ `--create-users` |
| 7 | Create-AdminUsers | ✅ `--create-users` |
| 7-8 | 1-resource-providers / 2-vcpu-quotas / 3-rbac / 4-resource-groups | ✅ wired into `--coach` |
| 9 | Quotas: Dsv5=8, Esv6=32, DCasv5=6 per student | ⚠️ Dsv5 + DCasv5 covered; **Esv6 must be requested manually** (script doesn't request that family) |
| 9-11 | Deploy ArcBox (~30 min) | ✅ `--deploy-arcbox` |
| 9-11 | Deploy LocalBox (~4-6 h) | ✅ `--deploy-localbox` |
| 11-12 | `CostControl=Ignore` on rg-arcbox/rg-localbox + clients + disable auto-shutdown | ✅ RG-level auto; client VM tag + schedule delete printed for coach after deploy |
| 12-13 | Cost estimates ~1000 USD/event | Documented in `common/LOCAL_LAB.md` §8.5 |
<!-- <<<END_INTERNAL_ONLY>>> -->

<!-- PUBLIC_REPLACEMENT_FOR_PREP_CROSSWALK
## What `--coach` does, step by step

| # | Step | Wired here? |
|---|---|---|
| 1 | Resource providers register | ✅ automatic |
| 2 | Security group "Microhack Sovereignty Summit" (parent over LabUsers + AdminUsers) | ✅ `--create-summit-group` |
| 3 | Conditional Access policy "Security info registration for Microsoft partners and vendors" excludes the group | ✅ `--apply-ca-exclusion` (auto + manual fallback) |
| 4 | vCPU quota verification (and optional request submission) | ✅ wired into `--coach` |
| 5 | RBAC: lab user group gets `Deployment Validator` + Security Reader + Resource Policy Contributor | ✅ wired into `--coach` |
| 6 | Per-attendee resource groups (`labuser-01` … `labuser-NN`) | ✅ wired into `--coach` |
| 7 | (optional) ArcBox + LocalBox demo VMs for Challenges 5 & 6 | ✅ `--deploy-arcbox` / `--deploy-localbox` |
| 8 | `CostControl=Ignore` tag on demo resource groups + auto-shutdown disable | ✅ RG-level auto; client VM tag + schedule delete printed after deploy |

> Note: lab user *creation* (Entra users + Temporary Access Passes) is left
> to the coach to perform via the Entra portal or partner-specific tooling.
> This repo does **not** ship a bulk-user-creation script for public use.
END_PUBLIC_REPLACEMENT_FOR_PREP_CROSSWALK -->

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

For a quick one-off scratch sub:

```bash
az group delete -n rg-<prefix>-foundation --yes --no-wait
az policy assignment delete --name <prefix>-allowed-locations
az policy assignment delete --name <prefix>-allowed-rg-locations
# Optional: purge the soft-deleted Key Vault (blocked while purge protection is on)
az keyvault purge --name <kv-name> --location ${country.azure.primary_region}
```

For a coach subscription that ran `--coach --create-users`, use the
**teardown** script which mirrors the build flag surface and handles
policy assignments, custom roles, attendee RGs, group role assignments,
soft-deleted Key Vaults, and Entra users + groups:

```bash
# Dry-run summary first (no flag = preview):
./teardown-za.sh --subscription <id> --attendees 30 --admin-user-count 5

# Tear down everything except Entra users + soft-deleted KVs:
./teardown-za.sh --apply --subscription <id> --attendees 30

# Full teardown — also remove lab/admin users, groups, and try to purge KVs:
./teardown-za.sh --apply --remove-users --purge-keyvault \
                 --subscription <id> --attendees 30 --admin-user-count 5
```

Notes:
- The sovereign foundation enables **Key Vault purge protection**, so
  `--purge-keyvault` will fail until the retention window expires
  (default 90 days). The soft-deleted vault will auto-purge after that.
- `--remove-users` deletes `LabUser-01..NN` and `AdminLabUser-01..NN`
  plus the `LabUsers`/`AdminUsers` groups in your **tenant**. Be sure
  you ran with the same `--attendees`/`--admin-user-count` you bootstrapped with.

## Files

| File | What it is |
|---|---|
| `main.bicep` | Subscription-scope orchestrator |
| `main.bicepparam` | Parameter file (edit prefix here if you want) |
| `modules/foundation.bicep` | RG-scoped: LAW, KV, identity, key, storage |
| `modules/policy-residency.bicep` | Subscription-scope: allowed-locations assignments |
| `build-za.sh` / `build-za.ps1` | One-shot wrappers |
| `teardown-za.sh` | Idempotent cleanup mirror of `build-za.sh` |

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
