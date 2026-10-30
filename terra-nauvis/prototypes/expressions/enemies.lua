--
-- A second spot_noise built like vanilla's enemy_base_probability (base/prototypes/noise-
-- enemy_share of a hotspot footprint (each row of prototypes/tables/hotspots.lua, its disc the region
-- layer's row of the same id, read through its depth), quantity and favourability on land only
-- spawn, where vanilla's own start term keeps the start free too. Spot radius, quantity and
-- frequency read vanilla's enemy_base_radius and enemy_base_frequency by name, so bobenemies'
-- intensity cap applies to the layer as it does to the live expression. Outside its spots the
-- layer is -inf, so the wrapper data-final-fixes.lua builds, max(live, layer), equals the live
-- expression there to the bit. The per-map rows fold on tn_map (the wrapper is preset-only).
-- Every name and number comes from config.lua.
local cfg = require("prototypes.config")
local T = require("prototypes.tables.hotspots")

local HC = cfg.hotspots
local EN = cfg.enemies
local K = cfg.keys
local S = K.scale
local SUFFIX = cfg.regions.names.suffix
local DEPTH = cfg.regions.names.row.depth

local function num(v)
  return string.format(cfg.number_format, v)
end

local MAPS = {}
for _, key in ipairs(cfg.map_order) do
  if cfg.geography[key] then
    MAPS[#MAPS + 1] = {key = key, id = cfg.maps[key].id}
  end
end

local function footprint(r)
  return "min(max(" .. num(r.radius_px) .. " * " .. S .. ", " .. num(HC.floor_tiles) .. "), " .. num(r.cap_px) ..
    " * " .. S .. ")"
end

-- A candidate inside enemy_share of the row's footprint (the disc's roughened distance).
local function core(r)
  return "(" .. DEPTH .. r.id .. SUFFIX .. " > " .. num(r.radius_px) .. " * " .. S .. " - " .. num(HC.enemy_share) ..
    " * " .. footprint(r) .. ")"
end

local LAND = "(" .. K.land_coarse .. " > " .. num(HC.land_px) .. ")"

  local mults, cores = {}, {}
    local on = false
    for _, mk in ipairs(r.maps) do
      on = on or mk == map_key
    end
    if on and r.mult > 1 then
    end
  end
  if #cores == 0 then
    return nil
  end
  local any = "(" .. table.concat(cores, " + ") .. ")"
end

end

local E = {}
  for i = #branch - 1, 1, -1 do
  end
  E[#E + 1] = {
    type = "noise-expression",
    local_functions = {
      },
    },
  }
end

if #E > 0 then
  data:extend(E)
end
