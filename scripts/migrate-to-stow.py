#!/usr/bin/env python3
"""One-time Home Manager -> Stow handoff. Preview by default; --apply to run.

Run after rebuilding NixOS without Home Manager. Existing files are backed up,
never deleted. Application state and secrets are not imported into the repo.
"""
import argparse
from datetime import datetime
import os
from pathlib import Path
import shutil
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    repo = Path(__file__).resolve().parent.parent
    home = Path.home()
    source = repo / "home"
    backup = home / ".local/state/dotfiles-backups" / datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    candidates = set()

    # Find old HM deployment links, without following directory symlinks.
    roots = [home / ".config", home / ".local/share/dbus-1/services",
             home / ".local/share/fish/home-manager", home / ".vscode/extensions"]
    for root in roots:
        if root.is_symlink():
            candidates.add(root)
        elif root.is_dir():
            for directory, dirs, files in os.walk(root, followlinks=False):
                candidates.update(Path(directory) / name for name in dirs + files)
    candidates.update(home / name for name in
                      [".zshrc", ".zshenv", ".zprofile", ".gtkrc-2.0", ".manpath"])
    conflicts = set()
    for path in candidates:
        if path.is_symlink() and "-home-manager-files/" in os.readlink(path):
            conflicts.add(path)

    # Preserve any real files or unrelated links at the new Stow destinations.
    for src in source.rglob("*"):
        if not src.is_file():
            continue
        dst = home / src.relative_to(source)
        if os.path.lexists(dst) and dst.resolve() != src.resolve():
            conflicts.add(dst)

    # A directory link already scheduled for backup subsumes its children.
    selected = []
    for path in sorted(conflicts, key=lambda p: (len(p.parts), str(p))):
        if not any(parent in selected for parent in path.parents):
            selected.append(path)
    for path in selected:
        print(f"Back up {path} -> {backup / path.relative_to(home)}", flush=True)

    command = ["stow", "--no-folding", f"--dir={repo}", f"--target={home}", "home"]
    if not args.apply:
        print("Then run:", " ".join(command))
        print("Preview only. Rebuild first, then rerun with --apply.")
        return
    if not shutil.which("stow"):
        parser.error("stow is not installed; rebuild NixOS first")
    for path in selected:
        destination = backup / path.relative_to(home)
        destination.parent.mkdir(parents=True, exist_ok=True)
        path.rename(destination)
    print(f"Backups: {backup}", flush=True)
    subprocess.run(command + ["--simulate", "--verbose"], check=True)
    subprocess.run(command + ["--verbose"], check=True)
    print("Done. Log out and back in to refresh the session environment.")


if __name__ == "__main__":
    main()
