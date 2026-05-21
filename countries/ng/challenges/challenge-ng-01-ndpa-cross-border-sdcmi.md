# Challenge NG-01 — NDPA cross-border guardrails + NDPC SDCMI registration

> **Country:** Nigeria
> **Edition:** Sovereignty Summit Nigeria 2026
> **Closest Azure region:** `southafricanorth` (South Africa North (closest hyperscale region to Nigeria))
> **NDPA breach notification:** 72 hours

## Scenario

You are the privacy and cloud-governance lead for
**National Identity Management Commission (NIMC) identity-verification and citizen-services workload**.
Because Nigeria has no in-country Azure region, any workload deployed to
`southafricanorth` is a **cross-border transfer posture** under
**NDPA ss.41-43** and the **GAID 2025**.

Your legal team has concluded that this organisation is a **data controller of
major importance** and must therefore complete **NDPC registration** under
**NDPA s.44** before production cutover. The platform team cannot simply say
“the closest Azure region is South Africa North”; it must prove:

1. which categories of data may cross the border,
2. which legal basis is being used for each transfer,
3. which safeguards reduce the exposure, and
4. how the NDPC can be notified within the statutory timeline if anything fails.

Build the **technical controls and evidence pack** that make that legal position
defensible to the NDPC, your DPO and your sponsoring ministry.

## Objectives

Build the **NDPA Nigeria Cross-Border + SDCMI** governance pack:

- Create an Azure Policy initiative that:
  - Denies resources outside `southafricanorth` and
    `southafricawest`.
  - Denies any regulated resource missing the tags
    `ndpc-registration-tier`, `ndpa-transfer-basis`, `ndpa-transfer-country`,
    `ndpa-transfer-instrument`, and `ng-data-classification`.
  - Deploys diagnostic settings to a Log Analytics workspace in
    `southafricanorth` for the approved derived-data tier.
  - Audits any resource where `ng-data-classification=restricted-raw` is paired
    with a public-cloud deployment.
- Produce an **NDPC registration workbook** containing the fields called for by
  **s.44(2)**: controller identity, DPO, categories of data subjects,
  processing purposes, recipients, intended transfer country, and safeguards.
- Build a **transfer decision register** showing whether each workload relies on:
  - an NDPC adequacy position,
  - an NDPC-recognised cross-border transfer instrument / SCC-equivalent,
  - or another lawful **s.43** basis.
- Configure a **Defender for Cloud / Sentinel / Logic App** flow that creates an
  NDPC breach case within `72` of a
  qualifying incident.
- Document why the workload qualifies as a major controller under the
  **14 Feb 2024 NDPC Guidance Notice** and how **GAID 2025** changes the
  operating model for annual returns and breach handling.

## Success criteria

- [ ] `az policy state list --management-group <mg>` returns zero
      `NonCompliant` resources for the *NDPA Nigeria Cross-Border + SDCMI*
      initiative after remediation.
- [ ] A test deployment to `westeurope` is **denied** at create time.
- [ ] An untagged storage account in `southafricanorth` is denied
      with your tag policy.
- [ ] Any resource tagged `ng-data-classification=restricted-raw` in
      `southafricanorth` is flagged `NonCompliant`.
- [ ] Your registration workbook captures all fields required by **NDPA s.44(2)**.
- [ ] Your transfer register records destination, transfer basis, instrument, and
      safeguard for every workload that leaves Nigeria.
- [ ] A simulated high-severity data-exfiltration alert triggers the breach
      workflow, proving NDPC notification can occur within
      `72` hours.
- [ ] Your evidence maps controls back to **NDPA ss.32, 40, 41, 42, 43, 44, 65**,
      **GAID 2025**, and the **NDPC Guidance Notice (14 Feb 2024)**.

## Guiding questions (try before peeking)

- If South Africa has not been formally declared adequate for your exact use
  case, what is your fallback **s.43** basis and who signs it off?
- What is the difference between `ndpa-transfer-basis` and
  `ndpa-transfer-instrument`, and why do you need both in evidence?
- Which identities are allowed to grant a policy exemption for a transfer, and
  where will you store the approval so auditors can retrieve it later?
- How will your SOC prove the 72-hour clock started when it claims it started?

## Nigeria-specific pitfalls

- **Registration scope drift:** the NDPC's 2024 guidance treats public-sector
  bodies and strategic sectors as major importance quickly; do not assume only
  “big tech” or “big banks” fall in scope.
- **Adequacy assumptions:** a platform team cannot casually label a transfer as
  “adequate.” If your legal basis is not a formal adequacy position, use the
  correct **s.43 / GAID 2025** instrument and record it.
- **Tag-only evidence is not enough:** tags help operations, but your evidence
  pack still needs the underlying memo, approval, contract language and breach
  runbook.
- **Public-cloud logging can become a hidden transfer:** diagnostic settings,
  backup reports and ticket exports also need to stay within the approved
  region set.

## Deeper NDPA mapping

| Control | NDPA / GAID anchor |
|---|---|
| DPO / accountability ownership | NDPA s.32 |
| Breach workflow and clock evidence | NDPA s.40 |
| Cross-border transfer decision register | NDPA ss.41-43 |
| Registration workbook and disclosure set | NDPA s.44 |
| Major-importance classification memo | NDPA s.65 + NDPC 14 Feb 2024 guidance |
| Transfer instruments, annual return discipline, templates | GAID 2025 |

## Regulator references

{'name': 'Nigeria Data Protection Commission', 'url': 'https://ndpc.gov.ng/'}, {'name': 'Central Bank of Nigeria', 'url': 'https://www.cbn.gov.ng/'}, {'name': 'National Information Technology Development Agency (NITDA)', 'url': 'https://www.nitda.gov.ng/'}

## Stretch goals

- Add an approval workflow where a transfer exemption cannot be activated until
  legal, security and the DPO each approve it.
- Publish your transfer register to a Power BI dashboard so the ministry CIO can
  see every cross-border workload in one view.
- Extend the initiative so `modify` policies stamp the DCPMI tier and owner on
  every resource group automatically.

## Estimated duration
90 minutes.
