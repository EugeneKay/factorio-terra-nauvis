-- Koppen biomes (0.4.0). A quantizer in front of the
-- three climate axes: four smooth fitted fields and the standard Koppen A/B/C/D/E cascade into the 14
-- shipped classes. The fields and the classifier (tn_koppen_class_v1) come first and reach no tile, tree
-- or decorative by themselves; the centroid snap below is what drives tiles, trees and decoratives.
--
-- The fields reuse the climate graph by name (new names only): annual mean temperature is the existing
-- core (climate.names.core) with the ridges highland field folded in (so Tibet, the Alps and
-- the Andes classify cold); the coldest- and warmest-month temperatures add and subtract a seasonality
-- amplitude that grows with latitude and continentality; the precipitation proxy is the existing
-- moisture mean plus the tile-belt moisture sum; the dry-season regime is a box field over the
-- Mediterranean and monsoon tile belts. Every threshold lives in config.lua climate.koppen (calibrated
-- in game), so this file holds no numeric literal but 0, 1 and 2, exactly as climate.lua does.
local cfg = require("prototypes.config")

local K = cfg.keys
local C = cfg.climate
local N = C.names
local KP = C.koppen
local MD = C.meander
local T = C.temperature
local M = C.moisture
local RN = cfg.ridges.names
local PPD = cfg.coordinates.px_per_degree

local function num(v)
  return string.format(cfg.number_format, v)
end

