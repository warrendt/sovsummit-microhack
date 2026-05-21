# Sovereignty Summit Qatar 2026 — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **Qatar**.
> Generated from `common/` + `countries/qa/overrides/` via
> `tools/render.py`.

## Qatar context

| Item | Value |
|---|---|
| Country | Qatar |
| Primary Azure region | `qatarcentral` (Qatar Central) |
| Official Azure pair | Qatar Central has no official Azure pair |
| Customer-selected DR region for this edition | `uaenorth` (UAE North) |
| Primary data-protection law | Personal Data Privacy Protection Law (Law No. 13 of 2016) |
| Executive regulations | Council of Ministers Decision No. 17 of 2024 (Executive Regulations) |
| Data protection regulator | National Data Privacy Office / Qatar Data Protection Office under NCSA, with MCIT policy coordination |
| Frameworks in scope | Qatar PDPPL (Law No. 13 of 2016), Council of Ministers Decision No. 17 of 2024 (Executive Regulations), NCSA National Information Assurance Policy (NIA Policy) v2.0, Qatar Central Bank Cloud Computing Regulation, QFC Data Protection Regulations 2021 |
| NIA classification scheme | Public, Internal, Limited Access, Restricted |
| Confidential compute note | Azure Products by Region does not list Confidential Compute / confidential VMs for Qatar Central; this edition uses CMK, tokenisation and documented cross-border controls instead. |
| Key Vault SKU | Premium |
| Sponsor | Microsoft Qatar |

### Scenarios used throughout the challenges
- **Public sector:** Ministry of Communications and Information Technology (MCIT) digital public-services platform aligned to Qatar National Vision 2030
- **Financial services:** A QCB-regulated bank launching a real-time merchant-payments platform in Doha
- **QFC contrast:** A QFC-licensed asset manager receiving investor-reporting and risk analytics extracts

### Qatar-specific notes
- **Qatar Central** is an in-country Azure region, so the default pattern is to keep regulated production data in `qatarcentral`.
- Microsoft documents **`qatarcentral` as a nonpaired region**. This edition therefore treats `uaenorth` as a **customer-chosen DR / transfer region**, not an official Azure pair.
- Under **Personal Data Privacy Protection Law (Law No. 13 of 2016)** and **Council of Ministers Decision No. 17 of 2024 (Executive Regulations)**, Transfers outside Qatar require adequate protection or another permitted derogation, plus explicit governance records; special-nature data needs heightened approval and safeguards.
- The **NCSA NIA Policy v2.0** classification ladder — Public, Internal, Limited Access, Restricted — is used in this edition as the tagging taxonomy that drives Azure Policy decisions.
- For QCB-regulated workloads, cloud use requires formal governance, provider due diligence, auditability, exit planning and strong key-management controls. For QFC firms, QFC entities follow a separate GDPR-style privacy regime under the QFC Data Protection Regulations 2021, even though infrastructure may still sit in Azure public regions.
- Azure Products by Region does not list Confidential Compute / confidential VMs for Qatar Central; this edition uses CMK, tokenisation and documented cross-border controls instead.

## Challenges (Qatar edition order)

1. Azure native sovereign controls (Policy, RBAC) — [`challenges/challenge-01.md`](challenges/challenge-01.md)
2. Encryption at rest with CMK — [`challenges/challenge-02.md`](challenges/challenge-02.md)
3. Encryption in transit (TLS) — [`challenges/challenge-03.md`](challenges/challenge-03.md)
4. Confidential VMs — [`challenges/challenge-04.md`](challenges/challenge-04.md)
5. Confidential AKS — [`challenges/challenge-05.md`](challenges/challenge-05.md)
6. Azure Local + Arc — [`challenges/challenge-06.md`](challenges/challenge-06.md)
7. **🇶🇦 PDPPL + NIA classification guardrails** — [`challenges/challenge-qa-01-pdppl-nia-classification.md`](challenges/challenge-qa-01-pdppl-nia-classification.md)
8. **🇶🇦 QCB payments landing zone in Qatar Central** — [`challenges/challenge-qa-02-qcb-payments-landing-zone.md`](challenges/challenge-qa-02-qcb-payments-landing-zone.md)

## Attribution

Based on the [Microsoft Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud)
(MIT-licensed) by Jan Egil Ring, Ye Zhang, Murali Rao Yelamanchili and other
Microsoft contributors. Qatar customizations © Sovereignty Summit QA Chapter.
