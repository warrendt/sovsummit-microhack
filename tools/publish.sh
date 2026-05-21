#!/usr/bin/env bash
# publish.sh — populate the public mirror of sovsummit-microhack.
#
# Strategy:
#   1. rsync content from this private repo to a sibling worktree, respecting
#      .publishignore.
#   2. Run audit greps to make sure no internal terms slip through.
#   3. Commit with the release tag.
#   4. Push to the public remote.
#
# Usage:
#   ./tools/publish.sh --check                # dry-run + audit greps, no writes
#   ./tools/publish.sh --release v1.0 \      # actually publish
#       --remote https://github.com/warrendt/sovsummit-microhack-public.git
#
# Flags:
#   --check               Dry-run. Prints what would be copied + runs audit.
#   --release <tag>       Release tag to commit (default: dated v0.1.0-<date>).
#   --remote <url>        Public remote URL. Defaults to env PUBLIC_REMOTE.
#   --dest <path>         Destination worktree (default: ../sovsummit-microhack-public).
#   --no-push             Commit locally only, skip push.
#
# Safety: this script will REFUSE to run if the private repo has uncommitted
# changes, or if any audit-grep returns a match.

set -euo pipefail

# ---- defaults ----
CHECK=0
RELEASE=""
REMOTE="${PUBLIC_REMOTE:-}"
DEST=""
PUSH=1

# ---- args ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)    CHECK=1; shift ;;
    --release)  RELEASE="$2"; shift 2 ;;
    --remote)   REMOTE="$2"; shift 2 ;;
    --dest)     DEST="$2"; shift 2 ;;
    --no-push)  PUSH=0; shift ;;
    -h|--help)
      sed -n 's/^# \{0,1\}//p' "$0" | sed -n '/^publish.sh/,/^Safety:/p'
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

[[ -z "$DEST" ]] && DEST="$(cd .. && pwd)/sovsummit-microhack-public"
[[ -z "$RELEASE" ]] && RELEASE="v0.1.0-$(date +%Y%m%d)"

echo "==> Private repo  : $REPO_ROOT"
echo "==> Public worktree: $DEST"
echo "==> Release tag   : $RELEASE"
echo "==> Public remote : ${REMOTE:-<none — use --remote or set PUBLIC_REMOTE>}"
echo "==> Mode          : $([[ $CHECK -eq 1 ]] && echo 'check (dry-run)' || echo 'publish')"
echo

# ---- pre-flight: clean private repo ----
if [[ -n "$(git status --porcelain)" && $CHECK -eq 0 ]]; then
  echo "ERROR: private repo has uncommitted changes. Commit or stash first." >&2
  git status --short
  exit 1
fi

# ---- pre-flight: render bundles ----
if [[ ! -d build/za ]]; then
  echo "==> build/ missing — running renderer."
  if [[ -x .venv/bin/python ]]; then
    .venv/bin/python tools/render.py
  else
    python3 tools/render.py
  fi
fi

# ---- 1. rsync to dest ----
mkdir -p "$DEST"

RSYNC_OPTS=(-a --delete --exclude-from=.publishignore)
# Always copy for real so the audit can scan actual destination files. In
# --check mode we still copy, just don't commit/push afterwards.

echo
echo "==> Copying public content to $DEST ..."
# Preserve .git in DEST (if any) so we keep public history.
RSYNC_OPTS+=(--exclude=.git/)
rsync "${RSYNC_OPTS[@]}" ./ "$DEST/"

