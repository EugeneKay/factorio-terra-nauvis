-- Patagonia and the Monte as dry steppe (config.lua climate.steppe; 1.0.0).
--
-- Rows of capsules in degrees give a depth, degrees inside the nearest edge, on a warped position. Inside it the
-- ground that was dune sand reads as a dry steppe of grass and bare dirt: the tile moisture rises to a target that
-- wanders between Alien Biomes' dirt and grass bands, the tile aux moves toward the brown and grey dirts, and the
-- grasses' own temperature rises to the olive and yellow grasses, each only where it was on the other side. Each body
-- reads what it wraps through an under name the preset points at whatever the key held, so past the rows every
-- reader meets the value it read before, bit for bit.
--
-- The weight is none at a range (the highland's cap), so no snow, grey rim or rim moisture moves. Tile scores alone
-- read the three tile bodies; the climate trees and decoratives read stays as it was. Alien Biomes' wetland and
-- grassland trees stand on grass and dirt but not on sand, so on the Patagonian rows the living trees' multiplier
-- thins where the ground is dry, and the steppe keeps about the few trees it had. Everything here exists with Alien
-- Biomes only, as the climate bodies it wraps do; a world whose preset names none of it compiles none of it.
local cfg = require("prototypes.config")

if not mods["alien-biomes"] then
  return
end

local K = cfg.keys
local C = cfg.climate
local S = C.steppe
local N = S.names
local MD = C.meander
local PPD = cfg.coordinates.px_per_degree

local function num(v)
  return string.format(cfg.number_format, v)
end

local E = {}
local function def(name, expression, locals)
  E[#E + 1] = {type = "noise-expression", name = name, expression = expression, local_expressions = locals}
end

-- A capsule's distance in degrees from (lat, lon), the names of two locals.
local function capsule(row, lat, lon)
  local a_lat, a_lon = row.from[1], row.from[2]
  local d_lat, d_lon = row.to[1] - a_lat, row.to[2] - a_lon
  local len2 = d_lat * d_lat + d_lon * d_lon
  local p_lat, p_lon = "(" .. lat .. " - " .. num(a_lat) .. ")", "(" .. lon .. " - " .. num(a_lon) .. ")"
  local t = "clamp((" .. p_lat .. " * " .. num(d_lat) .. " + " .. p_lon .. " * " .. num(d_lon) .. ") / " ..
    num(len2) .. ", 0, 1)"
  -- each offset times itself: a power of a negative base is not relied on
  local o_lat = "(" .. p_lat .. " - " .. num(d_lat) .. " * " .. t .. ")"
  local o_lon = "(" .. p_lon .. " - " .. num(d_lon) .. " * " .. t .. ")"
  return "(" .. o_lat .. " * " .. o_lat .. " + " .. o_lon .. " * " .. o_lon .. ") ^ " .. num(S.root)
end

local function fade(value, from, full)
  return "clamp((" .. value .. " - " .. num(from) .. ") / " .. num(full - from) .. ", 0, 1)"
end

-- The plain position: the climate's without its meander.
local PLAIN = {p_lat = C.names.lat .. " - " .. num(MD.degrees) .. " * " .. MD.name, p_lon = C.names.lon}

-- East of the crest: none at crest.from degrees east of the crest's longitude, full at crest.full, the longitude
-- linear in latitude between the points and held past the first and the last, on the plain position.
local function east_of_crest()
  local P = S.crest.points
  local terms = {num(P[1][2])}
  for i = 1, #P - 1 do
    local t0, t1 = -P[i][1], -P[i + 1][1]
    local slope = (P[i + 1][2] - P[i][2]) / (t1 - t0)
    terms[#terms + 1] = num(slope) .. " * (clamp(-p_lat, " .. num(t0) .. ", " .. num(t1) .. ") - " .. num(t0) .. ")"
  end
  return fade("p_lon - (" .. table.concat(terms, " + ") .. ")", S.crest.from, S.crest.full)
end

-- The depth: the largest r minus distance over the rows, on the plain position moved by the warps.
local W = S.warp
local rows = {}
for _, row in ipairs(S.rows) do
  rows[#rows + 1] = num(row.r) .. " - " .. capsule(row, "w_lat", "w_lon")
end
def(N.depth, #rows == 1 and rows[1] or ("max(" .. table.concat(rows, ", ") .. ")"),
  {w_lat = C.names.lat .. " - " .. num(MD.degrees) .. " * " .. MD.name .. " + " .. num(W.degrees) .. " * " .. W.a,
   w_lon = C.names.lon .. " + " .. num(W.degrees) .. " * " .. W.b})

local GRAIN = "noise_layer_noise(" .. num(C.grain.layer) .. ")"
local MIX = cfg.tiles.noise_share.fields
local CAP = cfg.ridges.names.cold2.cap

-- The weight. edge moves the outline at two scales in tiles (a shared field's 24 to 768 tiles and the grain's 6 to
-- 48); wide lets the ramp swell and thin along the outline with the second warp. Then none at a range: the weight
-- falls with the highland cap from cap.full to none at cap.from, over the grey rim's top; and none west of the crest.
local EG = S.edge
def(N.w, "clamp((" .. N.depth .. " + edge) / wide, 0, 1) * " .. fade(CAP, S.cap.from, S.cap.full) .. " * " ..
  east_of_crest(),
  {edge = "(" .. num(EG.mid_tiles / PPD) .. " * " .. MIX[EG.mix] .. " + " .. num(EG.fray_tiles / PPD) .. " * " ..
     GRAIN .. ") / " .. K.scale,
   wide = num(S.ramp) .. " * clamp(1 + " .. num(EG.width_per_noise) .. " * " .. W.b .. ", " ..
     num(EG.width_min) .. ", " .. num(EG.width_max) .. ")",
   p_lat = PLAIN.p_lat, p_lon = PLAIN.p_lon})

-- The patches of grass and bare ground: a noise of octaves from wavelength_tiles up, in tiles at every scale, so the
-- steppe reads as a patchwork at player zoom.
local P = S.patch
def(N.patch, "multioctave_noise{x = x, y = y, seed0 = map_seed, seed1 = " .. num(P.seed1) .. " + " .. C.names.shift ..
  ", octaves = " .. num(P.octaves) .. ", persistence = " .. num(P.persistence) .. ", input_scale = " ..
  num(1 / P.wavelength_tiles) .. ", output_scale = 1}")

-- The tile bodies, each only toward its target and never past it. The moisture's target wanders with the patches
-- and the grain between the dirt and the grass; the aux's with a shared field round the brown and grey dirts' band;
-- the grasses' temperature rises to the olive grasses' floor, wandering with a second shared field, so cold ground
-- grows dry grass and not green, and warm ground keeps its yellow.
-- Each under name is what a world reads if no preset points it, which never happens on a world that compiles these.
local T = S.tile
local M, A, V = S.m, S.a, S.veg
def(T.moisture.under, "0")
def(T.moisture.body, "u + " .. N.w .. " * max(0, clamp(" .. num(M.mid) .. " + " .. num(M.amp) .. " * " .. N.patch ..
  " + " .. num(M.fine) .. " * " .. GRAIN .. ", " .. num(M.min) .. ", " .. num(M.max) .. ") - u)",
  {u = T.moisture.under})
-- The aux and the grasses' temperature move only on ground that was dry before (S.dry, on the moisture under).
local DRY = "(1 - " .. fade(T.moisture.under, S.dry.from, S.dry.full) .. ")"
def(T.aux.under, "0")
def(T.aux.body, "u + " .. N.w .. " * " .. DRY .. " * (clamp(" .. num(A.mid) .. " + " .. num(A.amp) .. " * " ..
  MIX[A.mix] .. ", " .. num(A.min) .. ", " .. num(A.max) .. ") - u)", {u = T.aux.under})
def(T.veg.under, "0")
def(T.veg.body, "u + " .. N.w .. " * " .. DRY .. " * max(0, clamp(" .. num(V.floor) .. " + " .. num(V.amp) .. " * " ..
  MIX[V.mix] .. ", " .. num(V.min) .. ", " .. num(V.max) .. ") - u)", {u = T.veg.under})

-- The trees: the reach over the rows marked thin, on the plain position (the Entity program reads it, so no tile
-- noise), and the living trees' multiplier thinned by it where the moisture trees read is dry.
local TR = S.trees
local thin = {}
for _, row in ipairs(S.rows) do
  if row.thin then
    thin[#thin + 1] = num(row.r) .. " - " .. capsule(row, "p_lat", "p_lon")
  end
end
def(TR.reach, "(" .. (#thin == 1 and thin[1] or ("max(" .. table.concat(thin, ", ") .. ")")) .. ") * " ..
  east_of_crest(), PLAIN)
def(TR.under, "1")
def(TR.body, "u * (1 - " .. num(TR.thin) .. " * " .. fade(TR.reach, 0, TR.ramp) .. " * (1 - " ..
  fade("moisture", TR.dry.from, TR.dry.full) .. "))", {u = TR.under})

data:extend(E)
