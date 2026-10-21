# Recovery

What to do when a switch goes wrong. Read this from a phone if the desktop will
not start.

## What a switch actually touches

| State | Path |
|---|---|
| Symlinks into the repo | `~/.config/...`, `~/.local/bin/...`, `~/.local/share/sounds/macos` |
| Active rice marker | `~/.config/.current_rice` |
| GDM session (next login) | AccountsService `Session` property |
| Managed-path list | `~/.local/state/dotfiles/manifest.tsv` |
| Rollback snapshots | `~/.local/state/dotfiles/rollback-<ts>-<pid>.tsv` |
| Replaced real files | `~/.config/dotfiles_backup_<ts>/` (path-mirrored) |

A switch writes symlinks first, verifies the new compositor config, and only
then commits `.current_rice` + the GDM session. If verification fails,
`rice-switch` restores the snapshot automatically: symlinks, `.current_rice`,
and the manifest go back to the previous rice.

## Case 1 — switch failed, desktop still alive

Nothing to do; the rollback already ran. The terminal prints
`verification failed ... restoring previous config`. Confirm:

```bash
dotfiles status
dotfiles doctor
```

Fix the offending config in the repo, then retry:

```bash
dotfiles switch <rice>
```

## Case 2 — logged out into a black screen / broken session

1. Switch to a TTY: `Ctrl+Alt+F3` (F2..F6 also work).
2. Log in, then roll back and relink the last good rice:

   ```bash
   cd ~/Projects/dotfiles
   ./install.sh --rollback          # restore the last snapshot
   ./install.sh --rice end4         # or whichever rice is known-good
   dotfiles doctor
   ```

3. Verify the config before logging in again:

   ```bash
   hyprland --verify-config    # Hyprland rices
   niri validate               # iris
   umbriel config validate -c ~/.config/umbriel/config.toml   # noctalia
   ```

4. `loginctl terminate-session "$XDG_SESSION_ID"` or reboot, then log in.

If GDM launches the wrong compositor, pick the session explicitly with the gear
icon on the login screen, or set it directly:

```bash
busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$UID" \
  org.freedesktop.Accounts.User SetSession s hyprland
busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$UID" \
  org.freedesktop.Accounts.User SetSessionType s wayland
```

## Case 3 — a config stopped tracking the repo

Symptom: you edit a file in the repo, but the running app does not change — or
`git status` stays clean while the live file differs. Cause: a shell wrote its
state with an atomic rename (`write tmp` + `rename`), which replaces the
symlink with a regular file.

```bash
dotfiles doctor          # lists "replaced" paths
dotfiles doctor --fix    # relinks the active rice
```

`doctor` fails closed (exit 1) when the manifest is missing or any managed path
drifted, so it is safe to use as a pre-commit or CI gate.

## Case 4 — lost UI state after a switch

The end-4 shell stores its state in `~/.config/illogical-impulse/config.json`,
which the installer "folds" back into the outgoing rice before relinking. If a
previous switch lost it, look for the copy:

```bash
ls -lt ~/.config/dotfiles_backup_*/illogical-impulse/config.json 2>/dev/null | head
```

Only the last five backup trees are kept; older ones are pruned on each
successful install.

## Inspecting a rollback

```bash
ls -lt ~/.local/state/dotfiles/rollback-*.tsv | head -3
less "$(ls -1t ~/.local/state/dotfiles/rollback-*.tsv | head -1)"
```

Format: `kind<TAB>path<TAB>data`, where `kind` is `link` (with the old target),
`file`/`dir` (restored from the backup tree), `absent` (did not exist), or
`meta` (`backup_dir`, `current_rice`, `status`, `rolled_back`).