# ---- 1b. Strip <<<INTERNAL_ONLY>>> blocks from the destination ----
# Three marker styles are supported and stripped together:
#   shell / pwsh:  # <<<INTERNAL_ONLY>>> ... # <<<END_INTERNAL_ONLY>>>
#   markdown:      <!-- <<<INTERNAL_ONLY>>> --> ... <!-- <<<END_INTERNAL_ONLY>>> -->
# Plus the markdown <!-- PUBLIC_REPLACEMENT_FOR_xxx ... END_PUBLIC_REPLACEMENT_FOR_xxx -->
# block (which IS rendered in the public version, by uncommenting it).
echo
echo "==> Stripping <<<INTERNAL_ONLY>>> blocks + activating PUBLIC_REPLACEMENT blocks ..."
python3 - "$DEST" <<'PYEOF'
import os, re, sys
root = sys.argv[1]
TEXT_EXTS = {'.sh','.ps1','.bicep','.bicepparam','.md','.yaml','.yml','.txt','.json','.psm1','.psd1'}
patterns = [
    # Strip whole region between markers (any comment style)
    (re.compile(r'(?ms)^[^\n]*<<<INTERNAL_ONLY>>>.*?<<<END_INTERNAL_ONLY>>>[^\n]*\n?'), ''),
    # Activate markdown PUBLIC_REPLACEMENT_FOR_xxx blocks by stripping the
    # surrounding <!-- ... --> wrapper.
    (re.compile(r'(?ms)<!--\s*PUBLIC_REPLACEMENT_FOR_[A-Z_]+\s*\n(.*?)\nEND_PUBLIC_REPLACEMENT_FOR_[A-Z_]+\s*-->'), lambda m: m.group(1)),
]
changed = 0
for dirpath, dirs, files in os.walk(root):
    if '/.git' in dirpath: continue
    for f in files:
        ext = os.path.splitext(f)[1].lower()
        if ext not in TEXT_EXTS: continue
        p = os.path.join(dirpath, f)
        try:
            with open(p, 'r', encoding='utf-8') as fh: s = fh.read()
        except UnicodeDecodeError:
            continue
        orig = s
        for pat, repl in patterns:
            s = pat.sub(repl, s)
        if s != orig:
            with open(p, 'w', encoding='utf-8') as fh: fh.write(s)
            changed += 1
print(f"    stripped/activated markers in {changed} file(s).")
PYEOF

# ---- 2. audit greps ----
echo
echo "==> Audit: scanning destination for internal-only terms ..."
AUDIT_PATTERN='MCAPS|Microhack_Prep|MngEnvMCAP|TemporaryAccessPasses|Create-MHUsers|Create-AdminUsers'
if grep -RIn -E "$AUDIT_PATTERN" "$DEST" \
     --exclude-dir=.git --exclude-dir=.venv --exclude=publish.sh \
     --exclude=INTERNAL.md --exclude=.publishignore 2>/dev/null; then
  echo
  echo "AUDIT FAILED — internal terms present in public content."
  echo "Scrub these files (or add them to .publishignore) before publishing." >&2
  [[ $CHECK -eq 1 ]] || exit 1
else
  echo "    audit clean."
fi

if [[ $CHECK -eq 1 ]]; then
  echo
  echo "==> Check complete. No changes made."
  exit 0
fi

# ---- 3. commit + tag in public worktree ----
cd "$DEST"
if [[ ! -d .git ]]; then
  echo "==> Initializing public git repo at $DEST"
  git init -b main
  if [[ -n "$REMOTE" ]]; then
    git remote add origin "$REMOTE"
  fi
fi

git add -A
if git diff --cached --quiet; then
  echo "==> No public-content changes to commit."
else
  COMMIT_MSG="release: $RELEASE — Sovereignty Summit MicroHack public release

Synced from private repo $(cd "$REPO_ROOT" && git rev-parse --short HEAD).
See INTERNAL.md in the private repo for the publish process."
  git commit -m "$COMMIT_MSG"
  git tag -a "$RELEASE" -m "Release $RELEASE"
fi

# ---- 4. push ----
if [[ $PUSH -eq 1 ]]; then
  if [[ -z "$REMOTE" ]] && ! git remote get-url origin >/dev/null 2>&1; then
    echo "WARNING: no public remote configured. Skipping push."
    echo "    Set with: cd $DEST && git remote add origin <url>"
  else
    echo
    echo "==> Pushing to public remote ..."
    git push -u origin main --tags
  fi
else
  echo "==> Skipping push (--no-push)."
fi

echo
echo "Done. Public worktree: $DEST"
