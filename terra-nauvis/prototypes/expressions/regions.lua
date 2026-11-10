-- The region layer (ARCHITECTURE.md, "Region layer").
--
-- Every row of prototypes/tables/regions.lua becomes three named expressions, in reference pixels of
-- the region frame (config.lua regions.frame):
--   row.sd .. id .. suffix      the signed distance to the row's shape, positive inside, at the query
--                               point moved by the row's share of the shared warp, plus the shared
--                               edge roughness (a hotspot row takes none: its disc is exact)
--   row.w .. id .. suffix       the membership weight clamp(mid + sd / width, 0, 1), the soft edge
--   row.depth .. id .. suffix   the same signed distance in tiles
-- and a hotspot row also row.pd .. id .. suffix, the plain distance to its jittered centre in reference pixels.
-- A marsh row's signed distance also reads the marsh outline noise and its weight a wider ramp (config.lua
-- regions.marsh), so no marsh shows its exact disc or path.
-- A hotspot row's disc sits at its adopted centre moved per seed by up to its jitter radius (a
-- linear fold of map_seed: constants only, so it folds the same on every peer); row.hu and row.hv
-- name that centre. The destroyed zone's polygon moves each vertex by the same fold (seeded_polygon).
-- Each layer's rows on a map make the layer's aggregates, the interface consumers
-- read (names in config.lua regions.names):
--   destroyed_sd, _w, _depth          min(max(include sd), -exclude sd, ...): exclusion rows (warp 0)
--                                     keep protected features out of the zone whatever the warp does
--   forest_w, forest_sum, tree_mult   the largest forest weight; the sum of boost times weight;
--                                     1 + forest_boost * forest_sum
--   marsh_w                           the largest marsh weight
--   hotspot_w, enemy_mult             the largest hotspot weight; 1 + the sum of (mult - 1) * weight
--
-- The query point is each map's own coordinate chain moved into the region frame by the map's
-- whole-pixel offset, so every row sits at its geography on every map and at every scale. The warp
-- and the roughness are anchored to the same frame: each octave is a basis_noise whose offsets make it
-- read the frame's reference pixels, so a seed's soft edges are one field in geography, the same on
-- every map, at every scale and for every spawn city. The octaves are built one by one because
-- 2.1.23's multioctave_noise offsets do not shift its input as basis_noise's do (measured in this
-- layer); the weights are multioctave_noise's own (the coarsest 1, each finer persistence times the
-- last, over their root sum of squares). The per-save map number picks the map's chain, offsets and
-- rows, so each choice folds to one map's (an if() on a folded number, never a per-tile
-- condition). The layer reads only x, y, map_seed and per-save constants through the chain, so it is
-- firewall-clean (ARCHITECTURE.md, "Programs and the firewall") and the Entity program may read it.
-- With no consumer nothing here compiles (unreferenced expressions are free). tn_map has no prototype:
-- consumers are preset-only.
--
-- One named expression per quantity (a copy under another name costs about +646): every
-- consumer reads these names, and the static regions row fails any region formula outside this file.
local cfg = require("prototypes.config")
local T = require("prototypes.tables.regions")
local T2 = require("prototypes.tables.hotspots_v2")
local T3 = require("prototypes.tables.hotspots_v3")
local TR2 = require("prototypes.tables.regions_v2")
local TC = require("prototypes.tables.zone_outline")
local TC2 = require("prototypes.tables.zone_outline_v2")
local TB = require("prototypes.tables.zone_blue")
local TB2 = require("prototypes.tables.zone_blue_v2")
local TM = require("prototypes.tables.zone_moscow")

local R = cfg.regions
local N = R.names
local K = cfg.keys
local SUF = N.suffix
local W = R.warp
local RO = R.rough
local JT = R.jitter

local function num(v)
  return string.format(cfg.number_format, v)
end

local E = {}
local function def(name, expression, locals)
  E[#E + 1] = {type = "noise-expression", name = name, expression = expression, local_expressions = locals}
end

-- name minus a constant, and name plus one, spelled without a double sign
local function minus(name, c)
  if c == 0 then
    return name
  end
  if c < 0 then
    return name .. " + " .. num(-c)
  end
  return name .. " - " .. num(c)
end
local function plus(name, c)
  return minus(name, -c)
end

-- The region frame and each map's whole-pixel offset into it (u_frame = u_map + du).
local F = cfg.maps[R.frame]
local PPD = cfg.coordinates.px_per_degree

local function whole(v, what)
  local r = math.floor(v + 1 / 2)
  if math.abs(v - r) > R.frame_tolerance_px then
    error(cfg.identity.title .. " regions: " .. what .. " is not a whole pixel from " .. R.frame .. "'s raster")
  end
  return r
end

local MAPS = {}
for _, key in ipairs(cfg.map_order) do
  -- the frame of the geography release config.lua's layer_chain_geo names for the map (config.lua frames), the
  -- chain the layer was registered against; every later version keeps that frame (the same city offset under names
  -- of its own), so its preset worlds read the same values here through the frozen offset fallbacks
  local g
  for _, v in ipairs({cfg.frames[key]}) do
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
                       du = whole((m.lon_left_edge - F.lon_left_edge) * PPD, key .. " u"),
                       dv = whole((F.lat_top_edge - m.lat_top_edge) * PPD, key .. " v")}
  end
end

local function to_px(lat, lon)
  return (lon - F.lon_left_edge) * PPD - 1 / 2, (F.lat_top_edge - lat) * PPD - 1 / 2
end

