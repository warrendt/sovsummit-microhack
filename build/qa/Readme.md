# Sovereignty Summit Qatar 2026 — MicroHack

Welcome to the **Qatar edition** of the Sovereignty Summit MicroHack. This pack is designed for self-paced delivery by cloud architects, platform engineers, security teams and regulators who want a realistic Qatar-focused Azure design exercise.

## What makes the Qatar edition different

| Topic | Qatar edition position |
|---|---|
| Production region | `qatarcentral` (Qatar Central) is the default in-country region for regulated workloads. |
| DR / transfer region | `uaenorth` (UAE North) is used in this edition as a customer-selected DR region; `Qatar Central` has no official Azure pair. |
| Privacy law | Personal Data Privacy Protection Law (Law No. 13 of 2016) remains the base mainland privacy law. |
| Public guidance baseline | As of 2026, no public PDPPL executive-regulation text was verified; the operable public compliance baseline is Law No. 13 of 2016 plus NCSA / NDPO guidance and enforcement decisions. |
| Cyber / assurance baseline | Qatar PDPPL (Law No. 13 of 2016), NCSA / NDPO PDPPL guidance suite for regulated entities, National Information Assurance Standard v2.1 (May 2023), National Data Classification Policy [IAP-NAT-DCLS], Qatar Central Bank Cloud Computing Regulation (effective 15 April 2024), QFC Data Protection Regulations 2021 and Data Protection Rules 2021 (in force 19 June 2022) |
| Classification model used in this lab | Public, Internal, Limited Access, Restricted |
| Financial-sector overlay | QCB Cloud Computing Regulation, effective 15 April 2024, with explicit governance, audit, exit-plan, key-management and data-protection obligations. |
| QFC overlay | QFC firms follow a separate QFC Data Protection Regulations 2021 regime administered by the QFC Data Protection Office; it is GDPR-style, contract-heavy and distinct from mainland Qatar PDPPL compliance. |
| Encryption-in-use constraint | As of 2026, Azure Products by Region still does not show Confidential Compute / confidential VM SKUs as GA in Qatar Central; this edition therefore uses CMK, tokenisation, private connectivity and SQL column-level protections as compensating controls. |

## Operating assumptions for every challenge

1. **Keep regulated production data in `qatarcentral` by default.**
2. **Treat `uaenorth` as an explicitly approved transfer / DR region, not an automatic pair.**
3. **Run a transfer decision before moving data out of Qatar.** PDPPL requires controller accountability and processor oversight, while PDPPL Article 15 is not a blanket localisation rule, but controllers still need a documented legality, privacy and processor-risk assessment before cross-border transfers; for QCB-regulated workloads, QCB Cloud Computing Regulation 21.4 is stricter and requires PII and financial information to be processed within Qatar.
4. **Use HSM-backed customer-managed keys.** The standard pattern in this edition is a `Premium` Key Vault in `qatarcentral` with strict RBAC, purge protection and private access.
5. **Do not rely on Confidential Compute in `qatarcentral`.** Challenge 4 is explicitly replaced with a Qatar-specific equivalent-controls exercise.

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
- a residual-risk statement for the lack of Confidential Compute in `qatarcentral`,
- a regulator-ready architecture narrative for PDPPL, QCB and (where relevant) QFC.

## Official reference points

- NCSA / NDPO: https://www.ncsa.gov.qa/
- QCB Cloud Computing Regulation: https://www.qcb.gov.qa/Documents/InformationSecurity/Cloud%20Computing%20Regulation.pdf
- QFC Data Protection Office: https://www.qfc.qa/en/operating-with-qfc/data-protection

## Attribution

Based on the [Microsoft Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud)
(MIT-licensed) by Jan Egil Ring, Ye Zhang, Murali Rao Yelamanchili and other Microsoft contributors. Qatar customizations © Sovereignty Summit QA Chapter.
