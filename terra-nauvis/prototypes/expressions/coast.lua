-- Coast and elevation expressions (ARCHITECTURE.md, "Expression graph" and "Elevation composition").
--
--
--   e = scale * c + if(c > 0, o, -o)       the sign offset: the tile class is the sign of c; a version
--                                          with a shore body (climate-tiles) reads it instead:
--                                          min(gain * c + if(c > 0, o, -o), far) with a land and a
--                                          water gain set for Alien Biomes' beach band and deepwater
--                                          line (config.lua shore)
--   e = min(e, far)                        deep water beyond the map's extent, and from scale 3
--                                          a ring of plain water on its outermost tiles, so deep
--                                          water starts 1 tile beyond it (deepwater borders only
--   e = max(e, land)                       the start land guarantee (a version with a spawn record)
--   elevation = min(max(e, dams), carves)  a version with waterways: the canals-off dams, then the
--                                          rivers, straits, basins and open canals, each set picked by
--                                          the folded scale (waterways.lua); dams come after the lakes
--                                          so no lake reopens a dammed isthmus, and a carve still cuts
--                                          the start land guarantee
--   elevation = if(e < 0, min(e, stamp), e)  a version with an offshore stamp (resources-enemies): the
--                                          map's stamp key, a Map type fallback, names the stamp body
--                                          (resources.lua) with hotspots on and the neutral zero off,
--                                          so each field's disc is deepwater where the ground is water
--                                          and the coast never moves
-- No term reads control:water:* or segmentation_multiplier. Vanilla cliffs, moisture and aux do,
-- so every Earth preset also bakes vanilla's three water-slider readers as constants (presets.lua;
-- config.lua's water_slider): the slider moves nothing on a preset world. Every coordinate and
-- constant comes from config.lua.
local cfg = require("prototypes.config")
local waterways = require("prototypes.expressions.waterways")

-- One require per generated file the release registry lists (the registration scan reads literal
-- module names), keyed by its path as config.lua's release_registry files and fits name it.
local FILES = {
  ["prototypes/generated/geo_europe_v1.lua"] = require("prototypes.generated.geo_europe_v1"),
  ["prototypes/generated/land_coarse_europe_v1.lua"] = require("prototypes.generated.land_coarse_europe_v1"),
  ["prototypes/generated/land_coarse_atlantic_v1.lua"] = require("prototypes.generated.land_coarse_atlantic_v1"),
  ["prototypes/generated/land_coarse_olde_world_v1.lua"] = require("prototypes.generated.land_coarse_olde_world_v1"),
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
    num(C.transfer_clamp_px) .. ")"
  local text = "min(if(cv > 0, " .. s .. " * cv + " .. o .. ", " .. s .. " * cv - " .. o .. "), " .. g.far .. ")"
  local locals = {cv = cv}
  -- A version with a shore body (climate-tiles) composes it in place of the transfer: the same sign
  -- offset with the land and water gains recalibrated with Alien Biomes (config.lua shore), so AB's
  -- beach band is a strip a few tiles wide at every scale and the open sea lies below AB's deepwater
  -- line, while the tile class stays the sign of c (the preview metrics are unchanged). The body is the version's
  -- own: it reads the version's fit, detail and box.
  if g.shore then
    local SH = cfg.shore
       gl = "max(" .. num(SH.land.min) .. ", " .. num(SH.land.per_scale) .. " * " .. s .. ")",
    text, locals = g.shore, {}
  end
  -- A version with a spawn record (spawn-cities) adds step 4, the start land guarantee, and step 7,
  -- the spawn lake and the version's inland lakes (spawn.lua defines all three). A version with
  -- waterways (waterways) wraps the rest in steps 5 and 6, the dams and carves (waterways.lua): a
  -- named waterway still cuts the guarantee, and no lake reopens a dammed isthmus.
  local sp = g.spawn
  if sp then
  end
    end
  end
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
