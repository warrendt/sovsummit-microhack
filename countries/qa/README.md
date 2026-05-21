# Qatar — Sovereignty MicroHack (preview)

> ⚠️ **Status: in development.** This country edition is scaffolded but not yet
> fully tested. The challenges below were authored against Qatar's sovereignty
> framework but the bootstrap automation, walkthroughs, and demo VMs have not
> been validated end-to-end.
>
> The reference implementation is **South Africa** (`countries/za/`). It is
> fully tested and ready to run.

## Scenario
- **Regulator(s):** National Cyber Security Agency, Qatar Central Bank
- **Primary law:** Law No. 13/2016 (PDPPL) + NIA Policy v2.0
- **Recommended landing region:** `qatarcentral`
- **Sovereignty pattern:** Sovereign Public Cloud with NIA classification controls

## Country-specific challenges
- [`challenges/challenge-04.md`](challenges/challenge-04.md)
- [`challenges/challenge-qa-01-pdppl-nia-classification.md`](challenges/challenge-qa-01-pdppl-nia-classification.md)
- [`challenges/challenge-qa-02-qcb-payments-landing-zone.md`](challenges/challenge-qa-02-qcb-payments-landing-zone.md)

## Walkthroughs
- [`walkthrough/challenge-04/solution-04.md`](walkthrough/challenge-04/solution-04.md)
- [`walkthrough/challenge-qa-01-pdppl-nia-classification/solution.md`](walkthrough/challenge-qa-01-pdppl-nia-classification/solution.md)
- [`walkthrough/challenge-qa-02-qcb-payments-landing-zone/solution.md`](walkthrough/challenge-qa-02-qcb-payments-landing-zone/solution.md)

## How to run
This folder does not (yet) ship its own bootstrap. To exercise the **shared**
six-challenge curriculum in this region, copy `countries/za/bootstrap/` and
adjust `main.bicepparam` so `primaryRegion` = `qatarcentral` and the policy
allowed-locations list reflects Qatar's residency requirements.

See [`../za/README.md`](../za/README.md) for the full reference build.
