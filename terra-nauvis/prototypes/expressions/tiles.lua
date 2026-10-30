-- data-final-fixes.lua writes the hooks on the shared tiles; this file defines the
-- keys they read, each holding its off value, and the versioned bodies Earth presets point them at.
--   tn_vtile_<tile>      the 19 vanilla land tiles beside Alien Biomes: every key names one bonus body,
--                        +bonus on land where the temperate lean plus patch noise passes, -inf
--                        elsewhere and inside marshes, so vanilla follows temperature and marshes
--                        keep their wetland biome
--   tn_ab_exclude        every non-adopted Alien Biomes land tile: -inf in the temperate band outside
--                        marshes, 0 elsewhere (only the adopted tiles mix into temperate zones)
--   tn_marsh_water_mud   water-mud pools on land inside marshes, outside the start clearing
--   tn_marsh_water_shallow  water-shallow along open water inside marshes, above shallow_depth, so a
--                        river's floor (-2.2) stays player-blocking water
--   tn_marsh_grass       without Alien Biomes: grass-1 between the pools, +bonus on marsh land, 0 elsewhere
-- Marshes read the region layer's marsh weight, the shared region expression, and nothing else of the
local cfg = require("prototypes.config")

local V = cfg.tiles.vanilla
local X = cfg.tiles.exclude
local MS = cfg.tiles.marsh
local K = cfg.keys
local MARSH_W = cfg.regions.names.marsh_w

local function num(v)
  return string.format(cfg.number_format, v)
end

local E = {}
local function def(name, expression, locals)
  E[#E + 1] = {type = "noise-expression", name = name, expression = expression, local_expressions = locals}
end

local function noise(P)
  return "multioctave_noise{x = x, y = y, seed0 = map_seed, seed1 = " .. num(P.seed1) .. ", octaves = " ..
    num(P.octaves) .. ", persistence = " .. num(P.persistence) .. ", input_scale = 1 / (" .. num(P.wavelength_px) ..
    " * " .. K.scale .. "), output_scale = 1}"
end

-- The keys, each at its off value (a world whose preset lacks one keeps the tile off).
for _, t in ipairs(V.tiles) do
  def(V.keys[t], V.off)
end
def(X.key, X.off)
def(MS.water_mud.key, MS.water_mud.off)
def(MS.water_shallow.key, MS.water_shallow.off)
def(MS.grass.key, MS.grass.off)

-- The vanilla bonus: the temperate lean, 1 at lean_t falling to 0 lean_span away, plus clamped patch noise,
-- gives +bonus on land below the band's top (temperate_below: the lean plus patch passes up to about
-- 73.5, inside the hot band and its desert bin, where AB's tiles score at most about 1.5, so the
-- bonus stops at the band's top); elsewhere in the temperate band vanilla keeps its own score (0), so
-- vanilla and the adopted AB tiles compete there by fit and AB's inland shallows stay patches, as in AB
-- alone (with -inf there, a test render showed water-mud covering the band wherever the lean
-- failed); at and above the band's top, below its bottom where the lean fails, on water and
-- inside marshes -inf. The lean still reaches below the band's bottom, on its cold side.
    num(X.temperate_below) .. ", -inf, if(1 - abs(" .. t .. " - " .. num(V.lean_t) .. ") / " .. num(V.lean_span) ..
end
local PATCH = {patch = "clamp(" .. num(V.patch.amplitude) .. " * " .. noise(V.patch) .. ", " .. num(-V.patch.clamp) ..
  ", " .. num(V.patch.clamp) .. ")"}


-- The exclusion of non-adopted Alien Biomes land tiles from the temperate band.
  return "if(" .. t .. " >= " .. num(X.temperate_from) .. ", if(" .. t .. " < " .. num(X.temperate_below) ..
end

-- The grain's tile copies (config.lua climate.grain): each key is its plain field, and the bonus and
-- exclusion versions read the temperature copy, so the temperate band's edge frays with the tiles. Tile
-- scores alone read them; they exist only with Alien Biomes, as the fields' grain bodies do.
if mods["alien-biomes"] then
  local GK = cfg.climate.grain.keys
  for field, key in pairs(GK) do
    def(key, field)
  end
end

-- Marsh pools: inside a marsh (weight above marsh_cut; normalized noise alone passes the weight-0 cut
-- on about 3 percent of tiles in a test run), the pool noise passes a cut that falls as
-- the weight rises (cut at weight 1, cut + cut_per_weight at weight 0), on land, away from the start.
local P = MS.pool
def(MS.water_mud.body, "if(elevation > 0, if(distance > " .. num(MS.start_clear_tiles) .. ", if(" .. MARSH_W ..
  " > " .. num(V.marsh_cut) .. ", if(pool + " .. num(P.cut_per_weight) .. " * " .. MARSH_W .. " - " ..
  num(P.cut + P.cut_per_weight) .. " > 0, " .. num(MS.score) .. ", -inf), -inf), -inf), -inf)",
  " > " .. num(V.marsh_cut) .. ", if(pool + " .. num(P.cut_per_weight) .. " * " .. MARSH_W .. " - " ..
  num(P.cut + P.cut_per_weight) .. " > 0, " .. num(MS.score) .. ", -inf), -inf), -inf), -inf)",
def(MS.water_shallow.body, "if(" .. MARSH_W .. " > " .. num(V.marsh_cut) .. ", if(elevation < 0, if(elevation > " ..
  num(-MS.shallow_depth) .. ", " .. num(MS.shallow_score) .. ", -inf), -inf), -inf)")
-- Without Alien Biomes: grass-1 between the pools, +bonus on land inside marshes, 0
-- elsewhere, so grass-1 keeps its own score outside marshes and the pools (score) still beat it.
def(MS.grass.body, "if(" .. MARSH_W .. " > " .. num(V.marsh_cut) .. ", if(elevation > 0, " .. num(MS.grass.bonus) ..
  ", 0), 0)")

data:extend(E)
