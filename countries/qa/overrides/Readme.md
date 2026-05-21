# ${country.summit_edition} — MicroHack

Welcome to the **Qatar edition** of the Sovereignty Summit MicroHack. This pack is designed for self-paced delivery by cloud architects, platform engineers, security teams and regulators who want a realistic Qatar-focused Azure design exercise.

## What makes the Qatar edition different

| Topic | Qatar edition position |
|---|---|
| Production region | `${country.azure.primary_region}` (${country.azure.primary_region_display}) is the default in-country region for regulated workloads. |
| DR / transfer region | `${country.azure.paired_region}` (${country.azure.paired_region_display}) is used in this edition as a customer-selected DR region; `${country.azure.primary_region_display}` has no official Azure pair. |
| Privacy law | ${country.regulatory.primary_law} remains the base mainland privacy law. |
| Public guidance baseline | ${country.regulatory.executive_regulations} |
| Cyber / assurance baseline | ${country.regulatory.frameworks} |
| Classification model used in this lab | ${country.regulatory.classification_scheme} |
| Financial-sector overlay | QCB Cloud Computing Regulation, effective 15 April 2024, with explicit governance, audit, exit-plan, key-management and data-protection obligations. |
| QFC overlay | ${country.regulatory.qfc_contrast} |
| Encryption-in-use constraint | ${country.azure.confidential_compute_note} |

## Operating assumptions for every challenge

1. **Keep regulated production data in `${country.azure.primary_region}` by default.**
2. **Treat `${country.azure.paired_region}` as an explicitly approved transfer / DR region, not an automatic pair.**
3. **Run a transfer decision before moving data out of Qatar.** PDPPL requires controller accountability and processor oversight, while ${country.regulatory.cross_border_rule}
4. **Use HSM-backed customer-managed keys.** The standard pattern in this edition is a `${country.azure.cmk_hsm_sku}` Key Vault in `${country.azure.primary_region}` with strict RBAC, purge protection and private access.
5. **Do not rely on Confidential Compute in `${country.azure.primary_region}`.** Challenge 4 is explicitly replaced with a Qatar-specific equivalent-controls exercise.

## Recommended way to work through the lab

- Read the scenario and write down the **business decision**, not just the Azure resource list.
- Classify the data first.
- Decide what must stay in Qatar, what may move, and what must be tokenised or masked before transfer.
- Build the smallest policy set that can enforce that decision.
- Capture an evidence pack: policy assignment, tags, key-management settings, private endpoint layout, and the transfer rationale.

## Challenge order

1. Azure native sovereign controls (Policy, RBAC) — [`challenges/challenge-01.md`](challenges/challenge-01.md)
2. Encryption at rest with CMK — [`challenges/challenge-02.md`](challenges/challenge-02.md)
3. Encryption in transit (TLS) — [`challenges/challenge-03.md`](challenges/challenge-03.md)
4. **🇶🇦 Equivalent controls for the Confidential Compute gap** — [`challenges/challenge-04.md`](challenges/challenge-04.md)
5. Confidential AKS — [`challenges/challenge-05.md`](challenges/challenge-05.md)
6. Azure Local + Arc — [`challenges/challenge-06.md`](challenges/challenge-06.md)
7. **🇶🇦 PDPPL + NIA classification and cross-border decisioning** — [`challenges/challenge-qa-01-pdppl-nia-classification.md`](challenges/challenge-qa-01-pdppl-nia-classification.md)
8. **🇶🇦 QCB payments landing zone in Qatar Central** — [`challenges/challenge-qa-02-qcb-payments-landing-zone.md`](challenges/challenge-qa-02-qcb-payments-landing-zone.md)

## Suggested evidence pack

By the end of the Qatar edition you should be able to hand over:

- a classification matrix,
- a cross-border / DR decision register,
- policy definitions and assignments,
- proof of CMK and private connectivity,
- a residual-risk statement for the lack of Confidential Compute in `${country.azure.primary_region}`,
- a regulator-ready architecture narrative for PDPPL, QCB and (where relevant) QFC.

## Official reference points

- NCSA / NDPO: ${country.regulatory.primary_regulator_url}
- QCB Cloud Computing Regulation: ${country.regulatory.qcb_regulation_url}
- QFC Data Protection Office: ${country.regulatory.qfc_dpo_url}

## Attribution

Based on the [Microsoft Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud)
(MIT-licensed) by Jan Egil Ring, Ye Zhang, Murali Rao Yelamanchili and other Microsoft contributors. Qatar customizations © Sovereignty Summit QA Chapter.
