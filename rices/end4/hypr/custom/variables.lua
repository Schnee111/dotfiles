local home = os.getenv("HOME")
if home then
    hl.env("PATH", home .. "/.local/bin:" .. (os.getenv("PATH") or "/usr/local/bin:/usr/bin"))
end
hl.env("qsConfig", "end4-pC")

-- Override default app launcher commands
terminal = "kitty"

package.loaded["custom.variables"] = nil
