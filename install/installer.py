#!/usr/bin/env python3
"""Install explicit Stow packages, optionally with one private overlay.

Planning is read-only. Tool provisioning is restricted to the real home.
Configuration changes are journaled and rolled back on application failure.
"""

import argparse
import contextlib
import datetime
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.request

if sys.version_info < (3, 9):
    sys.exit("dotfiles: Python 3.9 or later is required")

ROOT = Path(__file__).resolve().parent.parent


class InstallError(Exception):
    """An actionable installation failure."""


def fail(message):
    raise InstallError(message)


def run(args, **kwargs):
    print("+ " + " ".join(str(arg) for arg in args), flush=True)
    subprocess.run([str(arg) for arg in args], check=True, **kwargs)


def safe_relative(value):
    path = Path(value)
    if path.is_absolute() or not path.parts or any(p in (".", "..") for p in path.parts):
        fail(f"Expected a relative destination without traversal: {value}")
    if any(ord(c) < 32 for c in value):
        fail("Control characters are not allowed in paths")
    return path


def check_parents(path, root):
    """Reject symlinked destination ancestors rather than writing through them."""
    parent = path.parent
    while parent != root:
        if parent.is_symlink() or (parent.exists() and not parent.is_dir()):
            fail(f"Destination ancestor is not an ordinary directory: {parent}")
        if parent == parent.parent:
            fail(f"Path escapes destination root: {path}")
        parent = parent.parent


def read_packages(root, profile, system):
    primary = root / "profiles" / f"{profile}.packages"
    manifests = [primary, root / "profiles" / f"{profile}.{system}.packages"]
    if not primary.is_file():
        fail(f"Missing profile: {primary}")
    packages = []
    for manifest in manifests:
        if not manifest.exists():
            continue
        for raw in manifest.read_text().splitlines():
            name = raw.split("#", 1)[0].strip()
            if not name:
                continue
            if not re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9_-]*", name):
                fail(f"Invalid package name in {manifest}")
            if name in packages:
                fail(f"Duplicate package in profile: {name}")
            package = root / name
            if package.is_symlink() or not package.is_dir():
                fail(f"Missing or symlinked package: {package}")
            packages.append(name)
    return packages


def dependency_manifests(root, args, system):
    manifests = [root / "Brewfile.essential"]
    if not manifests[0].is_file():
        fail(f"Missing required dependency manifest: {manifests[0]}")
    if args.with_optional and (root / "Brewfile.optional").exists():
        manifests.append(root / "Brewfile.optional")
    if system == "macos" and args.profile == "desktop" and (root / "Brewfile.macos").exists():
        manifests.append(root / "Brewfile.macos")
    for path in manifests:
        if path.is_symlink() or not path.is_file():
            fail(f"Dependency manifest is not an ordinary file: {path}")
    return manifests


def collect_files(selections, target, check_destinations=True):
    files = {}
    for root, packages in selections:
        for package in packages:
            base = root / package
            for directory, dirs, names in os.walk(base, followlinks=False):
                for name in dirs + names:
                    source = Path(directory) / name
                    if source.is_symlink():
                        fail(f"Package symlinks require explicit review: {source}")
                for name in names:
                    if name == ".gitkeep":
                        continue
                    source = Path(directory) / name
                    if not source.is_file():
                        fail(f"Unsupported package entry: {source}")
                    relative = safe_relative(str(source.relative_to(base)))
                    if relative.parts[0] == ".git":
                        fail(f"Git metadata is not deployable: {source}")
                    if relative in files:
                        fail(f"Two packages own {relative}: {files[relative]} and {source}")
                    files[relative] = source
    for relative in files:
        for parent in relative.parents:
            if parent in files:
                fail(f"File/directory collision: {relative} and {parent}")
        if check_destinations:
            check_parents(target / relative, target)
    return files


def matching_link(path, source):
    return path.is_symlink() and path.resolve() == source.resolve()


def check_conflicts(files, target, backups, overlay):
    if not overlay and (target / ".config/dotfiles-work").exists():
        fail("Work extensions are already installed; migrate them explicitly before a public-only install")
    for relative, source in files.items():
        destination = target / relative
        if matching_link(destination, source):
            continue
        if destination.exists() or destination.is_symlink():
            if relative not in backups:
                fail(f"Conflict at {destination}; inspect it, then explicitly use --backup-file {relative}")
            if destination.is_dir() and not destination.is_symlink():
                fail(f"Refusing to back up a directory: {destination}")
    for relative in backups:
        if relative not in files:
            fail(f"--backup-file does not name a selected destination: {relative}")
    record = target / ".local/state/dotfiles/current.json"
    check_parents(record, target)
    if record.is_symlink():
        fail(f"Refusing symlinked state record: {record}")
    if record.exists():
        previous = json.loads(record.read_text())
        if not isinstance(previous, dict) or not isinstance(previous.get("files"), list):
            fail(f"Invalid ownership record; inspect it before continuing: {record}")
        for item in previous["files"]:
            if (not isinstance(item, dict) or not isinstance(item.get("target"), str)
                    or not isinstance(item.get("source"), str)):
                fail(f"Invalid file ownership entry in {record}")
            relative = safe_relative(item["target"])
            if relative not in files and matching_link(target / relative, Path(item["source"])):
                fail(f"Previously managed file is no longer selected: {relative}; explicitly unstow its old package first")


