# Challenge QA-01 — Enforce PDPPL + NIA classification with Azure Policy and tags

> **Country:** ${country.name}
> **Edition:** ${country.summit_edition}
> **Primary region:** `${country.azure.primary_region}` (${country.azure.primary_region_display})
> **Classification scheme:** ${country.regulatory.classification_scheme}

## Scenario

You are the cloud platform engineer for **${country.scenarios.public_sector_tenant}**.
The programme must publish digital services quickly, but the platform team has to
prove that every resource is labelled and governed in line with:

1. **${country.regulatory.primary_law}** — especially controller accountability,
   purpose limitation, technical safeguards and tighter handling for
   **special-nature personal data**.
2. **${country.regulatory.executive_regulations}** — records of processing,
   risk-based controls and documented transfer governance.
3. **NCSA NIA Policy v2.0** — classify information as
   `${country.regulatory.classification_scheme}` and apply stronger controls as
   sensitivity rises.

## Objectives

Build a country-specific policy initiative called **`Qatar PDPPL + NIA Data Classification`** that:

- Requires these tags on all resource groups and all data-handling resources:
  - `nia-classification` = `Public|Internal|Limited Access|Restricted`
  - `pdppl-data-type` = `non-personal|personal|special-nature|anonymised`
  - `data-owner` = owning ministry / department
  - `processing-purpose` = approved service identifier
- Denies `Limited Access` or `Restricted` workloads outside
  `${country.azure.primary_region}`.
- Denies any resource tagged `pdppl-data-type=special-nature` unless:
  - a CMK-backed data store is used,
  - private endpoints are enabled for storage / SQL,
  - diagnostic logs stay in `${country.azure.primary_region}`.
- Denies any deployment to `${country.azure.paired_region}` unless the resource
  group carries a valid `cross-border-adr-id`; for `Limited Access` and
  `Restricted` workloads, deny `${country.azure.paired_region}` entirely.

## Success criteria

- [ ] Untagged resources are denied at create time by the initiative.
- [ ] A test deployment of a `Restricted` workload to `${country.azure.paired_region}` is denied.
- [ ] A `Public` or `Internal` workload can be deployed to `${country.azure.paired_region}` only when the RG carries an approved cross-border record.
- [ ] `az policy state list --filter "ComplianceState eq 'NonCompliant'"` returns zero non-compliant items after remediation.
- [ ] Your control matrix maps each tag and policy back to the PDPPL / executive-regulation obligation it supports.

## Hints

- Start from built-ins such as **Allowed locations**, **Require a tag on resources**, **Require a tag and its value on resource groups**, and **Storage accounts should use customer-managed key for encryption**.
- Use a custom policy rule to make `nia-classification in ['Limited Access','Restricted']` imply `location = ${country.azure.primary_region}`.
- For `special-nature` data, pair `Deny` controls with `DeployIfNotExists` for diagnostics and private endpoint baselines.
- Store your architecture decision record reference in an RG tag such as `cross-border-adr-id`.
- Regulator portal for evidence and guidance: ${country.regulatory.primary_regulator_url}

## Estimated duration
75 minutes.
