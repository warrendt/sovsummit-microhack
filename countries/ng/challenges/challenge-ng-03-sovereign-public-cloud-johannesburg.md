# Challenge NG-03 — Sovereign public cloud in Johannesburg with in-country tokenisation boundary

> **Country:** Nigeria
> **Edition:** Sovereignty Summit Nigeria 2026
> **Primary public-cloud region:** `southafricanorth` (South Africa North (closest hyperscale region to Nigeria))
> **Paired region:** `southafricawest` (South Africa West)

## Scenario

You are the cloud platform lead for **A tier-1 Nigerian bank modernising digital channels under CBN cloud and outsourcing rules**.
The board has accepted that Nigeria has no in-country Azure region, but it does
**not** want the architecture framed as “Azure Local only.” Your task is to
build a **sovereign public-cloud landing zone** in `southafricanorth`
that is honest about the cross-border posture and still uses stronger-than-usual
sovereignty controls.

The solution must prove all of the following:

1. `southafricanorth` is the closest practical hyperscale Azure
   region for Nigeria, with better latency and service availability than routing
   the workload to Europe or North America.
2. The deployment is treated as a **cross-border transfer** under **NDPA
   ss.41-43** and **GAID 2025**, not disguised as “local enough.”
3. Any field that NDPA or the bank's own risk model says must stay in Nigeria is
   protected by a **customer-controlled tokenisation boundary** whose secrets and
   detokenisation capability stay on Nigerian infrastructure.
4. The public-cloud tier is locked to
   `southafricanorth` and `southafricawest` with
   Azure Policy, HSM-backed CMK, Private Link and explicit outsourcing evidence.

## Why Johannesburg / South Africa North

- **Closest mainstream Azure region:** `southafricanorth` is the
  nearest broadly available Azure region for Nigeria in this lab, reducing user
  and operations latency compared with Europe-based alternatives.
- **Regional pair available:** `southafricawest` gives you an
  Africa-based paired-region story for DR, backup validation and policy scope.
- **Honest NDPA posture:** a Nigeria-to-South-Africa deployment is still a
  **cross-border transfer**. You must document whether you are relying on an
  NDPC adequacy position, an NDPC-recognised transfer instrument /
  SCC-equivalent, or another lawful **s.43** basis.
- **Operationally realistic:** many Nigerian teams already use South African
  hyperscale regions while keeping the most sensitive identifiers, key
  ceremonies and detokenisation points in-country.

## Objectives

Build a **Nigeria sovereign public-cloud landing zone** with these controls:

- Assign an **allowed-locations** initiative that pins workloads to
  `southafricanorth` and `southafricawest` only.
- Deploy a **Premium Key Vault** in `southafricanorth` and use an
  **RSA-HSM CMK** for storage encryption. Where required by CBN policy, seed the
  key material via **BYOK** from a Nigerian on-prem HSM ceremony.
- Configure a storage account with:
  - `keySource = Microsoft.Keyvault`
  - TLS minimum version = `TLS1_2`
  - public network access disabled
  - private endpoints only
- Use **Private Link** for the storage account, Key Vault, SQL / managed
  database endpoints, and any analytics landing services used in the challenge.
- Build a **customer-controlled tokenisation layer** in Nigeria. Point the
  public-cloud apps at a Nigerian on-prem tokenisation vault reachable through
  **Azure Local + Arc** or another private connectivity pattern.
- Produce an explicit **data-classification table** showing which data may live
  in `southafricanorth` and which data must stay in Nigeria.
- Produce a **cross-border evidence pack** covering NDPA **s.43** transfer
  requirements, adequacy / SCC-equivalent posture, NDPC registration impact,
  and the **72-hour** breach
  notification workflow.

## Data-classification split you must implement

| Data class | Example | Target location | Why |
|---|---|---|---|
| `restricted-raw` | BVN, NIN, account number, card PAN, full KYC document image | Nigeria only (token vault / Azure Local boundary) | Too sensitive to place directly in public cloud. |
| `tokenised-operational` | Transaction records with surrogate customer token | `southafricanorth` | Supports apps and analytics without exposing raw identifiers. |
| `derived-analytics` | Aggregates, risk scores, fraud features without direct identifiers | `southafricanorth` / `southafricawest` | Permitted cross-border workload with safeguards. |
| `break-glass-detokenisation` | Token maps, HSM export material, detokenisation approvals | Nigeria only | Customer-controlled recovery boundary. |

## Success criteria

- [ ] A deployment to `westeurope` is denied by the allowed-locations assignment.
- [ ] `az keyvault key show` confirms an `RSA-HSM` key in a `Premium` Key Vault in `southafricanorth`.
- [ ] Your primary storage account reports `encryption.keySource = Microsoft.Keyvault`, `minimumTlsVersion = TLS1_2`, and `publicNetworkAccess = Disabled`.
- [ ] All PaaS endpoints used in the challenge are reachable through **Private Link** only.
- [ ] The tokenisation service / vault remains in Nigeria, and detokenisation cannot occur from `southafricanorth` alone.
- [ ] Your evidence pack explicitly records the transfer basis under **NDPA s.43**, the adequacy / SCC-equivalent position, the NDPC registration implication, and the breach-notification flow.

## Guiding questions (try before peeking)

- If legal cannot rely on a clean adequacy argument, which **s.43** basis or
  transfer instrument will it accept for this workload?
- Which workloads genuinely need raw identifiers in the public cloud, and are
  you sure the answer is not “none”?
- Where does the **BYOK** ceremony happen, who witnesses it, and how do you
  prove the bank retained control of the key origin?
- What breaks first if Private Link is removed from one dependency: security,
  availability, or compliance evidence?

## Nigeria-specific pitfalls

- **South Africa is still cross-border:** “same continent” does not remove NDPA
  transfer obligations.
- **CMK without origin story is weak evidence:** if the bank says key custody
  matters, document the HSM source, import path, rotation plan and who owns the
  approvals.
- **Public endpoints create policy exceptions everywhere:** once one service is
  allowed to stay public, teams tend to copy the pattern. Deny it up front.
- **Tokenisation is only real if detokenisation stays in Nigeria:** do not place
  reversible token maps, master salts or HSM export material in
  `southafricanorth`.

## Control mapping

| Control | Nigeria / bank rationale |
|---|---|
| Allowed locations = `southafricanorth`, `southafricawest` | Limits cross-border sprawl and supports a clear transfer register. |
| Premium Key Vault + RSA-HSM CMK + optional BYOK | Supports customer-controlled encryption and CBN key-custody expectations. |
| TLS 1.2 + public access disabled + Private Link | Reduces network exposure and creates stronger technical evidence. |
| Tokenisation boundary in Nigeria | Keeps raw identifiers and detokenisation authority in-country. |
| Transfer register + breach workflow | Supports NDPA ss.40-44 and GAID 2025 evidence discipline. |

## Regulator references

{'name': 'Nigeria Data Protection Commission', 'url': 'https://ndpc.gov.ng/'}, {'name': 'Central Bank of Nigeria', 'url': 'https://www.cbn.gov.ng/'}, {'name': 'National Information Technology Development Agency (NITDA)', 'url': 'https://www.nitda.gov.ng/'}

## Stretch goals

- Add confidential-compute worker nodes for the token-aware app tier in
  `southafricanorth`.
- Create a quarterly legal / security attestation that revalidates the transfer
  basis and tokenisation scope.
- Extend the evidence pack with a payment-switch specific annex for CBN review.

## Estimated duration
135 minutes.