-- One text per map, folded on the per-save map number: if(map == id1, t1, if(map == id2, t2, t3)).
-- A text the same on every map needs no fold.
local function by_map(fn)
  local texts, same = {}, true
  for i, M in ipairs(MAPS) do
    texts[i] = fn(M)
    same = same and texts[i] == texts[1]
  end
  if same then
    return texts[1]
  end
  local out = texts[#texts]
  for i = #texts - 1, 1, -1 do
    out = "if(" .. K.map .. " == " .. num(MAPS[i].id) .. ", " .. texts[i] .. ", " .. out .. ")"
  end
  return out
end

local function joined(fn, parts, empty)
  if #parts == 0 then
    return empty
  end
  if #parts == 1 then
    return parts[1]
  end
  if #parts > R.max_arguments then
    error(cfg.identity.title .. " regions: " .. fn .. " over " .. #parts .. " rows exceeds the noise language's limit")
  end
  return fn .. "(" .. table.concat(parts, ", ") .. ")"
end

-- The query point: the map's chain moved into the frame (unwarped).
local QU, QV = N.u .. SUF, N.v .. SUF
def(QU, by_map(function(M) return plus(M.g.u, M.du) end))
def(QV, by_map(function(M) return plus(M.g.v, M.dv) end))

-- The noise anchor: offsets that make a noise read the frame's reference pixels, (u - frame wr) at the
-- frame map's own origin, whatever the map, the scale and the spawn city. The noise calls keep x = x,
-- y = y with the shift in offset_x and offset_y; these fold to constants per save.
local corner = "floor(" .. K.scale .. " / " .. num(cfg.coordinates.corner_offset_divisor) .. ")"
local function anchor(c_name, radius, frame_radius, d)
  local k = radius + d - frame_radius
  local text = c_name .. " - " .. corner
  if k > 0 then
    text = text .. " + " .. K.scale .. " * " .. num(k)
  elseif k < 0 then
    text = text .. " - " .. K.scale .. " * " .. num(-k)
  end
  return text
end
def(N.ox, by_map(function(M) return anchor(M.g.cx, M.m.wr, F.wr, M.du) end))
def(N.oy, by_map(function(M) return anchor(M.g.cy, M.m.hr, F.hr, M.dv) end))

-- One octave: basis noise at wavelength_px times 2^k reference pixels, shifted along x by its index
-- times octave_shift_px so the octaves of one seed1 never share a lattice zero.
local function octave(seed1, P, k, j)
  local ox = N.ox
  if j > 0 then
    ox = ox .. " + " .. K.scale .. " * " .. num(j * R.octave_shift_px)
  end
  return "basis_noise{x = x, y = y, seed0 = map_seed, seed1 = " .. num(seed1) .. ", input_scale = 1 / (" ..
    num(P.wavelength_px * 2 ^ k) .. " * " .. K.scale .. "), output_scale = 1, offset_x = " .. ox .. ", offset_y = " ..
    N.oy .. "}"
end

-- The layer's multi-octave noise from its octaves: the coarsest first at weight 1, each finer persistence
-- times the last, normalized by the root sum of the squared weights (multioctave_noise's weights).
local function noise(seed1, P)
  local parts, norm = {}, 0
  for j = 0, P.octaves - 1 do
    local w = P.persistence ^ j
    norm = norm + w * w
    parts[#parts + 1] = num(w) .. " * " .. octave(seed1, P, P.octaves - 1 - j, j)
  end
  return "(" .. table.concat(parts, " + ") .. ") / " .. num(math.sqrt(norm))
end

-- The shared warp: two noises, the displacement vector clamped to clamp_px in length, so a row's
-- edge moves at most its share of clamp_px plus the roughness clamp from its shape (27 px with the shipped values).
def(N.ax, num(W.amplitude_px) .. " * " .. noise(W.seed1_x, W))
def(N.ay, num(W.amplitude_px) .. " * " .. noise(W.seed1_y, W))
def(N.wk, num(W.clamp_px) .. " / max(" .. num(W.clamp_px) .. ", sqrt(" .. N.ax .. " * " .. N.ax .. " + " .. N.ay ..
  " * " .. N.ay .. "))")
def(N.wx, N.ax .. " * " .. N.wk)
def(N.wy, N.ay .. " * " .. N.wk)
-- The shared edge roughness, added to every signed distance.
def(N.rough, "clamp(" .. num(RO.amplitude_px) .. " * " .. noise(RO.seed1, RO) .. ", " .. num(-RO.clamp_px) .. ", " ..
  num(RO.clamp_px) .. ")")

-- The query point for a warp share: unwarped at 0, the full warp at 1, a share of it between.
local made = {}
local function query(share)
  local h = math.floor(share * R.share_hundredths + 1 / 2)
  if h == 0 then
    return QU, QV
  end
  local u, v = N.u .. N.share .. h .. SUF, N.v .. N.share .. h .. SUF
  if not made[h] then
    made[h] = true
    if h == R.share_hundredths then
      def(u, QU .. " + " .. N.wx)
      def(v, QV .. " + " .. N.wy)
    else
      def(u, QU .. " + " .. num(share) .. " * " .. N.wx)
      def(v, QV .. " + " .. num(share) .. " * " .. N.wy)
    end
  end
  return u, v
end

-- A hotspot's centre coordinate: base + (2 * frac(seed fold + phase) - 1) * reach, where the reach is
-- the jitter radius over sqrt(2), so the jitter box stays inside the jitter radius.
local function jittered(base, mult, phase, reach)
  return num(base) .. " + (2 * ((map_seed_small * " .. num(mult) .. " + floor(map_seed_normalized * " ..
    num(JT.high_bits) .. ") * " .. num(JT.mult_high) .. " + " .. num(phase) .. ") % 1) - 1) * " .. num(reach)
end

-- The signed distance of a shape at (qu, qv), with its locals. A disc's centre is a number, or the
-- name of a hotspot's jittered centre.
local function from(q, c)
  if type(c) == "number" then
    return minus(q, c)
  end
  return q .. " - " .. c
end

local function disc(cu, cv, r, qu, qv)
  return num(r) .. " - sqrt(du * du + dv * dv)", {du = from(qu, cu), dv = from(qv, cv)}
end

local function lines(pts, qu, qv, closed)
  local L, d2s, cross, n = {}, {}, {}, #pts
  for i = 1, closed and n or n - 1 do
    local a, b = pts[i], pts[i % n + 1]
    local ex, ey = b[1] - a[1], b[2] - a[2]
    local s = tostring(i)
    L["du" .. s] = minus(qu, a[1])
    L["dv" .. s] = minus(qv, a[2])
    L["t" .. s] = "clamp((du" .. s .. " * " .. num(ex) .. " + dv" .. s .. " * " .. num(ey) .. ") * " ..
      num(1 / (ex * ex + ey * ey)) .. ", 0, 1)"
    L["qx" .. s] = "du" .. s .. " - t" .. s .. " * " .. num(ex)
    L["qy" .. s] = "dv" .. s .. " - t" .. s .. " * " .. num(ey)
    d2s[#d2s + 1] = "qx" .. s .. " * qx" .. s .. " + qy" .. s .. " * qy" .. s
    if closed and ey ~= 0 then
      -- the edge straddles the point's row and crosses it to the right (the crossing number)
      cross[#cross + 1] = "((" .. qv .. " < " .. num(a[2]) .. ") != (" .. qv .. " < " .. num(b[2]) .. ")) * (" ..
        qu .. " < " .. num(a[1]) .. " + dv" .. s .. " * " .. num(ex / ey) .. ")"
    end
  end
  L.d2 = joined("min", d2s, nil)
  return L, cross
end

local function polygon(pts, qu, qv)
  local L, cross = lines(pts, qu, qv, true)
  L.inside = "(" .. table.concat(cross, " + ") .. ") % 2"
  return "(2 * inside - 1) * sqrt(d2)", L
end

-- A polygon whose every vertex moves per seed by up to its own jitter radius: polygon()'s formulas with the
-- vertices and edges as locals, which are constants per save and fold, so the program costs what a fixed
-- polygon of as many vertices costs. Each vertex has its own multipliers, so a seed moves the vertices
-- independently. An edge whose two ends land on one row has no crossing, so its slope is never read.
local function seeded_polygon(pts, r, qu, qv)
  local L, d2s, cross, n = {}, {}, {}, #pts
  for i, p in ipairs(pts) do
    local s = tostring(i)
    local reach = r.vertex_jitter_km[i] / R.km_per_px / math.sqrt(2)
    local step = i * JT.vertex_step
    L["au" .. s] = jittered(p[1], (JT.mult_x + step) % 1, r.vertex_phase[i], reach)
    L["av" .. s] = jittered(p[2], (JT.mult_y + step) % 1, r.vertex_phase[i], reach)
  end
  for i = 1, n do
    local s, e = tostring(i), tostring(i % n + 1)
    local ex, ey = "ex" .. s, "ey" .. s
    L[ex] = "au" .. e .. " - au" .. s
    L[ey] = "av" .. e .. " - av" .. s
    L["du" .. s] = qu .. " - au" .. s
    L["dv" .. s] = qv .. " - av" .. s
    L["t" .. s] = "clamp((du" .. s .. " * " .. ex .. " + dv" .. s .. " * " .. ey .. ") / (" .. ex .. " * " .. ex ..
      " + " .. ey .. " * " .. ey .. "), 0, 1)"
    L["qx" .. s] = "du" .. s .. " - t" .. s .. " * " .. ex
    L["qy" .. s] = "dv" .. s .. " - t" .. s .. " * " .. ey
    L["sl" .. s] = "if(abs(" .. ey .. ") < " .. num(JT.flat_px) .. ", 0, " .. ex .. " / " .. ey .. ")"
    d2s[#d2s + 1] = "qx" .. s .. " * qx" .. s .. " + qy" .. s .. " * qy" .. s
    cross[#cross + 1] = "((" .. qv .. " < av" .. s .. ") != (" .. qv .. " < av" .. e .. ")) * (" .. qu .. " < au" ..
      s .. " + dv" .. s .. " * sl" .. s .. ")"
  end
  L.d2 = joined("min", d2s, nil)
  L.inside = "(" .. table.concat(cross, " + ") .. ") % 2"
  return "(2 * inside - 1) * sqrt(d2)", L
end

local function path(pts, r, qu, qv)
  local L = lines(pts, qu, qv, false)
  return num(r) .. " - sqrt(d2)", L
end

local function row_names(r)
  local rn = N.row
  return {sd = rn.sd .. r.id .. SUF, w = rn.w .. r.id .. SUF, depth = rn.depth .. r.id .. SUF,
          hu = rn.hu .. r.id .. SUF, hv = rn.hv .. r.id .. SUF, pd = rn.pd .. r.id .. SUF}
end

local function weight(sd_name, width_px)
  return "clamp(" .. num(R.ramp.mid) .. " + " .. sd_name .. " / " .. num(width_px or R.ramp.width_px) .. ", 0, 1)"
end

-- A marsh's own edge (config.lua regions.marsh): the one outline noise every marsh row reads at its
-- own amplitude, and the row's wider ramp, both from the row's radius in reference pixels.
local MH = R.marsh
def(N.marsh_rough, noise(MH.seed1, MH))

local function marsh_edge(r)
  local radius = r.radius_km / R.km_per_px
  local ramp = math.min(MH.ramp_cap_px, MH.ramp_share * radius)
  return math.min(MH.cap_px, MH.share * radius), math.max(R.ramp.width_px, ramp)
end

-- A marsh row's gain on the shared roughness (config.lua regions.marsh.edge_gain), folded on the map.
local function marsh_gain(r)
  local G = MH.edge_gain
  local gain = math.min(G.top, math.max(MH.rough_gain, G.share * r.radius_km / R.km_per_px))
  return by_map(function(M) return num(G.maps[M.key] and gain or MH.rough_gain) end)
end

-- A row's signed distance, weight and depth (and a hotspot's jittered centre).
local function row_bodies(r, bare)
  local nm = row_names(r)
  local qu, qv = query(r.warp)
  local text, L
  if r.shape == "disc" then
    local cu, cv = to_px(r.lat, r.lon)
    if r.layer == "hotspot" then
      local reach = r.jitter_km * JT.hotspot_share / R.km_per_px / math.sqrt(2)
      def(nm.hu, jittered(cu, JT.mult_x, r.phase, reach))
      def(nm.hv, jittered(cv, JT.mult_y, r.phase, reach))
      text, L = disc(nm.hu, nm.hv, r.radius_km / R.km_per_px, qu, qv)
      -- the plain distance to the jittered centre, in reference pixels, for the hard footprint (resources.lua)
      def(nm.pd, "sqrt(du * du + dv * dv)", {du = L.du, dv = L.dv})
    else
      text, L = disc(cu, cv, r.radius_km / R.km_per_px, qu, qv)
    end
  else
    local pts = {}
    for i, ll in ipairs(r.latlon) do
      local u, v = to_px(ll[1], ll[2])
      pts[i] = {u, v}
    end
    if r.vertex_jitter_km then
      text, L = seeded_polygon(pts, r, qu, qv)
    elseif r.shape == "polygon" then
      text, L = polygon(pts, qu, qv)
    else
      text, L = path(pts, r.radius_km / R.km_per_px, qu, qv)
    end
  end
  if r.layer == "marsh" then
    local amplitude, width = marsh_edge(r)
    def(nm.sd, "(" .. text .. ") + (" .. marsh_gain(r) .. ") * " .. N.rough .. " + " .. num(amplitude) .. " * (" ..
      N.marsh_rough .. " + " .. num(MH.bias) .. ")", L)
    def(nm.w, weight(nm.sd, width))
  else
    -- a hotspot's disc stays exact: its footprint is a hard limit on its ore (config.lua hotspots.size), so
    -- its signed distance takes no roughness, and the ore inside shapes the outline
    def(nm.sd, r.layer == "hotspot" and text or ("(" .. text .. ") + " .. N.rough), L)
    if not bare then
      def(nm.w, weight(nm.sd))
    end
  end
  def(nm.depth, nm.sd .. " * " .. K.scale)
  return nm
end

local ROWS = {}
for _, r in ipairs(T.rows) do
  ROWS[#ROWS + 1] = {row = r, names = row_bodies(r)}
end
-- The rows only the second hotspot table holds: their bodies, less the weight no aggregate of theirs reads, since
-- this layer's aggregates are released bodies and take no row. prototypes/expressions/hotspots_v2.lua reads them.
for _, r in ipairs(T2.rows) do
  row_bodies(r, true)
end
-- The third hotspot table's rows (0.3.1), the same way: the moved discs under new ids.
for _, r in ipairs(T3.rows) do
  row_bodies(r, true)
end

-- The second region table (config.lua regions_v2): its rows' bodies, and with the first table's rows the list its
-- aggregates sum.
local ROWS2 = {}
for _, x in ipairs(ROWS) do
  ROWS2[#ROWS2 + 1] = x
end
for _, r in ipairs(TR2.rows) do
  ROWS2[#ROWS2 + 1] = {row = r, names = row_bodies(r)}
end

-- A map's rows of a layer (and of a destroyed mode), from the first table or the list given.
local function on_map(M, layer, mode, rows)
  local out = {}
  for _, x in ipairs(rows or ROWS) do
    local r = x.row
    if r.layer == layer and (mode == nil or (r.mode or "include") == mode) then
      for _, mk in ipairs(r.maps) do
        if mk == M.key then
          out[#out + 1] = x
          break
        end
      end
    end
  end
  return out
end

local function each(list, fn)
  local out = {}
  for _, x in ipairs(list) do
    out[#out + 1] = fn(x)
  end
  return out
end

-- The destroyed zone.
def(N.destroyed_sd, by_map(function(M)
  local inc = joined("max", each(on_map(M, "destroyed", "include"), function(x) return x.names.sd end), "-inf")
  local parts = {inc}
  for _, x in ipairs(on_map(M, "destroyed", "exclude")) do
    parts[#parts + 1] = "-" .. x.names.sd
  end
  return joined("min", parts, inc)
end))
def(N.destroyed_w, weight(N.destroyed_sd))
def(N.destroyed_depth, N.destroyed_sd .. " * " .. K.scale)

-- The outline a world made after the first release reads (config.lua destroyed.outline): seeded_polygon's formulas,
-- with land edges and sea edges in two bodies, so the barrier can measure from the land edges alone. The presence
-- stops at the isles line and the keep rows; the depth ignores the isles line, which lies on water, and is squeezed
-- by the whole outline, so a sea edge that lands on an island still frays. A vertex's locals repeat per body, and
-- each folds per save. OT is the table, O the names it builds: the first release's, then 0.3.0's next outline
-- (prototypes/tables/zone_outline_v2.lua), which adds the fixed cuts.
-- A later presence and depth over the same outline (NP): every term the same, but a land cut NP.cuts names opens where
-- its function says, so the zone may cross the cut's line there.
local function next_outline(NP, present, opened, depth, deep)
  local parts, dparts = {}, {}
  for i, t in ipairs(present) do
    parts[i] = opened[i] or t
  end
  for i, t in ipairs(depth) do
    dparts[i] = deep[i] or t
  end
  def(NP.present, joined("min", parts))
  def(NP.depth, joined("min", dparts))
end

local function outline(OT, O, NP)
  local Q = cfg.destroyed.outline
  local verts = OT.vertices
  local n = #verts
  local qu, qv = query(OT.warp)

  local function vertex(L, i)
    local v, s = verts[i], tostring(i)
    local u, w = to_px(v.lat, v.lon)
    local reach = v.jitter_km / R.km_per_px / math.sqrt(2)
    local step = i * JT.vertex_step
    L["au" .. s] = jittered(u, (JT.mult_x + step) % 1, v.phase, reach)
    L["av" .. s] = jittered(w, (JT.mult_y + step) % 1, v.phase, reach)
  end

  local function edge(L, i)
    local j = i % n + 1
    vertex(L, i)
    vertex(L, j)
    local s, e = tostring(i), tostring(j)
    L["ex" .. s] = "au" .. e .. " - au" .. s
    L["ey" .. s] = "av" .. e .. " - av" .. s
    L["du" .. s] = qu .. " - au" .. s
    L["dv" .. s] = qv .. " - av" .. s
    return s, e
  end

  local function nearest(name, land)
    local L, d2s = {}, {}
    for i, v in ipairs(verts) do
      if (v.land == true) == land then
        local s = edge(L, i)
        local ex, ey = "ex" .. s, "ey" .. s
        L["t" .. s] = "clamp((du" .. s .. " * " .. ex .. " + dv" .. s .. " * " .. ey .. ") / (" .. ex .. " * " .. ex ..
          " + " .. ey .. " * " .. ey .. "), 0, 1)"
        L["qx" .. s] = "du" .. s .. " - t" .. s .. " * " .. ex
        L["qy" .. s] = "dv" .. s .. " - t" .. s .. " * " .. ey
        d2s[#d2s + 1] = "qx" .. s .. " * qx" .. s .. " + qy" .. s .. " * qy" .. s
      end
    end
    def(name, joined("min", d2s, nil), L)
  end
  nearest(O.land, true)
  nearest(O.sea, false)

  local L, cross = {}, {}
  for i = 1, n do
    local s, e = edge(L, i)
    L["sl" .. s] = "if(abs(ey" .. s .. ") < " .. num(JT.flat_px) .. ", 0, ex" .. s .. " / ey" .. s .. ")"
    cross[#cross + 1] = "((" .. qv .. " < av" .. s .. ") != (" .. qv .. " < av" .. e .. ")) * (" .. qu .. " < au" ..
      s .. " + dv" .. s .. " * sl" .. s .. ")"
  end
  def(O.inside, "(" .. table.concat(cross, " + ") .. ") % 2", L)

  local sign = "(2 * " .. O.inside .. " - 1)"
  def(O.sd, sign .. " * sqrt(min(" .. O.land .. ", " .. O.sea .. ")) + " .. N.rough)

  if type(OT.isles) == "table" then
    local pts = {}
    for i, ll in ipairs(OT.isles) do
      local u, v = to_px(ll[1], ll[2])
      pts[i] = {u, v}
    end
    local text, isles = polygon(pts, QU, QV)
    def(O.isles, text, isles)
  end

  local present, opened, deep = {O.sd}, {}, {}
  if O.isles then
    present[2] = "-" .. O.isles
  end
  local function fray(FR, per_tile)
    -- in tiles: size tiles, but never more than cap reference pixels (at scale 1 a tile is a reference pixel)
    return (per_tile and ("min(" .. num(FR.cap) .. ", " .. num(FR.size) .. " / " .. K.scale .. ")") or num(FR.size)) ..
      " * multioctave_noise{x = x, y = y, seed0 = map_seed, seed1 = " .. num(FR.seed1) .. ", octaves = " ..
      num(FR.octaves) .. ", persistence = " .. num(FR.persistence) .. ", input_scale = 1 / " ..
      (per_tile and num(FR.wavelength) or ("(" .. num(FR.wavelength) .. " * " .. K.scale .. ")")) ..
      ", output_scale = 1}"
  end
  if OT.version >= 2 then
    -- The next outline's presence frays its contour where the wasteland reaches it (destroyed.outline.edge_fray), in
    -- reference pixels and in tiles: the shared roughness alone is a smooth curve there, which the tile grid turns into
    -- long straight runs.
    local EF = Q.edge_fray
    present[1] = O.sd .. " + " .. fray(EF.px) .. " + " .. fray(EF.tiles, true)
  end
  local depth = {sign .. " * sqrt(" .. O.land .. ") + " .. N.rough, num(Q.squeeze) .. " * " .. O.sd}
  for _, id in ipairs(OT.land_keeps or {}) do
    local keep = "-" .. N.row.sd .. id .. SUF
    present[#present + 1] = keep
    depth[#depth + 1] = keep
  end
  -- The fixed cuts (zone_outline_v2.lua). A sea cut reads as far inside or far outside at once, from its crossing
  -- count alone, as a Blue sea shape does; a land cut is a keep: its signed distance with the shared roughness.
  local function cut_points(list)
    local cpts = {}
    for i, ll in ipairs(list) do
      local u, v = to_px(ll[1], ll[2])
      cpts[i] = {u, v}
    end
    return cpts
  end
  for _, c in ipairs(OT.cuts or {}) do
    local name = O.cuts[c.id]
    if c.land then
      -- one polygon per map when the cut lists maps: each map's locals take the map's key as a prefix
      local cl = {}
      local function one(list, prefix)
        local text, PL = polygon(cut_points(list), QU, QV)
        for k, v in pairs(PL) do
          cl[prefix .. k] = v:gsub("%f[%w_](%a+%d*)%f[^%w_]", function(w)
            return PL[w] and prefix .. w or w
          end)
        end
        return (text:gsub("%f[%w_](%a+%d*)%f[^%w_]", function(w) return PL[w] and prefix .. w or w end))
      end
      local ctext
      if c.maps then
        ctext = by_map(function(M) return one(c.maps[M.key], M.key .. "_") end)
      else
        ctext = one(c.latlon, "")
      end
      def(name, "(" .. ctext .. ") + " .. N.rough, cl)
      depth[#depth + 1] = "-" .. name .. (c.depth_px and (" + " .. num(c.depth_px)) or "")
      present[#present + 1] = "-" .. name .. " + " .. fray(Q.cut_fray, true)
      if NP and NP.cuts[c.id] then
        opened[#present] = NP.cuts[c.id](name) .. " + " .. fray(Q.cut_fray, true)
        deep[#depth] = NP.cuts[c.id](name) .. " + " .. num(NP.depth_add)
      end
    else
      local cpts = cut_points(c.latlon)
      local SL, scross = lines(cpts, QU, QV, true)
      local text = num(Q.cut_px) .. " * (2 * ((" .. table.concat(scross, " + ") .. ") % 2) - 1)"
      local keep = {}
      for i in text:gmatch("dv(%d+)") do
        keep["dv" .. i] = SL["dv" .. i]
      end
      def(name, text, keep)
      present[#present + 1] = "-" .. name
    end
  end
  def(O.present, joined("min", present))
  def(O.depth, joined("min", depth))
  if NP then
    next_outline(NP, present, opened, depth, deep)
  end
end
outline(TC, cfg.destroyed.outline.names)
-- 0.3.1 (destroyed.dev.pyrenees): the next outline's presence and depth with the Iberia cut moved strip_px into Spain,
-- under the Pyrenees' snow: the zone then reaches the massif's snow, and the devastation field yields to the snow
-- there (destroyed.lua). The depth's cut term starts at the field's own start_px, so where no snow stands the field's
-- edge stands on the moved cut.
local DV = cfg.destroyed.dev
local PY = DV.pyrenees
outline(TC2, cfg.destroyed.outline.next, {present = DV.names.present, depth = DV.names.depth, depth_add = DV.start_px,
                                          cuts = {iberia = function(name)
  return num(PY.strip_px) .. " - " .. name
end}})

-- 0.3.1: the Moscow zone's outline (config.lua moscow; prototypes/tables/zone_moscow.lua), the same formulas: no isles
-- line, keep rows or cuts.
outline(TM, cfg.moscow.outline.names)

-- The shapes of Blue corrupted (config.lua blue; prototypes/tables/zone_blue.lua). A sea shape needs its crossing
-- count alone, so it costs a fraction of a distance to every edge, and a map skips the shapes it does not hold. BT is
-- the table, O the names it builds: the first release's, then 0.3.1's next outline
-- (prototypes/tables/zone_blue_v2.lua), which holds the United Kingdom alone.
local function blue_outline(BT, O)
  local big = num(cfg.blue.outline.inside_px)

  local function holds(shape, M)
    for _, key in ipairs(shape.maps) do
      if key == M.key then
        return true
      end
    end
    return false
  end

  local function crossings(pts, qu, qv)
    local L, cross = {}, {}
    local n = #pts
    for i, a in ipairs(pts) do
      local b, s = pts[i % n + 1], tostring(i)
      if b[2] ~= a[2] then
        L["dv" .. s] = minus(qv, a[2])
        cross[#cross + 1] = "((" .. qv .. " < " .. num(a[2]) .. ") != (" .. qv .. " < " .. num(b[2]) .. ")) * (" ..
          qu .. " < " .. num(a[1]) .. " + dv" .. s .. " * " .. num((b[1] - a[1]) / (b[2] - a[2])) .. ")"
      end
    end
    return "(" .. table.concat(cross, " + ") .. ") % 2", L
  end

  local function pixels(shape)
    local pts = {}
    for i, ll in ipairs(shape) do
      local u, v = to_px(ll[1], ll[2])
      pts[i] = {u, v}
    end
    return pts
  end

  local function sea_shape(name, shape)
    local text, L = crossings(pixels(shape), QU, QV)
    def(name, text, L)
  end
  sea_shape(O.britain, BT.britain)
  if BT.australia then
    sea_shape(O.australia, BT.australia)
  end
  def(O.sea, by_map(function(M)
    local parts = {}
    if holds(BT.britain, M) then
      parts[#parts + 1] = O.britain
    end
    if BT.australia and holds(BT.australia, M) then
      parts[#parts + 1] = O.australia
    end
    return joined("max", parts, "0")
  end))

  local U = BT.ulster
  local pts = {}
  for i, v in ipairs(U.vertices) do
    local a, b = to_px(v.lat, v.lon)
    pts[i] = {a, b, land = v.land}
  end
  local qu, qv = query(U.warp)
  local text, inside = crossings(pts, qu, qv)
  def(O.ulster, text, inside)
  local L, d2s = {}, {}
  local n = #pts
  for i, a in ipairs(pts) do
    if a.land then
      local b, s = pts[i % n + 1], tostring(i)
      local ex, ey = b[1] - a[1], b[2] - a[2]
      L["du" .. s] = minus(qu, a[1])
      L["dv" .. s] = minus(qv, a[2])
      L["t" .. s] = "clamp((du" .. s .. " * " .. num(ex) .. " + dv" .. s .. " * " .. num(ey) .. ") * " ..
        num(1 / (ex * ex + ey * ey)) .. ", 0, 1)"
      L["qx" .. s] = "du" .. s .. " - t" .. s .. " * " .. num(ex)
      L["qy" .. s] = "dv" .. s .. " - t" .. s .. " * " .. num(ey)
      d2s[#d2s + 1] = "qx" .. s .. " * qx" .. s .. " + qy" .. s .. " * qy" .. s
    end
  end
  def(O.land, joined("min", d2s, nil), L)
  -- A sea shape reads as far inside or far outside at once, and only the border has a depth to speak of.
  def(O.depth, "max((2 * " .. O.ulster .. " - 1) * sqrt(" .. O.land .. ") + " .. N.rough .. ", " .. big .. " * (2 * " ..
    O.sea .. " - 1))")
end
blue_outline(TB, cfg.blue.outline.names)
blue_outline(TB2, cfg.blue.outline.next)

-- Great forests.
local function boosted(x)
  if x.row.boost == 1 then
    return x.names.w
  end
  return num(x.row.boost) .. " * " .. x.names.w
end
def(N.forest_w, by_map(function(M) return joined("max", each(on_map(M, "forest"), function(x) return x.names.w end),
  "0") end))
def(N.forest_sum, by_map(function(M)
  local terms = each(on_map(M, "forest"), boosted)
  return #terms > 0 and table.concat(terms, " + ") or "0"
end))
def(N.tree_mult, "1 + " .. num(R.forest_boost) .. " * " .. N.forest_sum)

-- Marshes.
def(N.marsh_w, by_map(function(M) return joined("max", each(on_map(M, "marsh"), function(x) return x.names.w end),
  "0") end))

-- 0.3.0: the forest and marsh aggregates over both tables (config.lua regions_v2), the first versions' formulas.
local NR2 = cfg.regions_v2.names
def(NR2.forest_w, by_map(function(M)
  return joined("max", each(on_map(M, "forest", nil, ROWS2), function(x) return x.names.w end), "0")
end))
def(NR2.forest_sum, by_map(function(M)
  local terms = each(on_map(M, "forest", nil, ROWS2), boosted)
  return #terms > 0 and table.concat(terms, " + ") or "0"
end))
def(NR2.marsh_w, by_map(function(M)
  return joined("max", each(on_map(M, "marsh", nil, ROWS2), function(x) return x.names.w end), "0")
end))

-- 1.0.0: the great forests' ground weight (config.lua trees.ground): the weight ramp on the largest forest signed
-- distance over both tables, each row's moved by its own share of the marsh outline noise and of the warp's second
-- noise, plus more of the shared roughness: all noise this layer computes already. A row's size is its radius, or
-- for a polygon the radius of the disc of its area. It exists with Alien Biomes alone, as its readers do (trees.lua).
if mods["alien-biomes"] then
  local FG = cfg.trees.ground
  local EG = FG.edge
  local function row_radius(r)
    if r.radius_km then
      return r.radius_km / R.km_per_px
    end
    local area, n = 0, #r.latlon
    for i = 1, n do
      local a, b = r.latlon[i], r.latlon[i % n + 1]
      local au, av = to_px(a[1], a[2])
      local bu, bv = to_px(b[1], b[2])
      area = area + au * bv - bu * av
    end
    return math.sqrt(math.abs(area) / 2 / math.pi)
  end
  local function moved(x)
    local radius = row_radius(x.row)
    local near = math.min(EG.cap_px, EG.share * radius)
    local wide = math.min(EG.wide_cap_px, EG.wide_share * radius)
    if x.row.shape == "disc" then
      -- a disc stands in for a real outline, so it takes more of the wide noise, and no cap
      wide = EG.disc_wide_share * radius
    end
    return x.names.sd .. " + " .. num(near) .. " * " .. N.marsh_rough .. " + " .. num(wide / W.amplitude_px) ..
      " * " .. N.ay .. " + " .. num(near * EG.bias)
  end
  def(FG.w, "clamp(" .. num(R.ramp.mid) .. " + (" .. by_map(function(M)
    return joined("max", each(on_map(M, "forest", nil, ROWS2), moved), "-inf")
  end) .. " + " .. num(EG.rough) .. " * " .. N.rough .. ") / " .. num(FG.ramp_px) .. ", 0, 1)")
end

-- The highland's noise (ridges.lua), in reference pixels, all of it noise this layer already computes: the fray
-- rocks read, the one tile scores read, and the massif factor, which breaks a long even crest.
local HF, GM, CF = cfg.ridges.high, cfg.ridges.ground.massif, cfg.ridges.cold
def(N.highland_fray, num(HF.fray_warp) .. " * " .. N.wx)
def(N.highland_fray_tile, num(HF.fray_warp) .. " * " .. N.wx .. " + " .. num(HF.fray_rough) .. " * " .. N.rough ..
  " + " .. num(HF.fray_massif) .. " * " .. N.marsh_rough)
def(N.highland_cold, num(CF.fray_warp) .. " * " .. N.wx .. " + " .. num(CF.massif) .. " * " .. N.wy .. " + " ..
  num(CF.fray_marsh) .. " * " .. N.marsh_rough .. " + " .. num(CF.fray_rough) .. " * min(1, " .. K.scale .. " / " ..
  num(CF.fit_scale) .. ") * " .. N.rough)
def(N.highland_massif, "clamp(1 + " .. num(GM.gain) .. " * " .. N.wy .. ", " .. num(GM.low) .. ", " .. num(GM.high) ..
  ")")

-- Hotspot regions and the biter multiplier inside them.
def(N.hotspot_w, by_map(function(M) return joined("max", each(on_map(M, "hotspot"), function(x) return x.names.w end),
  "0") end))
def(N.enemy_mult, by_map(function(M)
  local terms = each(on_map(M, "hotspot"), function(x) return num(x.row.mult - 1) .. " * " .. x.names.w end)
  return "1" .. (#terms > 0 and (" + " .. table.concat(terms, " + ")) or "")
end))

-- 1.0.0: the river deltas (config.lua regions_v3; prototypes/tables/regions_v3.lua). A marsh row takes the first
-- table's bodies; the third marsh aggregate is the largest marsh weight over the three tables and the delta weight
-- the largest over this table's.
local TR3 = require("prototypes.tables.regions_v3")
local NR3, CH = cfg.regions_v3.names, cfg.regions_v3.channel
local ROWS3, DELTAS, CHANNELS = {}, {}, {}
for _, x in ipairs(ROWS2) do
  ROWS3[#ROWS3 + 1] = x
end
for _, r in ipairs(TR3.rows) do
  if r.layer == "channel" then
    CHANNELS[#CHANNELS + 1] = r
  else
    local x = {row = r, names = row_bodies(r)}
    ROWS3[#ROWS3 + 1] = x
    DELTAS[#DELTAS + 1] = x
  end
end
def(NR3.marsh_w, by_map(function(M)
  return joined("max", each(on_map(M, "marsh", nil, ROWS3), function(x) return x.names.w end), "0")
end))
def(NR3.delta_w, by_map(function(M)
  return joined("max", each(on_map(M, "marsh", nil, DELTAS), function(x) return x.names.w end), "0")
end))

-- The channels. A noise fixed in tiles on the region anchor, so the same ground reads the same value from every
-- spawn; the query point, in reference pixels; and the bank, a channel's half-width factor. All three are bodies of
-- their own: every segment reads the point, and the game copies a local at every read.
local function tile_noise(seed1, wavelength)
  return "basis_noise{x = x, y = y, seed0 = map_seed, seed1 = " .. num(seed1) .. ", input_scale = 1 / (" ..
    num(wavelength[1]) .. " + " .. num(wavelength[2]) .. " * " .. K.scale .. "), output_scale = 1, offset_x = " ..
    N.ox .. ", offset_y = " .. N.oy .. "}"
end
local function channel_warp(axis)
  local parts = {}
  for _, o in ipairs(CH.warp) do
    parts[#parts + 1] = "(" .. num(o.amplitude[1]) .. " + " .. num(o.amplitude[2]) .. " * " .. K.scale .. ") * " ..
      tile_noise(o["seed1" .. axis], o.wavelength)
  end
  return "(" .. table.concat(parts, " + ") .. ") / " .. K.scale
end
-- The point a map's rivers read (waterways.lua's warp bodies X and Y of the map's geography version with a river warp
-- of its own, by name, picked by the folded scale as that version's entry picks its sets), moved into the region
-- frame: a channel bends with the river it leaves, so the two stay joined at every seed, scale and spawn. A map with
-- no such version reads the plain point. A version's warp names run X, Y, XP, YP per scale, as waterways.lua
-- lists them.
local RIVER_PARTS = {"X", "Y", "XP", "YP"}
local function river_point(M, k, plain, radius, d)
  local g
  for _, v in ipairs(cfg.geography[M.key].versions) do
    if v.warp and not v.map_type_of then
      g = v
    end
  end
  if not g then
    return plain
  end
  local values = g.scales or cfg.scales.released
  local text = g.warp[(#values - 1) * #RIVER_PARTS + k]
  for i = #values - 1, 1, -1 do
    text = "if(" .. K.scale .. " == " .. num(values[i]) .. ", " .. g.warp[(i - 1) * #RIVER_PARTS + k] .. ", " ..
      text .. ")"
  end
  return "(" .. text .. " - " .. corner .. ") / " .. K.scale .. " + " .. num(radius + d)
end
def(NR3.u, by_map(function(M) return river_point(M, 1, QU, M.m.wr, M.du) end) .. " + " .. channel_warp("x"))
def(NR3.v, by_map(function(M) return river_point(M, 2, QV, M.m.hr, M.dv) end) .. " + " .. channel_warp("y"))
def(NR3.bank, "1 + " .. num(CH.bank.amplitude) .. " * clamp(" .. tile_noise(CH.bank.seed1, CH.bank.wavelength) ..
  ", -1, 1)")

-- The channel field: per channel row its half-width less the distance to its polyline, in tiles, so it is above 0
-- inside a channel; the largest over the map's rows, -1 on a map with none. Each row's segments are locals under the
-- row's index, the nearest squared distance cd<row>.
local CL = {}
-- A number of a rooted row's start, folded on the per-save map and scale: fn(u, v) of the start the table holds for
-- each map and offered scale. A map the row is not on reads another map's, which no world of it compiles.
local function by_start(r, fn)
  local scales = cfg.scales.values
  return by_map(function(M)
    local starts = r.starts[M.key] or r.starts[r.maps[#r.maps]]
    local text
    for j = #scales, 1, -1 do
      local value = num(fn(to_px(starts[j][1], starts[j][2])))
      text = text and ("if(" .. K.scale .. " == " .. num(scales[j]) .. ", " .. value .. ", " .. text .. ")") or value
    end
    return text
  end)
end
-- A rooted row's first segment, from its start on the river's own course at the save's map and scale to the row's
-- first vertex: the segment formula of the rest with its ends' constants folded per save. Returns its squared
-- distance.
local function root_segment(s, r)
  local bu, bv = to_px(r.latlon[1][1], r.latlon[1][2])
  local k = s .. "_0"
  CL["cu" .. k] = NR3.u .. " - (" .. by_start(r, function(au) return au end) .. ")"
  CL["cv" .. k] = NR3.v .. " - (" .. by_start(r, function(_, av) return av end) .. ")"
  CL["ce" .. k] = by_start(r, function(au) return bu - au end)
  CL["cf" .. k] = by_start(r, function(_, av) return bv - av end)
  CL["cg" .. k] = by_start(r, function(au, av) return 1 / ((bu - au) * (bu - au) + (bv - av) * (bv - av)) end)
  CL["ct" .. k] = "clamp((cu" .. k .. " * ce" .. k .. " + cv" .. k .. " * cf" .. k .. ") * cg" .. k .. ", 0, 1)"
  CL["cp" .. k] = "cu" .. k .. " - ct" .. k .. " * ce" .. k
  CL["cq" .. k] = "cv" .. k .. " - ct" .. k .. " * cf" .. k
  return "cp" .. k .. " * cp" .. k .. " + cq" .. k .. " * cq" .. k
end
local function channel_term(i, r)
  local s, d2s = tostring(i), {}
  if r.starts then
    d2s[#d2s + 1] = root_segment(s, r)
  end
  for j = 1, #r.latlon - 1 do
    local au, av = to_px(r.latlon[j][1], r.latlon[j][2])
    local bu, bv = to_px(r.latlon[j + 1][1], r.latlon[j + 1][2])
    local ex, ey = bu - au, bv - av
    local k = s .. "_" .. tostring(j)
    CL["cu" .. k] = minus(NR3.u, au)
    CL["cv" .. k] = minus(NR3.v, av)
    CL["ct" .. k] = "clamp((cu" .. k .. " * " .. num(ex) .. " + cv" .. k .. " * " .. num(ey) .. ") * " ..
      num(1 / (ex * ex + ey * ey)) .. ", 0, 1)"
    CL["cp" .. k] = "cu" .. k .. " - ct" .. k .. " * " .. num(ex)
    CL["cq" .. k] = "cv" .. k .. " - ct" .. k .. " * " .. num(ey)
    d2s[#d2s + 1] = "cp" .. k .. " * cp" .. k .. " + cq" .. k .. " * cq" .. k
  end
  CL["cd" .. s] = joined("min", d2s, nil)
  return "max(" .. num(CH.least_half_tiles) .. ", " .. num(r.width) .. " * (" .. num(CH.half_tiles[1]) .. " + " ..
    num(CH.half_tiles[2]) .. " * " .. K.scale .. ")) * " .. NR3.bank .. " - " .. K.scale .. " * sqrt(cd" .. s .. ")"
end
local CHANNEL_TERMS = {}
for i, r in ipairs(CHANNELS) do
  CHANNEL_TERMS[i] = channel_term(i, r)
end
def(NR3.channel, by_map(function(M)
  local terms = {}
  for i, r in ipairs(CHANNELS) do
    for _, mk in ipairs(r.maps) do
      if mk == M.key then
        terms[#terms + 1] = CHANNEL_TERMS[i]
      end
    end
  end
  return joined("max", terms, "-1")
end), CL)

data:extend(E)
