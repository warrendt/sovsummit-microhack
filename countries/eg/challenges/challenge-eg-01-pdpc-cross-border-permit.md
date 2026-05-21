# Challenge EG-01 — PDPC cross-border permit + adequacy guardrails

> **Country:** Egypt
> **Edition:** Sovereignty Summit Egypt 2026
> **Closest Azure region:** `uaenorth` (UAE North (closest hyperscale region to Egypt))
> **PDPL compliance countdown ends:** 2026-10-31

## The situation

You are the data-protection officer for **Ministry of Communications and Information Technology (MCIT) citizen-services portal**.
The product team wants to use `uaenorth` immediately because it
is the nearest Azure hyperscale region to Egypt. Legal has stopped the rollout.

Their position is simple:

1. Because Egypt has **no in-country Azure region**, any use of
   `uaenorth` is a **cross-border transfer** under PDPL Law
   151/2020.
2. The **Executive Regulations** (Ministerial Decree 816 of 2025) now make the
   operating model explicit: licensing, transfer approvals, breach response, and
   records of processing are no longer high-level concepts.
3. Some data may lawfully move to `uaenorth` after PDPC
   approval; some data may need to remain physically in Egypt and therefore
   belongs on **Azure Local + Arc** instead.

Before the platform team can deploy anything, you must build the control set that
proves the organisation knows **which data may leave Egypt, under which permit,
and with which safeguards**.

## Your mission

Build a **PDPC-ready cross-border governance pack** that turns the legal process
into technical guardrails:

- enforce transfer metadata on every regulated workload;
- pin approved cloud destinations to `uaenorth` and
  `uaecentral` only;
- record the permit, lawful basis and transfer-impact-assessment reference for
  every cross-border workload;
- establish an incident path that can support PDPC notification within
  **72 hours** of awareness.

## Learning objectives

By the end of this challenge you should be able to:

- Explain why **closest region** does **not** mean **automatic compliance** when
  there is no Egyptian Azure region.
- Design Azure Policy controls that distinguish **permitted cross-border** data
  from **must-stay-in-Egypt** data.
- Capture the minimum metadata that legal and audit need for PDPC transfer
  approval: destination, purpose, categories, safeguards, controller, and
  onward-transfer path.
- Build evidence showing that breach handling, transfer approval, and resource
  deployment controls line up.

## Success criteria

- [ ] An initiative named `PDPL Egypt Cross-Border Governance` exists and bundles
      policies for allowed locations, required tags, resource-group transfer
      approval metadata, and diagnostic-settings enforcement.
- [ ] A test deployment of a regulated workload to `westeurope` is **denied at
      create time** with a clear `PdplRegionRestriction`-style error.
- [ ] An untagged regulated resource is denied with a `PdplTagRequired`-style
      error.
- [ ] `az policy state list --management-group <mg>` returns zero active
      `NonCompliant` resources for the initiative after remediation.
- [ ] A simulated high-severity Defender / Sentinel incident produces a Logic App
      run record showing the PDPC notification workflow can start within
      `72` hours.
- [ ] Your Transfer Impact Assessment (TIA) template covers: data categories,
      destination country, recipients, onward transfers, safeguards, retention,
      data-subject rights, and the reason the workload is allowed in
      `uaenorth` rather than kept on Azure Local.

## Guiding questions (try before peeking)

- If the PDPC approves transfer to `uaenorth`, does that
  mean **all** Egyptian personal data may go there? If not, what decides the
  boundary?
- Which is stronger evidence for a regulator: `audit` after deployment, or
  `deny` at create time? Where would you still keep an `audit` control?
- What is the minimum set of tags or metadata that lets you answer, in minutes,
  the question: **"Which workloads are operating under which PDPC permit?"**
- Your incident team can notify the PDPC in 72 hours only if they know which
  controller, data category and permit were involved. How will your cloud
  platform surface that context automatically?

## Egypt-specific pitfalls

- **No automatic adequacy assumption:** the UAE may be operationally sensible,
  but you still need **PDPC approval**, a documented destination assessment and a
  clear legal basis. Do not write workshop material that treats `uaenorth`
  as automatically adequate.
- **Permit scope drift:** if the permit covers analytics data only, do not let a
  team reuse the same permit ID for raw customer-master or financial-identity
  data.
- **Resource-group loophole:** built-in `Allowed locations` does not control
  resource groups; pair it with the resource-group equivalent or your evidence is
  incomplete.
- **Telemetry is data too:** if logs contain identifiers or request payloads,
  exporting them outside the approved region set creates a second cross-border
  problem.

## Minimum transfer metadata

| Field | Example | Why it matters |
|---|---|---|
| `pdpc-permit-id` | `PDPC-XB-2026-014` | Links the workload to the transfer approval. |
| `pdpl-data-category` | `general`, `sensitive`, `tokenised`, `anonymised` | Drives which safeguards and hosting pattern apply. |
| `eg-data-controller` | `MCIT Citizen Services` | Identifies the accountable legal entity. |
| `transfer-basis` | `permit+consent`, `permit+contract` | Shows the legal basis actually relied on. |
| `tia-reference` | `TIA-EG-PORTAL-2026-03` | Links technical deployment to legal assessment. |
| `must-stay-in-egypt` | `true` / `false` | Forces the Azure Local vs public-cloud decision. |

## Regulatory anchors

- PDPL Law 151 of 2020
- Executive Regulations — Ministerial Decree 816 of 2025
- Personal Data Protection Centre (PDPC): <https://pdpc.gov.eg/>
- Central Bank of Egypt: <https://www.cbe.org.eg/>

## Stretch goals

- Add a Logic App approval workflow that refuses policy exemption requests unless
  a `tia-reference` and `pdpc-permit-id` are supplied together.
- Export policy state plus resource tags to CSV as an evidence pack your legal
  team can attach to the PDPC file.
- Extend the initiative with a custom policy that blocks diagnostic settings from
  using any workspace outside `uaenorth` /
  `uaecentral`.