def brew_environment():
    brew = shutil.which("brew")
    if not brew:
        for candidate in ("/opt/homebrew/bin/brew", "/usr/local/bin/brew", "/home/linuxbrew/.linuxbrew/bin/brew"):
            if Path(candidate).is_file() and os.access(candidate, os.X_OK):
                brew = candidate
                break
    if brew:
        prefix = subprocess.check_output([brew, "--prefix"], text=True).strip()
        os.environ["PATH"] = f"{prefix}/bin:{prefix}/sbin:" + os.environ.get("PATH", "")
    return brew


def download_and_run(url, shell, env):
    """Download an official bootstrap only in the explicit tools phase."""
    with tempfile.TemporaryDirectory(prefix="dotfiles-bootstrap-") as directory:
        script = Path(directory) / "install.sh"
        with urllib.request.urlopen(url, timeout=60) as response:
            script.write_bytes(response.read())
        run([shell, script], env=env)


def install_tools(selections, args, system):
    env = dict(os.environ, NONINTERACTIVE="1", HOMEBREW_NO_AUTO_UPDATE="1",
               HOMEBREW_BUNDLE_NO_UPGRADE="1", HOMEBREW_NO_ANALYTICS="1",
               HOMEBREW_NO_INSTALL_CLEANUP="1")
    brew = brew_environment()
    if not brew:
        for command in ("git", "curl", "make", "cc"):
            if not shutil.which(command):
                fail(f"Install the platform prerequisite {command} before bootstrapping Homebrew")
        download_and_run("https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh", "/bin/bash", env)
        brew = brew_environment()
        if not brew:
            fail("Homebrew bootstrap did not produce a usable installation")
    env["PATH"] = os.environ["PATH"]
    for root, _ in selections:
        for manifest in dependency_manifests(root, args, system):
            run([brew, "bundle", "install", "--no-upgrade", f"--file={manifest}"], env=env)
    zsh_root = Path.home() / ".oh-my-zsh"
    if not (zsh_root / "oh-my-zsh.sh").is_file():
        if zsh_root.exists():
            fail(f"Existing incomplete Oh My Zsh directory: {zsh_root}")
        download_and_run(
            "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh", "/bin/sh",
            dict(env, RUNZSH="no", CHSH="no", KEEP_ZSHRC="yes", ZSH=str(zsh_root)),
        )


def required_commands(selections):
    commands = {"stow"}
    for root, _ in selections:
        path = root / "profiles/required.commands"
        if not path.is_file():
            fail(f"Missing required-command manifest: {path}")
        for raw in path.read_text().splitlines():
            command = raw.split("#", 1)[0].strip()
            if command:
                if not re.fullmatch(r"[a-zA-Z0-9_.+-]+", command):
                    fail(f"Invalid command in {path}")
                commands.add(command)
    return sorted(commands)


def stow(selections, target, simulate):
    # Isolate Stow's rc/ignore files; every selected file has explicit ownership.
    with tempfile.TemporaryDirectory(prefix="dotfiles-stow-") as directory:
        (Path(directory) / ".stow-global-ignore").write_text("^\\.gitkeep$\n")
        for root, packages in selections:
            if packages:
                run(["stow", "--no-folding", "--ignore=^\\.gitkeep$",
                     "--simulate" if simulate else "--stow",
                     f"--dir={root}", f"--target={target}", *packages], cwd=directory,
                    env=dict(os.environ, HOME=directory))


def write_record(path, record):
    temporary = path.with_suffix(".tmp")
    with temporary.open("x", encoding="utf-8") as output:
        json.dump(record, output, indent=2)
        output.write("\n")
    temporary.replace(path)


@contextlib.contextmanager
def locked(state):
    state.mkdir(parents=True, exist_ok=True, mode=0o700)
    lock = state / "install.lock"
    try:
        lock.mkdir(mode=0o700)
    except FileExistsError:
        fail(f"Another installation or stale lock exists: {lock}; inspect before removing it")
    try:
        yield
    finally:
        lock.rmdir()


