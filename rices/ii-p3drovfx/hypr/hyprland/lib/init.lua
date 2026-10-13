HOME = os.getenv("HOME")

function is_file_exists(name)
   local f = io.open(name, "r")
   if f ~= nil then
      io.close(f)
      return true
   else
      return false
   end
end

function create_if_not_exists(path)
   if not is_file_exists(path) then
      os.execute("mkdir -p \"$(dirname \"" .. path .. "\")\"")
      os.execute("echo '-- This file will not be overwritten across dots-hyprland updates.\n-- The file name is for the sake of organization and does not matter\n-- See the corresponding files in ~/.config/hypr/hyprland for examples' > \"" .. path .. "\"")
      return true
   end
   return false
end

function workspace_in_group(i)
    local active_ws = hl.get_active_workspace()
    local curr = active_ws and active_ws.id or 1
    local newVal = math.floor((curr - 1) / workspaceGroupSize) * workspaceGroupSize + i
    -- hl.notification.create({ text = "curr " .. curr .. " floor " .. math.floor(curr / 10) .. " new " .. newVal, duration = 5000 })
    return newVal
end

function parse_workspace_map()
    local home_dir = os.getenv("HOME")
    local f = io.open(home_dir .. "/.config/illogical-impulse/config.json", "r")
    if not f then return false, {}, {} end
    local content = f:read("*all")
    f:close()

    local workspacesStart = content:find('"workspaces"%s*:%s*{')
    local useMap = false
    if workspacesStart then
        local matchStart = content:find('"useWorkspaceMap"', workspacesStart)
        if matchStart then
            local val = content:match('"useWorkspaceMap"%s*:%s*(%a+)', matchStart)
            if val == "true" then
                useMap = true
            end
        end
    end

    if not useMap then
        return false, {}, {}
    end

    local map = {}
    local mapStart = content:find('"workspaceMap"', workspacesStart)
    if mapStart then
        local startBr = content:find('{', mapStart)
        local endBr = content:find('}', startBr)
        if startBr and endBr then
            local mapStr = content:sub(startBr + 1, endBr - 1)
            for name, offset in string.gmatch(mapStr, '"([^"]+)"%s*:%s*([0-9]+)') do
                map[name] = tonumber(offset)
            end
        end
    end

    local monitors = hl.get_monitors() or {}
    local sorted_mons = {}
    for _, mon in ipairs(monitors) do
        local offset = map[mon.name] or (mon.id * 6)
        table.insert(sorted_mons, { name = mon.name, offset = offset })
    end
    table.sort(sorted_mons, function(a, b) return a.offset < b.offset end)

    return true, map, sorted_mons
end

function focus_workspace_and_monitor(W)
    local useMap, map, sorted_mons = parse_workspace_map()
    if not useMap then
        hl.dispatch(hl.dsp.focus({ workspace = tostring(W) }))
        return
    end

    -- Parse target workspace ID before any dispatch runs
    local target_ws = nil
    if type(W) == "number" then
        target_ws = W
    elseif type(W) == "string" then
        local active_ws = hl.get_active_workspace()
        local curr = active_ws and active_ws.id or 1
        if W:match("^r%+[0-9]+") or W:match("^%+[0-9]+") then
            local val = tonumber(W:match("[0-9]+"))
            target_ws = curr + val
        elseif W:match("^r%-[0-9]+") or W:match("^%-[0-9]+") then
            local val = tonumber(W:match("[0-9]+"))
            target_ws = curr - val
        else
            target_ws = tonumber(W)
        end
    end

    -- 1. Focus the workspace
    hl.dispatch(hl.dsp.focus({ workspace = tostring(W) }))

    if not target_ws then return end

    local target_mon = nil
    for i, mon in ipairs(sorted_mons) do
        local offset = mon.offset
        local next_offset = sorted_mons[i+1] and sorted_mons[i+1].offset or 99999
        if target_ws >= offset + 1 and target_ws < next_offset + 1 then
            target_mon = mon.name
            break
        end
    end

    if target_mon then
        local active_mon = hl.get_active_monitor()
        if active_mon and active_mon.name ~= target_mon then
            hl.dispatch(hl.dsp.focus({ monitor = target_mon }))
        end
    end
end

-- 3. Apply static workspace-to-monitor rules based on the workspaceMap
local useMap, map, sorted_mons = parse_workspace_map()
if useMap then
    for i, mon in ipairs(sorted_mons) do
        local offset = mon.offset
        local next_offset = sorted_mons[i+1] and sorted_mons[i+1].offset or (offset + 20)
        local limit = next_offset
        if limit > offset + 20 then
            limit = offset + 20
        end
        for ws = offset + 1, limit do
            local ws_name = tostring(ws)
            if hl.workspace_rule then
                hl.workspace_rule({ workspace = ws_name, monitor = mon.name })
            elseif hl.workspace then
                hl.workspace({
                    workspace = ws_name,
                    options = "monitor:" .. mon.name
                })
            else
                hl.config({
                    workspace = ws_name .. ",monitor:" .. mon.name
                })
            end
        end
    end
else
    -- If workspace map is disabled, clear any monitor workspace rules so workspaces can float freely
    for ws = 1, 100 do
        local ws_name = tostring(ws)
        if hl.workspace_rule then
            hl.workspace_rule({ workspace = ws_name, monitor = "" })
        elseif hl.workspace then
            hl.workspace({
                workspace = ws_name,
                options = "monitor:"
            })
        else
            hl.config({
                workspace = ws_name .. ",monitor:"
            })
        end
    end
end
