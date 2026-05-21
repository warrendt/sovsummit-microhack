# Solution — Challenge EG-02 (CBE hybrid Azure Local + Arc)

> Walkthrough for `${country.summit_edition}` / Challenge EG-02.

## 1. Stand up the lab Azure Local cluster

Use the upstream LocalBox helper pinned to a region near the lab (registration
plane lives in `${country.azure.azure_local_instance_location}`):

```powershell
. ./countries/${country.iso2}/params/defaults.ps1
./common/resources/demo-vm-creator/deploy-localbox.ps1 `
  -ResourceGroupName rg-eg-localbox `
  -Location $Global:DefaultLocation `
  -AzureLocalInstanceLocation $Global:DefaultAzureLocalInstanceLoc
```

Once the nested cluster is up, register it with Arc:

```bash
az stack-hci cluster show -g rg-eg-localbox --name eg-cluster
az connectedmachine list -g rg-eg-arc -o table
```

## 2. Hybrid landing-zone subscriptions

Create two subscriptions (or RGs in the lab):

- `sub-eg-regulated` → Arc-enabled on-prem only. Policy denies any Azure
  region.
- `sub-eg-derived`   → `${country.azure.primary_region}` /
  `${country.azure.paired_region}` only. Policy requires
  `cbe-tier=non-regulated` tag.

## 3. CBE Hybrid Landing Zone policy initiative

Key policies:

| Policy | Scope | Effect |
|---|---|---|
| Allowed locations = `${country.azure.primary_region}, ${country.azure.paired_region}` | `sub-eg-derived` | Deny |
| Storage account encryption keySource = Microsoft.Keyvault | `sub-eg-derived` | DeployIfNotExists |
| Require tag `cbe-tier` | both | Deny |
| Audit Arc machines missing tag `azure-arc-eg-data-centre` | `sub-eg-regulated` | Audit |
| Defender for Cloud (Standard) on storage + SQL + Arc | both | DeployIfNotExists |

## 4. Tokenisation pipeline

On the regulated AKS-on-Azure-Local cluster deploy Presidio (or your
tokeniser of choice). The pattern:

```
PII source -> Presidio (on-prem) -> tokenised stream -> Event Hubs in
${country.azure.primary_region} -> ADLS Gen2 (CMK from Premium KV) ->
Synapse / Fabric analytics
```

Wrapping key: generate in **on-prem HSM**, import as a BYOK blob into the
Premium Key Vault; never enable `Soft delete + Recover` for the wrapping key
material outside Egypt.

## 5. Telemetry split

- Regulated workloads → Arc MMA / AMA → on-prem syslog → SIEM in Cairo.
- Non-regulated workloads → Log Analytics workspace in
  `${country.azure.primary_region}` → Sentinel.

## 6. Verify

```bash
# Should be denied
az storage account create -n stregulated -g rg-eg-derived \
  -l ${country.azure.primary_region} --tags cbe-tier=regulated

# Tokenised end-to-end smoke test
kubectl -n tokeniser run smoke --image=ghcr.io/sovsummit/tokeniser-smoke -- \
  --pii "01099887766" --expect-token-prefix EG-TOK-
```

DR drill: restore a tokenised backup into `${country.azure.paired_region}`
and confirm `SELECT customer_id, msisdn FROM wallet.users LIMIT 1` returns
token strings, not raw MSISDNs.

## 7. Evidence

Map each control to:

- CBE Cloud Computing Framework Sections 5 (data localisation), 7 (key
  management), 9 (incident response).
- PDPL Articles 4 (purpose), 12 (processor obligations), 14 (cross-border),
  35 (security), 41 (breach notification).
