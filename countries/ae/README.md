# United Arab Emirates — Sovereignty MicroHack (preview)

> ⚠️ **Status: in development.** This country edition is scaffolded but not yet
> fully tested. The challenges below were authored against United Arab Emirates's sovereignty
> framework but the bootstrap automation, walkthroughs, and demo VMs have not
> been validated end-to-end.
>
> The reference implementation is **South Africa** (`countries/za/`). It is
> fully tested and ready to run.

## Scenario
- **Regulator(s):** UAE Data Office, CBUAE
- **Primary law:** Federal Decree-Law 45/2021 (PDPL)
- **Recommended landing region:** `uaenorth`
- **Sovereignty pattern:** Sovereign Public Cloud + Confidential Computing

## Country-specific challenges
- [`challenges/challenge-ae-01-jurisdiction-routing.md`](challenges/challenge-ae-01-jurisdiction-routing.md)
- [`challenges/challenge-ae-02-confidential-banking.md`](challenges/challenge-ae-02-confidential-banking.md)

## Walkthroughs
- [`walkthrough/challenge-ae-01-jurisdiction-routing/solution.md`](walkthrough/challenge-ae-01-jurisdiction-routing/solution.md)
- [`walkthrough/challenge-ae-02-confidential-banking/solution.md`](walkthrough/challenge-ae-02-confidential-banking/solution.md)

## How to run
This folder does not (yet) ship its own bootstrap. To exercise the **shared**
six-challenge curriculum in this region, copy `countries/za/bootstrap/` and
adjust `main.bicepparam` so `primaryRegion` = `uaenorth` and the policy
allowed-locations list reflects United Arab Emirates's residency requirements.

See [`../za/README.md`](../za/README.md) for the full reference build.
