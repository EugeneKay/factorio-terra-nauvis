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
--     engine places no cliffs at all, whatever the cliff expressions say, and the starting area is
--     generated before on_init. So on an Earth world with ridges on, a size of 0 is written back as
--     reset_size (config.lua ridges) with a whole-table assignment, once, logged in one line: the
--     preview and the starting chunks keep none, and every chunk generated from then on gets its
--     active, the warning that the world has no zone, stored through guards.record_warning like the RSO
--     warning. The preset baked the zone off for lack of Alien Biomes, so the save
--     cannot tell an asked-for zone from none: this one check reads the startup setting, which on_init
--     reads as the world was created with. With the zone on and the spawn city at random, the save's city
--     number names the map's random pool, which counts as random (0) here.
--
local cfg = require("prototypes.config")
local cities = require("prototypes.city_tables")
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

-- The cliff "none" reset; returns true when it wrote the control back.
local function reset_cliffs(earth, surface)
  local mgs = surface.map_gen_settings
  local pen = mgs.property_expression_names or {}
  local sw = cfg.toggles.ridges
  if pen[sw.preset_key] ~= sw.on then
    return false
  end
  local control = mgs.cliff_settings and mgs.cliff_settings.control
  local controls = mgs.autoplace_controls or {}
  local c = control and controls[control]
  if not (c and c.size == 0) then
    return false
  end
  c.size = cfg.ridges.reset_size
  controls[control] = c
  mgs.autoplace_controls = controls
  surface.map_gen_settings = mgs
  earth.cliff_reset = true
  log(message("cliff_reset", control, cfg.ridges.reset_size))
  return true
end

function M.on_init()
  local surface = game.surfaces["nauvis"]
    return
  end
  local earth = storage.earth
    end
    end
  end
  local rso = script.active_mods["rso-mod"]
  if rso then
    guards.record_warning("rso", {rso})
  end
  end
end

return M
