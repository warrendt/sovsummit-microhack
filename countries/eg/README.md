# Egypt — Sovereignty MicroHack (preview)

> ⚠️ **Status: in development.** This country edition is scaffolded but not yet
> fully tested. The challenges below were authored against Egypt's sovereignty
> framework but the bootstrap automation, walkthroughs, and demo VMs have not
> been validated end-to-end.
>
> The reference implementation is **South Africa** (`countries/za/`). It is
> fully tested and ready to run.

## Scenario
- **Regulator(s):** PDPC, Central Bank of Egypt
- **Primary law:** Law No. 151/2020 (PDPL)
- **Recommended landing region:** `uaenorth (no in-country region — see Ch3)`
- **Sovereignty pattern:** Hybrid (Azure Local on-prem + Sovereign Public Cloud)

## Country-specific challenges
- [`challenges/challenge-eg-01-pdpc-cross-border-permit.md`](challenges/challenge-eg-01-pdpc-cross-border-permit.md)
- [`challenges/challenge-eg-02-hybrid-cbe-azure-local.md`](challenges/challenge-eg-02-hybrid-cbe-azure-local.md)
- [`challenges/challenge-eg-03-sovereign-public-cloud-uaenorth.md`](challenges/challenge-eg-03-sovereign-public-cloud-uaenorth.md)

## Walkthroughs
- [`walkthrough/challenge-eg-01-pdpc-cross-border-permit/solution.md`](walkthrough/challenge-eg-01-pdpc-cross-border-permit/solution.md)
- [`walkthrough/challenge-eg-02-hybrid-cbe-azure-local/solution.md`](walkthrough/challenge-eg-02-hybrid-cbe-azure-local/solution.md)
- [`walkthrough/challenge-eg-03-sovereign-public-cloud-uaenorth/solution.md`](walkthrough/challenge-eg-03-sovereign-public-cloud-uaenorth/solution.md)

## How to run
This folder does not (yet) ship its own bootstrap. To exercise the **shared**
six-challenge curriculum in this region, copy `countries/za/bootstrap/` and
adjust `main.bicepparam` so `primaryRegion` = `uaenorth (no in-country region — see Ch3)` and the policy
allowed-locations list reflects Egypt's residency requirements.

See [`../za/README.md`](../za/README.md) for the full reference build.
