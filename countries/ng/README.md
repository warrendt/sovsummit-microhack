# Nigeria — Sovereignty MicroHack (preview)

> ⚠️ **Status: in development.** This country edition is scaffolded but not yet
> fully tested. The challenges below were authored against Nigeria's sovereignty
> framework but the bootstrap automation, walkthroughs, and demo VMs have not
> been validated end-to-end.
>
> The reference implementation is **South Africa** (`countries/za/`). It is
> fully tested and ready to run.

## Scenario
- **Regulator(s):** NDPC, Central Bank of Nigeria
- **Primary law:** Nigeria Data Protection Act 2023 (NDPA)
- **Recommended landing region:** `southafricanorth (no in-country region — see Ch3)`
- **Sovereignty pattern:** Hybrid (Azure Local on-prem + Sovereign Public Cloud)

## Country-specific challenges
- [`challenges/challenge-ng-01-ndpa-cross-border-sdcmi.md`](challenges/challenge-ng-01-ndpa-cross-border-sdcmi.md)
- [`challenges/challenge-ng-02-cbn-hybrid-azure-local.md`](challenges/challenge-ng-02-cbn-hybrid-azure-local.md)
- [`challenges/challenge-ng-03-sovereign-public-cloud-johannesburg.md`](challenges/challenge-ng-03-sovereign-public-cloud-johannesburg.md)

## Walkthroughs
- [`walkthrough/challenge-ng-01-ndpa-cross-border-sdcmi/solution.md`](walkthrough/challenge-ng-01-ndpa-cross-border-sdcmi/solution.md)
- [`walkthrough/challenge-ng-02-cbn-hybrid-azure-local/solution.md`](walkthrough/challenge-ng-02-cbn-hybrid-azure-local/solution.md)
- [`walkthrough/challenge-ng-03-sovereign-public-cloud-johannesburg/solution.md`](walkthrough/challenge-ng-03-sovereign-public-cloud-johannesburg/solution.md)

## How to run
This folder does not (yet) ship its own bootstrap. To exercise the **shared**
six-challenge curriculum in this region, copy `countries/za/bootstrap/` and
adjust `main.bicepparam` so `primaryRegion` = `southafricanorth (no in-country region — see Ch3)` and the policy
allowed-locations list reflects Nigeria's residency requirements.

See [`../za/README.md`](../za/README.md) for the full reference build.
