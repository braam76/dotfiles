#!/usr/bin/env python3
"""Render native application themes from JSON + Jinja, optionally watching inputs."""
import argparse
import colorsys
import hashlib
import json
import logging
import math
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time
import tomllib

from jinja2 import Environment, FileSystemLoader, StrictUndefined, TemplateError

LOG = logging.getLogger("theme-generator")
ROOT = Path(__file__).resolve().parent


def color(value):
    """Accept #rrggbb, NONE, or an HSL triple [degrees, percent, percent]."""
    if isinstance(value, str):
        if value == "NONE":
            return value
        if re.fullmatch(r"#[0-9a-fA-F]{6}", value):
            return value.lower()
    if isinstance(value, list) and len(value) == 3:
        if not all(isinstance(x, (int, float)) and not isinstance(x, bool)
                   and math.isfinite(x) for x in value):
            raise ValueError(f"Invalid HSL: {value!r}")
        h, s, light = value
        if not (0 <= h <= 360 and 0 <= s <= 100 and 0 <= light <= 100):
            raise ValueError(f"HSL out of range: {value!r}")
        rgb = colorsys.hls_to_rgb((h % 360) / 360, light / 100, s / 100)
        return "#" + "".join(f"{math.floor(x * 255 + 0.5):02x}" for x in rgb)
    raise ValueError(f"Expected #rrggbb, NONE or [h, s, l], got {value!r}")


def channels(value):
    if not re.fullmatch(r"#[0-9a-f]{6}", value):
        raise ValueError(f"Not an RGB color: {value!r}")
    return tuple(int(value[n:n + 2], 16) for n in (1, 3, 5))


def within(root, name):
    """Reject traversal and symlinks escaping the managed output/source tree."""
    relative = Path(name)
    if relative.is_absolute() or ".." in relative.parts or not relative.parts:
        raise ValueError(f"Expected a relative path: {name!r}")
    path = root / relative
    if not path.resolve().is_relative_to(root.resolve()):
        raise ValueError(f"Path escapes {root}: {name!r}")
    return path


def context(path):
    data = json.loads(path.read_text())
    palette = {key: color(value) for key, value in data["palette"].items()}
    roles = {}
    for key, value in data["roles"].items():
        roles[key] = palette[value] if isinstance(value, str) and value in palette else color(value)
        channels(roles[key])  # Semantic roles must be actual RGB colors.
    return {"name": data["name"], "palette": palette, "roles": roles}


def atomic_write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    # Preserve a source symlink if one is introduced later; replace its referent.
    path = path.resolve()
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o644
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def render(root=ROOT, output=None, check=False, reload=False):
    config = json.loads((root / "config.json").read_text())
    output = output or root.parent / "home"
    theme = context(within(root, config["theme"]))
    env = Environment(loader=FileSystemLoader(root / "templates"),
                      undefined=StrictUndefined, autoescape=False,
                      keep_trailing_newline=True)
    env.filters.update(
        hex=lambda value: "".join(f"{x:02x}" for x in channels(value)),
        rgb=lambda value: ",".join(str(x) for x in channels(value)),
        rgba=lambda value, alpha="ff": "".join(f"{x:02x}" for x in channels(value)) + alpha,
    )
    planned = []
    seen = set()
    # Render and validate everything before touching any output.
    for item in config["templates"]:
        within(root / "templates", item["template"])
        path = within(output, item["target"])
        if path.resolve() in seen:
            raise ValueError(f"Duplicate target: {path}")
        seen.add(path.resolve())
        text = env.get_template(item["template"]).render(**theme)
        if path.suffix == ".toml":
            tomllib.loads(text)
        elif path.suffix == ".json":
            json.loads(text)
        if not path.exists() or path.read_text() != text:
            planned.append((path, text, item))
    for path, text, _ in planned:
        LOG.info("%s %s", "Would update" if check else "Updating", path)
        if not check:
            atomic_write(path, text)
    if reload and not check:
        commands = []
        for _, _, item in planned:
            for command in item.get("reload", []):
                if command not in commands:
                    commands.append(command)
        for command in commands:
            # Local trusted configuration, argv only; no shell evaluation.
            try:
                result = subprocess.run(command, capture_output=True, text=True, timeout=10)
                if result.returncode:
                    LOG.warning("Reload %r: %s", command, result.stderr.strip() or result.returncode)
            except (OSError, subprocess.TimeoutExpired) as error:
                LOG.warning("Reload %r: %s", command, error)
    LOG.info("%s: %d output(s) %s", theme["name"], len(planned), "pending" if check else "updated")
    return len(planned)


def fingerprint(root):
    digest = hashlib.sha256()
    paths = [root / "config.json"]
    for directory in [root / "themes", root / "templates"]:
        if directory.exists():
            paths.extend(p for p in directory.rglob("*") if p.is_file())
    for path in sorted(paths):
        digest.update(str(path).encode())
        digest.update(path.read_bytes())
    return digest.digest()


def watch(root, output, interval):
    previous = None
    pending = None
    while True:
        try:
            current = fingerprint(root)
            # Debounce until inputs are unchanged for one polling interval.
            if current != previous and current == pending:
                try:
                    render(root, output, reload=True)
                except Exception:
                    LOG.exception("Theme rejected; waiting for the next input change")
                previous = current
            pending = current
        except OSError:
            LOG.exception("Cannot read inputs; retrying")
        time.sleep(interval)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--output-root", type=Path, help="Default: ../home relative to root")
    parser.add_argument("--check", action="store_true", help="Preview without writing; exit 1 if changes needed")
    parser.add_argument("--reload", action="store_true", help="Reload affected apps after rendering")
    parser.add_argument("--watch", action="store_true", help="Watch palette, config and templates")
    parser.add_argument("--interval", type=float, default=0.5)
    args = parser.parse_args()
    if args.interval <= 0 or not math.isfinite(args.interval):
        parser.error("--interval must be a positive finite number")
    if args.watch and args.check:
        parser.error("--watch and --check cannot be combined")
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    try:
        if args.watch:
            watch(args.root, args.output_root, args.interval)
        else:
            changed = render(args.root, args.output_root, args.check, args.reload)
            return int(args.check and changed > 0)
    except (ValueError, OSError, KeyError, TemplateError) as error:
        LOG.error("%s", error)
        return 2
    except KeyboardInterrupt:
        return 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
