# Challenge SA-01 — Enforce POPIA data residency with Azure Policy + CMK

> **Country:** South Africa
> **Edition:** Sovereignty Summit South Africa 2026
> **Primary region:** `southafricanorth` (South Africa North)
> **Paired region:** `southafricawest` (South Africa West)

## Scenario

You are the cloud platform engineer for **Department of Home Affairs (DHA) digital identity workload**.
Your CISO has signed off on Azure as the strategic cloud, conditional on
provable enforcement of the following sovereignty controls:

1. All workload resources are deployed **only** in
   `southafricanorth` or `southafricawest`.
2. Storage accounts, SQL databases, Cosmos DB and disks are encrypted with
   **customer-managed keys** stored in an HSM-backed Azure Key Vault
   (SKU: `Premium`) that lives in
   `southafricanorth`.
3. Diagnostic/telemetry data does **not** egress South Africa (no Log Analytics
   workspaces, Application Insights instances or Azure Monitor data exports
   outside the approved regions).
4. Cross-border data transfers under **POPIA s.72** require a documented
   exception; the platform must surface any non-compliant resource within
   24 hours of creation.

Regulatory references in scope: POPIA (Protection of Personal Information Act, 2013), SARB Directive 3/2018 (cloud computing & offshoring of data), FSCA Joint Standard 2 of 2024 (cybersecurity & cyber resilience), NCA (National Credit Act).

## Objectives

By the end of this challenge you will have:

- Built a **policy initiative** (`Sovereignty Summit ZA / POPIA Residency`) that
  combines built-in and custom Azure policies to enforce the four controls
  above.
- Assigned the initiative at a **management group** scope with a deny effect
  for region violations and audit/deployIfNotExists for the rest.
- Provisioned a **Premium Key Vault** with purge protection + soft delete in
  `southafricanorth` and configured at least one storage account
  to use a CMK from that vault.
- Produced a **compliance evidence pack** (CSV + screenshots) that you could
  hand to the Information Regulator on request.

## Success criteria

- [ ] `az policy state list --management-group <mg>` returns zero
      `NonCompliant` resources for the residency policy after remediation.
- [ ] A test deployment to any region other than
      `southafricanorth` / `southafricawest` is
      **denied** at create time.
- [ ] `az keyvault show` confirms `sku.name = Premium`,
      `purgeProtection = true`, `softDelete = true`, and the vault is in
      `southafricanorth`.
- [ ] A storage account in the workload RG reports
      `encryption.keySource = Microsoft.Keyvault` against the CMK.
- [ ] Your evidence pack maps each control to a POPIA section
      (1→s.19, 2→s.19+s.20, 3→s.72, 4→s.72/process).

## Guiding questions (try before peeking)

- A built-in `Allowed locations` policy denies *resources*; what does it
  fail to deny, and which companion policy must you also assign?
- "Deny at create time" vs "audit + remediate later" — which one would
  you defend to the Information Regulator after a cross-border leak?
- Diagnostic settings can quietly route data out of the country if a
  developer picks a Log Analytics workspace in `westeurope`. How do you
  *prevent* that, not just *detect* it?
- POPIA s.72 allows cross-border transfers in defined circumstances. How
  would you build an **exemption workflow** that documents the legal
  basis whenever an exception is granted?

## South Africa-specific pitfalls

- **`Premium` Key Vault availability** in
  `southafricanorth` is reliable but verify before the
  workshop — Managed HSM is **not** in every South African region.
- **Activity logs vs resource logs:** activity logs are a tenant-level
  setting and route to subscription-level diagnostic settings —
  pinning the workspace there protects *everything*, not just one
  resource type.
- **Geo-redundant storage** in `southafricanorth`
  replicates to `southafricawest`. Both are inside South
  Africa, but make sure your `Allowed locations` initiative explicitly
  includes the paired region or your GRS deployments will fail policy.
- **Tag remediation** requires a managed identity on the policy
  assignment — without it `modify`-effect policies report
  "Non-compliant" forever.

## Deeper POPIA mapping

| Control                              | POPIA section(s) |
|--------------------------------------|------------------|
| Region restriction                   | s.72             |
| HSM-backed CMK + key custody         | s.19, s.20       |
| Record of processing activities      | s.14             |
| Notification of security compromise  | s.22             |
| Special personal information         | s.26             |
| Information Officer responsibilities | s.55             |

Each entry in your evidence pack should reference at least one row.

## Regulator references

{'name': 'Information Regulator (South Africa)', 'url': 'https://inforegulator.org.za/'}, {'name': 'South African Reserve Bank', 'url': 'https://www.resbank.co.za/'}, {'name': 'Financial Sector Conduct Authority', 'url': 'https://www.fsca.co.za/'}

## Stretch goals

- Publish the initiative as Bicep under source control with a CI check
  that fails the build if anyone weakens a `deny` effect to `audit`.
- Build a Logic App that emails the Information Officer whenever an
  exemption is granted under POPIA s.72.
- Extend the evidence pack with a quarterly attestation template the
  Accounting Officer can sign and return to the Information Regulator.
- Repeat the entire challenge for the financial-services scenario
  (A South African tier-1 retail bank issuing virtual cards) and add the SARB Directive
  3/2018 mapping next to the POPIA one.
