# Solution — Challenge 4 (Qatar equivalent controls for the Confidential Compute gap)

> Walkthrough for `Sovereignty Summit Qatar 2026` / Challenge 4.

## 1. Start with the honest statement

`As of 2026, Azure Products by Region still does not show Confidential Compute / confidential VM SKUs as GA in Qatar Central; this edition therefore uses CMK, tokenisation, private connectivity and SQL column-level protections as compensating controls.`

That means the right Qatar answer is not “deploy a confidential VM anyway.”
It is “use the strongest available compensating controls, document the residual risk, and define the review trigger for when the region catches up.”

## 2. Equivalent-control stack

| Need | Qatar design today |
|---|---|
| Strong key custody | `Premium` Key Vault in `qatarcentral` with RBAC, purge protection and logging |
| Private service access | Private endpoints for SQL / Storage / Key Vault, no public network access |
| Sensitive columns protected in the database | Always Encrypted; use secure enclaves if supported by the chosen Azure SQL deployment |
| Safe DR / analytics | Tokenise or mask before export to `uaenorth` |
| Admin blast-radius reduction | Separate RBAC roles for workload ops, DB admins and key custodians |
| Regulator-ready explanation | Residual-risk note that memory is not hardware-confidential yet |

## 3. Suggested architecture narrative

```text
App tier in qatarcentral
-> tokenisation service in qatarcentral
-> Azure SQL / Storage with CMK + private endpoints
-> transformed-data-only feed to uaenorth
-> no detokenisation keys, no raw PII, no raw financial data leave Qatar
```

## 4. Example build steps

```bash
az keyvault create \
  --name kv-qa-gap-$RANDOM \
  --resource-group rg-qa-sensitive \
  --location qatarcentral \
  --sku Premium \
  --enable-rbac-authorization true \
  --enable-purge-protection true
```

Then:

1. create SQL / Storage privately,
2. attach CMKs,
3. enable Always Encrypted for the highest-value columns,
4. add app-tier tokenisation before any DR or analytics export,
5. log every key access and admin elevation.

## 5. Residual-risk wording

Use wording close to this:

> This workload uses the strongest currently available controls in Qatar Central: HSM-backed CMK, private connectivity, RBAC separation, column-level encryption and tokenisation before transfer. These controls substantially reduce exposure but do not provide hardware-backed memory confidentiality or attestation. The workload must therefore be re-reviewed when Confidential Compute reaches GA in Qatar Central.

## 6. What “done” looks like

You are successful when you can clearly distinguish between:

- **controls we have now**,
- **the protection Confidential Compute would add later**, and
- **the residual risk leadership is consciously accepting today**.
