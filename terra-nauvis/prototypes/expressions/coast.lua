-- Coast and elevation expressions (ARCHITECTURE.md, "Expression graph" and "Elevation composition").
--
--
--   e = min(e, far)                        deep water beyond the map's extent, and from scale 3
--                                          a ring of plain water on its outermost tiles, so deep
--                                          water starts 1 tile beyond it (deepwater borders only
--   e = max(e, land)                       the start land guarantee (a version with a spawn record)
-- No term reads control:water:* or segmentation_multiplier. Vanilla cliffs, moisture and aux do,
-- so every Earth preset also bakes vanilla's three water-slider readers as constants (presets.lua;
-- config.lua's water_slider): the slider moves nothing on a preset world. Every coordinate and
-- constant comes from config.lua.
local cfg = require("prototypes.config")

-- One require per generated file the release registry lists (the registration scan reads literal
-- module names), keyed by its path as config.lua's release_registry files and fits name it.
local FILES = {
  ["prototypes/generated/geo_europe_v1.lua"] = require("prototypes.generated.geo_europe_v1"),
  ["prototypes/generated/land_coarse_europe_v1.lua"] = require("prototypes.generated.land_coarse_europe_v1"),
}

local K = cfg.keys
local C = cfg.coast

local function num(v)
  return string.format(cfg.number_format, v)
end

local E, defined = {}, {}
local function def(name, expression, locals)
  if defined[name] then
    error("two geography versions define " .. name .. ": each version takes names of its own")
  end
  defined[name] = true
  E[#E + 1] = {type = "noise-expression", name = name, expression = expression, local_expressions = locals}
  return E[#E]
end

  local fit = FILES[file]
  if not fit then
    error("no generated fit is loaded from " .. tostring(file) .. " for " .. name)
  end
  local L = {}
  for k, v in pairs(fit.locals) do
    L[k] = v
  end
  def(name, fit.expression, L)
end

  local corner = "floor(" .. s .. " / " .. num(cfg.coordinates.corner_offset_divisor) .. ")"
  def(g.gx, "x + " .. g.cx)
  def(g.gy, "y + " .. g.cy)
  def(g.u, "(" .. g.gx .. " - " .. corner .. ") / " .. s .. " + " .. num(m.wr))
  def(g.v, "(" .. g.gy .. " - " .. corner .. ") / " .. s .. " + " .. num(m.hr))
-- One geography version of a map: its chain, fit bodies, detail, box and elevation entry. Returns
-- the entry's prototype.
local function version(m, g)
  local s = K.scale
  -- the integer-corner offset in tiles, floor(s / corner_offset_divisor) (config.lua)
  local corner = "floor(" .. s .. " / " .. num(cfg.coordinates.corner_offset_divisor) .. ")"


  fit_body(g.land_coarse, g.fits.land_coarse, g)

  -- Lattice detail: each octave's lattice holds every pixel centre (basis noise is 0 there; its
  -- offset is added before the input scale), so the preview metrics at pixel centres see the fit alone
  -- and the coast moves at most the amplitude between them.
  local off_x = g.cx .. " - " .. corner .. " + " .. s .. " * " .. num(m.wr)
  local off_y = g.cy .. " - " .. corner .. " + " .. s .. " * " .. num(m.hr)
  local octaves = {}
  for _, o in ipairs(C.detail_octaves) do
    octaves[#octaves + 1] = num(o.weight) .. " * basis_noise{x = x, y = y, seed0 = map_seed, seed1 = " ..
      num(o.seed1) .. ", input_scale = " .. num(o.frequency) .. " / " .. s .. ", offset_x = " .. off_x ..
      ", offset_y = " .. off_y .. "}"
  end

  -- The far-field box: d is the signed distance in tiles to the edge of the map's extent, the
  -- W s x H s tiles its raster covers (>= 0 inside); beyond it everything is deep water, at any
  -- distance. Tents can reach past the raster edge, so this box, not the fit, ends the map.
  -- The extent's outermost tiles (d = 0) read the edge water from edge_min_scale up, where none of
  -- them holds a pixel centre: ring is 1 there and 0 below, so d < ring never holds at scales 1
  -- and 2.
  local ring = "min(1, floor(" .. s .. " / " .. num(C.edge_min_scale) .. "))"

  -- The elevation entry: the sign-offset transfer of the clamped coast field, then the far field.
  -- Never name a local e, pi or inf: the built-in constants win over locals.
  local o = num(C.transfer_offset)
  local text = "min(if(cv > 0, " .. s .. " * cv + " .. o .. ", " .. s .. " * cv - " .. o .. "), " .. g.far .. ")"
  -- A version with a spawn record (spawn-cities) adds step 4, the start land guarantee, and step 7,
  local sp = g.spawn
  if sp then
  end
end

for _, key in ipairs(cfg.map_order) do
  local g = cfg.geography[key]
  local versions = g and g.versions or {}
  for i, v in ipairs(versions) do
    if i == #versions then
      entry.intended_property = K.elevation
      entry.order = g.map_type_order
    end
  end
end

data:extend(E)