def apply_config(selections, files, args, backups, state):
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S")
    directory = Path(tempfile.mkdtemp(prefix=stamp + "-", dir=state))
    journal = {"status": "applying", "profile": args.profile, "files": []}
    journal_path = directory / "journal.json"
    restored = []
    created = []
    complete = False
    try:
        for relative, source in files.items():
            destination = args.target / relative
            journal["files"].append({"target": str(relative), "source": str(source)})
            if matching_link(destination, source):
                continue
            if relative in backups and (destination.exists() or destination.is_symlink()):
                backup = directory / "backups" / relative
                backup.parent.mkdir(parents=True, exist_ok=True)
                # Journal the intended move before changing the destination.
                journal["files"][-1]["backup"] = str(backup)
                write_record(journal_path, journal)
                destination.rename(backup)
                restored.append((destination, backup))
            created.append((destination, source))
        write_record(journal_path, journal)
        stow(selections, args.target, simulate=True)
        stow(selections, args.target, simulate=False)
        for relative, source in files.items():
            if not matching_link(args.target / relative, source):
                fail(f"Link verification failed: {args.target / relative}")
        journal["status"] = "complete"
        write_record(journal_path, journal)
        write_record(state / "current.json", journal)
        complete = True
        print(f"Configuration installed. Ownership and backups: {journal_path}")
    finally:
        if not complete:
            for destination, source in reversed(created):
                if matching_link(destination, source):
                    destination.unlink()
            for destination, backup in reversed(restored):
                if destination.exists() or destination.is_symlink():
                    print(f"ROLLBACK BLOCKED: restore {backup} to {destination} manually", file=sys.stderr)
                else:
                    backup.rename(destination)
            journal["status"] = "failed; attempted rollback"
            write_record(journal_path, journal)
            print(f"Installation failed; inspect recovery record: {journal_path}", file=sys.stderr)


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    default_profile = "codespaces" if os.environ.get("CODESPACES") == "true" else "desktop"
    parser.add_argument("--profile", choices=("desktop", "codespaces"), default=default_profile)
    parser.add_argument("--overlay", type=Path)
    parser.add_argument("--target", type=Path, default=Path.home())
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--plan", action="store_true")
    group.add_argument("--tools-only", action="store_true")
    group.add_argument("--config-only", action="store_true")
    parser.add_argument("--with-optional", action="store_true")
    parser.add_argument("--non-interactive", action="store_true", help="All operations are already non-interactive")
    parser.add_argument("--backup-file", action="append", default=[], metavar="RELATIVE_PATH",
                        help="Explicitly authorize backing up this one conflicting file")
    args = parser.parse_args()
    args.target = args.target.expanduser().resolve()
    if not args.target.is_dir():
        parser.error("--target must be an existing directory")
    if args.target == Path("/"):
        parser.error("The filesystem root cannot be an installation target")
    if not (args.plan or args.config_only) and args.target != Path.home().resolve():
        parser.error("Tool installation is only supported for the current user's home")
    if args.overlay:
        args.overlay = args.overlay.expanduser().resolve()
        if args.overlay == ROOT or not args.overlay.is_dir():
            parser.error("--overlay must be a different existing root")
    return args


def main():
    args = parse_args()
    system = {"Darwin": "macos", "Linux": "linux"}.get(platform.system())
    if not system:
        fail("Only macOS and Linux are supported")
    roots = [ROOT] + ([args.overlay] if args.overlay else [])
    if os.environ.get("XDG_CONFIG_HOME") not in (None, "", str(Path.home() / ".config")):
        fail("These packages target ~/.config; unset a custom XDG_CONFIG_HOME before installation")
    selections = [(root, read_packages(root, args.profile, system)) for root in roots]
    commands = required_commands(selections)
    files = collect_files(selections, args.target, check_destinations=not args.tools_only)
    backups = {safe_relative(value) for value in args.backup_file}
    if not args.tools_only:
        check_conflicts(files, args.target, backups, args.overlay)
    print(f"Profile: {args.profile}; platform: {system}; target: {args.target}")
    for root, packages in selections:
        print(f"Source: {root}; packages: {', '.join(packages)}")
        for manifest in dependency_manifests(root, args, system):
            print(f"Dependencies: {manifest}")
    print("Required commands: " + ", ".join(commands))
    for relative in sorted(files):
        print(f"  {relative} <- {files[relative]}")
    if args.plan:
        print("Read-only filesystem plan complete. No Stow simulation or tool provisioning was performed.")
        return
    brew_environment()
    state = args.target / ".local/state/dotfiles"
    check_parents(state / "current.json", args.target)
    if state.is_symlink():
        fail(f"Refusing symlinked state directory: {state}")
    with locked(state):
        if not args.config_only:
            install_tools(selections, args, system)
        missing = [command for command in commands if not shutil.which(command)]
        if missing:
            fail("Missing required commands: " + ", ".join(missing) + "; run the tools phase first")
        if not args.tools_only:
            check_conflicts(files, args.target, backups, args.overlay)
            apply_config(selections, files, args, backups, state)
    print("Requested installation phases completed.")


if __name__ == "__main__":
    try:
        main()
    except (InstallError, OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print(f"dotfiles: {error}", file=sys.stderr)
        sys.exit(1)
