# Challenge 1 — Sovereign guardrails for South Africa with Azure Policy & RBAC

**[Home](../Readme.md)** — Next: [Challenge 2](challenge-02.md)

> **Country edition:** Sovereignty Summit South Africa 2026
> **Primary region:** `southafricanorth` (South Africa North)
> **Paired region:** `southafricawest` (South Africa West)
> **Primary law:** POPIA

## The situation

You have just been appointed cloud platform lead for **Department of Home Affairs (DHA) digital identity workload**.
Your Information Officer received a letter from the Information Regulator
requesting evidence that the department's Azure estate enforces the data
sovereignty controls promised in its Promotion of Access to Information Act
(PAIA) manual.

Specifically, the regulator wants to see — within 30 days — proof that:

1. Personal information of South African data subjects is processed **only**
   in `southafricanorth` or `southafricawest`.
2. Every resource carries a **data classification tag** so the platform team
   can answer the question "where is our restricted data?" in seconds.
3. Public IP exposure on data-bearing resources is **blocked by default** —
   private endpoints are mandatory.
4. Access to production is **least-privilege** and the compliance officer can
   audit configurations **without** being able to change anything.

The CIO has approved Azure for this workload **conditional** on you proving
those four controls are enforced *by the platform*, not by hope.

## Your mission

Build a single Azure Policy initiative that delivers controls 1–3, plus the
RBAC model that delivers control 4. Apply both at the right scope. Then
generate the evidence pack the Information Regulator will accept.

## Learning objectives

By the end of this challenge you should be able to:

- Explain the difference between an Azure Policy **assignment**, **initiative**,
  **definition** and **exemption**, and choose the right tool per control.
- Restrict workload deployments to a defined list of Azure regions using a
  **deny** effect, including for resource groups.
- Enforce required tags using **modify** + **deny** effects so non-compliant
  resources are remediated, not just reported.
- Design a custom RBAC role for an auditor that grants read-only access to
  configuration *and* policy state but **no** access to data plane operations.
- Map each Azure control back to the relevant section of
  POPIA so a non-technical regulator can follow
  your evidence.

## Success criteria

Each item is independently verifiable — capture command output or a portal
screenshot for your evidence pack.

- [ ] An initiative named `Sovereignty Summit ZA / Foundations` exists and
      bundles at least four policy definitions covering: allowed locations,
      allowed locations for resource groups, required tag, and "public network
      access disabled" for data services (Storage, SQL, Key Vault).
- [ ] The initiative is assigned at **management group** scope (not a single
      subscription) with effect `Deny` for region and public-network controls.
- [ ] A test deployment of a storage account in `westeurope` is **denied at
      create time** with a clear error referencing the policy assignment.
- [ ] A storage account created **without** the
      `DataClassification` tag is denied; one created with
      `DataClassification=Restricted` succeeds.
- [ ] A custom RBAC role `SovereigntyComplianceAuditor` exists with
      `*/read` actions plus `Microsoft.PolicyInsights/*/read`, **no**
      `Microsoft.Storage/storageAccounts/listKeys/action` (or equivalent
      data-plane actions), and is assigned at management-group scope to a
      named identity.
- [ ] `az policy state summarize --management-group <mg>` shows the
      initiative reporting compliance, with zero **active** non-compliant
      resources after remediation tasks complete.
- [ ] Your evidence pack contains a control-to-section map:
      control 1 → POPIA s.72; control 2 → POPIA s.14 (record-keeping);
      control 3 → POPIA s.19 (security safeguards); control 4 → POPIA s.19
      + POPIA s.55 (Information Officer duties).

## Guiding questions (don't peek until you've tried)

- Why is "deny at create time" stronger evidence than "audit + remediate"
  for a residency control? When would you reverse that choice?
- The built-in `Allowed locations` policy does **not** apply to resource
  groups. What happens if you only assign the resource policy and skip the
  resource-group equivalent? Try it.
- A developer claims they "need" `Owner` on a subscription "just to deploy".
  Which built-in role(s) would you propose instead, and why?
- The Information Regulator does not have an Azure account. How will you
  hand them evidence that survives screenshots being edited?

## South Africa-specific pitfalls

- **`southafricanorth` capacity:** some SKUs (especially
  newer Confidential Compute and certain Cosmos DB capabilities) are not yet
  available in `southafricanorth`. Plan exemptions per *SKU*,
  not per *region*, so the residency rule itself never gets weakened.
- **Paired region awareness:** geo-redundant storage in
  `southafricanorth` replicates to
  `southafricawest` — both are inside South Africa. Make sure
  your `Allowed locations` initiative includes the paired region or
  GRS-enabled storage will fail policy.
- **Tag remediation requires a managed identity** on the assignment.
  Forgetting this is the #1 reason `modify` policies report
  "Non-compliant" forever.

## Regulatory anchors

- POPIA s.19 — security safeguards (confidentiality, integrity)
- POPIA s.72 — transfers of personal information outside South Africa
- POPIA s.14 — records of processing activities
- {'name': 'Information Regulator (South Africa)', 'url': 'https://inforegulator.org.za/'}, {'name': 'South African Reserve Bank', 'url': 'https://www.resbank.co.za/'}, {'name': 'Financial Sector Conduct Authority', 'url': 'https://www.fsca.co.za/'}

## Stretch goals

- Export the initiative as Bicep/JSON and put it under source control so the
  next platform engineer inherits *infrastructure as policy*.
- Wire a Logic App / Azure Function that posts a Teams message to the
  Sovereignty channel whenever a new `Deny` event fires.
- Add a custom policy that **requires** diagnostic settings on every new
  resource to flow to a Log Analytics workspace located in
  `southafricanorth` (this sets up Challenge 3 nicely).
