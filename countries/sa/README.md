# Saudi Arabia (KSA) — Sovereignty MicroHack (preview)

> ⚠️ **Status: in development.** This country edition is scaffolded but not yet
> fully tested. The challenges below were authored against Saudi Arabia (KSA)'s sovereignty
> framework but the bootstrap automation, walkthroughs, and demo VMs have not
> been validated end-to-end.
>
> The reference implementation is **South Africa** (`countries/za/`). It is
> fully tested and ready to run.

## Scenario
- **Regulator(s):** NCA, SDAIA, SAMA
- **Primary law:** PDPL (2023) + NCA CCC (1:2020)
- **Recommended landing region:** `saudiarabiaeast`
- **Sovereignty pattern:** Sovereign Public Cloud + Confidential AKS

## Country-specific challenges
- [`challenges/challenge-ksa-01-nca-ccc-sovereign-landing-zone.md`](challenges/challenge-ksa-01-nca-ccc-sovereign-landing-zone.md)
- [`challenges/challenge-ksa-02-sama-confidential-aks-payments.md`](challenges/challenge-ksa-02-sama-confidential-aks-payments.md)

## Walkthroughs
- [`walkthrough/challenge-ksa-01-nca-ccc-sovereign-landing-zone/solution.md`](walkthrough/challenge-ksa-01-nca-ccc-sovereign-landing-zone/solution.md)
- [`walkthrough/challenge-ksa-02-sama-confidential-aks-payments/solution.md`](walkthrough/challenge-ksa-02-sama-confidential-aks-payments/solution.md)

## How to run
This folder does not (yet) ship its own bootstrap. To exercise the **shared**
six-challenge curriculum in this region, copy `countries/za/bootstrap/` and
adjust `main.bicepparam` so `primaryRegion` = `saudiarabiaeast` and the policy
allowed-locations list reflects Saudi Arabia (KSA)'s residency requirements.

See [`../za/README.md`](../za/README.md) for the full reference build.
