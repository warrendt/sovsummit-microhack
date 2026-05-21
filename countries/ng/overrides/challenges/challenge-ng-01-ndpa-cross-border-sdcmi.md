# Challenge NG-01 — NDPA cross-border guardrails + NDPC SDCMI registration

> **Country:** ${country.name}
> **Edition:** ${country.summit_edition}
> **Closest Azure region:** `${country.azure.primary_region}` (${country.azure.primary_region_display})
> **NDPA breach notification:** ${country.regulatory.breach_notification_hours} hours

## Scenario

You are the privacy and cloud-governance lead for
**${country.scenarios.public_sector_tenant}**.
Because Nigeria has no in-country Azure region, any workload deployed to
`${country.azure.primary_region}` is a **cross-border transfer** under the NDPA.
Your legal team has concluded that this organisation is a **data controller of
major importance** under **NDPA s.65** and must therefore complete NDPC
registration under **s.44** before production cutover.

You must build the **technical controls and evidence pack** that support that
legal position:

1. Record the transfer basis for any personal data sent to
   `${country.azure.primary_region}` under **NDPA s.41**, with adequacy checks
   from **s.42** or fallback grounds from **s.43**.
2. Enforce resource tagging that maps every regulated workload to its NDPC
   registration tier, transfer basis and data classification.
3. Restrict approved cloud destinations to `${country.azure.primary_region}` and
   `${country.azure.paired_region}` only.
4. Prove that the organisation can notify the **NDPC** within
   **${country.regulatory.breach_notification_hours} hours** under **NDPA s.40**.
5. Prepare the metadata required for major-controller registration under
   **NDPA s.44**.

## Objectives

Build the **NDPA Nigeria Cross-Border + SDCMI** governance pack:

- Create an Azure Policy initiative that:
  - Denies resources outside `${country.azure.primary_region}` and
    `${country.azure.paired_region}`.
  - Denies any regulated resource missing the tags
    `ndpc-registration-tier`, `ndpa-transfer-basis`, `ndpa-transfer-country`,
    and `ng-data-classification`.
  - Deploys diagnostic settings to a Log Analytics workspace in
    `${country.azure.primary_region}` for the derived-data tier.
- Produce an **NDPC registration workbook** containing the fields called for by
  **s.44(2)**: controller identity, DPO, categories of data subjects,
  processing purposes, recipients, intended transfer country, and safeguards.
- Configure a **Defender for Cloud / Sentinel / Logic App** flow that creates an
  NDPC breach case within `${country.regulatory.breach_notification_hours}` of a
  qualifying incident.
- Document why the workload qualifies as a major controller under **s.65** and
  the **14 Feb 2024 NDPC Guidance Notice**.

## Success criteria

- [ ] `az policy state list --management-group <mg>` returns zero
      `NonCompliant` resources for the *NDPA Nigeria Cross-Border + SDCMI*
      initiative after remediation.
- [ ] A test deployment to `westeurope` is **denied** at create time.
- [ ] An untagged storage account in `${country.azure.primary_region}` is denied
      with your tag policy.
- [ ] Your registration workbook captures all fields required by **NDPA s.44(2)**.
- [ ] A simulated high-severity data-exfiltration alert triggers the breach
      workflow, proving NDPC notification can occur within
      `${country.regulatory.breach_notification_hours}` hours.
- [ ] Your evidence maps controls back to **NDPA ss.32, 40, 41, 42, 43, 44, 65**
      and the **NDPC Guidance Notice (14 Feb 2024)**.

## Hints

- Use `ndpc-registration-tier` values such as `MDP-UHL`, `MDP-EHL`, or
  `MDP-OHL` to mirror the NDPC's 2024 categorisation approach.
- A public-sector identity workload almost certainly qualifies as major under
  **s.65**, and the NDPC guidance expressly treats government bodies and
  regulated sectors such as finance as high-significance controllers.
- **NDPA s.41(2)** requires you to **record the basis for transfer**. A tag,
  policy exemption note, or evidence file linked to each workload is acceptable
  for the lab.
- **NDPA s.40(2)** gives the timer: notify the NDPC within
  `${country.regulatory.breach_notification_hours}` hours after awareness of a
  qualifying breach.
- Reference: ${country.regulatory.regulator_links}.

## Estimated duration
75 minutes.
