-- created, after guards.on_init has detected it and built storage.earth.
--
--   - The resolved spawn city, read back with calculate_tile_properties at (0, 0): random folds in
--     float32, so Lua never recomputes it (seed 4294967295 gives a city the integer hash does
--     not). The city table is the one of the geography release the save names in tn_geo, resolved
--     through the release registry (guards.geography_of), never the newest.
--   - The start message, "Spawn city: <name>. World size: <W> x <H> tiles.", logged once and
--     set as freeplay's custom intro (after the intro freeplay would show), when that interface
--     exists.
--   - With RSO active, the RSO warning, stored through guards.record_warning, which logs it
--     once here and sends it to each created player (game.print in on_init reaches no player;
--
local cfg = require("prototypes.config")
local guards = require("scripts.guards")

local M = {}
local MSG = cfg.messages

local function message(key, ...)
  return {MSG.section .. "." .. MSG.keys[key], ...}
end

-- The city row of a resolved index (1 to n) of a spawn record's city setting, or nil.
local function city_row(map_key, sp, index)
  local setting = cfg.settings[sp.city_setting]
  local value = setting and setting.allowed_values[index + 1]
  local tbl = cities[map_key]
  return value and tbl and tbl.cities[value]
end

-- Freeplay's intro with the start message under it, keeping the intro freeplay (or a mod before
-- us) would show. Returns whether the interface took it.
local function intro(text)
  local fp = remote.interfaces["freeplay"]
  if not (fp and fp["set_custom_intro_message"] and fp["get_custom_intro_message"]) then
    return false
  end
  local before = remote.call("freeplay", "get_custom_intro_message")
  if before == nil then
    if script.active_mods["space-age"] then
      before = {"msg-intro-space-age"}
    else
      before = {"msg-intro"}
    end
  end
  remote.call("freeplay", "set_custom_intro_message", {"", before, "\n\n", text})
  return true
end

function M.on_init()
  local surface = game.surfaces["nauvis"]
    return
  end
  local earth = storage.earth
    end
  end
  local rso = script.active_mods["rso-mod"]
  if rso then
    guards.record_warning("rso", {rso})
  end
end

return M
