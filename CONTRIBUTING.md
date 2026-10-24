# Contributing

This is a personal dotfiles repository, but changes are welcome. Work is tracked in
issues and pull requests so every change has a reason and a review trail.

## Workflow

1. **Open an issue first** for anything that is not a typo: what happens, why it is a
   problem, and how to reproduce it.
2. **Branch from `main`**, one change per branch (`fix/...`, `chore/...`, `docs/...`).
3. **Open a pull request** that explains what changed and how it was verified, and closes
   the issue with `Fixes #N`.
4. CI must be green and the automated review must approve before it is merged. PRs are
   squash-merged, so the PR title becomes the commit subject.

## Commit and PR titles

`type(scope): subject`, lower-case, no trailing period. Types in use: `fix`, `feat`,
`chore`, `docs`, `ci`, `refactor`, `style`, `perf`, `test`, `revert`. Examples from the history:

```
fix(power): group-restrict the ASUS sysfs nodes instead of making them world-writable
chore(installer): re-pin end4-pC to c2cb8cf
```

Describe the behaviour, not the diff. Say what you ran to verify it.

## Before you push

```bash
git config core.hooksPath .githooks    # once: runs tests/run.sh before each commit
bash tests/run.sh                      # syntax, ShellCheck and regression tests
./install.sh --dry-run --rice <rice>   # what a link pass would do
```

Install `shellcheck` locally; CI requires it. The hook is safe to use from a linked
worktree.

## Conventions

- **No machine-specific paths.** Use `$HOME` / `Path.home()`, never `/home/<user>`, in
  anything that is executed.
- **Vendored scripts stay untouched.** Files under `rices/*/hypr/hyprland/scripts/` are
  copied from other projects; they are skipped by lint so they can be diffed against their
  source. Fix them upstream.
- **Hand-written config and generated state are committed separately** (see "Config vs
  generated state" in the README).
- **Third-party shells are pinned** in `lib/shells.sh`. Bump a pin in its own PR and run
  `bash tests/network/check-pins.sh`; the pin must be on the default branch of its
  repository, so do not rewrite a pinned history without re-pinning right after.
- **Changes that touch permissions** (`common/udev`, `common/tmpfiles`, systemd units,
  `setup_power_permissions.sh`) should say in the PR who can do what afterwards.

## License

Contributions are accepted under the repository's [GPL-3.0](LICENSE) license.

## Security issues

Do not open a public issue for a vulnerability; see [SECURITY.md](SECURITY.md).