local E = {}
local function def(name, expression, locals)
  E[#E + 1] = {type = "noise-expression", name = name, expression = expression, local_expressions = locals}
end

-- The maps with a geography, in order, with their extents in degrees (climate.lua's MAPS, so the
-- per-map fold and the box overlaps match).
local MAPS = {}
for _, key in ipairs(cfg.map_order) do
  local g
  for _, v in ipairs({cfg.frames[key]}) do
    if v.geo_id == cfg.layer_chain_geo[key] then
      g = v
    end
  end
  if g then
    local m = cfg.maps[key]
    MAPS[#MAPS + 1] = {key = key, id = m.id,
                       lon = {m.lon_left_edge, m.lon_left_edge + m.width_px / PPD},
                       lat = {m.lat_top_edge - m.height_px / PPD, m.lat_top_edge}}
  end
end

-- One text per map, folded on the per-save map number (climate.lua by_map).
local function by_map(fn)
  local out = fn(MAPS[#MAPS])
  for i = #MAPS - 1, 1, -1 do
    out = "if(" .. K.map .. " == " .. num(MAPS[i].id) .. ", " .. fn(MAPS[i]) .. ", " .. out .. ")"
  end
  return out
end

local function ramp_in(v, lo, hi, r)
  return "clamp(min(" .. v .. " - " .. num(lo) .. ", " .. num(hi) .. " - " .. v .. ") / " .. num(r) .. ", 0, 1)"
end

local function overlaps(a, b)
  return a[1] < b[2] and b[1] < a[2]
end

-- Field 1: annual mean temperature. The existing core minus the highland fold: lapse_t at
-- full highland membership (tn_high_tile, 0..1, 0 off ridges), so mountain ranges classify cold.
def(KP.names.tann, N.core .. " - " .. num(KP.highland.lapse_t) .. " * " .. RN.high_tile)

-- Field 2: the seasonality amplitude. (amp0 + per_deg*|lat|) * (1 + continentality * cont_box), clamped,
-- where cont_box is the Eurasia-interior continental box of climate.temperature.continental, so
-- continental interiors swing colder in winter and hotter in summer.
local CT = T.continental
def(KP.names.season,
  "clamp((" .. num(KP.season.amp0) .. " + " .. num(KP.season.per_deg) .. " * abs(" .. N.lat .. ")) * (1 + " ..
    num(KP.season.continentality) .. " * cont), 0, " .. num(KP.season.max) .. ")",
  {cont = "clamp((" .. N.lon .. " - " .. num(CT.lon_start) .. ") / " .. num(CT.lon_span) .. ", 0, 1) * clamp((" ..
     N.lat .. " - " .. num(CT.lat_start) .. ") / " .. num(CT.lat_span) .. ", 0, 1)"})

-- Fields 3 and 4: coldest- and warmest-month temperature.
def(KP.names.tcold, KP.names.tann .. " - " .. KP.names.season)
def(KP.names.twarm, KP.names.tann .. " + " .. KP.names.season)

-- Field 5: the annual precipitation proxy. The moisture mean (reused from climate.moisture: base, the
-- equatorial bump, the dry-belt pull) plus the tile-belt moisture sum (CL_BELT_M), monotone in real
-- precipitation.
local function moisture_mean()
  return num(M.base) .. " + " .. num(M.equatorial) .. " * clamp((" .. num(M.equatorial_lat + M.equatorial_ramp) ..
    " - abs(" .. N.lat .. ")) / " .. num(M.equatorial_ramp) .. ", 0, 1) - " .. num(M.dry) .. " * " .. N.dry
end
def(KP.names.pann, "(" .. moisture_mean() .. ") + " .. N.belts.m)

-- Field 6: the dry-season regime s_w. The summer-dry Mediterranean boxes give +, the winter-dry monsoon
-- and savanna boxes give -, over the climate tile belts by id, on the meandering latitude and longitude
-- (the belt wander, so edges wander as climate.lua's belts do). s_w = clamp(sum(+) - sum(-), -1, 1).
local BW = C.tile_belts_wander
local BELT_AT = {belt_lat = N.lat .. " + " .. num(BW.lat) .. " * " .. MD.name,
                 belt_lon = N.lon .. " + " .. num(BW.lon) .. " * " .. MD.name}
local function belt_weight(b)
  return ramp_in("belt_lat", b.lat[1], b.lat[2], b.ramp[1]) .. " * " ..
    ramp_in("belt_lon", b.lon[1], b.lon[2], b.ramp[2])
end
local BY_ID = {}
for _, b in ipairs(C.tile_belts) do
  BY_ID[b.id] = b
end
local function regime_sum(ids, X)
  local parts = {}
  for _, id in ipairs(ids) do
    local b = BY_ID[id]
    if b and overlaps(b.lat, X.lat) and overlaps(b.lon, X.lon) then
      parts[#parts + 1] = belt_weight(b)
    end
  end
  return #parts == 0 and "0" or ("(" .. table.concat(parts, " + ") .. ")")
end
def(KP.names.sw, by_map(function(X)
  return "clamp(" .. regime_sum(KP.regime.summer_dry, X) .. " - " .. regime_sum(KP.regime.winter_dry, X) .. ", -1, 1)"
end), BELT_AT)

-- The classifier (tn_koppen_class_v1): the standard A/B/C/D/E cascade, first match wins, returning the
-- class id. The cascade temperatures wander by warp_t times the climate meander (no new noise call), so
-- class edges are not latitude lines. Pth is the aridity threshold in proxy units; the C/D
-- boundary is thresholds.cd_tcold. The polar split uses the annual mean (thresholds.ef_tann) because the
-- warmest-month proxy saturates near the pole (found in calibration).
local TH, CLS = KP.thresholds, KP.classes
local warp = num(KP.warp_t) .. " * " .. MD.name
local A = KP.aridity
local function cls(id)
  return num(id)
end
-- Pth and the regime term, built on the warped annual mean (local ta) and the regime (local sw).
local pth = "(" .. num(A.base) .. " + " .. num(A.per_t) .. " * ta + if(sw > " .. num(TH.sw_hi) .. ", " ..
  num(A.summer_dry) .. ", if(sw < " .. num(TH.sw_lo) .. ", " .. num(A.winter_dry) .. ", " .. num(A.neutral) .. ")))"
-- D branch: hot-summer Dfa, warm-summer Dfb, boreal Dfc, extreme Dfd.
local d_branch = "if(tw >= " .. num(TH.dfa_twarm) .. ", " .. cls(CLS.dfa) .. ", if(tw >= " .. num(TH.dfb_twarm) ..
  ", " .. cls(CLS.dfb) .. ", if(tc >= " .. num(TH.dfc_tcold) .. ", " .. cls(CLS.dfc) .. ", " .. cls(CLS.dfd) .. ")))"
-- C branch: Mediterranean Cs, humid-subtropical Cfa, oceanic Cfb.
local c_branch = "if(sw > " .. num(TH.cs_sw) .. ", " .. cls(CLS.cs) .. ", if(tw >= " .. num(TH.cfa_twarm) .. ", " ..
  cls(CLS.cfa) .. ", " .. cls(CLS.cfb) .. "))"
-- E branch: ice cap EF by the annual mean, else tundra ET.
local e_branch = "if(ta < " .. num(TH.ef_tann) .. ", " .. cls(CLS.ef) .. ", " .. cls(CLS.et) .. ")"
-- A branch: rainforest Af (wet and no strong dry season), else monsoon/savanna Am/Aw.
local a_branch = "if(pa >= " .. num(TH.af_pann) .. ", if(sw > " .. num(TH.af_sw) .. ", " .. cls(CLS.af) .. ", " ..
  cls(CLS.amaw) .. "), " .. cls(CLS.amaw) .. ")"
-- B branch: desert (BWh hot / BWk cold) below desert_frac * Pth, else steppe BS.
local b_branch = "if(pa < " .. num(A.desert_frac) .. " * " .. pth .. ", if(ta >= " .. num(TH.bwh_tann) .. ", " ..
  cls(CLS.bwh) .. ", " .. cls(CLS.bwk) .. "), " .. cls(CLS.bs) .. ")"
-- The cascade: B if arid, else A (tropical), else E (polar), else C (temperate), else D (continental).
local cascade = "if(pa < " .. pth .. ", " .. b_branch .. ", if(tc >= " .. num(TH.a_tcold) .. ", " .. a_branch ..
  ", if(tw < " .. num(TH.e_twarm) .. ", " .. e_branch .. ", if(tc >= " .. num(TH.cd_tcold) .. ", " .. c_branch ..
  ", " .. d_branch .. "))))"
def(KP.names.class, cascade, {
  ta = "(" .. KP.names.tann .. " + " .. warp .. ")",
  tc = "(" .. KP.names.tcold .. " + " .. warp .. ")",
  tw = "(" .. KP.names.twarm .. " + " .. warp .. ")",
  pa = KP.names.pann,
  sw = KP.names.sw,
})

-- The centroid snap. Three axis-snap bodies (plus a
-- vegetation-temperature snap) the preset points temperature/moisture/aux and the grain tile keys at
-- when Koppen is on. Each reads the warped classifier (class_v2) once via the local c (a named body is
-- evaluated once per program, so the three axes and the two programs share one class evaluation), picks
-- that class's centroid, blends it toward the continuous field so boundaries ramp, and adds
-- the existing per-axis spread (climate.lua's AB spreads, same seeds) so each class is a patchwork.
local AUX = C.aux
local SN = KP.snap
local CENT = KP.centroids
local BL = SN.blend

-- climate.lua's noise helper, byte for byte, so the spread reuses the released seeds and city shift.
local function knoise(P, freq)
  local scale = "1 / (" .. num(P.wavelength_px) .. " * " .. K.scale .. ")"
  if freq then
    scale = "(" .. freq .. ") / (" .. num(P.wavelength_px) .. " * " .. K.scale .. ")"
  end
  return num(P.amplitude) .. " * multioctave_noise{x = x, y = y, seed0 = map_seed, seed1 = " .. num(P.seed1) ..
    " + " .. N.shift .. ", octaves = " .. num(P.octaves) .. ", persistence = " .. num(P.persistence) ..
    ", input_scale = " .. scale .. ", output_scale = 1}"
end

-- The centroid of the tile's class on one axis, as a nested if over the class id (1..14) read from local c.
local function cent(axis)
  local out = num(CENT[#CENT][axis])
  for i = #CENT - 1, 1, -1 do
    out = "if(c == " .. num(i) .. ", " .. num(CENT[i][axis]) .. ", " .. out .. ")"
  end
  return "(" .. out .. ")"
end

-- The warped classifier (class_v2): the released v1 cascade with v1's warp plus the extra mid-wavelength
-- warp on the cascade temperatures, so class edges wander on a shorter wavelength and no edge runs straight.
local warp2 = num(SN.warp2.amplitude) .. " * multioctave_noise{x = x, y = y, seed0 = map_seed, seed1 = " ..
  num(SN.warp2.seed1) .. ", octaves = " .. num(SN.warp2.octaves) .. ", persistence = " ..
  num(SN.warp2.persistence) .. ", input_scale = 1 / (" .. num(SN.warp2.wavelength_px) .. " * " .. K.scale ..
  "), output_scale = 1}"
def(SN.names.class, cascade, {
  ta = "(" .. KP.names.tann .. " + " .. warp .. " + " .. warp2 .. ")",
  tc = "(" .. KP.names.tcold .. " + " .. warp .. " + " .. warp2 .. ")",
  tw = "(" .. KP.names.twarm .. " + " .. warp .. " + " .. warp2 .. ")",
  pa = KP.names.pann,
  sw = KP.names.sw,
})

-- The AB spreads (climate.lua): temperature on the averaged hot/cold frequency, moisture shrunk in the dry
-- belts, aux on its own frequency. The Tile-only temperature fray (grain noise layer) breaks razor edges.
local t_spread = knoise(T.noise, "(var('control:hot:frequency') + var('control:cold:frequency')) / 2")
local m_spread = "(1 - " .. num(M.spread.dry) .. " * " .. N.dry .. ") * " ..
  knoise(M.noise, "var('control:moisture:frequency')")
local a_spread = knoise(AUX.noise, "var('control:aux:frequency')")
local t_fray = num(SN.fray.amplitude) .. " * noise_layer_noise(" .. num(C.grain.layer) .. ")"

-- Temperature: centroid blended toward the annual mean (the field the class derived from, so the blend
-- interpolates neighbouring centroids at a boundary), the spread, and the razor-edge fray.
def(SN.names.t, "(1 - " .. num(BL.t) .. ") * " .. cent("t") .. " + " .. num(BL.t) .. " * " .. KP.names.tann ..
  " + " .. t_spread .. " + " .. t_fray, {c = SN.names.class})
-- Moisture: centroid blended toward the moisture mean plus the spread, clamped under the natural top.
def(SN.names.m, "clamp((1 - " .. num(BL.m) .. ") * " .. cent("m") .. " + " .. num(BL.m) .. " * (" ..
  moisture_mean() .. ") + " .. m_spread .. ", 0, " .. num(M.ab_top) .. ")", {c = SN.names.class})
-- Aux: centroid plus the spread, folded under the aux cap so no class reaches Alien Biomes' alien palette.
def(SN.names.a, "clamp(" .. cent("a") .. " + " .. a_spread .. ", 0, " .. num(AUX.ab_cap) .. ")", {c = SN.names.class})
-- The vegetation temperature caps strictly under veg_cap, so no spread can carry a class into orange grass.
def(SN.names.tv, "min(" .. SN.names.t .. ", " .. num(C.grain.veg_cap - SN.fray.veg_margin) .. ")")

-- The composition (config.lua climate.koppen.compose). Koppen is
-- the base biome layer; the overrides win where they apply, and each reads the released cold-north/zone/spawn
-- names so the drop's zone exemption (zone_drop, baked when a zone is on) and the clearing carry over with no
-- change to a released body. The Chaos/Corrupted/Moscow zone tile look is a tile-score overlay
-- (destroyed.lua/blue.lua) taken by max() in data-final-fixes: it wins inside its outline over the Koppen
-- tiles and fades to the Koppen base at its edge, so no new body is needed for it here (its trees are the
-- zone's own dead/excluded set). Scarcity is ore-only (resources.lua), orthogonal.
local CMP = KP.compose
-- the released drop (climate.north3.names.drop); a preset with a zone on redirects it to the zone drop, so
-- inside the Chaos heat ground the drop is 0 and the heat keeps its band under High snow.
local DROP = cfg.climate.north3.names.drop
local CLEAR = cfg.climate.north3.names.clear
local CLEAR_T = C.north2.clear.t

-- A per-class lift as a nested if over the class id (1..14), read through `var` (local c or the class body
-- name), defaulting 0 for an absent class.
local function perclass(tbl, var)
  local out = num(tbl[#CENT] or 0)
  for i = #CENT - 1, 1, -1 do
    out = "if(" .. var .. " == " .. num(i) .. ", " .. num(tbl[i] or 0) .. ", " .. out .. ")"
  end
  return "(" .. out .. ")"
end

-- The cooled base: the snap less the per-class cool (Frankfurt/oceanic greenness), so the oceanic, temperate
-- and boreal ground reads at the continuous climate's cooler temperature there - cool green grass, not the
-- warm dry grass the snap centroid gives. Read by the tile temperature only (the roles keep the plain snap
-- for the Entity budget); a cheap per-class offset on the snap, no new noise.
def(CMP.names.cool_t, SN.names.t .. " - " .. perclass(CMP.cool, SN.names.class))
-- Tile temperature: the cooled base lowered by the cold north's drop (so near the snow line the ground
-- deepens into cold grass/tundra/snow and the frozen tile still overrides north of it), and warmed to the
-- clearing floor at spawn (a playable cold-grass start; the frozen weight is cleared by the same clearing in
-- tiles.lua, so no spawn on snow). The grain tile key points here (the Alien Biomes ground reads the grain
-- key, not the role, via data-final-fixes grain_scores), so this Tile-only drop/clear composition stays off
-- the Entity program.
def(CMP.names.t, "kt + " .. CLEAR .. " * max(0, " .. num(CLEAR_T) .. " - kt)",
  {kt = CMP.names.cool_t .. " - " .. DROP})
-- The vegetation temperature caps strictly under veg_cap, as the snap's does, so the cooler north reads as
-- cold grass and no spread carries a class into orange grass.
def(CMP.names.tv, "min(" .. CMP.names.t .. ", " .. num(C.grain.veg_cap - SN.fray.veg_margin) .. ")")

-- Moisture: the snap (m_snap_v1's formula, untouched and frozen) plus a per-class green lift for the oceanic,
-- temperate and boreal classes (Frankfurt/oceanic greenness), clamped under ab_top so no forest ring. The
-- lift is the only change from v1.
def(CMP.names.m, "clamp((1 - " .. num(BL.m) .. ") * " .. cent("m") .. " + " .. num(BL.m) .. " * (" ..
  moisture_mean() .. ") + " .. m_spread .. " + " .. perclass(CMP.green, "c") .. ", 0, " .. num(M.ab_top) .. ")",
  {c = SN.names.class})

data:extend(E)
