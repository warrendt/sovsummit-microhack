# Local lab prerequisites — ${country.summit_edition}

> Country: **${country.name}**  ·  Primary region: `${country.azure.primary_region}` (${country.azure.primary_region_display})

Run through this checklist **before** the summit. Most steps take 5–15 minutes
each; total ~60 minutes including the quota request which may take a day.

## 1. Azure subscription

- [ ] Azure subscription with **Owner** or **Contributor + User Access
      Administrator** role.
- [ ] Free trial subscriptions are **not** supported (no Confidential Compute
      SKUs, no Premium Key Vault HSM).
- [ ] Tenant-level rights to create **Management Groups** (needed for the
      policy-initiative challenges). If you do not have these, ask your
      tenant admin to pre-create `mg-sovsummit-${country.iso2}` and assign
      you `Management Group Contributor`.

## 2. CLI tools

| Tool | Minimum version | Install |
|---|---|---|
| Azure CLI | 2.61 | `brew install azure-cli` / `winget install Microsoft.AzureCLI` |
| Azure PowerShell | 11.0 | `Install-Module Az -Force` |
| Bicep | 0.27 | `az bicep install` |
| kubectl | 1.30 | `az aks install-cli` |
| jq | latest | `brew install jq` / `winget install jqlang.jq` |
| gh (GitHub CLI) | 2.50 | `brew install gh` / `winget install GitHub.cli` |

After installing the Azure CLI, add the extensions used by these challenges:

```bash
az extension add --name aks-preview --upgrade
az extension add --name confidentialledger --upgrade
az extension add --name stack-hci --upgrade
az extension add --name connectedmachine --upgrade
```

## 3. Resource providers

Register every provider the upstream and country-specific challenges touch:

```bash
. ./countries/${country.iso2}/params/defaults.ps1  # PowerShell — optional, sets $Global:DefaultLocation
pwsh ./resources/subscription-preparations/1-resource-providers.ps1
```

Or in plain `az`:

```bash
for ns in Microsoft.Compute Microsoft.Storage Microsoft.KeyVault \
          Microsoft.ContainerService Microsoft.PolicyInsights \
          Microsoft.HybridCompute Microsoft.GuestConfiguration \
          Microsoft.AzureStackHCI Microsoft.OperationalInsights \
          Microsoft.Security Microsoft.Insights Microsoft.ManagedIdentity \
          Microsoft.Authorization; do
  az provider register --namespace "$ns"
done
```

## 4. vCPU quota

The Confidential Compute challenges need at least **8 vCPU** of the
`StandardDCASv5Family` and **8 vCPU** of the `StandardECASv5Family` in
`${country.azure.primary_region}` per attendee. Available CC SKUs in this
region: ${country.azure.confidential_compute_skus}.

Submit a quota request (interactive):

```powershell
pwsh ./resources/subscription-preparations/2-vcpu-quotas.ps1 -Region ${country.azure.primary_region} -NumberOfLabUsers 1 -SubmitQuotaRequests
```

Quota requests can take **up to 48 hours** — request well before the event.

## 5. RBAC + resource groups

```powershell
pwsh ./resources/subscription-preparations/3-rbac.ps1
pwsh ./resources/subscription-preparations/4-resource-groups.ps1 -Location ${country.azure.primary_region}
```

## 6. Verify

```bash
az login --tenant <your-tenant>
az account set --subscription <sub-id>
az group create -n rg-sovsummit-${country.iso2}-smoke -l ${country.azure.primary_region}
az group delete -n rg-sovsummit-${country.iso2}-smoke --yes --no-wait
```

If the create fails with `LocationNotAvailable`, your subscription is not
enabled for `${country.azure.primary_region}` — request access via the Azure
portal (Subscriptions → Resource providers/locations) or contact your CSAM.

## 7. Country-specific gotchas

- **Regulatory law in scope:** ${country.regulatory.primary_law}.
- **Frameworks you should skim before the event:**
  ${country.regulatory.frameworks}.
- **Regulator references:** ${country.regulatory.regulator_links}.

