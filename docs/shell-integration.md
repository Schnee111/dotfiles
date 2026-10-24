# Integration with the end4-pC shell

The `end4` rice is two repositories that work together: this one (Hyprland config, scripts,
installer) and [`Schnee111/end4-pC`](https://github.com/Schnee111/end4-pC) (the Quickshell
configuration, installed at `~/.config/quickshell/end4-pC` and pinned in `lib/shells.sh`).
The shell's side of the contract, including which of its calls are guarded, is in that
repository's [`FORK.md`](https://github.com/Schnee111/end4-pC/blob/main/FORK.md). This page is
the host's side: what the shell expects to find here, and what must not change without
changing the shell too.

## What the shell calls

All paths are where the installer puts them under `$HOME`; they are symlinks into this
repository.

| Installed path | Source in this repo | Called by the shell | Interface |
|---|---|---|---|
| `~/.config/hypr/scripts/autostart.sh` | `rices/end4/hypr/scripts/autostart.sh` | `LockScreen.qml` after the first unlock, and `hl.exec_cmd` in `custom/execs.lua` 10 s after login if `qs` is not running | no arguments; guarded by `/tmp/hypr-autostart-<instance>.lock` so it runs once per login |
| `~/.config/hypr/scripts/layout_engine.py` | `rices/end4/hypr/scripts/layout_engine.py` | `SessionLayoutEditor.qml`, and `autostart.sh` | `--run` places the windows, `--capture` writes the current windows into the config, `--config <path>` overrides it |
| `~/.config/hypr/custom/session_layout.json` | `rices/end4/hypr/custom/session_layout.json` | read and written by `SessionLayoutEditor.qml` | a JSON list; each entry has `workspace`, `name`, `cmd`, `match`, `split`, `target`, `width`, `height`, `timeout` |
| `~/.config/hypr/scripts/restore_kitty_fonts.py` | `rices/end4/hypr/scripts/restore_kitty_fonts.py` | `scripts/colors/applycolor.sh`, in the background | no arguments; exits quietly when `hyprctl` or kitty is missing |
| `~/.config/hypr/scripts/apply_adaptive_glass.sh` | `rices/end4/hypr/scripts/apply_adaptive_glass.sh` | `scripts/colors/switchwall.sh`, in the background | `$1` is the wallpaper path; without a valid one it falls back to `~/.local/state/quickshell/user/generated/wallpaper/path.txt` |

The shell never checks a version. A change to any of these interfaces is a change to the
shell as well and needs a matching pull request there, merged first or together.

## What this repository calls in the shell

| Here | Calls |
|---|---|
| `rices/end4/hypr/scripts/apply_adaptive_glass.sh`, `opacity_toggle.sh` | `python3 ~/.config/quickshell/end4-pC/scripts/hyprland/hyprconfigurator.py --file <main.lua> --set <key> <value>` |
| `rices/end4/hypr/{custom,hyprland}/variables.lua`, `rices/end4/hypr/scripts/monitor_watcher.py` | the install directory name (`qsConfig=end4-pC`, `qs -c end4-pC`) |
| `lib/rices/end4.sh` | links `rices/end4/illogical-impulse/config.json` to `~/.config/illogical-impulse/config.json`, and checks out `END4PC_REV` |
| `lib/common.sh` (`kitty_theme_source`) | reads `~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf` |

## Things to know

- **The executable bit of `autostart.sh` is a switch.** The shell turns "session autostart"
  on and off with `chmod +x` / `chmod -x` on `~/.config/hypr/scripts/autostart.sh`. Because
  that path is a symlink into this repository, the change lands on the tracked file: the
  working tree shows a mode change, and committing it would turn autostart off for every new
  install (the file is `100755` in git).
- **Both `LockScreen.qml` and `custom/execs.lua` can start autostart**; the lock file is what
  keeps it to once per login.
- **Generated state is committed separately** from hand-written config (see "Config vs
  generated state" in the README); `illogical-impulse/config.json` is the shell's own state.
