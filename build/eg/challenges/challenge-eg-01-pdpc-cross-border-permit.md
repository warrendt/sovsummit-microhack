# Challenge EG-01 — PDPC cross-border permit + adequacy guardrails

> **Country:** Egypt
> **Edition:** Sovereignty Summit Egypt 2026
> **Closest Azure region:** `uaenorth` (UAE North (closest hyperscale region to Egypt))
> **PDPL enforcement deadline:** 2026-10-31

## Scenario

You are the data-protection officer for **Ministry of Communications and Information Technology (MCIT) citizen-services portal**.
Egypt does not yet have an in-country Azure region, so any workload running in
`uaenorth` is by definition a **cross-border transfer**
under PDPL Law 151/2020 — which requires:

1. A **general processing licence** from the PDPC.
2. A **cross-border transfer permit** specific to the destination country.
3. Documented **adequacy assessment** of the destination, OR PDPC-approved
   standard contractual clauses.
4. Explicit data-subject consent (or another lawful basis) recorded per
   transfer category.
5. A **breach-notification pipeline** that reaches the PDPC within
   72 hours of detection.

## Objectives

Build the **technical guardrails** that make the legal process auditable:

- Tag every resource handling Egyptian personal data with a
  `pdpc-permit-id` and `pdpl-data-category` tag. Enforce via Azure Policy
  (deny resources missing the tags).
- Restrict workloads handling regulated PDPL data to the approved
  destination set: `uaenorth`,
  `uaecentral`. Deny all other regions.
- Wire **Microsoft Sentinel** (or Log Analytics + Logic App) to fire a webhook
  to the PDPC breach-notification mailbox within
  72 hours of a high-severity
  data-exfiltration incident.
- Produce a **Transfer Impact Assessment (TIA)** template referencing the
  adequacy criteria the PDPC publishes.

## Success criteria

- [ ] `az policy state list ... --filter "ComplianceState eq 'NonCompliant'"`
      returns zero entries for the *PDPL Egypt Cross-Border* initiative.
- [ ] Attempting to deploy a tagged regulated workload to `westeurope` is
      **denied** at create time with the `PdplRegionRestriction` policy.
- [ ] An untagged resource creation is denied with `PdplTagRequired`.
- [ ] A simulated `Defender for Cloud` high-severity alert triggers a Logic
      App that posts to the configured PDPC webhook within 72 hours
      (verify by checking Logic App run history within the alert window).
- [ ] Your TIA template covers: data categories, recipients, safeguards,
      onward-transfer chains, retention, and data-subject rights.

## Hints

- Required tags: `pdpc-permit-id` (string), `pdpl-data-category`
  (sensitive/general/anonymised), `eg-data-controller` (entity name).
- The *Allowed locations* built-in policy is your starting point; pair it with
  *Require a tag on resources* and *Require a tag and its value on resource
  groups*.
- For the breach pipeline, use **Defender for Cloud → Workflow automation →
  Logic App** with an HTTP action; the action target is the PDPC webhook your
  legal team registered.
- Reference: {'name': 'Personal Data Protection Center (PDPC)', 'url': 'https://pdpc.gov.eg/'}, {'name': 'Central Bank of Egypt', 'url': 'https://www.cbe.org.eg/'}, {'name': 'National Telecommunications Regulatory Authority (NTRA)', 'url': 'https://www.tra.gov.eg/'}.

## Estimated duration
75 minutes.