You're ready when `az group create` in `${country.azure.primary_region}` works
and `az vm list-skus -l ${country.azure.primary_region} --query "[?contains(name,'DC') || contains(name,'EC')].name"`
returns at least one Confidential Compute SKU (or returns empty *with a
documented workaround* in your country's `Readme.md`).

---

## 8. Coach-only: live event prep (PDF pp.5-12)

These steps map 1:1 to the upstream `Microhack_Prep.pdf` and are wired into
`build/${country.iso2}/bootstrap/build-${country.iso2}.sh --coach` for South
Africa. Other editions can run the same helpers manually from
`build/<iso2>/resources/preparation-helpers/`.

### 8.1 Security group + Conditional Access (PDF pp.5-6)

- Helper: `preparation-helpers/New-SummitSecurityGroup.ps1` — creates the parent
  **Microhack Sovereignty Summit** group and nests `LabUsers` + `AdminUsers`.
- Helper: `preparation-helpers/Set-CAExclusion.ps1` — adds that group to the
  **Security info registration for Microsoft partners and vendors** Conditional
  Access policy's `excludeGroups`. If the caller's Graph token lacks
  `Policy.ReadWrite.ConditionalAccess`, it prints exact portal steps.
- Wired flags (ZA): `--create-summit-group`, `--apply-ca-exclusion`,
  `--summit-group "<name>"`, `--ca-policy-name "<name>"`. Both default **on**
  under `--coach`.

### 8.2 vCPU quota (PDF p.9)

The prep guide calls for:

| Family | Quota / student | Default in `2-vcpu-quotas.ps1` |
|---|---|---|
| `standardDSv5Family` | 8 | ✅ 32 shared (covers 4 attendees per request) |
| `standardESv6Family` | 32 | ⚠️ **not** in the script's default request set — add manually for Confidential Compute (DC/EC families on Esv6 hardware) |
| `standardDCASv5Family` | 6 | ✅ requested per user |

If your Challenge 4 (Confidential Compute) attendees need the Esv6 hardware,
file an Esv6 quota request manually via the portal before the event.

### 8.3 ArcBox + LocalBox demo VMs (PDF pp.9-11)

For Challenges 5 & 6 the coach typically deploys two reference environments:

| Demo | Resource group | Region (HARDCODED) | Deploy time | Cost (approx) |
|---|---|---|---|---|
| ArcBox (full) | `rg-arcbox` | `swedencentral` | ~30 min | ~7 USD/day |
| LocalBox | `rg-localbox` | `swedencentral` shell + Azure Local instance in `westeurope`/etc. | ~4-6 h | ~40 USD/day |

⚠️ **Do not change the regions.** The upstream Bicep + Azure Local supported
location set is narrow; passing your country's primary region will fail.
Pre-fixed in `deploy-arcbox.ps1` and `deploy-localbox.ps1` (`ValidateSet` on
`AzureLocalInstanceLocation`).

Wired flags (ZA): `--deploy-arcbox`, `--deploy-localbox`,
`--demo-admin-password '<pw>'`, `--arcbox-rg`, `--localbox-rg`,
`--arcbox-location`, `--localbox-location`, `--azure-local-instance-location`,
`--demo-admin-username`.

### 8.4 Cost-control tagging (PDF pp.11-12)

MCAPS subscriptions auto-shutdown VMs unless tagged `CostControl=Ignore`.
The deploy scripts apply the tag at the RG scope automatically; the coach
must apply it to **the deployed VM** after the Bicep deploy finishes and
delete the auto-shutdown schedule:

```bash
az tag update --resource-id $(az vm show -g rg-arcbox -n ArcBox-Client --query id -o tsv) \
              --operation merge --tags CostControl=Ignore
az resource delete -g rg-arcbox \
              --resource-type microsoft.devtestlab/schedules \
              -n shutdown-computevm-ArcBox-Client
# Same for LocalBox-Client in rg-localbox.
```

`deploy-arcbox.ps1` / `deploy-localbox.ps1` print these exact commands when
their deploys finish.

### 8.5 What this costs (PDF pp.12-13)

A full Sov-Cloud MicroHack runs **~1000 USD per event** with 30 attendees over
two days. The bulk is ArcBox + LocalBox + Confidential Compute SKUs. Tear down
with `build/${country.iso2}/bootstrap/teardown-${country.iso2}.sh` when done.

