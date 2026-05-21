# Solution — Challenge NG-02 (CBN hybrid Azure Local + Arc)

> Walkthrough for `${country.summit_edition}` / Challenge NG-02.

## 1. Stand up the lab Azure Local cluster

Use the upstream LocalBox helper and pin the registration plane to
`${country.azure.azure_local_instance_location}`:

```powershell
. ./countries/${country.iso2}/params/defaults.ps1
./common/resources/demo-vm-creator/deploy-localbox.ps1 `
  -ResourceGroupName rg-ng-localbox `
  -Location $Global:DefaultLocation `
  -AzureLocalInstanceLocation $Global:DefaultAzureLocalInstanceLoc
```

Once the nested cluster is ready, connect it to Arc:

```bash
az stack-hci cluster show -g rg-ng-localbox --name ng-cluster
az connectedmachine list -g rg-ng-arc -o table
```

## 2. Create the regulated / derived split

Use two subscriptions or (for the lab) two resource groups:

- `rg-ng-regulated` → Arc-enabled on-prem workloads only.
- `rg-ng-derived`   → `${country.azure.primary_region}` /
  `${country.azure.paired_region}` only.

Tag convention:

- `cbn-tier=regulated`
- `cbn-tier=derived`
- `ng-datacentre=lagos-dc1` (or your test site)
- `cbn-outsourcing-id=<board-approved reference>`

## 3. Build the CBN Hybrid Landing Zone policy initiative

Key policies:

| Policy | Scope | Effect |
|---|---|---|
| Deny locations for `cbn-tier=regulated` in public Azure | derived subscription | Deny |
| Allowed locations = `${country.azure.primary_region}, ${country.azure.paired_region}` | derived subscription | Deny |
| Storage account encryption keySource = Microsoft.Keyvault | derived subscription | DeployIfNotExists |
| Require tags `cbn-tier`, `ng-datacentre`, `cbn-outsourcing-id`, `data-classification` | both | Deny / Audit |
| Defender for Cloud on storage + SQL + Arc | both | DeployIfNotExists |

This gives you a direct line from technical policy to CBN expectations around
third-party risk management, monitoring and compliance.

## 4. Tokenisation pipeline

Deploy the tokeniser **inside Nigeria** on the regulated cluster.

```text
Customer PII source
  -> Tokeniser on Azure Local / AKS
  -> Token-only stream
  -> Event Hubs in ${country.azure.primary_region}
  -> ADLS Gen2 (CMK in Premium Key Vault)
  -> Synapse / Fabric analytics
```

Detokenisation secret / key material must remain in Nigeria. For the lab, that
can be an on-prem HSM-backed secret store or a service endpoint reachable only
from the regulated network.

## 5. Telemetry split

- **Regulated workloads:** Arc agents -> on-prem syslog / SIEM in Nigeria.
- **Derived workloads:** Log Analytics workspace in `${country.azure.primary_region}` -> Sentinel.

If you test an incident scenario, record two clocks:

1. time of detection for the bank SOC,
2. time the CBN / internal regulatory workflow is opened.

This helps prove compliance with the CBN framework's monitoring and reporting
expectations.

## 6. Outsourcing evidence pack

Capture at least these artefacts:

1. Cloud-provider due-diligence checklist.
2. Board / management approval reference for the cloud arrangement.
3. Contract clause inventory: audit rights, regulator access, breach notice,
   location transparency, sub-outsourcing controls.
4. Exit and repatriation plan: how regulated workloads fall back to the Nigeria
   tier if `${country.azure.primary_region}` is unavailable.
5. Mapping of controls to CBN framework sections and NDPA safeguards.

## 7. Verify

```bash
# Should be denied
az vm create -n vm-ng-regulated-test -g rg-ng-derived \
  --image Ubuntu2204 --location ${country.azure.primary_region} \
  --tags cbn-tier=regulated

# Tokenised smoke test
kubectl -n tokeniser run smoke --image=ghcr.io/sovsummit/tokeniser-smoke -- \
  --pii "22222222222" --expect-token-prefix NG-TOK-
```

Restore a tokenised backup into `${country.azure.paired_region}` and confirm the
dataset is analytically useful but does not reveal raw customer identifiers.

## 8. Evidence mapping

Map each control to:

- **CBN Risk-Based Cybersecurity Framework (2024)** — **para. 2.1.5**
  (risk monitoring/reporting), **para. 2.6** (third-party risk), **para. 5**
  (metrics / incident reporting), **para. 6** (regulatory compliance),
  **para. 7** (enforcement).
- **CBN Shared Services / Outsourcing Guidelines** — approval, contract,
  audit-rights, exit/repatriation.
- **NDPA 2023** — security/accountability, breach handling, cross-border
  treatment of derived datasets.
