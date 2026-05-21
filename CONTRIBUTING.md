# Contributing — adding or updating a country

This repo hosts a single MicroHack template (`common/`) with per-country
overrides under `countries/<iso2>/`. Follow this checklist when adding a new
country or updating an existing one.

## 1. Pick the ISO2 code

Use the **lowercase ISO 3166-1 alpha-2** code (e.g. `za`, `eg`, `ng`, `ae`,
`sa`, `qa`). The folder name must match the `iso2` field inside
`country.yaml`.

## 2. Create the folder

```
countries/<iso2>/
  country.yaml            # required, see common/schema/country.schema.yaml
  overrides/              # optional, mirrors the layout of common/
  params/                 # optional, country defaults consumed by scripts
```

## 3. Fill in `country.yaml`

Required fields:

- `iso2`
- `name`
- `summit_edition`
- `azure.primary_region`
- `azure.paired_region`

Strongly recommended:

- `azure.confidential_compute_skus` — verify with
  `az vm list-skus -l <region> --query "[?contains(name, 'DC') || contains(name, 'EC')]"`
- `azure.cmk_hsm_sku` — `Premium` if Key Vault Managed HSM is required.
- `regulatory.frameworks` — primary statute first.

Use the South Africa file (`countries/za/country.yaml`) as a worked example.

## 4. Author overrides

Anything you place under `countries/<iso2>/overrides/` is laid down on top of
the rendered `common/` tree with the same relative path. Common overrides:

- `overrides/Readme.md` — country landing page replacing the upstream one.
- `overrides/challenges/challenge-<id>.md` — replace or add a challenge.
- `overrides/walkthrough/<challenge-id>/solution.md` — matching solution.

Tokens of the form `${country.<dotted.path>}` in any text file are substituted
at render time with the value from `country.yaml`.

## 5. Render and review locally

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r tools/requirements.txt
python tools/render.py <iso2>
open build/<iso2>/Readme.md
```

Run `python tools/render.py --check` to render every country into a temp
directory; CI does the same.

## 6. Verify region & SKU availability

Before publishing a country edition, confirm in the chosen Azure region:

- Confidential Compute VM SKUs are available (`Standard_DC*as_v5`,
  `Standard_EC*as_v5`).
- AKS Confidential node pools are supported.
- Key Vault Premium / Managed HSM is offered.
- Azure Arc + Azure Local are supported (`az connectedmachine` /
  `az stack-hci`).

Note any gaps in the country `Readme.md` override so attendees know what to
substitute (e.g. running a workload in the paired region instead).

## 7. Open a PR

CI must be green (`renders all countries` + `bicep build`). Tag the PR with the
country code (`country/za`, `country/eg`, …) and request review from the local
chapter lead.

## Upstream sync

To pick up new upstream Microsoft MicroHack content:

```bash
# from a fresh checkout of microsoft/MicroHack main
rsync -a --delete \
  03-Azure/01-03-Infrastructure/01_Sovereign_Cloud/ \
  /path/to/sovsummit/common/
git diff -- common/
```

Review the diff carefully — country overrides referenced by path may need
updates if upstream renames files.
