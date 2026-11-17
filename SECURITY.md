# Security policy

fix-storage reads your whole disk and can delete files, so bugs that make it remove the wrong thing are treated as security issues.

## Reporting

Please **don't open a public issue** for:

- anything that makes fix-storage delete or move files it shouldn't (outside the folders it scans, protected folders, or without the second confirmation)
- `--dry-run` or `--demo` changing anything on disk
- problems with the install script

Report it privately through [GitHub security advisories](https://github.com/govijr/fix-storage/security/advisories/new). Include your OS version (and Linux distribution), the command you ran, and the path involved. You'll get a reply within a few days.

## Supported versions

Only the latest release gets fixes. Update with the install command in the [README](README.md).
