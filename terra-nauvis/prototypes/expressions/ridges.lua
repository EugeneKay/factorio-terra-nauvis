--
--   cliffiness = cliffiness_on * (1 - opening) outside the ridge-free start disc, 0 inside it
local cfg = require("prototypes.config")
local T = require("prototypes.tables.ranges")

local RD = cfg.ridges
local N = RD.names
local K = cfg.keys
local SW = cfg.toggles.ridges
local PPD = cfg.coordinates.px_per_degree

local function num(v)
  return string.format(cfg.number_format, v)
end

-- name minus a constant, spelled without a double sign
local function minus(name, c)
  if c < 0 then
    return name .. " + " .. num(-c)
  end
  return name .. " - " .. num(c)
end

local E = {}
local function def(name, expression, locals)
  E[#E + 1] = {type = "noise-expression", name = name, expression = expression, local_expressions = locals}
end

-- f(a, b, ...) over many parts, as a tree when they exceed the noise language's argument limit.
local function joined(fn, parts, empty)
  if #parts == 0 then
    return empty
  end
  if #parts == 1 then
    return parts[1]
  end
  if #parts <= RD.max_arguments then
    return fn .. "(" .. table.concat(parts, ", ") .. ")"
  end
  local groups, cur = {}, {}
  for _, p in ipairs(parts) do
    cur[#cur + 1] = p
    if #cur == RD.max_arguments then
      groups[#groups + 1] = fn .. "(" .. table.concat(cur, ", ") .. ")"
      cur = {}
    end
  end
  if #cur > 0 then
    groups[#groups + 1] = joined(fn, cur, empty)
  end
  return joined(fn, groups, empty)
end

-- A map's chain coordinates of a table point: pixel centres at integer u, v (ARCHITECTURE.md, "The
-- coordinate chain"), so the tile holding a pixel centre reads that centre.
local function to_px(m, lat, lon)
  return (lon - m.lon_left_edge) * PPD - 1 / 2, (m.lat_top_edge - lat) * PPD - 1 / 2
end

local function on_map(list, key)
  for _, k in ipairs(list or {}) do
    if k == key then
      return true
    end
  end
  return false
end

local S = K.scale
local scale2 = S .. " * " .. S

-- The crest band of one run of consecutive kept segments (pts: chain px), as band terms of one piece
-- each: a piece is a run of segments monotone along one axis within band_max_angle_degrees of it,
-- longest first, and its term is 1 where the tile lies within the piece's half-height of the
-- piecewise-linear function f of that axis through the piece's vertices and within ore_clear_tiles
-- of its span. f = c + sum of slope * clamp(p, p0, p1) costs 3 operations per segment (the clamp
-- bounds fold with the scale), and the half-height ore_clear_tiles / cos(steepest angle) covers every
-- tile within ore_clear_tiles of a segment; beyond the span f stays flat, which covers the ends.
local MAXT = math.tan(math.rad(RD.band_max_angle_degrees))
local function band_pieces(pts, run)
  local out, i = {}, 1
  while i <= #run do
    local best
    for _, axis in ipairs({"x", "y"}) do
      local j, sign = i, nil
      while j <= #run do
        local a, b = pts[run[j]], pts[run[j] + 1]
        local c, o = b[1] - a[1], b[2] - a[2]
        if axis == "y" then
          c, o = o, c
        end
        local sg = c > 0
        if c == 0 or math.abs(o) > MAXT * math.abs(c) or (sign ~= nil and sg ~= sign) then
          break
        end
        sign = sg
        j = j + 1
      end
      if not best or j - i > best.n then
        best = {n = j - i, axis = axis}
      end
    end
    if best.n == 0 then
      -- a segment along no axis within the angle: band_max_angle_degrees is below half a right angle
      error(cfg.identity.title .. " ridges: band_max_angle_degrees leaves a segment on no axis")
    end
    out[#out + 1] = {axis = best.axis, first = i, last = i + best.n - 1}
    i = i + best.n
  end
  return out
end

-- One band term (and its locals) for a piece; P and Q name the scaled axis and cross coordinates.
  for j = piece.first, piece.last do
    if j == piece.first then
      vs[#vs + 1] = pts[run[j]]
    end
    vs[#vs + 1] = pts[run[j] + 1]
  end
  local p, q = "bu", "bv"
  local list = {}
  for n, v in ipairs(vs) do
  end
  if piece.axis == "y" then
    p, q = "bv", "bu"
  end
  if list[#list][1] < list[1][1] then
    local rev = {}
    for n = #list, 1, -1 do
      rev[#rev + 1] = list[n]
    end
    list = rev
  end
  local terms, c, steep = {}, list[1][2], 0
  for n = 2, #list do
    local a, b = list[n - 1], list[n]
    local slope = (b[2] - a[2]) / (b[1] - a[1])
    steep = math.max(steep, math.abs(slope))
    c = c - slope * a[1]
  end
  local half = RD.ore_clear_tiles * math.sqrt(1 + steep * steep)
  local mid, span = (list[1][1] + list[#list][1]) / 2, (list[#list][1] - list[1][1]) / 2
  local f = "f" .. k
  B[f] = S .. " * " .. num(c) .. " + " .. table.concat(terms, " + ")
  return "(abs(" .. q .. " - " .. f .. ") < " .. num(half) .. ") * (abs(" .. p .. " - " .. S .. " * " .. num(mid) ..
    ") < " .. S .. " * " .. num(span) .. " + " .. num(RD.ore_clear_tiles) .. ")"
end

-- One opening on a map: a slot across the crest at a pass or a gap; at an edge crossing, the tiles
-- within edge_tiles of the map's extent (its edges at -1/2 and W - 1/2 in this frame) and within
-- edge_reach_tiles of the crossing.
  local cu, cv = to_px(m, o.lat, o.lon)
  local a, b = pts[o.seg], pts[o.seg + 1]
  local dx, dy = b[1] - a[1], b[2] - a[2]
  local len = math.sqrt(dx * dx + dy * dy)
  if o.vertex and len > 0 then
    -- at an interior vertex: across the bisector of the incoming and the outgoing segment
    local p, q = pts[o.vertex - 1], pts[o.vertex]
    local ix, iy = q[1] - p[1], q[2] - p[2]
    local il = math.sqrt(ix * ix + iy * iy)
    if il > 0 then
      dx, dy = dx / len + ix / il, dy / len + iy / il
      len = math.sqrt(dx * dx + dy * dy)
    end
  end
  local s = tostring(#O.terms + 1)
  local pu, pv = "pu" .. s, "pv" .. s
  if o.kind == "edge" then
    O.terms[#O.terms + 1] = "(ed" .. s .. " * " .. S .. " < " .. num(RD.edge_tiles) .. ") * ((" .. pu .. " * " ..
      pu .. " + " .. pv .. " * " .. pv .. ") * " .. scale2 .. " < " .. num(RD.edge_reach_tiles ^ 2) .. ")"
  elseif len > 0 then
    -- along the crest, outward at a tip (the crest's end vertex): from pass_tiles / 2 inside it to
    -- tip_tiles past it, so the end cap goes too; elsewhere pass_tiles / 2 either side
    local tx, ty = dx / len, dy / len
    if o.tip then
      tx, ty = tx * o.tip, ty * o.tip
      local lo, hi = -RD.pass_tiles / 2, RD.tip_tiles
        num((lo + hi) / 2) .. ") < " .. num((hi - lo) / 2)
    end
  end
end

-- The crest band of one range on a map: its kept segments in runs of consecutive ones, each cut
-- into monotone pieces.
  local run = {}
  local function flush()
    if #run > 0 then
      for _, piece in ipairs(band_pieces(pts, run)) do
      end
    end
    run = {}
  end
  for _, i in ipairs(segs) do
    if #run > 0 and i ~= run[#run] + 1 then
      flush()
    end
    run[#run + 1] = i
  end
  flush()
end

  local centre = " + " .. num(RD.centre_tiles)
    local segs = r.segments[key]
    if segs then
      for i, ll in ipairs(r.crest) do
        local pu, pv = to_px(m, ll[1], ll[2])
        pts[i] = {pu, pv}
      end
      for _, o in ipairs(r.openings) do
        if on_map(o.maps, key) then
local function map_bodies(key)
  -- the chain every map-wide layer reads (config.lua layer_chain_geo): a later geography version keeps
  -- its frame, so these registered bodies never move with one
  local g
    if v.geo_id == cfg.layer_chain_geo[key] then
      g = v
    end
  end
  if not g then
    error("config.lua layer_chain_geo names no geography version of " .. key .. " for the ridges")
  end
  local m = cfg.maps[key]
  local centre = " + " .. num(RD.centre_tiles)
  for _, r in ipairs(T.ranges) do
    local segs = r.segments[key]
    if segs then
      for i, ll in ipairs(r.crest) do
        local pu, pv = to_px(m, ll[1], ll[2])
        pts[i] = {pu, pv}
      end
      for _, o in ipairs(r.openings) do
        if on_map(o.maps, key) then
        end
      end
    end
  end
  if #Bd.terms == 0 then
    def(N.band[key], "0")
  else
    def(N.band[key], joined("max", Bd.terms, "0"), Bd.L)
  end
end

for _, key in ipairs(cfg.map_order) do
    map_bodies(key)
  end
end

    end
    run = {}
  end
  for _, i in ipairs(segs) do
    if #run > 0 and i ~= run[#run] + 1 then
      flush()
    end
    run[#run + 1] = i
  end
  flush()
    if v.geo_id == cfg.layer_chain_geo[key] then
      g = v
    end
  end
    local segs = r.segments[key]
    if segs then
      for i, ll in ipairs(r.crest) do
        local pu, pv = to_px(m, ll[1], ll[2])
        pts[i] = {pu, pv}
      end
      for _, o in ipairs(r.openings) do
        if on_map(o.maps, key) then
        end
      end
    end
  end
end

for _, key in ipairs(cfg.map_order) do
local on = K.ridges .. " > " .. num(RD.switch_threshold)
def(N.free, "distance < max(" .. num(RD.start.radius_tiles) .. ", starting_area_radius) + " ..
  num(RD.start.margin_tiles))
def(N.cliffiness, "if(" .. on .. ", " .. num(RD.cliffiness) .. " * (1 - " .. K.openings .. ") * (1 - " .. N.free ..
  "), 0)")
-- The ore clearance: 0 in the map's crest band (every tile within ore_clear_tiles of a crest, and a
-- little more where the crest bends or climbs) outside the start disc, else 1.
def(N.clear, "if(" .. on .. ", max(1 - " .. K.band .. ", " .. N.free .. "), 1)")

-- The toggle's neutral bodies, shared with waterways' canals switch: defined here unless an earlier
-- module did (one definition per name).
local NE = data.raw["noise-expression"] or {}
if not NE[SW.on] then
  def(SW.on, num(1))
end
if not NE[SW.off] then
  def(SW.off, num(0))
end

data:extend(E)
