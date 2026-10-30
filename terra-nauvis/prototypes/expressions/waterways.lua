--
-- Per map and scale, four named sets from the generated files (tools/build_waterways.py): the rivers,
-- straits and turning basins (ww), the canals, the dams and the fords. Each reads only its map's geo
-- elevation entry (coast.lua) picks the save's scale's ww, canal and dam sets by name through the
-- folded scale, and its preset points the ford key at the map's ford set for its scale, which the
-- water-shallow hook in data-final-fixes.lua reads behind the gate.
--
-- Also the shared bodies: the gate's and the ford key's prototypes, which hold their off values, and
-- the canals switch's two neutral bodies. Every name and number comes from config.lua.
local cfg = require("prototypes.config")

local FILES = {
  europe = {
  },
  atlantic = {
  },
  olde_world = {
  },
}

local H = cfg.hooks

local function num(v)
  return string.format(cfg.number_format, v)
end

-- A copy of a generated local function, so no two prototypes share one Lua table.
local function fn(f)
  local locals = {}
  for k, v in pairs(f.local_expressions or {}) do
    locals[k] = v
  end
  local params = {}
  for i, p in ipairs(f.parameters) do
    params[i] = p
  end
  return {parameters = params, expression = f.expression, local_expressions = locals}
end

local E = {}
      if not gen then
        error("waterways.lua has no generated file for " .. key .. " at scale " .. s)
      end
      local function set(kind, expression, functions)
        local lf = {}
        for _, f in ipairs(functions) do
          lf[f] = fn(gen.functions[f])
        end
        E[#E + 1] = {type = "noise-expression", name = name, expression = expression, local_expressions = locals,
                     local_functions = lf}
      end
      set("ww", gen.ww, {"seg"})
      set("canals", gen.canals, {"seg"})
      set("dams", gen.dams, {"seg"})
      set("fords", gen.fords, {"box"})
    end
for _, key in ipairs(cfg.map_order) do
  local versions = (cfg.geography[key] or {}).versions or {}
  for _, g in ipairs(versions) do
  end
end

for _, key in ipairs(cfg.map_order) do
  local versions = (cfg.geography[key] or {}).versions or {}
-- The hook gate and the ford key hold their off values; Earth presets set the gate and point the key at
-- the map's ford set (ARCHITECTURE.md, "Stable hooks"). The canals switch's neutral bodies.
E[#E + 1] = {type = "noise-expression", name = cfg.keys.on, expression = num(H.gate_off)}
E[#E + 1] = {type = "noise-expression", name = H.fords.key, expression = H.fords.off}
E[#E + 1] = {type = "noise-expression", name = cfg.neutral.one, expression = num(H.gate_on)}
E[#E + 1] = {type = "noise-expression", name = cfg.neutral.zero, expression = num(H.gate_off)}

data:extend(E)

-- coast.lua's entry of a version with waterways: the waterway composition wrapped around the rest of
-- the version's composition (ARCHITECTURE.md, "Elevation composition", steps 5 and 6). Dams come
-- first, so a dam never closes a named waterway; both come after the rest of the version's
-- composition, so no lake of an earlier step reopens a dammed isthmus, and min() makes the carves
-- and lakes order-free. Each set is picked by name through the folded scale, so only the save's
-- scale's sets compile, and the canals switch compiles only its selected branch (measured Tile 19,620 off
local M = {}

  for i = #values - 1, 1, -1 do
  end
  return text
end

  if not sets then
    error("a waterways composition needs the version's waterway sets")
  end
  local on = cfg.keys.canals .. " > " .. num(H.threshold)
  }
end

return M
