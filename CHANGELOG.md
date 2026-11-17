# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Linux support (x86_64 and arm64). Categories follow Linux conventions (XDG folders, Flatpak, Snap, `~/.local/share`, `~/.config`, `~/.cache`), System data lists where it is (`/usr`, package caches, the journal, crash dumps, swap) with the command that shrinks each, and removed items go to the freedesktop.org trash, so the file manager can put them back.
- Multiple drives on Linux: every mounted drive can be scanned on its own. `v` or `1`–`9` switch drives, `--drive` picks one at start, and `--drives` lists them along with partitions that are not mounted. A drive mounted twice (a bind mount, btrfs subvolumes) is measured once, and another drive mounted inside a folder is not counted in it.
- Dual boot: a mounted Windows partition, another Linux install, or an EFI/boot partition is shown look only, with Windows-aware labels (`hiberfil.sys`, `pagefile.sys`, `WinSxS`, `Windows.old`, Windows Update downloads). A read-only NTFS mount says Windows may be hibernated (fast startup).

### Fixed

- The installer now checks the downloaded package against the release's published `.sha256` and stops on a mismatch.
- The installer works on Linux: it checks with `sha256sum`, needs `unzip`, and unpacks the graphics runtime on the same filesystem as the install, so a tmpfs `/tmp` no longer breaks it.

## [0.1.0] - 2026-11-14

### Added

- Interactive disk view with a live dot-matrix meter, a category list and a folder browser you can dive into at any depth.
- Culprit finder: shows which nested folder or file holds most of a folder's space; `g` jumps straight to it.
- Labels on every item (`junk`, `unused`, `system`) with a one-line reason, plus a filter (`f`) to show only junk and unused.
- Last-used ages from Spotlight's last-opened dates, falling back to modification time.
- Reveal in Finder, move to Trash, and delete for good (caches and Trash only), each behind a second keypress.
- One-step clearing of caches and emptying the Trash.
- `--dry-run`, `--demo`, `--plain` and `--json` modes.
- `curl | sh` installer with `--version` and `--uninstall`.

[Unreleased]: https://github.com/govijr/fix-storage/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/govijr/fix-storage/releases/tag/v0.1.0
