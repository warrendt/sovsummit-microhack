# Challenge QA-01 — Enforce PDPPL + NIA classification with Azure Policy and tags

> **Country:** Qatar
> **Edition:** Sovereignty Summit Qatar 2026
> **Primary region:** `qatarcentral` (Qatar Central)
> **Classification scheme:** Public, Internal, Limited Access, Restricted

## Scenario

You are the cloud platform engineer for **Ministry of Communications and Information Technology (MCIT) digital public-services platform aligned to Qatar National Vision 2030**.
The programme must publish digital services quickly, but the platform team has to
prove that every resource is labelled and governed in line with:

1. **Personal Data Privacy Protection Law (Law No. 13 of 2016)** — especially controller accountability,
   purpose limitation, technical safeguards and tighter handling for
   **special-nature personal data**.
2. **Council of Ministers Decision No. 17 of 2024 (Executive Regulations)** — records of processing,
   risk-based controls and documented transfer governance.
3. **NCSA NIA Policy v2.0** — classify information as
   `Public, Internal, Limited Access, Restricted` and apply stronger controls as
   sensitivity rises.

## Objectives

Build a country-specific policy initiative called **`Qatar PDPPL + NIA Data Classification`** that:

- Requires these tags on all resource groups and all data-handling resources:
  - `nia-classification` = `Public|Internal|Limited Access|Restricted`
  - `pdppl-data-type` = `non-personal|personal|special-nature|anonymised`
  - `data-owner` = owning ministry / department
  - `processing-purpose` = approved service identifier
- Denies `Limited Access` or `Restricted` workloads outside
  `qatarcentral`.
- Denies any resource tagged `pdppl-data-type=special-nature` unless:
  - a CMK-backed data store is used,
  - private endpoints are enabled for storage / SQL,
  - diagnostic logs stay in `qatarcentral`.
- Denies any deployment to `uaenorth` unless the resource
  group carries a valid `cross-border-adr-id`; for `Limited Access` and
  `Restricted` workloads, deny `uaenorth` entirely.

## Success criteria

- [ ] Untagged resources are denied at create time by the initiative.
- [ ] A test deployment of a `Restricted` workload to `uaenorth` is denied.
- [ ] A `Public` or `Internal` workload can be deployed to `uaenorth` only when the RG carries an approved cross-border record.
- [ ] `az policy state list --filter "ComplianceState eq 'NonCompliant'"` returns zero non-compliant items after remediation.
- [ ] Your control matrix maps each tag and policy back to the PDPPL / executive-regulation obligation it supports.

## Hints

- Start from built-ins such as **Allowed locations**, **Require a tag on resources**, **Require a tag and its value on resource groups**, and **Storage accounts should use customer-managed key for encryption**.
- Use a custom policy rule to make `nia-classification in ['Limited Access','Restricted']` imply `location = qatarcentral`.
- For `special-nature` data, pair `Deny` controls with `DeployIfNotExists` for diagnostics and private endpoint baselines.
- Store your architecture decision record reference in an RG tag such as `cross-border-adr-id`.
- Regulator portal for evidence and guidance: https://assurance.ncsa.gov.qa/

## Estimated duration
75 minutes.
