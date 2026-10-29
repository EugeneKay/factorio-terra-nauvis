-- Map-gen presets and the Map type fallbacks (ARCHITECTURE.md, "Preset redirects" and "Map type
-- entries"), built from config.lua.
--
-- Each Earth preset bakes every map-shaping value into basic_settings.property_expression_names, so
-- a save keeps its map for life whatever the startup settings say later: its map's elevation
-- entry, the start mask on the coarse land field, the coarse field itself, the numbers tn_map,
-- tn_scale, tn_geo and the map's city offset, and vanilla's three readers of the water slider at
-- their default-slider values, so the slider moves nothing on the preset (config.lua's
-- water_slider). From spawn-cities a version with a spawn record also bakes the distance redirect,
-- the map's city number and the spawn lake and bias keys, and its city offset names name the city
--
-- A Map type pick sets only elevation, so every other per-save name a geography version's entry
-- reads gets a prototype-level fallback valued as that version's preset bakes it under the current
--
local cfg = require("prototypes.config")

local K = cfg.keys

local function num(v)
  return string.format(cfg.number_format, v)
end

local function geography(map_key)
  local g = cfg.geography[map_key]
  end
end

local scale = tonumber(settings.startup[cfg.settings.scale.name].value)

-- The per-save city number a spawn-city setting stands for: its value's position in the setting's
-- allowed values, less one, so random (the first) is 0 and the first city 1.
local function city_number(setting_key)
  local s = cfg.settings[setting_key]
  local value = settings.startup[s.name].value
  for i, v in ipairs(s.allowed_values) do
    if v == value then
      return i - 1
    end
  end
  error("the setting " .. s.name .. " holds " .. tostring(value) .. ", which config.lua does not list")
end

-- The property_expression_names one geography version's preset bakes under the current startup
-- settings (tools/tnconfig.py baked_names mirrors it). A version with a spawn record also bakes the
-- distance redirect (vanilla's starting ore and enemy-free start follow the spawn through it),
local function baked(map_key, v)
  local names = {
    [K.start_mask] = v.start_mask,
    [K.land_coarse] = v.land_coarse,
    [K.map] = cfg.maps[map_key].id,
    [K.scale] = scale,
    [K.geo] = v.geo_id,
    [v.cx] = v.city_offset[1],
    [v.cy] = v.city_offset[2],
  }
  for _, w in ipairs(cfg.water_slider) do
    names[w.key] = w.value
  end
  local sp = v.spawn
  if sp then
    names[K.distance] = sp.distance
    names[sp.city] = city_number(sp.city_setting)
    names[K.spawn_lake] = sp.spawn_lake
    names[K.spawn_bias] = sp.spawn_bias
  end
  return names
end

local function withheld(p)
  for _, m in ipairs(p.withheld_with or {}) do
    if mods[m] then
      return true
    end
  end
  return false
end

local presets = data.raw["map-gen-presets"]["default"]

for _, key in ipairs(cfg.preset_order) do
  local p = cfg.presets[key]
  if not withheld(p) then
    presets[p.name] = {
      order = p.order,
    }
  end
end

-- The fallbacks of every geography version: one prototype per name, valued as every version that
local fallbacks, seen = {}, {}
for _, key in ipairs(cfg.map_order) do
  local g = cfg.geography[key]
  for _, v in ipairs(g and g.versions or {}) do
    local names = baked(key, v)
    for _, f in ipairs(v.fallbacks) do
      local value = names[f.name]
      if value == nil then
        error("the Map type fallback " .. f.name .. " of " .. v.entry .. " has no value in its version's preset")
      end
      if seen[f.name] == nil then
        seen[f.name] = value
      elseif seen[f.name] ~= value then
        error("the Map type fallback " .. f.name .. " differs between versions or maps: one fallback holds one value")
      end
    end
  end
end
data:extend(fallbacks)
