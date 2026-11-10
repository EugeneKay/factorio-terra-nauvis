-- The Middle East's sand desert (config.lua climate.desert; 1.0.0).
--
-- Rows of capsules in degrees give a depth, degrees inside the nearest edge, on a warped position. Inside it,
-- ground that is desert sand already reads as Alien Biomes' cream sand, the pale yellow sand with dark specks: the
-- tile temperature falls out of its tan band and the tile aux under its beige and brown, each read through an under
-- name the preset points at whatever the key held, so past the rows every reader meets the value it read before, bit
-- for bit. Cream sand lies inside the temperate band, where the band tests hold back Alien Biomes' ground, so the
-- band's own bodies take the weight too (tiles.lua): inside the rows the ground counts as a wild belt's.
--
-- Nothing else moves. The weight is none at a range (the highland's cap), on moist ground (the tile moisture past
-- the sand's box: grass, forest ground, marsh), on the temperate band's own ground, inside the keep rows and, in the
-- rows that carry them, inside the patches of old ground, so no snow, grey rim, marsh or grass changes and the
-- desert gains no new edge against green ground; the tile moisture and everything trees and decoratives read stay
-- as they were. Tile scores alone read these bodies. Everything here exists with Alien Biomes only, as the climate
-- bodies it wraps do; a world whose preset names none of it compiles none of it.
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

-- The patches of old ground (the flats): 1 inside, where a noise of their own passes the cut, its rim moved by mid
-- of a shared field, by rag of the ragged factor (12 to 384 tiles) and by fray of the grain's noise, so a patch has
-- no smooth side.
local F = D.flats
def(N.flats, fade("flat + " .. num(F.mid) .. " * " .. MIX[F.mix] .. " + " .. num(F.rag) .. " * (" .. C.ragged.name ..
  " - " .. num(C.ragged.mean) .. ") + " .. num(F.fray) .. " * " .. GRAIN, F.cut, F.cut + F.soft),
  {flat = px_noise(F, F.seed1)})

-- The coast line (config.lua climate.desert.coast): 1 east of it and past its ends, 0 west of it, on the plain
-- position. along(i) is the points' i-th value run piecewise linear in latitude: the line's longitude and its land
-- share, which takes each tile count (the shift east, the meander's two scales, the soft) from the sea's value to
-- the land's.
local CO = D.coast
local pts = CO.points
local LAT = CO.fields.lat
local function along(i)
  local run = {num(pts[1][i])}
  for j = 2, #pts do
    local a, b = pts[j - 1], pts[j]
    if b[i] ~= a[i] then
      run[#run + 1] = num((b[i] - a[i]) / (b[LAT] - a[LAT])) .. " * (clamp(c_lat, " .. num(a[LAT]) .. ", " ..
        num(b[LAT]) .. ") - " .. num(a[LAT]) .. ")"
    end
  end
  return table.concat(run, " + ")
end
local function tiles(key)
  return "((" .. num(CO[key]) .. " + " .. num(CO.land[key] - CO[key]) .. " * on_land) / (" .. num(PPD) .. " * " ..
    K.scale .. "))"
end
def(N.coast, "max(clamp((c_lon - axis - " .. tiles("shift_tiles") .. " + " .. tiles("mid_tiles") .. " * " ..
  MIX[CO.mix] .. " + " .. tiles("fray_tiles") .. " * " .. GRAIN .. ") / " .. tiles("soft_tiles") .. ", 0, 1), " ..
  "clamp((c_lat - " .. num(pts[#pts][LAT]) .. ") / " .. num(CO.taper) .. ", 0, 1), clamp((" .. num(pts[1][LAT]) ..
  " - c_lat) / " .. num(CO.taper) .. ", 0, 1))",
  {c_lat = C.names.lat .. " - " .. num(MD.degrees) .. " * " .. MD.name, c_lon = C.names.lon,
   axis = along(CO.fields.lon), on_land = along(CO.fields.land)})

-- The weight. edge moves the outline at two scales in tiles (a shared field's 24 to 768 tiles and the grain's 6 to
-- 48); wide lets the ramp swell and thin along the outline with the second warp. Then none west of the coast line,
-- none at a range (from the highland cap's cap.from down), none on moist ground and none inside a keep row.
local EG = D.edge
local CAP = cfg.ridges.names.cold2.cap
def(N.w, "max(clamp((" .. N.depth .. " + edge) / wide, 0, 1), clamp((" .. N.depth_flats ..
  " + edge) / wide, 0, 1) * " .. "(1 - " .. N.flats .. ")) * " .. N.coast .. " * " ..
  fade(CAP, D.cap.from, D.cap.full) .. " * (1 - " .. fade(C.grain.keys.moisture, D.dry.from, D.dry.full) ..
  ") * (1 - " .. fade(N.keep, 0, D.keep_ramp) .. ")",
  {edge = "(" .. num(EG.mid_tiles / PPD) .. " * " .. MIX[EG.mix] .. " + " .. num(EG.fray_tiles / PPD) .. " * " ..
     GRAIN .. ") / " .. K.scale,
   wide = num(D.ramp) .. " * clamp(1 + " .. num(EG.width_per_noise) .. " * " .. N.warp_b .. ", " ..
     num(EG.width_min) .. ", " .. num(EG.width_max) .. ")"})

-- The sand weight, which every tile body reads: the weight on Alien Biomes ground alone, judged on the temperature
-- under the desert (past the temperate band's top before any tile belt cooled it, or lifted out of the band by a wild
-- belt, by the band tests' own measure), none on the temperate band's own ground and none on cold ground (up to
-- ground.cold_from: snow, ice and the grey rim, whatever the cap reads beside them).
local T = D.tile
local G = D.ground
local WILD = C.tile_belts_wild
def(N.sand, N.w .. " * max(" .. fade("t_under - " .. C.names.belts.t, G.band_from, G.band_full) .. ", " ..
  fade(C.names.belts.wild .. " + " .. num(WILD.fine) .. " * " .. cfg.tiles.marsh.pool.name, WILD.cut,
    WILD.cut + G.wild_soft) .. ") * " .. fade("t_under", G.cold_from, G.cold_full), {t_under = T.temperature.under})

-- The tile bodies: each falls toward the cream sand's middle, only where it was above it. Each under name is what a
-- world reads if no preset points it, which never happens on a world that compiles these.
def(T.temperature.under, "0")
def(T.temperature.body, "u - " .. N.sand .. " * max(0, u - " .. num(D.t) .. ")", {u = T.temperature.under})
def(T.aux.under, "0")
def(T.aux.body, "u - " .. N.sand .. " * max(0, u - " .. num(D.a) .. ")", {u = T.aux.under})

data:extend(E)
