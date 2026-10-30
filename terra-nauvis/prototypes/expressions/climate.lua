--
-- Temperature, moisture and aux after EarthMaps' layout: latitude on each map's own chain (frozen in
-- the far north, cold from about 54 N, temperate, hot toward the tropics), Eurasia's continental cold
-- (Russia is cold), and the dry belts EarthMaps paints as sand (config.lua climate.dry_belts, from
-- the measured sand share), which run hot and dry. Each Earth preset redirects temperature, moisture
-- and aux to the Alien Biomes variant when alien-biomes is loaded, else to the fallback (presets.lua):
--   Alien Biomes  temperature in AB units with AB's hot and cold shift and frequency, moisture and aux
--                 with AB's 2.2 times bias; the marsh weight lifts moisture into the wet band;
--                 dry temperate land lifts aux toward vanilla red desert, inside the band where the
--                 exclusion hook keeps every non-adopted AB tile out (tiles.lua)
-- Every field is the Earth mean plus a seeded spread (config.lua climate: spread), so each real climate
-- zone is a patchwork of several tiles that changes with the seed; the caps and pulls move the mean
-- and bound the result, never the spread alone.
-- The latitude, longitude and dry weight fold on the per-save map number (only one map's branch
-- compiles), so these bodies are preset-only, like tn_map, which has no prototype. Nothing here reads
-- elevation or any firewall name: Alien Biomes' trees and the vanilla trees read the climate in the
-- Entity program (ARCHITECTURE.md, "Programs and the firewall"). The marsh weight is the region layer's
-- interface name (ARCHITECTURE.md, "Region layer"); the region formula lives in regions.lua alone.
-- Bodies that read Alien Biomes' hot and cold controls exist only with Alien Biomes, which defines them.
local cfg = require("prototypes.config")

local AB = mods["alien-biomes"] ~= nil

local K = cfg.keys
local C = cfg.climate
local N = C.names
local T = C.temperature
local M = C.moisture
local A = C.aux
local PPD = cfg.coordinates.px_per_degree
local MARSH_W = cfg.regions.names.marsh_w

local function num(v)
  return string.format(cfg.number_format, v)
end

