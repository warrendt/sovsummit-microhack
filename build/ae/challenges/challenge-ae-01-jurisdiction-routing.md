# Challenge AE-01 — Route workloads to the correct UAE legal perimeter

> **Country:** United Arab Emirates
> **Edition:** Sovereignty Summit United Arab Emirates 2026
> **Primary region:** `uaenorth` (UAE North)
> **Paired region:** `uaecentral` (UAE Central)

## Scenario

You are the platform lead for **An Abu Dhabi government entity modernising a citizen-services and case-management platform**.
The programme includes two external integrations:

1. A **DIFC-licensed bank** that disburses benefits and refunds.
2. An analytics service hosted by a group entity in **ADGM**.

Everyone wants to use the same Azure landing zone in the UAE region, but the
legal team has stopped the rollout until you can prove which regulator applies
to each workload boundary:

- **Onshore government services** must stay under the UAE **PDPL** + Executive
  Regulations.
- **DIFC-established processing** falls under **DIFC Law No. 5 of 2020**.
- **ADGM-established processing** falls under the **ADGM Data Protection
  Regulations 2021**.
- Any shared platform controls must still align with **UAE IAS** and, where
  relevant, sector overlays such as **CBUAE** or Dubai health-data rules.

Your job is to build a **jurisdiction-aware landing zone** that uses resource
classification, management-group segmentation and Azure Policy to route each
workload into the correct regulatory regime while keeping all data in-country.

## Objectives

By the end of this challenge you will have:

- Created three management-group or subscription landing zones:
  `mg-ae-onshore`, `mg-ae-difc`, and `mg-ae-adgm`.
- Enforced a mandatory classification model with tags such as:
  - `uae-regulatory-regime` = `federal-pdpl|difc|adgm`
  - `data-classification` = `public|internal|confidential|restricted`
  - `data-controller` = legal entity / authority name
- Built a policy initiative **`UAE Jurisdiction Routing`** that:
  - denies deployments outside `uaenorth` and
    `uaecentral`;
  - denies a workload tagged `uae-regulatory-regime=difc` unless it is deployed
    into the designated DIFC landing zone;
  - denies a workload tagged `uae-regulatory-regime=adgm` unless it is deployed
    into the designated ADGM landing zone;
  - defaults all unclassified public-sector workloads to the onshore
    `federal-pdpl` regime and audits any exception request.
- Produced an evidence matrix showing which regulator applies to each sample
  application, dataset and integration.

## Success criteria

- [ ] A deployment to `westeurope` is denied immediately by the initiative.
- [ ] A test resource tagged `uae-regulatory-regime=difc` is denied when created
      in the onshore subscription / management group.
- [ ] A test resource tagged `uae-regulatory-regime=adgm` is denied when created
      in the DIFC landing zone.
- [ ] Untagged resources handling confidential data are denied or remediated
      according to your initiative design.
- [ ] Your evidence pack clearly separates: federal PDPL scope, DIFC scope,
      ADGM scope, and the additional sector overlay applied to each workload.

## Hints

- Start with **Allowed locations**, **Allowed locations for resource groups**,
  **Require a tag on resources**, and a custom policy that checks the current
  management-group / subscription path against `uae-regulatory-regime`.
- A simple pattern is to dedicate one subscription per regime and make the
  initiative validate both **tag + scope** together.
- For auditability, send diagnostic settings to a Log Analytics workspace in
  `uaenorth` and export policy state for legal review.
- Your regulator decision tree should answer one core question first:
  **where is the controller / processor established for this workload boundary?**
  That answer usually determines whether federal PDPL, DIFC or ADGM applies.

## Estimated duration

75 minutes.
