--
-- regions row fails one outside regions.lua). The zone is cut by the start disc around the spawn, which the
-- spawn shift keeps at the origin on every map, so every spawn city, the zone's included, starts on normal
-- ground with normal trees. Its heat climbs from a heat-1 rim to a core that mixes Alien Biomes' four
-- heat bands, and the Alien Biomes temperature's next version lifts the zone to it, so AB's
-- compiles climate-tiles' first temperature alone when off. Without Alien Biomes nothing here is
-- named by any preset: the toggle bakes off at the data stage and the presets keep the fallback climate,
-- so the world equals the zone off. Every body is analytic in x, y, map_seed and per-save
-- numbers: firewall-clean, as the region layer is, so the Entity program, where Alien Biomes' trees read
-- temperature, may read it. Every number comes from config.lua's destroyed group.
local cfg = require("prototypes.config")

local AB = mods["alien-biomes"] ~= nil

local D = cfg.destroyed
local N = D.names
local DEPTH = cfg.regions.names.destroyed_depth
local K = cfg.keys

local function num(v)
  return string.format(cfg.number_format, v)
end

local E = {}
local function def(name, expression, locals)
  E[#E + 1] = {type = "noise-expression", name = name, expression = expression, local_expressions = locals}
end

def(N.zone, "min(" .. DEPTH .. ", " .. D.start.distance .. " - max(" .. num(D.start.radius_tiles) ..

local H = D.heat
local NZ = H.noise

-- the zone's heat where it is hotter, with the toggle on. It reads AB's controls through the first
-- version, so it exists only with Alien Biomes, as that one does.
if AB then
  local T1 = cfg.climate.names.ab.temperature
  def(N.temperature, "if(" .. K.destroyed .. " > " .. num(D.switch_threshold) .. ", max(" .. T1 .. ", " .. N.heat ..
    "), " .. T1 .. ")")
end

data:extend(E)
