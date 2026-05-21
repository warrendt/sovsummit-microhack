# Solution — Challenge QA-01 (PDPPL + NIA classification and transfer decisioning)

> Walkthrough for `Sovereignty Summit Qatar 2026` / Challenge QA-01.
> Primary region: `qatarcentral`.

## 1. Build the classification matrix first

A good answer starts with the data, not the resources.

| Dataset / flow | NIA class | PDPPL type | Special-nature? | QCB impact | Region decision | Notes |
|---|---|---|---|---|---|---|
| Public service FAQs | Public | non-personal | No | none | `qatarcentral` or `uaenorth` | Safe for public replication. |
| Internal case-routing metadata | Internal | personal | No | none | `qatarcentral` by default; `uaenorth` only with approved transfer record | Still personal data; do not move casually. |
| Citizen profile + national ID | Restricted | personal | No | none | `qatarcentral` only | High misuse impact even if not Article 16 special-nature. |
| Benefits health attachments | Restricted | special-nature | Yes | none | `qatarcentral` only | PDPPL Article 16 + stronger technical safeguards. |
| Complaints + investigation notes | Limited Access or Restricted | personal | Context-dependent | none | `qatarcentral` only unless redacted | Usually too sensitive for routine export. |
| Settlement-bank payment reconciliation | Restricted | personal | Usually No | regulated-payments | `qatarcentral` only | QCB 21.4 keeps PII and financial information processed in Qatar. |
| Tokenised analytics extract | Internal | tokenised | No | supporting | `uaenorth` allowed with register entry | Re-identification keys stay in Qatar. |

## 2. Record the transfer decision

Use a compact register with one row per approved movement:

| transfer-decision-id | Dataset | Destination | Data form | Processor / service | Why allowed | Review date |
|---|---|---|---|---|---|---|
| QA-XFER-001 | Public FAQs | `uaenorth` | public | Azure Storage RA copy | Public content only | 12 months |
| QA-XFER-002 | Tokenised analytics extract | `uaenorth` | tokenised | Azure SQL read replica / Storage | Analytics only; re-identification keys remain in `qatarcentral` | 6 months |
| DENIED | Payment reconciliation | `uaenorth` | raw PII / financial data | N/A | QCB 21.4 requires PII and financial info processing in Qatar | N/A |

## 3. Build the initiative

Bundle these policies into **`Qatar PDPPL + NIA Classification Guardrails`**:

| Policy | Effect | Why |
|---|---|---|
| Allowed locations | Deny | Base region fence. |
| Require classification / owner / purpose / transfer tags | Deny | Makes every data workload explain itself. |
| `QaRestrictedInCountryOnly` | Deny | Forces `Limited Access` / `Restricted` to `qatarcentral`. |
| `QaQcbPaymentsInCountryOnly` | Deny | Blocks regulated payment data outside Qatar. |
| `QaTransferDecisionRequired` | Deny | `uaenorth` needs a non-empty `transfer-decision-id`. |
| Storage / SQL CMK enforcement | Deny or DeployIfNotExists | Required for high-impact data stores. |
| Public network access disabled | Deny | Keeps sensitive services private. |
| Diagnostics to Qatar workspace | DeployIfNotExists | Keeps the evidence trail in-country. |

## 4. Example assignment flow

```bash
az policy set-definition create \
  --name qa-pdppl-nia-guardrails \
  --display-name "Qatar PDPPL + NIA Classification Guardrails" \
  --management-group mg-sovsummit-qa \
  --definitions @qa-pdppl-nia-guardrails.json

az policy assignment create \
  --name qa-pdppl-nia-guardrails \
  --policy-set-definition qa-pdppl-nia-guardrails \
  --scope /providers/Microsoft.Management/managementGroups/mg-sovsummit-qa \
  --location qatarcentral \
  --mi-system-assigned
```

## 5. Negative tests you should run

```bash
# Denied: restricted workload in UAE North
az group create -n rg-qa-restricted-dr -l uaenorth \
  --tags nia-classification=Restricted pdppl-data-type=personal \
         data-owner=MCIT processing-purpose=citizen-portal \
         transfer-decision-id=QA-XFER-999 qcb-impact=none

# Denied: payment-regulated data outside Qatar
az storage account create -n stqapaydr$RANDOM -g rg-qa-dr -l uaenorth \
  --tags nia-classification=Restricted pdppl-data-type=personal \
         data-owner=BankOps processing-purpose=payments-dr \
         transfer-decision-id=QA-XFER-888 qcb-impact=regulated-payments

# Allowed only with decision record: tokenised analytics
az group create -n rg-qa-analytics-dr -l uaenorth \
  --tags nia-classification=Internal pdppl-data-type=tokenised \
         data-owner=MCIT processing-purpose=analytics \
         transfer-decision-id=QA-XFER-002 qcb-impact=none
```

## 6. Evidence mapping

- **PDPPL Articles 12–14** → controller / processor safeguards and breach handling.
- **PDPPL Article 16** → special-nature data approval and extra precautions.
- **National Information Assurance Standard v2.1 + National Data Classification Policy** → classification-driven control scaling.
- **QCB Cloud Computing Regulation 20 and 21** → key management, least privilege, segregation, private handling and in-Qatar processing of PII / financial data.

## 7. What “good” looks like

A strong submission does **not** say “everything is restricted and must stay in Qatar.”
It shows that you can:

- distinguish public, internal, restricted and tokenised flows,
- justify why some lower-risk or transformed data can move,
- prove why raw payment or special-nature data cannot,
- convert that reasoning into enforceable Azure Policy.
