# Sovereignty Summit MicroHack

A multi-country adaptation of the
[Microsoft Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud)
for the **Sovereignty Summit** series — starting with **South Africa**, then
Egypt, Nigeria, UAE, Saudi Arabia, and Qatar.

The upstream MicroHack content is preserved verbatim under [`common/`](common/)
and customized per event via [`countries/<iso2>/`](countries/) overrides plus a
[`country.yaml`](common/schema/country.schema.yaml) configuration file. A
single source of truth, rendered per event.

## Why a multi-country structure?

Each summit edition needs the same core challenges (Azure Policy, CMK, TLS,
Confidential Compute, Arc/Azure Local) but:

- **Different Azure regions** (`southafricanorth`, `uaenorth`, `qatarcentral`, …)
- **Different regulatory frameworks** (POPIA, PDPL, SAMA, DIFC, …)
- **Different scenarios** (DHA, CBE, NDPC, SAMA-regulated banks, …)
- **Different sponsors and branding**

The hybrid `common/` + `countries/<iso2>/` model lets us:

- ✅ Share challenges, scripts, and Bicep modules across all editions.
- ✅ Override anything per country without forking.
- ✅ Pick up upstream Microsoft updates by re-syncing `common/`.

## Repository layout

```
common/                     Upstream Microsoft Sovereign Cloud MicroHack content
  challenges/               6 shared challenge briefs (markdown)
  walkthrough/              Solution walkthroughs per challenge
  resources/                PowerShell prep + cleanup + Azure Local/Arc deploys
  schema/country.schema.yaml  Documented country.yaml schema
countries/
  za/                       🇿🇦 South Africa (first concrete edition)
    country.yaml            Region, regulators, scenarios, sponsor, etc.
    overrides/              Files that override or extend common/ (same layout)
    params/                 Country-specific deployment defaults (PowerShell)
  eg/  ng/  ae/  sa/  qa/   Stub editions awaiting authoring
tools/
  render.py                 Merges common/ + countries/<iso2> -> build/<iso2>/
  requirements.txt          PyYAML
.github/workflows/ci.yml    Renders every country on every push
LICENSE                     MIT (upstream + customizations)
```

## Rendering a country bundle

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r tools/requirements.txt

# Render every country into build/<iso2>/
python tools/render.py

# Or just one
python tools/render.py za
```

Tokens of the form `${country.<dotted.path>}` (for example
`${country.azure.primary_region}`) found in any text file are replaced with the
value from the country's `country.yaml`.

The generated `build/za/` is the bundle you hand to attendees of the South
Africa summit.

## Country roadmap

| Order | Country | ISO2 | Status | Primary region |
|---|---|---|---|---|
| 1 | South Africa | `za` | ✅ Authored | `southafricanorth` |
| 2 | Egypt | `eg` | ✅ Authored | `uaenorth` (no in-country region) |
| 3 | Nigeria | `ng` | ✅ Authored | `southafricanorth` (no in-country region) |
| 4 | UAE | `ae` | ✅ Authored | `uaenorth` |
| 5 | Saudi Arabia | `sa` | ✅ Authored | `saudiarabiaeast` |
| 6 | Qatar | `qa` | ✅ Authored | `qatarcentral` |

## Adding a new country

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Attribution

Original MicroHack content authored by **Jan Egil Ring**, **Ye Zhang**,
**Murali Rao Yelamanchili** and other Microsoft contributors, released under
the MIT License. See [`common/Readme.md`](common/Readme.md) and
[`LICENSE`](LICENSE).

Sovereignty Summit customizations © 2026 Warren du Toit and contributors.