local E = {}
local function def(name, expression, locals)
  E[#E + 1] = {type = "noise-expression", name = name, expression = expression, local_expressions = locals}
end

-- version keeps that frame (the same city offset under names of its own), so its preset worlds read
-- the same values here through the frozen offset fallbacks.
local MAPS = {}
for _, key in ipairs(cfg.map_order) do
  local g
    if v.geo_id == cfg.layer_chain_geo[key] then
      g = v
    end
  end
  if cfg.layer_chain_geo[key] and not g then
    error("config.lua layer_chain_geo names geography " .. tostring(cfg.layer_chain_geo[key]) .. ", which " .. key ..
      " does not have")
  end
  if g then
    local m = cfg.maps[key]
    MAPS[#MAPS + 1] = {key = key, id = m.id, g = g, m = m,
                       lon = {m.lon_left_edge, m.lon_left_edge + m.width_px / PPD},
                       lat = {m.lat_top_edge - m.height_px / PPD, m.lat_top_edge}}
  end
end

-- One text per map, folded on the per-save map number.
local function by_map(fn)
  local out = fn(MAPS[#MAPS])
  for i = #MAPS - 1, 1, -1 do
    out = "if(" .. K.map .. " == " .. num(MAPS[i].id) .. ", " .. fn(MAPS[i]) .. ", " .. out .. ")"
  end
  return out
end

-- A noise of wavelength_px reference pixels, its input scale times `freq` (a slider's frequency or 1).
local function noise(P, freq)
  local scale = "1 / (" .. num(P.wavelength_px) .. " * " .. K.scale .. ")"
  if freq then
    scale = "(" .. freq .. ") / (" .. num(P.wavelength_px) .. " * " .. K.scale .. ")"
  end
  return num(P.amplitude) .. " * multioctave_noise{x = x, y = y, seed0 = map_seed, seed1 = " .. num(P.seed1) ..
end

local function ramp_in(v, lo, hi, r)
  return "clamp(min(" .. v .. " - " .. num(lo) .. ", " .. num(hi) .. " - " .. v .. ") / " .. num(r) .. ", 0, 1)"
end

local function overlaps(a, b)
  return a[1] < b[2] and b[1] < a[2]
end

-- Latitude and longitude in degrees at the tile's reference pixel; the latitude meanders by one basis
-- noise octave, so climate fronts wander instead of running along rows.
local MD = C.meander
def(N.lat, by_map(function(X)
  return num(X.m.lat_top_edge) .. " - (" .. X.g.v .. " + " .. num(C.centre_px) .. ") / " .. num(PPD)
def(N.lon, by_map(function(X)
  return num(X.m.lon_left_edge) .. " + (" .. X.g.u .. " + " .. num(C.centre_px) .. ") / " .. num(PPD)
end))

-- The dry weight: the largest weight of the map's dry belts.
def(N.dry, by_map(function(X)
  local parts = {}
  for _, b in ipairs(C.dry_belts) do
    if overlaps(b.lat, X.lat) and overlaps(b.lon, X.lon) then
    end
  end
  if #parts == 0 then
    return "0"
  end
  if #parts == 1 then
    return parts[1]
  end
  return "max(" .. table.concat(parts, ", ") .. ")"

    end
  end
  if #parts == 0 then
    return "0"
  end
  end
  if #parts == 0 then
    return "0"
  end
-- The temperature core in Alien Biomes units, before noise and sliders.
local CT = T.continental
def(N.core, "clamp(" .. num(T.ref_t) .. " + " .. num(T.per_degree) .. " * (" .. num(T.ref_lat) .. " - abs(" ..
  N.lat .. ")), " .. num(T.min) .. ", " .. num(T.cap) .. ") - " .. num(CT.t) .. " * clamp((" .. N.lon .. " - " ..
  num(CT.lon_start) .. ") / " .. num(CT.lon_span) .. ", 0, 1) * clamp((" .. N.lat .. " - " .. num(CT.lat_start) ..
  ") / " .. num(CT.lat_span) .. ", 0, 1) + " .. num(T.desert_heat) .. " * " .. N.dry)

-- The Earth moisture mean before the spread, caps and biases: the base, wetter at the equator, dry in
-- the dry belts.
local function moisture_mean()
  return num(M.base) .. " + " .. num(M.equatorial) .. " * clamp((" .. num(M.equatorial_lat + M.equatorial_ramp) ..
    " - abs(" .. N.lat .. ")) / " .. num(M.equatorial_ramp) .. ", 0, 1) - " .. num(M.dry) .. " * " .. N.dry
end

-- The coldness, 0 at core cold.t and warmer, 1 at cold.t - cold.span and colder.
local COLD = "clamp((" .. num(C.cold.t) .. " - " .. N.core .. ") / " .. num(C.cold.span) .. ", 0, 1)"

-- The spread: the seeded patchwork inside every climate zone, added after the caps and pulls so they
-- never flatten it (config.lua climate: spread). The moisture spread shrinks in the dry belts (and on
-- the fallback in the cold), so deserts stay dry and the far north dry and dead ground.
local MFREQ = "var('control:moisture:frequency')"
local AFREQ = "var('control:aux:frequency')"
local function moisture_spread(cold)
  local w = "1 - " .. num(M.spread.dry) .. " * " .. N.dry
  if cold then
    w = w .. " - " .. num(M.spread.cold) .. " * cold"
  end
  return "(" .. w .. ") * " .. noise(M.noise, MFREQ)
end

-- The fallback, with no Alien Biomes control: the vanilla scale for temperature, the cold cap on the
-- moisture mean, the cold and dry pulls on the aux mean and the cold cap on aux.
local FB = T.fallback
local MF = M.fallback
  {mean = moisture_mean(), cold = COLD,
   cap = num(MF.cap_base) .. " + " .. num(MF.cap_per_t) .. " * clamp(" .. N.core .. " / " .. num(MF.cap_t) ..
local AF = A.fallback
def(N.fallback.aux, "clamp(min(" .. num(A.base) .. " + (" .. num(AF.cold_aux) .. " - " .. num(A.base) ..
  ") * cold - " .. num(AF.dry_pull) .. " * " .. N.dry .. " + " .. noise(A.noise, AFREQ) .. ", 1 - " ..
  num(1 - AF.cold_cap) .. " * cold) + " .. num(AF.bias) .. " * var('control:aux:bias'), 0, 1)",

if AB then
  -- Alien Biomes' hot and cold sliders: their size shifts the temperature as AB's own average does, their
  -- mean frequency scales the noise.
  local TA = T.ab
  def(N.ab.temperature, "clamp(" .. N.core .. " + " .. noise(T.noise, "(var('control:hot:frequency') + " ..
    "var('control:cold:frequency')) / 2") .. " + " .. num(TA.shift_per_unit) .. " * (var('control:hot:size') - " ..
    "var('control:cold:size')), " .. num(TA.min) .. ", " .. num(TA.max) .. ")")
  -- lifts toward vanilla red desert, a lift that is 0 wherever the AB temperature lies outside the
  -- exclusion band, so no alien AB colour can follow it.
  local R = A.red
end

data:extend(E)
