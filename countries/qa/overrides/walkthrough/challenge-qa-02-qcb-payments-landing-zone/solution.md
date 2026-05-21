# Solution — Challenge QA-02 (QCB payments landing zone)

> Walkthrough for `${country.summit_edition}` / Challenge QA-02.
> Primary region: `${country.azure.primary_region}`.

## 1. Create the workload split

Use two logical zones:

- `sub-qa-payments-prod` → production payments in `${country.azure.primary_region}` only.
- `sub-qa-payments-dr` → controlled DR / analytics in `${country.azure.paired_region}` for tokenised or encrypted backup data only.

This is necessary because ${country.azure.official_region_pair}; `${country.azure.paired_region}` is a deliberate customer DR choice rather than an Azure-managed pair.

## 2. Build the QCB initiative

Core policies:

| Policy | Scope | Effect |
|---|---|---|
| Allowed locations = `${country.azure.primary_region}` | prod subscription | Deny |
| Allowed locations = `${country.azure.primary_region}`, `${country.azure.paired_region}` | DR subscription | Deny |
| Storage / SQL / disk encryption with CMK | both | Deny or DeployIfNotExists |
| Public network access disabled for Storage / SQL / Key Vault | both | Deny |
| Require tags `qcb-approval-id`, `outsourcing-tier`, `dr-transfer-approved`, `nia-classification` | both | Deny |
| Custom `QaProdNoDrDataStores` | DR subscription | Deny if production-class data store lacks `dr-transfer-approved=yes` |

```bash
az policy set-definition create \
  --name qa-qcb-payments \
  --display-name "QCB Payments Landing Zone" \
  --management-group mg-sovsummit-qa \
  --definitions @qa-qcb-payments.initiative.json
```

## 3. Provision the Qatar Central CMK stack

```bash
az keyvault create \
  --name kv-qa-payments-$RANDOM \
  --resource-group rg-qa-payments-platform \
  --location ${country.azure.primary_region} \
  --sku ${country.azure.cmk_hsm_sku} \
  --enable-purge-protection true \
  --enable-rbac-authorization true

az storage account create \
  --name stqapaymentsprod$RANDOM \
  --resource-group rg-qa-payments-prod \
  --location ${country.azure.primary_region} \
  --sku Standard_ZRS \
  --public-network-access Disabled
```

Attach the CMK from the Premium vault before onboarding application data.

## 4. Compensating control for missing confidential compute

${country.azure.confidential_compute_note}

Use this lab pattern instead:

```text
Card / payer data in ${country.azure.primary_region}
-> tokenisation or masking job in ${country.azure.primary_region}
-> approved replica in ${country.azure.paired_region}
-> DR restore / analytics without de-tokenisation keys
```

Keep re-identification keys and vault administration in `${country.azure.primary_region}`.

## 5. QFC contrast

For `${country.scenarios.qfc_tenant}` create a separate policy assignment that:

- requires processor contracts and transfer records,
- allows `${country.azure.paired_region}` for analytics,
- still denies unrestricted public endpoints,
- keeps the free-zone evidence pack distinct from the state-wide QCB evidence pack.

Reference URLs:
- QCB: `${country.regulatory.qcb_regulation_url}`
- QFC DPO: `${country.regulatory.qfc_dpo_url}`

## 6. Verify

```bash
# Should be denied: no CMK
az storage account create -n stnocmkqa -g rg-qa-payments-prod \
  -l ${country.azure.primary_region} --sku Standard_LRS

# Should be denied: production data in UAE North
az sql server create -n sqlqadrtest -g rg-qa-payments-dr -l ${country.azure.paired_region} \
  --tags qcb-approval-id=QCB-2026-014 outsourcing-tier=critical dr-transfer-approved=no nia-classification=Restricted

# Smoke test: only tokenised rows replicate
az policy state list --management-group mg-sovsummit-qa -o table
```

Evidence mapping:

- QCB cloud regulation → approval, outsourcing governance, audit rights, exit planning, resilience testing.
- PDPPL / executive regulations → transfer documentation and technical safeguards.
- QFC regulations → lawful transfer mechanics for the free-zone analytics case.
