# Contributing

## Repository layout

The repo is intentionally simple. Each country is a self-contained folder under
`countries/`. There is **no** template rendering, no `common/` directory, and
no build step. To read a challenge, open the markdown file directly.

```
countries/<iso2>/
├── README.md             # scenario, region, challenge index
├── challenges/           # the markdown attendees read
├── walkthrough/          # solutions (coaches only)
├── bootstrap/            # main.bicep + build / teardown scripts (ZA only today)
├── subscription-prep/    # idempotent multi-attendee prep (ZA only today)
├── demo-vms/             # ArcBox + LocalBox deployers (ZA only today)
└── cleanup/              # post-event resource-group purge
```

Only the South Africa folder (`countries/za/`) currently ships the bootstrap
automation. The other country folders are scaffolded with country-specific
challenges only.

## Adding a new country

1. Copy `countries/za/` to `countries/<iso2>/`.
2. Update `README.md` with the regulator(s), primary region, and sovereignty
   pattern for the new country.
3. Edit `bootstrap/main.bicep` and `main.bicepparam`:
   - `primaryRegion` = new country's preferred region
   - allowed-locations list reflects that country's residency requirements
4. Rename `build-za.sh` / `build-za.ps1` / `teardown-za.sh` to use the new ISO
   code (e.g. `build-ae.sh`). Update the banner text.
5. Rewrite each `challenges/challenge-*.md` so the regulator names, citations,
   and acceptance criteria reflect the new country's law and supervisor.
6. Add or update walkthroughs in `walkthrough/` to match the new acceptance
   criteria.
7. Validate locally before committing (see below).

## Validating a country folder

Run from the repo root:

```bash
# Bicep compiles
az bicep build --file countries/<iso2>/bootstrap/main.bicep --stdout >/dev/null

# Bash scripts parse
bash -n countries/<iso2>/bootstrap/build-*.sh
bash -n countries/<iso2>/bootstrap/teardown-*.sh

# PowerShell scripts parse
pwsh -NoProfile -Command "[System.Management.Automation.Language.Parser]::ParseFile('countries/<iso2>/bootstrap/build-<iso2>.ps1',[ref]\$null,[ref]\$errs); if(\$errs){\$errs;exit 1}"

# Dry-run the deployment
./countries/<iso2>/bootstrap/build-<iso2>.sh --what-if
```

The CI workflow (`.github/workflows/ci.yml`) runs the bicep + bash + markdown
checks on every push.

## Sensitive content

Private preparation helpers (user / TAP / CA-exclusion scripts, prep PDFs,
internal docs) **must not** be committed to this repo. Coaches keep them in a
separate private location and point the bootstrap at it via the
`--internal-helpers-path <dir>` flag or the `$SOVSUMMIT_INTERNAL_HELPERS`
environment variable. Without those helpers the repo still runs end-to-end in
**engineer mode** and in **coach mode without `--create-users`**.

If you ever need to redact the bootstrap script for a public mirror, the
internal-only blocks are wrapped in `# <<<INTERNAL_ONLY>>> ... # <<<END_INTERNAL_ONLY>>>`
markers so they can be stripped with `sed`.

## Conventions

- Markdown: use ATX headings (`#`), unordered lists with `-`, code fences for
  every command block.
- PowerShell scripts: `param()` block, `Set-StrictMode -Version Latest`,
  `$ErrorActionPreference = 'Stop'`, support `-NonInteractive` where attended
  prompts exist.
- Bash scripts: `#!/usr/bin/env bash`, `set -euo pipefail`, `--help` text in
  leading `#` comments.
- Bicep: prefer modules under `bootstrap/modules/`. Parameters that need
  customisation per country live in `main.bicepparam`.
