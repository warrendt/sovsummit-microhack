# Challenge AE-02 — Confidential AKS + CMK for a CBUAE-regulated bank

> **Country:** United Arab Emirates
> **Edition:** Sovereignty Summit United Arab Emirates 2026
> **Primary region:** `uaenorth` (UAE North)
> **Paired region:** `uaecentral` (UAE Central)

## The situation

You are the cloud security architect for **A CBUAE-licensed UAE bank modernising digital onboarding, payments and fraud analytics**.
The bank is rolling out a new digital-onboarding, sanctions-screening and
payments platform. The board will approve Azure only if you can prove the
landing zone satisfies a UAE-banking control story equivalent in depth to the
bank's GCC peers:

1. **Customer PII, KYC documents, complaints evidence and payment-support data
   stay in the UAE** — primary processing in `uaenorth`.
2. **Decrypted regulated workloads run only on confidential-computing
   infrastructure**.
3. **Customer-managed keys stay under bank control** in an HSM-backed Key Vault
   in `uaenorth`.
4. **CBUAE cloud / outsourcing controls** are evidenced for governance,
   materiality, data protection, auditability, business continuity and exit.

This is an onshore **CBUAE-regulated** bank scenario. If the bank also books
business through DIFC or ADGM entities, that becomes a separate legal-perimeter
question; the core banking platform in this challenge answers to the CBUAE.

## Your mission

Build a production-grade **Confidential AKS landing zone** in
`uaenorth` and produce an evidence pack a risk committee,
internal audit or regulator would recognize.

## Learning objectives

By the end of this challenge you should be able to:

- Deploy AKS with a confidential node pool based on a supported SKU from
  `Standard_DC2as_v5, Standard_DC4as_v5, Standard_EC2as_v5, Standard_EC4as_v5`.
- Protect the platform with a `Premium` Key Vault,
  HSM-backed key rotation, CMK-backed storage, and CMK-backed disk encryption
  where applicable.
- Use workload identity + Key Vault CSI so secrets and certificates stay outside
  containers and under central key custody.
- Map Azure design choices to **CBUAE** control themes: governance,
  materiality, data protection, auditability, resiliency, and exit planning.

## Build requirements

Create a landing zone with at least these components:

- Resource groups for `network`, `security`, `platform`, and `apps`, all in
  `uaenorth`.
- A **private AKS cluster** in `uaenorth` with:
  - one standard system node pool;
  - one confidential user node pool using an approved SKU;
  - taints / labels such as `banking-tier=regulated` so regulated namespaces can
    only run on the confidential pool.
- A `Premium` Key Vault in `uaenorth`
  with:
  - RBAC authorization enabled;
  - purge protection enabled;
  - soft delete retention of at least 90 days;
  - at least one HSM-backed key with a documented rotation policy.
- A **Disk Encryption Set** and at least one **CMK-backed storage account** for
  KYC documents, onboarding evidence and complaints records.
- **Key Vault CSI / workload identity** integration for app secrets,
  certificates and signing material.
- Diagnostic settings for AKS, Key Vault, Storage and Azure Policy into a bank
  security workspace in `uaenorth`.

## Policy initiative

Build an initiative named **`CBUAE Confidential Banking Baseline`** that
combines built-in and custom policies to enforce:

- allowed locations = `uaenorth` and
  `uaecentral` only;
- AKS must be **private** and use Azure RBAC / managed identity;
- namespaces or workloads tagged `banking-tier=regulated` must land only on the
  confidential node pool;
- Storage accounts and managed disks for regulated workloads must use CMK;
- Key Vault must use `Premium`, RBAC, soft delete and
  purge protection;
- public network access is disabled for regulated data services where the
  service supports it;
- diagnostic settings flow to the in-country security workspace.

## CBUAE control themes you must evidence

Map your design to these control families:

| CBUAE theme | What to evidence in Azure |
|---|---|
| Governance | Named landing-zone owner, approved architecture, separation of duties |
| Materiality & risk assessment | Why onboarding / payments are material cloud arrangements |
| Data protection | CMK, private networking, workload identity, confidential compute |
| Auditability | Diagnostic settings, policy state, immutable deployment records |
| Business continuity | `uaecentral` for DR design, documented failover constraints |
| Exit planning | Backup / restore, image portability, key escrow / revocation procedures |
| Consumer data protection | How complaints evidence and customer records remain protected and retrievable |

## Success criteria

- [ ] `az aks show` confirms the cluster is in `uaenorth`
      and includes a confidential node pool.
- [ ] `kubectl get nodes -L banking-tier` (or equivalent) shows the regulated
      pool labeled for confidential workloads.
- [ ] `az keyvault show` confirms `Premium`, RBAC, purge
      protection and in-country placement.
- [ ] A storage account for KYC / onboarding evidence reports
      `encryption.keySource = Microsoft.Keyvault`.
- [ ] A regulated workload cannot schedule onto the non-confidential node pool.
- [ ] A storage account or managed disk created without CMK is denied by policy.
- [ ] Your evidence pack maps the deployment to CBUAE governance,
      materiality/cloud-outsourcing, data-protection and auditability controls.

## Guiding questions

- Why is confidential compute stronger evidence than simple encryption at rest
  when the bank is worried about memory-resident exposure?
- What remains under bank control if Microsoft operates the cloud but the bank
  controls the CMK and workload identity model?
- Which controls deserve a `deny` effect and which should be `audit` or
  `deployIfNotExists` to stay operationally realistic?
- How do you prove a regulator could still obtain records during an incident,
  even if live production access is tightly restricted?

## UAE-specific pitfalls

- **CBUAE scope is not the same as DIFC scope.** A CBUAE-regulated bank may have
  DIFC entities, but the core onshore bank remains answerable to the CBUAE.
- **Same-region DR is not enough.** Use `uaecentral` for
  recovery design, but keep the primary control evidence anchored in
  `uaenorth`.
- **Confidential pool scheduling is easy to get wrong.** If your taints,
  tolerations and selectors are weak, regulated pods will quietly land on the
  standard pool.
- **CMK without operations is not a regulator story.** Show rotation,
  revocation, audit logs and recovery expectations, not just a single `az`
  screenshot.

## Regulator references

- [UAE Government data protection overview](https://u.ae/en/about-the-uae/digital-uae/data/data-protection-laws)
- [CBUAE Rulebook](https://rulebook.centralbank.ae/)
- [DIFC data protection](https://www.difc.ae/business/laws-regulations/data-protection/)
- [ADGM Office of Data Protection](https://www.adgm.com/operating-in-adgm/office-of-data-protection)
- [TDRA](https://tdra.gov.ae/)
- [Dubai Health Authority](https://www.dha.gov.ae/)

## Stretch goals

- Add an admission-control policy that rejects regulated pods unless they set
  the correct node selector, workload identity and restricted security context.
- Add a quarterly attestation export for the bank's outsourcing register.
- Extend the design so a DIFC branch can consume the platform through a
  documented inter-perimeter interface rather than sharing the same landing
  zone directly.
