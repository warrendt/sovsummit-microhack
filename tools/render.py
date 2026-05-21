#!/usr/bin/env python3
"""Render per-country Sovereignty Summit MicroHack bundles.

Merges `common/` with `countries/<iso2>/overrides/` and substitutes
`${country.<dotted.path>}` tokens (drawn from `country.yaml`) into all text
files. Outputs to `build/<iso2>/`.

Usage:
    python tools/render.py              # render every country
    python tools/render.py za eg        # render specific countries
    python tools/render.py --check      # render to a temp dir; fail on errors

Dependency: PyYAML (see tools/requirements.txt).
"""
from __future__ import annotations

import argparse
import re
import shutil
import sys
import tempfile
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:  # pragma: no cover
    sys.stderr.write("PyYAML is required: pip install -r tools/requirements.txt\n")
    sys.exit(2)

ROOT = Path(__file__).resolve().parent.parent
COMMON = ROOT / "common"
COUNTRIES = ROOT / "countries"
BUILD = ROOT / "build"

TOKEN_RE = re.compile(r"\$\{country\.([a-zA-Z0-9_.]+)\}")
TEXT_SUFFIXES = {".md", ".ps1", ".sh", ".bicep", ".bicepparam", ".json",
                 ".yaml", ".yml", ".txt", ".tf", ".tfvars"}

REQUIRED_FIELDS = ["iso2", "name", "summit_edition",
                   "azure.primary_region", "azure.paired_region"]


def dotted_get(data: dict, path: str) -> Any:
    cur: Any = data
    for part in path.split("."):
        if not isinstance(cur, dict) or part not in cur:
            raise KeyError(path)
        cur = cur[part]
    return cur


def validate(country: dict, iso2: str) -> None:
    for field in REQUIRED_FIELDS:
        try:
            dotted_get(country, field)
        except KeyError:
            raise SystemExit(f"[{iso2}] missing required field: {field}")
    if str(country["iso2"]).lower() != iso2:
        raise SystemExit(
            f"[{iso2}] iso2 in country.yaml ({country['iso2']}) does not match folder")


def substitute(text: str, country: dict, iso2: str) -> str:
    def repl(m: re.Match[str]) -> str:
        key = m.group(1)
        try:
            value = dotted_get(country, key)
        except KeyError:
            sys.stderr.write(
                f"[{iso2}] warning: unresolved token ${{country.{key}}}\n")
            return m.group(0)
        if isinstance(value, list):
            return ", ".join(str(v) for v in value)
        return str(value)

    return TOKEN_RE.sub(repl, text)


def copy_tree(src: Path, dst: Path, country: dict, iso2: str) -> None:
    for path in src.rglob("*"):
        rel = path.relative_to(src)
        target = dst / rel
        if path.is_dir():
            target.mkdir(parents=True, exist_ok=True)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        if path.suffix.lower() in TEXT_SUFFIXES:
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                shutil.copy2(path, target)
                continue
            target.write_text(substitute(text, country, iso2), encoding="utf-8")
        else:
            shutil.copy2(path, target)


def render_country(iso2: str, out_root: Path) -> Path:
    country_dir = COUNTRIES / iso2
    if not country_dir.exists():
        raise SystemExit(f"unknown country: {iso2}")
    country = yaml.safe_load((country_dir / "country.yaml").read_text(encoding="utf-8"))
    validate(country, iso2)

    out = out_root / iso2
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)

    copy_tree(COMMON, out, country, iso2)
    overrides = country_dir / "overrides"
    if overrides.exists():
        copy_tree(overrides, out, country, iso2)
    shutil.copy2(country_dir / "country.yaml", out / "country.yaml")
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("countries", nargs="*",
                        help="country iso2 codes (default: all)")
    parser.add_argument("--check", action="store_true",
                        help="render to temp dir; do not modify build/")
    args = parser.parse_args()

    targets = args.countries or sorted(
        p.name for p in COUNTRIES.iterdir()
        if p.is_dir() and (p / "country.yaml").exists()
    )

    out_root = Path(tempfile.mkdtemp(prefix="sovsummit-")) if args.check else BUILD
    out_root.mkdir(parents=True, exist_ok=True)

    for iso2 in targets:
        out = render_country(iso2, out_root)
        print(f"[{iso2}] rendered -> {out}")

    if args.check:
        shutil.rmtree(out_root, ignore_errors=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
