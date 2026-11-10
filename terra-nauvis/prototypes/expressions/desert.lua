--
-- Rows of capsules in degrees give a depth, degrees inside the nearest edge, on a warped position. Inside it,
--
-- Nothing else moves. The weight is none at a range (the highland's cap), on moist ground (the tile moisture past
-- the sand's box: grass, forest ground, marsh), on the temperate band's own ground, inside the keep rows and, in the
local cfg = require("prototypes.config")

if not mods["alien-biomes"] then
  return
end

local K = cfg.keys
local C = cfg.climate
local D = C.desert
local N = D.names
local MD = C.meander
local PPD = cfg.coordinates.px_per_degree

local function num(v)
  return string.format(cfg.number_format, v)
end

local E = {}
local function def(name, expression, locals)
  E[#E + 1] = {type = "noise-expression", name = name, expression = expression, local_expressions = locals}
end

-- A noise of octaves from wavelength_px reference pixels up, with the city shift the climate's noises take, so the
-- desert keeps its outline and its flats at every scale.
local function px_noise(P, seed1)
  return "multioctave_noise{x = x, y = y, seed0 = map_seed, seed1 = " .. num(seed1) .. " + " .. C.names.shift ..
    ", octaves = " .. num(P.octaves) .. ", persistence = " .. num(P.persistence) .. ", input_scale = 1 / (" ..
    num(P.wavelength_px) .. " * " .. K.scale .. "), output_scale = 1}"
end
local W = D.warp
def(N.warp_a, px_noise(W, W.seed1_a))
def(N.warp_b, px_noise(W, W.seed1_b))

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
  return "(" .. o_lat .. " * " .. o_lat .. " + " .. o_lon .. " * " .. o_lon .. ") ^ " .. num(D.root)
end

-- A depth: the largest r minus distance over the rows that pass `want`, on the climate's position without its
-- meander, moved by the warps when `warped`. The keep rows stand on the plain position: they guard real places.
local function depth_at(warped)
  local lat, lon = C.names.lat .. " - " .. num(MD.degrees) .. " * " .. MD.name, C.names.lon
  if warped then
    lat, lon = lat .. " + " .. num(W.degrees) .. " * " .. N.warp_a, lon .. " + " .. num(W.degrees) .. " * " .. N.warp_b
  end
  return {w_lat = lat, w_lon = lon}
end
local function depth(name, list, want, warped)
  local rows = {}
  for _, row in ipairs(list) do
    if want(row) then
      rows[#rows + 1] = num(row.r) .. " - " .. capsule(row, "w_lat", "w_lon")
    end
  end
  def(name, #rows == 1 and rows[1] or ("max(" .. table.concat(rows, ", ") .. ")"), depth_at(warped))
end
depth(N.depth, D.rows, function(row) return not row.flats end, true)
depth(N.depth_flats, D.rows, function(row) return row.flats end, true)
depth(N.keep, D.keep, function() return true end, false)

local function fade(value, from, full)
  return "clamp((" .. value .. " - " .. num(from) .. ") / " .. num(full - from) .. ", 0, 1)"
end
local GRAIN = "noise_layer_noise(" .. num(C.grain.layer) .. ")"

-- Two of the tile scores' shared noise fields (24 to 768 tiles, already in the Tile program): the mid scale of the
-- weight's edge and of the flats' rim.
local MIX = cfg.tiles.noise_share.fields

local F = D.flats
def(N.flats, fade("flat + " .. num(F.mid) .. " * " .. MIX[F.mix] .. " + " .. num(F.rag) .. " * (" .. C.ragged.name ..
  " - " .. num(C.ragged.mean) .. ") + " .. num(F.fray) .. " * " .. GRAIN, F.cut, F.cut + F.soft),
  {flat = px_noise(F, F.seed1)})

-- The weight. edge moves the outline at two scales in tiles (a shared field's 24 to 768 tiles and the grain's 6 to
local EG = D.edge
local CAP = cfg.ridges.names.cold2.cap
def(N.w, "max(clamp((" .. N.depth .. " + edge) / wide, 0, 1), clamp((" .. N.depth_flats ..
  {edge = "(" .. num(EG.mid_tiles / PPD) .. " * " .. MIX[EG.mix] .. " + " .. num(EG.fray_tiles / PPD) .. " * " ..
     GRAIN .. ") / " .. K.scale,
   wide = num(D.ramp) .. " * clamp(1 + " .. num(EG.width_per_noise) .. " * " .. N.warp_b .. ", " ..
     num(EG.width_min) .. ", " .. num(EG.width_max) .. ")"})

local T = D.tile
local G = D.ground
local WILD = C.tile_belts_wild
def(T.temperature.under, "0")
def(T.aux.under, "0")

data:extend(E)
