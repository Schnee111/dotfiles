# Security policy

## Supported versions

Only the current `main` branch is maintained.

## Reporting a vulnerability

Please report it privately through GitHub: open the repository's **Security** tab and
choose **Report a vulnerability**. Do not open a public issue or pull request that
describes the problem.

Include what is affected, how to reproduce it, and what an attacker gains. This is a
personal project, so replies are best effort, but a report is read and acknowledged.

## What is in scope

The parts of this repository that run with privileges or execute downloaded or generated
content:

- `setup_power_permissions.sh` and the files it installs (`common/udev`, `common/tmpfiles`,
  `common/systemd/system`);
- the installer (`install.sh`, `lib/`) and the scripts it links into `$HOME`;
- the third-party shells fetched by the installer, and the pinned revisions in
  `lib/shells.sh`.

Vulnerabilities in the upstream projects themselves (Hyprland, Quickshell, the shells)
should be reported to those projects.
