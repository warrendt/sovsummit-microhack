# Challenge 4 — Confidential VMs for ${country.name} payroll processing

[Previous Challenge](challenge-03.md) — **[Home](../Readme.md)** — Next: [Challenge 5](challenge-05.md)

> **Confidential compute SKUs available in `${country.azure.primary_region}`:**
> ${country.azure.confidential_compute_skus}

## The situation

${country.scenarios.public_sector_tenant} runs the monthly payroll for the
entire public service. The payroll application processes ID numbers,
banking details, medical-aid scheme membership, garnishee orders and trade
union deductions — every category of **personal information** and several
categories of **special personal information** as defined in POPIA s.26.

The Auditor-General's office has asked, in writing, whether Microsoft
operators in Dublin could in principle read the contents of the payroll
VMs while they are running. Today, the answer is "no, by policy and
contract — but yes, by hypervisor capability". The Auditor-General wants
that answer to become "no, by mathematics".

## Your mission

Move the payroll compute onto **Azure Confidential VMs** so that the VM
memory and CPU state are encrypted with a key the host operator cannot
read. Then **prove** it — using Microsoft Azure Attestation (MAA) — that
the workload is running on real, attested confidential hardware before
any payroll data is decrypted into the VM.

## Learning objectives

- Differentiate the three pillars of Azure confidential computing
  (confidential VMs, confidential containers, confidential ledger) and
  pick the right one for a given workload.
- Deploy a confidential VM on a current-generation SKU
  (`Standard_DC*as_v5` / `Standard_EC*as_v5`).
- Generate and read an **attestation token** issued by Microsoft Azure
  Attestation, and explain the claims that matter to a regulator
  (`x-ms-isolation-tee.x-ms-attestation-type`, `x-ms-compliance-status`,
  `x-ms-runtime`).
- Wire attestation into application start-up so that the app refuses to
  decrypt data unless the attestation token is valid and fresh.

## Success criteria

- [ ] A virtual network and subnet exist in
      `${country.azure.primary_region}` with private endpoints for the
      supporting Key Vault and Storage account.
- [ ] A confidential VM is running, using one of:
      ${country.azure.confidential_compute_skus}.
- [ ] The VM's OS disk is configured with **VMGuestStateOnly**
      confidential disk encryption (or full-disk, depending on the
      scenario you chose) and references a CMK from the Premium Key
      Vault built in Challenge 2.
- [ ] An MAA attestation provider exists and you have retrieved at least
      one **attestation token** for the VM. The token validates against
      the provider's JWKS.
- [ ] You have a small program (PowerShell, Python or .NET — your choice)
      that:
      1. Asks the VM for an attestation token.
      2. Verifies the token's signature and the
         `x-ms-compliance-status = azure-compliant-cvm` claim.
      3. Only then calls Key Vault to release the symmetric data
         encryption key that "unwraps" a sample payroll record.
- [ ] If you tamper with the program (or run it on a non-confidential
      VM), the unwrap step fails closed.
- [ ] Evidence pack maps the control to **POPIA s.19** and **POPIA
      s.26** (special personal information), and to **FSCA Joint
      Standard 2 of 2024 §5** (defence-in-depth).

## Guiding questions

- What threat model does a confidential VM defend against that a normal
  VM with full-disk encryption does not?
- An attestation token typically expires in minutes. Why? What's the
  attack you would enable if you cached it for 24 hours?
- The Auditor-General asks whether **Microsoft** could forge an
  attestation token. What is the root of trust, and what would have to
  happen for that to be feasible?
- Confidential VMs cost more than equivalent general-purpose VMs. How
  would you decide which workloads in the department justify the
  premium?

## ${country.name}-specific pitfalls

- **CC SKU quota in `${country.azure.primary_region}`:** new
  subscriptions often start with zero quota for DC/EC `*as_v5` families.
  Request quota *before* the workshop, not during.
- **Image selection:** only Gen2, TPM-enabled images marked as
  "Confidential compute" support CVM. Vanilla Ubuntu / Windows Server
  images will deploy as a normal VM and silently skip the confidential
  guarantees.
- **Disk encryption modes:** `VMGuestStateOnly` is enough for the
  attestation story but does *not* encrypt the OS disk; choose
  `DiskWithVMGuestState` if you also want the OS disk encrypted with the
  CMK from Challenge 2.
- **Pairing for DR:** `${country.azure.paired_region}` has fewer CC SKUs
  than `${country.azure.primary_region}` — design your DR runbook
  accordingly.

## Regulatory anchors

- POPIA s.19 — security safeguards
- POPIA s.26 — prohibition on processing of special personal information
- POPIA s.55 — Information Officer duties
- FSCA Joint Standard 2 of 2024 §5 — defence in depth
- ${country.regulatory.regulator_links}

## Stretch goals

- Build a small "attestation proxy" service that issues short-lived
  data-encryption keys only to VMs whose attestation tokens satisfy
  policy — and put the policy in a versioned repo.
- Stream attestation events to Log Analytics and write a KQL query that
  alerts the SOC if any VM ever fails attestation more than three times
  in 10 minutes.
- Pilot Confidential VMs for the bank-side workload from Challenge 2 and
  compare the threat-model improvement with cardholder data.
