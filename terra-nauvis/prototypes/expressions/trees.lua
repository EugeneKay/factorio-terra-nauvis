-- ships the palm switch; trees-forests adds the forest boost, the restored vanilla trees, rocks and
-- decals beside Alien Biomes, and the palms' second versions.
--
-- The palm switch: Alien Biomes' palms read
-- Earth copies of its autoplace (presets.lua) that read this constant where AB reads elevation. The
-- constant is the palm band's middle (AB's palms grow from elevation 0 to 2), so on Earth presets palms
-- follow climate and sand alone; every other world keeps AB's own palms,
-- untouched. A Map type pick sets no key, so its palms read the fine field.
--
--
-- The great forests (trees-forests; ARCHITECTURE.md, "Stable hooks"): every living tree's
--
-- The restored base game beside Alien Biomes (trees-forests): AB nils
-- the autoplace of the 15 living vanilla trees and of the vanilla rocks and decals. data-final-fixes.lua
-- rebuilds each behind the gate tn_on with one key, whose prototype here holds the off value and which
-- Earth presets with AB point at the Earth body defined here from prototypes/tables/vanilla.lua: the
-- base game's own text, with the Earth temperature on the vanilla scale where a tree reads temperature
-- (the fallback climate's scale and clamp, which the vanilla trees read without AB). These bodies read
-- the base game's shared tree and rock helpers by name, as the base game's own entities do. The re-listed
-- decoratives' keys hold -inf and Earth presets name one shared body, 0.
local cfg = require("prototypes.config")
local V = require("prototypes.tables.vanilla")

local P = cfg.tiles.palm
local TR = cfg.trees
local B = TR.boost
local R = TR.restore
local FB = cfg.climate.temperature.fallback

local function num(v)
  return string.format(cfg.number_format, v)
end

local M = {}

end

local function ident(name)
  return "%f[%w_]" .. (string.gsub(name, "%p", "%%%0")) .. "%f[^%w_]"
end

  end
  end
  end
    end
  end
  return out
end

local E = {{type = "noise-expression", name = P.body, expression = string.format(cfg.number_format, P.value)}}

local function def(name, expression, locals)
  E[#E + 1] = {type = "noise-expression", name = name, expression = expression, local_expressions = locals}
end

-- The boost's gate and multiplier key, at their off values.
def(B.gate, B.gate_off)
def(B.key, B.key_off)

-- The Earth temperature on the vanilla scale, as the fallback climate hands it to vanilla trees.
def(TR.temperature, "clamp(" .. num(FB.scale) .. " * temperature, " .. num(FB.min) .. ", " .. num(FB.max) .. ")")

local TEMP = "%f[%w_]temperature%f[^%w_]"
  end
end
def(R.richness, V.tree_richness)

-- The rebuilt rocks and decals: each one's own autoplace text and local expressions.
for _, row in ipairs(V.rocks) do
  local n = R.rocks[row.name]
  if not n then
    error("config.lua trees.restore.rocks has no names for " .. row.name)
  end
  local locals = nil
  if row.local_expressions then
    locals = {}
    for k, v in pairs(row.local_expressions) do
      locals[k] = v
    end
  end
  def(n.key, R.rock_off)
  def(n.body, row.probability_expression, locals)
end

-- The re-listed decoratives: one key each at -inf, all naming one body.
for _, name in ipairs(V.relist) do
  local key = R.decoratives[name]
  if not key then
    error("config.lua trees.restore.decoratives has no key for " .. name)
  end
  def(key, R.deco_off)
end
def(R.deco_body, R.deco_on)

-- The palms' second probability versions: the boost around climate-tiles' copies, defined on every
for _, p in ipairs(TR.palm) do
  def(p.body, M.boost(p.base))
end

data:extend(E)

return M
