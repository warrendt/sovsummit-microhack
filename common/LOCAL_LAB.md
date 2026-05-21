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
