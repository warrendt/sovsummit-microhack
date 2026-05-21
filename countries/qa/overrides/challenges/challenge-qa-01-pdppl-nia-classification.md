# Challenge QA-01 — PDPPL + NIA classification, transfer decisioning and cloud guardrails

[Previous Challenge](challenge-06.md) — **[Home](../Readme.md)** — [Next Challenge](challenge-qa-02-qcb-payments-landing-zone.md)

> **Country:** ${country.name}
> **Edition:** ${country.summit_edition}
> **Primary region:** `${country.azure.primary_region}` (${country.azure.primary_region_display})
> **Classification model used in this challenge:** ${country.regulatory.classification_scheme}

## The situation

You are the lead cloud governance engineer for **${country.scenarios.public_sector_tenant}**.
The platform is about to onboard four high-profile services into one shared landing zone:

1. a **citizen identity and benefits portal**,
2. a **ministerial case-management system** with complaint attachments,
3. a **payments-reconciliation feed** exchanged with a QCB-regulated settlement bank, and
4. a **public information portal** that is safe for broad publication.

The programme sponsor wants one answer to three questions before deployment starts:

- **How should each dataset be classified under the Qatar NIA / national classification model?**
- **Which datasets must remain in `${country.azure.primary_region}` and which can move to `${country.azure.paired_region}`?**
- **How do we prove that Azure Policy enforces the decision rather than relying on manual discipline?**

This is not just a tagging exercise. You must combine:

- **${country.regulatory.primary_law}** — controller accountability, security safeguards, processor oversight and special-nature data handling,
- **current NCSA / NDPO guidance** for regulated entities,
- **National Information Assurance Standard v2.1 + National Data Classification Policy** for classification and control scaling,
- **QCB Cloud Computing Regulation** where the settlement-bank feed touches payment and financial information.

## What you must produce

Build a working control package called **`Qatar PDPPL + NIA Classification Guardrails`** that includes all four of these artefacts.

### 1) Dataset classification matrix

Create a table with at least these columns:

| Dataset / flow | NIA class | PDPPL data type | Special-nature? | QCB impact? | Default region | Can move to `${country.azure.paired_region}`? | Required safeguard |
|---|---|---|---|---|---|---|---|

Your matrix must cover, at minimum:

- citizen profile + national ID fields,
- health or disability attachments used for benefits eligibility,
- ministerial complaints and investigation notes,
- payment-reconciliation exports with merchant / payer identifiers,
- public FAQs and service status content,
- masked or tokenised analytics extracts.

### 2) Cross-border decision register

For each flow that could leave Qatar, record:

- the **business purpose**,
- the **legal / regulatory basis**,
- the **destination**,
- whether the destination receives **raw, masked, tokenised or encrypted-backup** data,
- the **processor / due-diligence reference**,
- the **approver**,
- the **expiry / review date**.

Use this rule of thumb in the lab:

- PDPPL is **not** an automatic blanket data-localisation law.
- But a transfer still needs a **documented controller decision**, processor oversight and evidence that the move does not undermine privacy obligations.
- For **QCB-regulated payment data**, use the stricter sector rule: **PII and financial information stay processed in Qatar**. If anything reaches `${country.azure.paired_region}`, it must be tokenised, masked or encrypted-backup content only.

### 3) Azure Policy initiative

Create a country-specific initiative named **`Qatar PDPPL + NIA Classification Guardrails`** that enforces all of the following:

#### Mandatory tags

Require these tags on resource groups and data-handling resources:

- `nia-classification` = `Public|Internal|Limited Access|Restricted`
- `pdppl-data-type` = `non-personal|personal|special-nature|anonymised|tokenised`
- `data-owner` = business owner / ministry / entity
- `processing-purpose` = approved service identifier
- `transfer-decision-id` = approved register reference or `none`
- `qcb-impact` = `none|supporting|regulated-payments`

#### Location rules

- **Deny** `Limited Access` and `Restricted` workloads outside `${country.azure.primary_region}`.
- **Deny** any resource with `qcb-impact=regulated-payments` outside `${country.azure.primary_region}`.
- **Allow** `${country.azure.paired_region}` only for `Public`, `Internal`, or explicitly `tokenised` data where `transfer-decision-id` is populated.

#### Stronger controls for higher-risk data

- **Deny** `pdppl-data-type=special-nature` unless the storage layer is CMK-backed.
- **Deny** storage / SQL / Key Vault resources unless public network access is disabled.
- **Require** diagnostics to a Log Analytics workspace in `${country.azure.primary_region}`.
- **Require** private endpoints for SQL / Storage / Key Vault handling `special-nature`, `Limited Access` or `Restricted` data.

### 4) Evidence narrative

Write a short regulator-facing explanation covering:

- why each dataset got its classification,
- why some flows can move and others cannot,
- how the QCB overlay changes the answer for payment data,
- how policy, tags and CMK/private-endpoint controls make the decision enforceable.

## Success criteria

- [ ] An untagged resource group is denied.
- [ ] A `Restricted` workload aimed at `${country.azure.paired_region}` is denied.
- [ ] A `qcb-impact=regulated-payments` SQL or Storage deployment outside `${country.azure.primary_region}` is denied.
- [ ] A `Public` or `tokenised` analytics workload can deploy to `${country.azure.paired_region}` only when `transfer-decision-id` is present.
- [ ] `special-nature` data stores are blocked unless CMK + private connectivity requirements are met.
- [ ] `az policy state list --filter "ComplianceState eq 'NonCompliant'"` returns no unresolved violations after remediation.
- [ ] Your classification matrix and transfer register tell a coherent story that a privacy officer and a cloud auditor would both accept.

## Guiding questions

- Which datasets are merely *sensitive*, and which are truly *special-nature* under PDPPL Article 16?
- Does a move to `${country.azure.paired_region}` change the privacy answer if the dataset is tokenised first and re-identification keys never leave `${country.azure.primary_region}`?
- Where does the QCB rule become stricter than the general PDPPL position?
- Which control belongs in a tag, which in Azure Policy, and which in the human approval workflow?

## Hints

- Start with built-ins such as **Allowed locations**, **Require a tag on resources**, **Require a tag and its value**, **Storage accounts should use customer-managed key for encryption**, and public-network-access deny policies.
- A practical custom rule is: `if nia-classification in ['Limited Access','Restricted'] then location must equal ${country.azure.primary_region}`.
- Another useful custom rule is: `if qcb-impact = regulated-payments then deny unless location = ${country.azure.primary_region}`.
- Treat the transfer register as a companion control to policy: policy enforces the tag, while the register proves the tag value was properly approved.
- Official reference points: ${country.regulatory.primary_regulator_url} and ${country.regulatory.qcb_regulation_url}

## Estimated duration

90 minutes.
