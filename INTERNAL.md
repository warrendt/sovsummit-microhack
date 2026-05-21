# INTERNAL — Microsoft-only content map

This repository contains both **public-shareable** content (the MicroHack itself)
and **Microsoft-internal** content (subscription provisioning, user creation,
the Microhack prep guide). This document is the source of truth for **what stays
private** and how we **publish a clean public mirror**.

> ⚠️ **This file (`INTERNAL.md`) is itself internal-only.** It is excluded from
> the public publish pipeline by `.publishignore`. Anything documented here is
> for Microsoft FSI / CSU teams running the Sovereignty Summit only.

## What stays private

| Path | Why | Public-repo replacement |
|---|---|---|
| `INTERNAL.md` (this file) | Documents the internal/public split itself. | — (omitted) |
| `common/resources/preparation-helpers/Create-MHUsers.ps1` | Creates lab users + 24-hour TAP at tenant scope. Requires Entra ID Premium P2 + User Administrator. Coach-only. | Public docs reference Entra portal "Add users" instead. |
| `common/resources/preparation-helpers/Create-AdminUsers.ps1` | Bulk admin user creation in `AdminUsers` group. | Same. |
| `common/resources/subscription-preparations/2-vcpu-quotas.ps1` (the **per-attendee Esv6 32 / DSv5 8 / DCasv5 6** numbers in the prep guide) | The exact quota-per-attendee table comes from `Microhack_Prep.pdf` which is Microsoft-internal MCAPS guidance. The script itself is public (upstream microsoft/MicroHack); only the explicit "per attendee" interpretation table is private. | Public docs reference the upstream script and say "tune to your event size". |
| Any reference to the `MCAPS` cost-control regime, `Microhack_Prep.pdf`, MCAPS subscription provisioning, or the partner-tenant `MngEnvMCAP*` accounts | Microsoft-partner contractual material. | Generic "MCA / EA / CSP subscription" wording. |
| `TemporaryAccessPasses.xlsx` (generated artifact) | Contains attendee identifiers + temporary credentials. | `.gitignore` + `.publishignore`. |
| `.planning/`, `.copilot/`, GSD session state, anything in `~/.copilot/session-state/` | Workflow artifacts, agent prompts, planning notes. | — (omitted) |
| `Microhack_Prep.pdf` (if ever vendored into repo) | The internal MCAPS prep guide. | — (omitted) |
| **PDF cross-walk table** in `countries/za/overrides/bootstrap/README.md` | The "PDF page → step" mapping references the internal prep guide page numbers. | Generic step list without page refs. |

## What is safe to publish

Everything else, including:

- `common/challenges/` — the 6 generic challenge briefs
- `common/walkthrough/` — solution walkthroughs
- `common/resources/demo-vm-creator/deploy-arcbox.ps1` + `deploy-localbox.ps1` (upstream microsoft/MicroHack, public)
- `common/resources/preparation-helpers/New-SummitSecurityGroup.ps1` + `Set-CAExclusion.ps1` (we wrote these, generic Entra patterns)
- `countries/*/country.yaml` + `countries/*/overrides/` (all country editions)
- `common/schema/`, `tools/render.py`, `.github/workflows/ci.yml`
- `build/<iso2>/` rendered bundles (with private prep scripts stripped at publish time)
- All bootstrap `main.bicep` / `main.bicepparam` / modules

## Publishing flow

```bash
# 1. Make sure private repo is clean and pushed.
git status              # must be clean
git pull --rebase

# 2. Render every country bundle so build/ is current.
rm -rf build && .venv/bin/python tools/render.py

# 3. Run the publish script. It will:
#    a. rsync everything except .publishignore entries into ../sovsummit-microhack-public/
#    b. commit with the release tag
#    c. push to the public remote (warrendt/sovsummit-microhack-public)
./tools/publish.sh --release v1.0 --remote https://github.com/warrendt/sovsummit-microhack-public.git
```

See `tools/publish.sh --help` for full options. The script is idempotent and
preserves the public repo's git history across releases (only **content** is
overwritten, not the public repo's commit log).

## Recommendation (public repo strategy)

**Option A — Separate repo with publish script (CHOSEN)**:
- Pro: Zero risk of leaking history.
- Pro: Public consumers `git clone` a small, clean repo.
- Pro: Private repo can stay private without affecting public discoverability.
- Pro: Release cadence is explicit (publish only when ready).
- Con: Two repos to keep in sync — mitigated by the publish script.

**Option B — Branch-based filter (rejected)**:
- Would have used `git filter-repo` + a `public` branch.
- Risk: a single mistake exposes the entire private history.

**Option C — GitHub Enterprise "Inner Source" with mirror (rejected)**:
- Requires GHEC + admin work.
- Not portable to a non-Microsoft consumer.

## Audit checklist before each publish

```bash
# Sanity-check: no private terms slip through.
./tools/publish.sh --check        # dry-run + grep

# Manual eyeball check:
grep -RIn -E "MCAPS|Microhack_Prep|MngEnvMCAP|TemporaryAccessPasses|Create-MHUsers|Create-AdminUsers" \
  ../sovsummit-microhack-public/ \
  --exclude-dir=.git
# Expected output: empty.
```

## Public repo name + visibility

| | |
|---|---|
| Org / user | `warrendt` (recommend moving to `microsoft` after first event) |
| Repo name | `sovsummit-microhack-public` (first release) → `sovsummit-microhack` (when public-only) |
| Visibility | Public |
| License | MIT (matches upstream microsoft/MicroHack) |
| Default branch | `main` |
| Issues | Enabled |
| Discussions | Enabled (community Q&A) |
| Pages | Optional — could host rendered challenge briefs |
