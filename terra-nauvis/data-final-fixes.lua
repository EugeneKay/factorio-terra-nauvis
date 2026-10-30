-- Everything that reads other mods' final state: entity wrappers and gated hooks on shared
--
-- Every gated hook is
--   if(tn_on > threshold, <on branch>, <off value>)
-- with the gate tn_on (prototype off, Earth presets on) outermost, so on every other world the hook
-- folds to the off value and the world stays hash- and complexity-identical (the t13_zero_cost check; a
-- gate inside the score instead cost default worlds Tile +7,489). Hooks run here, after every mod's data
-- stage, so each wraps a tile's final autoplace; a tile placed nowhere before is registered on Nauvis,
-- because the game evaluates a tile's autoplace only on a planet whose map gen settings list the tile.
--
-- water-shallow: the on branch is max() of the ford key tn_fords, which an Earth
-- preset points at its map's ford set for the save's scale, and the marsh key (climate-tiles). Where
-- another mod gives the tile an autoplace (Alien Biomes' coastal shallows), that expression is the off
-- value and joins the max(), so its shallows are unchanged on every world; without one the off value is
-- -inf. water-mud (climate-tiles): the same shape around the marsh key; Alien Biomes' inland shallows
-- are its off value with AB, and without AB the tile is registered on Nauvis for Earth presets only.
local cfg = require("prototypes.config")

local H = cfg.hooks
local TL = cfg.tiles
local AB = mods["alien-biomes"] ~= nil

local function num(v)
  return string.format(cfg.number_format, v)
end

local GATE = cfg.keys.on .. " > " .. num(H.threshold)

local function hook(on_branch, off_value)
  return "if(" .. GATE .. ", " .. on_branch .. ", " .. off_value .. ")"
end

local nauvis = data.raw.planet and data.raw.planet.nauvis
local tile_settings = nauvis and nauvis.map_gen_settings and nauvis.map_gen_settings.autoplace_settings and
  nauvis.map_gen_settings.autoplace_settings.tile and nauvis.map_gen_settings.autoplace_settings.tile.settings

local function register(name)
  if tile_settings and tile_settings[name] == nil then
    tile_settings[name] = {}
  end
end

-- A max() hook on a water tile: the keys joined with the tile's own autoplace where it has one.
local function water_hook(name, keys, off, why)
  local tile = data.raw.tile[name]
  if not tile then
    log(cfg.identity.title .. ": no tile " .. name .. " for the " .. why)
    return
  end
  local autoplace = tile.autoplace or {}
  local original = autoplace.probability_expression
  local parts, off_value = {}, nil
  for _, k in ipairs(keys) do
    parts[#parts + 1] = k
  end
  if original ~= nil and original ~= "" then
    off_value = "(" .. tostring(original) .. ")"
    parts[#parts + 1] = off_value
  end
  local on_branch = #parts == 1 and parts[1] or ("max(" .. table.concat(parts, ", ") .. ")")
  autoplace.probability_expression = hook(on_branch, off_value or off)
  tile.autoplace = autoplace
  register(name)
  log(cfg.identity.title .. ": " .. why .. " on " .. name .. (original and " around its own autoplace" or "") ..
    (tile_settings and ", registered on Nauvis" or ", Nauvis has no tile settings"))
end

water_hook(H.fords.tile, {H.fords.key, TL.marsh.water_shallow.key}, H.fords.off, "ford and marsh hook")
water_hook(TL.marsh.water_mud.tile, {TL.marsh.water_mud.key}, TL.marsh.water_mud.off, "marsh hook")

-- The vanilla land tiles beside Alien Biomes: AB keeps their autoplace on the
-- prototypes and takes them off Nauvis's tile list; re-listed here behind the gate, each adds its key.
local function vanilla_hooks()
  local V = TL.vanilla
    local tile = data.raw.tile[name]
    if tile and tile.autoplace and tile.autoplace.probability_expression then
      tile.autoplace.probability_expression = hook("(" .. tostring(tile.autoplace.probability_expression) .. ") + " ..
      register(name)
    else
      log(cfg.identity.title .. ": vanilla tile " .. name .. " is missing or has no autoplace")
    end
  end
end

  for name in pairs(tile_settings or {}) do
    local t = data.raw.tile[name]
        if string.sub(name, 1, #p) == p then
    local autoplace = data.raw.tile[name].autoplace
    local original = "(" .. tostring(autoplace.probability_expression) .. ")"
  for name in pairs(tile_settings or {}) do
-- Only the adopted Alien Biomes tiles mix into temperate bands: every other AB land
-- tile on Nauvis adds the exclusion key, and its own score stays the off value.
local function exclusion_hooks()
  local X = TL.exclude
  local adopted = {}
  for _, name in ipairs(TL.ab_adopted) do
    adopted[name] = true
  end
  local names = {}
  for name in pairs(tile_settings or {}) do
    local t = data.raw.tile[name]
    if not adopted[name] and t and t.autoplace and t.autoplace.probability_expression then
      for _, p in ipairs(X.prefixes) do
        if string.sub(name, 1, #p) == p then
          names[#names + 1] = name
          break
        end
      end
    end
  end
  table.sort(names)
  for _, name in ipairs(names) do
    local autoplace = data.raw.tile[name].autoplace
    local original = "(" .. tostring(autoplace.probability_expression) .. ")"
  end
  log(cfg.identity.title .. ": temperate exclusion on " .. #names .. " Alien Biomes tiles")
end

local PALM = TL.palm

  end
  end
  end
    end
  end
  for _, c in ipairs(PALM.copies) do
    end
  end
end

  end
  end
  end
    end
  end
  return nil
end

local function reads_elevation(autoplace)
  local pattern = "%f[%w_]" .. PALM.reads .. "%f[^%w_]"
  local texts = {}
  for _, field in ipairs({"probability_expression", "richness_expression"}) do
    texts[#texts + 1] = autoplace[field]
  end
  for _, lv in pairs(autoplace.local_expressions or {}) do
    texts[#texts + 1] = lv
  end
  for _, text in pairs(texts) do
    if type(text) == "string" and string.find(text, pattern) then
      return true
    end
  end
  return false
end

local function palm_check()
        end
      end
    end
  end
  local copied = {}
  for _, c in ipairs(PALM.copies) do
    copied[c.tree] = true
  local trees = {}
  for name in pairs(data.raw.tree or {}) do
    trees[#trees + 1] = name
  end
  table.sort(trees)
  for _, name in ipairs(trees) do
    local autoplace = data.raw.tree[name].autoplace
    if autoplace and not copied[name] and reads_elevation(autoplace) then
      log(cfg.identity.title .. ": ERROR tree " .. name .. " reads " .. PALM.reads .. " and has no Earth copy")
    end
  end
end

-- Without Alien Biomes: grass-1 between the marsh pools, (score) +
-- the grass key behind the gate, its own score off, so every other world keeps vanilla's grass-1.
local function marsh_grass_hook()
  local G = TL.marsh.grass
  local tile = data.raw.tile[G.tile]
  local original = tile and tile.autoplace and tile.autoplace.probability_expression
  if original == nil then
    log(cfg.identity.title .. ": no autoplace on " .. G.tile .. " for the marsh grass hook")
    return
  end
  local o = "(" .. tostring(original) .. ")"
  tile.autoplace.probability_expression = hook(o .. " + " .. G.key, o)
end

    local tile = data.raw.tile[name]
if AB then
  vanilla_hooks()
  exclusion_hooks()
else
  marsh_grass_hook()
end

-- back on Earth presets: AB nils their
-- autoplace or takes them off Nauvis, so each is rebuilt from prototypes/tables/vanilla.lua behind the gate
-- tn_on with its key (trees.lua), restricted to the vanilla land tiles so AB's land keeps AB's own, and
-- listed on Nauvis where the base game lists it (trees ride the trees control). Then the great-forests
local TR = cfg.trees
local VAN = require("prototypes.tables.vanilla")
local TREES = require("prototypes.expressions.trees")

local function nauvis_settings(kind)
  local s = nauvis and nauvis.map_gen_settings and nauvis.map_gen_settings.autoplace_settings and
    nauvis.map_gen_settings.autoplace_settings[kind]
  return s and s.settings
end

local function list_on_nauvis(kind, name)
  local s = nauvis_settings(kind)
  if s and s[name] == nil then
    s[name] = {}
  end
end

local function land_tiles()
  local out = {}
  for i, t in ipairs(TL.vanilla.tiles) do
    out[i] = t
  end
  return out
end

local function extend_restriction(autoplace)
  end
  for _, t in ipairs(autoplace.tile_restriction) do
    end
  end
end

-- The living trees: each rebuilt behind the gate with its probability and richness keys.
local function restore_trees(R)
  local n = 0
  for _, row in ipairs(VAN.trees) do
    local tree, names = data.raw.tree[row.tree], R.trees[row.tree]
    if tree and names then
      n = n + 1
    else
      log(cfg.identity.title .. ": vanilla tree " .. row.tree .. " is missing; not restored")
    end
  end
  return n
end

-- The rocks and decals: each rebuilt behind the gate with its key and listed on Nauvis.
local function restore_rocks(R)
  local n = 0
  for _, row in ipairs(VAN.rocks) do
    local proto, names = data.raw[row.type] and data.raw[row.type][row.name], R.rocks[row.name]
    if proto and names then
      proto.autoplace = {control = row.control, order = row.order, placement_density = row.placement_density,
                         probability_expression = hook(names.key, R.rock_off), tile_restriction = land_tiles()}
      list_on_nauvis(row.type == "simple-entity" and "entity" or "decorative", row.name)
      n = n + 1
    else
      log(cfg.identity.title .. ": vanilla " .. row.type .. " " .. row.name .. " is missing; not restored")
    end
  end
  return n
end

  end
local function relist_decoratives(R)
  local n = 0
  for _, name in ipairs(VAN.relist) do
    local proto, key = data.raw["optimized-decorative"][name], R.decoratives[name]
    local autoplace = proto and proto.autoplace
    if autoplace and autoplace.probability_expression ~= nil and key then
      list_on_nauvis("decorative", name)
      n = n + 1
    else
      log(cfg.identity.title .. ": vanilla decorative " .. name .. " is missing or has no autoplace; not re-listed")
    end
  end
  return n
end

-- The vanilla decoratives and dead trees AB restricts to its own tiles: the vanilla land tiles appended.
local function extend_restrictions()
  local n = 0
  for _, group in ipairs({{data.raw["optimized-decorative"], VAN.extend}, {data.raw.tree, VAN.dead_trees}}) do
    for _, name in ipairs(group[2]) do
      local autoplace = group[1] and group[1][name] and group[1][name].autoplace
      if autoplace and autoplace.tile_restriction then
        extend_restriction(autoplace)
        n = n + 1
      end
    end
  end
  return n
end

    local autoplace = proto and proto.autoplace
  for _, name in ipairs(VAN.dead_trees) do
local function restore_vanilla()
  local R = TR.restore
  local trees, rocks, relisted, extended = restore_trees(R), restore_rocks(R), relist_decoratives(R),
    extend_restrictions()
  log(cfg.identity.title .. ": restored " .. trees .. " vanilla trees and " .. rocks .. " rocks and decals, " ..
    "re-listed " .. relisted .. " decoratives, extended " .. extended .. " restrictions beside Alien Biomes")
end

local function boost_hooks()
  for _, name in ipairs(VAN.dead_trees) do
  for _, c in ipairs(PALM.copies) do
  end
  local names = {}
  for name, tree in pairs(data.raw.tree or {}) do
      names[#names + 1] = name
    end
  end
  table.sort(names)
  for _, row in ipairs(VAN.trees) do
  for _, name in ipairs(names) do
    local autoplace = data.raw.tree[name].autoplace
  end
  log(cfg.identity.title .. ": the great-forests hook on " .. #names .. " living trees")
end

  for _, name in ipairs(names) do
if AB then
  restore_vanilla()
end
boost_hooks()

  for name in pairs(data.raw.tree or {}) do
-- ore of config.lua's ridges group whose resource has an autoplace, a wrapper body holds the live
-- probability expression (as the pack leaves it: base, Alien Biomes, the Oil Rig and the rest load
-- before this) times the ore clearance of prototypes/expressions/ridges.lua, and every Terra Nauvis
-- preset points the ore's probability key at it. Only those presets read the wrappers, so a default
-- world compiles none of them, and no resource prototype changes: no cliff_removal_probability edit,
-- which would change default worlds. resources-enemies moves the keys to its own wrappers under
--
-- expressions on purpose, so bobenemies' cap and the Oil Rig's patch set keep acting, and Earth
-- freezes its own terms). Each wrapper is a folded if() on the hotspots toggle, so hotspots off
-- compiles the live expression alone (a folded condition compiles only its selected branch):
--   probability  the ore's ridges wrapper (live times the ridge clearance) or the hotspot term times
--                the same clearance, whichever is larger (max(live, hotspot)); the presets' ore
--                probability keys move to this next version and ridges' bodies stay defined
--   richness     the live richness, times the ramp on the four solid ores, or the hotspot richness
--   enemies      max(live enemy_base_probability, the enemy layer of prototypes/expressions/enemies.lua)
--   offshore     with the Oil Rig loaded: its live probability times the sea mask (random wells on
--                open sea only), or the field wells, which the stamp keeps on deepwater
local presets = data.raw["map-gen-presets"]["default"]
local clear = cfg.ridges.names.clear
local NE = data.raw["noise-expression"]

local function copy(t)
  local out = {}
  for k, v in pairs(t or {}) do
    out[k] = v
  end
  return out
end

local function deep(t)
  if type(t) ~= "table" then
    return t
  end
  local out = {}
  for k, v in pairs(t) do
    out[k] = deep(v)
  end
  return out
end

local function text_of(v)
  if type(v) == "number" then
    return string.format(cfg.number_format, v)
  end
  return v
end

-- Every Terra Nauvis preset points these keys at these bodies.
local function point_presets(keys)
  for _, key in ipairs(cfg.preset_order) do
    local p = presets[cfg.presets[key].name]
    local names = p and p.basic_settings and p.basic_settings.property_expression_names
    if names then
      for k, v in pairs(keys) do
        names[k] = v
      end
    end
  end
end

local function ridge_wrappers()
  local E, keys = {}, {}
  for _, o in ipairs(cfg.ridges.ores) do
    local r = data.raw.resource[o.resource]
    local ap = r and r.autoplace
    local live = ap and text_of(ap.probability_expression)
    if type(live) == "string" then
      E[#E + 1] = {type = "noise-expression", name = o.name, expression = "(" .. live .. ") * " .. clear,
                   local_expressions = copy(ap.local_expressions)}
      keys[o.key] = o.name
    elseif ap then
      log(cfg.identity.title .. ": the autoplace of " .. o.resource .. " holds no probability expression this " ..
          "version wraps; its ore keeps no ridge clearance")
    end
  end
  point_presets(keys)
end

local RS = cfg.resources
local on = cfg.keys.hotspots .. " > " .. string.format(cfg.number_format, cfg.ridges.switch_threshold)
for _, h in ipairs(cfg.hotspots.resources) do
  HS[h.resource] = h.names
end
local RAMPED = {}
for _, name in ipairs(RS.ramped) do
  RAMPED[name] = true
end

-- A wrapper body around a live expression: the live text becomes the local live_value beside the
-- autoplace's own locals, so each branch of the folded if() reads one copy.
local function wrapper(name, live, owner, expression)
  local locals = deep(owner and owner.local_expressions) or {}
  locals.live_value = live
  return {type = "noise-expression", name = name, expression = expression, local_expressions = locals,
          local_functions = deep(owner and owner.local_functions)}
end

-- Each Earth ore: the probability wrapper's next version and the richness wrapper.
local function ore_wrappers(W, keys)
  for _, o in ipairs(RS.ores) do
    local r = data.raw.resource[o.resource]
    local ap = r and r.autoplace
    local hs = HS[o.resource]
    local rich = ap and text_of(ap.richness_expression)
    -- only around ridges' probability wrapper: an ore that one does not wrap keeps the live autoplace
    if NE[o.p_v1] and hs and type(rich) == "string" then
      W[#W + 1] = {type = "noise-expression", name = o.p, expression = "if(" .. on .. ", max(" .. o.p_v1 .. ", " ..
                   hs.p .. " * " .. clear .. "), " .. o.p_v1 .. ")"}
      local base = RAMPED[o.resource] and ("live_value * " .. RS.ramp.name) or "live_value"
      W[#W + 1] = wrapper(o.r, rich, ap, "if(" .. on .. ", max(" .. base .. ", " .. hs.r .. "), " .. base .. ")")
      keys[o.probability] = o.p
      keys[o.richness] = o.r
    elseif ap then
      log(cfg.identity.title .. ": " .. o.resource .. " has no wrapper this version builds; its ore keeps no " ..
          "hotspots")
    end
  end
end

-- The enemy wrapper around the live enemy_base_probability (bobenemies' or vanilla's).
local function enemy_wrapper(W, keys)
  local ebp = NE[cfg.keys.enemy]
  local layer = cfg.enemies.layer
  local live = ebp and text_of(ebp.expression)
  if NE[layer] and type(live) == "string" then
    W[#W + 1] = wrapper(cfg.enemies.wrapper, live, ebp, "if(" .. on .. ", max(live_value, " .. layer ..
      "), live_value)")
  end
end

-- The Oil Rig's offshore oil, when it is loaded.
local function offshore_wrappers(W, keys)
  local OF = RS.offshore
  local res = data.raw.resource[OF.resource]
  local ap = res and res.autoplace
  local p, r = ap and text_of(ap.probability_expression), ap and text_of(ap.richness_expression)
  local hs = HS[OF.resource]
  if type(p) == "string" and type(r) == "string" and hs then
    local random = "live_value * " .. RS.sea.name
    W[#W + 1] = wrapper(OF.p, p, ap, "if(" .. on .. ", max(" .. random .. ", " .. hs.p .. "), " .. random .. ")")
    W[#W + 1] = wrapper(OF.r, r, ap, "if(" .. on .. ", max(live_value, " .. hs.r .. "), live_value)")
    keys[OF.probability] = OF.p
    keys[OF.richness] = OF.r
  end
end

ridge_wrappers()
local W, keys = {}, {}
ore_wrappers(W, keys)
enemy_wrapper(W, keys)
offshore_wrappers(W, keys)
if #W > 0 then
  data:extend(W)
end
point_presets(keys)
