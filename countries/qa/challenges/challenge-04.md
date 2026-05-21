# Challenge 4 — Qatar equivalent controls when Confidential Compute is unavailable

[Previous Challenge](challenge-03.md) — **[Home](../Readme.md)** — [Next Challenge](challenge-05.md)

> **Country:** Qatar
> **Primary region:** `qatarcentral` (Qatar Central)
> **Qatar reality:** As of 2026, Azure Products by Region still does not show Confidential Compute / confidential VM SKUs as GA in Qatar Central; this edition therefore uses CMK, tokenisation, private connectivity and SQL column-level protections as compensating controls.

## The situation

A ministry payroll workload and a QCB-regulated payments workload both ask the same question:

> “If Qatar Central does not yet offer Confidential Compute, what is the most defensible Azure design we can use today — and what risk remains?”

This challenge turns that gap into the main learning objective.

You are **not** allowed to pretend confidential VMs exist in `qatarcentral`.
Instead, you must design the **closest practical equivalent-control stack** and explain exactly where it falls short of true hardware-backed encryption in use.

## Your mission

Build a Qatar-specific control pattern for highly sensitive workloads that combines:

- **HSM-backed CMK** in `qatarcentral`,
- **private-only connectivity** to data services,
- **SQL Always Encrypted** for the most sensitive columns, using **secure enclaves if available for the selected Azure SQL deployment**,
- **application-tier tokenisation** whenever data may need to leave the primary trust boundary,
- **strict separation of duties** between application admins, DB admins and key custodians,
- **documented residual risk and review trigger** for the day Confidential Compute becomes available in Qatar Central.

## Learning objectives

- Explain what Azure Confidential Compute would protect that ordinary CMK + private networking does not.
- Design a compensating-control stack that is credible for Qatar **today**.
- Use tokenisation and column-level encryption to keep raw identifiers and special-nature fields out of DR, analytics and operator workflows.
- Produce a residual-risk statement a regulator can actually understand.

## Required design outputs

### 1) Equivalent-control matrix

Create a table like this:

| Threat / regulator concern | Confidential Compute answer | Qatar alternative today | Residual risk |
|---|---|---|---|
| Hypervisor / host-admin visibility into workload memory | Hardware-backed encrypted memory + attestation | Not available in `qatarcentral` | Residual memory-exposure risk remains |
| Raw identifiers in database | Confidential execution + column protection | Always Encrypted, optionally with secure enclaves | Query flexibility may be reduced |
| Sensitive data leaving Qatar for DR | Attested confidential processing path | Tokenisation / masking before transfer | Detokenisation path must stay in Qatar |
| Key misuse | Attested workload release + CMK | Premium Key Vault, RBAC, logging, least privilege | Still relies on procedural separation |

### 2) Reference architecture

Your architecture must show:

- app tier in `qatarcentral`,
- HSM-backed Key Vault in `qatarcentral`,
- private endpoints for SQL / Storage / Key Vault,
- tokenisation service before any DR / analytics feed,
- no detokenisation keys outside Qatar,
- an exception / review note that this workload should be reassessed when Confidential Compute reaches GA in `qatarcentral`.

### 3) Compensating technical controls

At minimum, implement or specify:

- customer-managed keys,
- disabled public network access,
- private DNS + Private Link,
- separate RBAC roles for key admins and workload operators,
- column-level protection for high-value data,
- transformed-data-only DR.

## Success criteria

- [ ] You explicitly state that Confidential Compute is **not** currently GA in `qatarcentral`.
- [ ] Your solution uses CMK in an HSM-backed Key Vault in `qatarcentral`.
- [ ] Sensitive SQL columns are protected with Always Encrypted where available; otherwise you document a tokenisation-first fallback.
- [ ] No raw PII, no raw financial data and no detokenisation secrets are replicated to `uaenorth`.
- [ ] Your control matrix names the **residual risk** that remains without hardware-backed memory confidentiality.
- [ ] Your final architecture gives a regulator a defensible “what we do now” answer instead of a misleading “wait for future SKUs” answer.

## Guiding questions

- Which risks are eliminated by CMK and Private Link, and which risks remain because memory is not confidential?
- When is Always Encrypted enough, and when do you still need tokenisation?
- What would trigger a future design review once Confidential Compute becomes available in Qatar Central?

## Regulatory anchors

- Personal Data Privacy Protection Law (Law No. 13 of 2016)
- NCSA / NDPO guidance for regulated entities
- National Information Assurance Standard v2.1 + National Data Classification Policy
- Qatar Central Bank Cloud Computing Regulation sections 20 and 21

## Solution

> [!TIP]
> Try the design yourself before opening the walkthrough.

<details>
<summary>Click here to view the solution</summary>

[Solution for Challenge 4](../walkthrough/challenge-04/solution-04.md)

</details>
