hl.env("PATH", (os.getenv("HOME") or "/home/schnee") .. "/.local/bin:" .. (os.getenv("PATH") or "/usr/local/bin:/usr/bin"))
hl.env("qsConfig", "end4-pC")

-- Override default app launcher commands
terminal = "kitty"

package.loaded["custom.variables"] = nil
