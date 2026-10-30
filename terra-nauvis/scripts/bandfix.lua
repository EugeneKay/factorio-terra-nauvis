-- on_chunk_generated is registered only on a save whose Nauvis surface carries the band-fix key (config.lua
-- bandfix.key set to bandfix.on; absent means off): on_init records the save's state once
-- (storage.earth.bandfix) and both on_init and on_load register from it, so a save made without the key
-- never registers it, whatever the setting says later.
--
-- Per new chunk of the Nauvis surface, a pure function of the chunk's position, its generated tiles and
-- the shipped K+ data of the save's map and scale (scripts/generated/, tools/build_geo.py --bandfix): the
-- map's K+ table (its K pixels at every offered scale with the reference classes of their neighbours)
--   1. the chunk's reference pixels: geo tile = world tile + the city offset read once in on_init, pixel
--      floor(geo / scale) + the map's radius, tile offset geo mod scale (the coordinate chain's frame);
--   2. a chunk with no K pixel returns before reading a tile;
local cfg = require("prototypes.config")
local guards = require("scripts.guards")

local TABLES = {
  europe = {
    },
  },
  olde_world = {
    },
  },
}

local M = {}
local B = cfg.bandfix
local MSG = cfg.messages
local byte, rep, find, sub, gsub, concat = string.byte, string.rep, string.find, string.sub, string.gsub, table.concat
local band = bit32.band

local CT = B.chunk_tiles
local KEEP_R2 = B.spawn_keep_tiles * B.spawn_keep_tiles

-- The table encoding (config.lua bandfix): digits, the symbol of each role, what a symbol means, and the K
-- symbols as one pattern. A masked pixel keeps its class for the band but is never written.
local DIGIT, BASE = {}, B.varint_base
for k = 1, #B.alphabet do
  DIGIT[byte(B.alphabet, k)] = k - 1
end
local ORDER, NSYM = B.symbol_order, #B.symbol_order
local CHAR, BY = {}, {}
for k, role in ipairs(ORDER) do
  CHAR[k - 1] = B.symbols[role]
  BY[role] = byte(B.symbols[role])
end
local S = B.symbols
local NONE = BY.none
local LANDISH = {[BY.land] = true, [BY.land_k] = true, [BY.land_masked] = true}
local IS_K = {[BY.water_k] = true, [BY.land_k] = true}
local OPEN = {[BY.water] = true, [BY.land] = true, [BY.water_k] = true, [BY.land_k] = true}
local KPAT = "[" .. S.water_k .. S.land_k .. "]"
local MASKED = {[S.water] = S.water_masked, [S.water_k] = S.water_masked, [S.land] = S.land_masked,
                [S.land_k] = S.land_masked, [S.thin] = S.thin, [S.none] = S.none,
                [S.water_masked] = S.water_masked, [S.land_masked] = S.land_masked}

local STATE, SHARED, MASKS, MAP, LUT, THIN
-- A geography version with the soft map edge (edge = true) sinks land into deep water within
local EDGE = 0

------------------------------------------------------------------------------------------------ the tables

-- One payload: its first column, then one varint per run, (length - 1) * n + value.
local function varints(payload)
  local vals, v, mul = {}, 0, 1
  for k = 1, #payload do
    local d = DIGIT[byte(payload, k)]
    if d >= BASE then
      v = v + (d - BASE) * mul
      mul = mul * BASE
    else
      vals[#vals + 1] = v + d * mul
      v, mul = 0, 1
    end
  end
  return vals
end

-- A shared row's symbols over its span, with the scale's masked runs applied.
local function decode(payload, masks)
  local vals = varints(payload)
  local parts = {}
  for k = 2, #vals do
    local x = vals[k]
    parts[#parts + 1] = rep(CHAR[x % NSYM], floor(x / NSYM) + 1)
  end
  local first, text = vals[1], concat(parts)
  if masks then
    local mv = varints(masks)
    for k = 2, #mv do
      local x = mv[k]
      local len = floor(x / 2) + 1
      if x % 2 == 1 then
        local a = c - first + 1
      end
      c = c + len
    end
  end
  return {first = first, text = text}
end


-- The decoded row r of the save's tables, or false where the K+ table holds no pixel on that row.
local function row_at(r)
  if CACHE_FOR ~= MASKS then
  end
  local hit = CACHE[r]
    return hit
  end
  local payload = SHARED.rows[r]
  end
  CACHE[r] = row
  return row
end

local function sym_in(row, c)
  if not row then
    return NONE
  end
  local k = c - row.first + 1
  if k < 1 or k > #row.text then
    return NONE
  end
  return byte(row.text, k)
end

-- Whether a pixel's reference class is land; thin water and the area outside the raster count as water.
local function landish(c, r)
  if c < 0 or r < 0 or c >= MAP.width_px or r >= MAP.height_px then
    return false
  end
  return LANDISH[sym_in(row_at(r), c)] or false
end

-- The other-class mask of a pixel: one bit per neighbour (config.lua's order) of the other class.
local function other_mask(c, r, me)
  local m, bit = 0, 1
  for _, nb in ipairs(B.neighbours) do
    if landish(c + nb[1], r + nb[2]) ~= me then
      m = m + bit
    end
    bit = bit * 2
  end
  return m
end

-- Per tile offset (i, j) of a pixel at scale s, the neighbours whose squares lie closer than half a pixel
-- to its sample point, exact in units of 1 / (2 s) px (the band table that tools/build_geo.py builds).
local function reach_lut(s)
  local half = floor(s / 2)
  local function g(d, k)
    local d2 = 2 * (k - half)
    if d == 0 then
      return 0
    elseif d == 1 then
      return s - d2
    end
    return d2 + s
  end
  local lut = {}
  for j = 0, s - 1 do
    for i = 0, s - 1 do
      local m, bit = 0, 1
      for _, nb in ipairs(B.neighbours) do
        local gx, gy = g(nb[1], i), g(nb[2], j)
        if gx * gx + gy * gy < s * s then
          m = m + bit
        end
        bit = bit * 2
      end
      lut[j * s + i] = m
    end
  end
  return lut
end

  for _, nb in ipairs(B.neighbours) do
  for _, nb in ipairs(B.neighbours) do
-- Per other-class mask (0 to 255), whether the band region holds no 2 x 2 block of tiles at scale s: such a
-- pixel is a fill pixel, written whole (tools/build_geo.py's thin_lut).
local function thin_lut(s, lut)
  local out = {}
  local masks = 2 ^ #B.neighbours
  for m = 0, masks - 1 do
    local open = {}
    for k = 0, s * s - 1 do
      open[k] = band(m, lut[k]) == 0
    end
    local block = false
    for j = 0, s - 2 do
      for i = 0, s - 2 do
        local k = j * s + i
        if open[k] and open[k + 1] and open[k + s] and open[k + s + 1] then
          block = true
        end
      end
    end
    out[m] = not block
  end
  return out
end

------------------------------------------------------------------------------------------------ one chunk

-- Per-chunk scratch, reused: marks stamped with the current chunk, so a new stamp clears them.
local stamp = 0
local QX, QY = {}, {}
local NWET, MARKS_WET, NW = 0, true, 0
local GX0, GY0, X0, Y0, C0, R0, WW, NEAR = 0, 0, 0, 0, 0, 0, 0, false
-- others) and its kept tiles are marked once.
local function read_tiles(surface, area)
  NWET = surface.count_tiles_filtered{area = area, name = WATER}
  MARKS_WET = true
    local list
      list = surface.find_tiles_filtered{area = area, name = WATER, invert = true}
      MARKS_WET = false
    else
      list = surface.find_tiles_filtered{area = area, name = WATER}
    end
    for k = 1, #list do
      local p = list[k].position
      WET[(p.y - Y0) * CT + p.x - X0] = stamp
    end
  end
  if #KEEP > 0 and surface.count_tiles_filtered{area = area, name = KEEP} > 0 then
    for _, t in ipairs(surface.find_tiles_filtered{area = area, name = KEEP}) do
      local p = t.position
    end
  end
end

local function generated_wet(idx)
  if NWET == 0 then
    return false
    return true
  end
  return (WET[idx] == stamp) == MARKS_WET
end

local function post_wet(idx)
  if WROTE[idx] == stamp then
    return not WLAND[idx]
  end
  return generated_wet(idx)
end

-- The chunk's window: the geo tile of its corner and pixel columns c0..c1, rows r0..r1.
local function window(chx, chy)
  local s = STATE.scale
  local gx0, gy0 = chx * CT + STATE.cx, chy * CT + STATE.cy
  local c0, c1 = floor(gx0 / s) + MAP.wr, floor((gx0 + CT - 1) / s) + MAP.wr
  local r0, r1 = floor(gy0 / s) + MAP.hr, floor((gy0 + CT - 1) / s) + MAP.hr
  return gx0, gy0, c0, c1, r0, r1
end

-- Whether world tile (x, y) of the chunk lies inside the spawn keep disc.
local function kept_by_spawn(lx, ly)
  if not NEAR then
    return false
  end
  local x, y = X0 + lx, Y0 + ly
  return x * x + y * y < KEEP_R2
end

  NW = NW + 1
  QX[NW], QY[NW] = lx, ly
end

-- The other-class mask of pixel (c, r) of the window, computed once per chunk.
local function pixel_mask(c, r, land)
  local k = (r - R0) * WW + (c - C0)
  if PM_STAMP[k] ~= stamp then
    PM_STAMP[k], PM_MASK[k] = stamp, other_mask(c, r, land)
  end
  return PM_MASK[k]
end

-- Whether reference pixel (c, r) lies in the soft edge band of the save's geography version.
local function in_edge(c, r)
end

  local code = sym_in(row_at(r), c)
    local row = row_at(r)
    if row then
    local row = row_at(r)
    if row then
    local row = row_at(r)
    if row then
  local s = STATE.scale
  end
      end
    end
  end
end

-- The reference class of the pixel holding chunk tile (lx, ly), for a written tile's neighbour: true for
-- land, false for water, nil where the pixel may not be written (outside K+, thin water, masked).
local function open_class(lx, ly)
  local s = STATE.scale
  local gx, gy = GX0 + lx, GY0 + ly
  local c, r = floor(gx / s) + MAP.wr, floor(gy / s) + MAP.hr
  local code = sym_in(row_at(r), c)
  if not OPEN[code] or in_edge(c, r) then
    return nil
  end
  return LANDISH[code] or false
end

local function writable(n, nx, ny, land)
  return WROTE[n] ~= stamp and KEPT[n] ~= stamp and not kept_by_spawn(nx, ny) and open_class(nx, ny) == land
end

local function extend_axis(q, dx, dy)
  local lx, ly = QX[q], QY[q]
  local wet = post_wet(ly * CT + lx)
  local ax, ay, bx, by = lx + dx, ly + dy, lx - dx, ly - dy
  local a, b = ay * CT + ax, by * CT + bx
  if (a_in and post_wet(a) == wet) or (b_in and post_wet(b) == wet) then
    return
  end
  if a_in and writable(a, ax, ay, not wet) then
  elseif b_in and writable(b, bx, by, not wet) then
  end
end

local RECS = {}

  for q = 1, NW do
      end
    end
    local rec = RECS[q]
    if rec then
      rec.name = name
    else
    end
  end
  for q = #RECS, NW + 1, -1 do
    RECS[q] = nil
  end
end

local function plan_chunk(surface, chx, chy)
  local c1, r1
  GX0, GY0, C0, c1, R0, r1 = window(chx, chy)
  NW = 0
  WW = c1 - C0 + 1
  X0, Y0 = chx * CT, chy * CT
  local dx = X0 > 0 and X0 or (X0 + CT - 1 < 0 and -(X0 + CT - 1) or 0)
  local dy = Y0 > 0 and Y0 or (Y0 + CT - 1 < 0 and -(Y0 + CT - 1) or 0)
  NEAR = dx * dx + dy * dy < KEEP_R2
  end
  local q = 1
  while q <= NW do
    extend_axis(q, 1, 0)
    extend_axis(q, 0, 1)
    q = q + 1
  end
end

local function fix_chunk(surface, chx, chy)
  plan_chunk(surface, chx, chy)
  end
  return NW
end

------------------------------------------------------------------------------------------------ lifecycle

local function map_of(id)
  for _, key in ipairs(cfg.map_order) do
    if cfg.maps[key].id == id then
      return key
    end
  end
  return nil
end

local function listed(list, v)
  for _, x in ipairs(list or {}) do
    if x == v then
      return true
    end
  end
  return false
end

-- The tile lists, from the prototypes: player-blocking water (water_tile and player layers, placed by an
-- autoplace, as the preview metrics count water) and kept water (water_tile without the player layer: fords,
-- marsh water).
local function tile_lists()
  WATER, KEEP, NONLAND = {}, {}, {}
  for name, t in pairs(prototypes.tile) do
    local layers = t.collision_mask.layers
    if layers.water_tile then
      if not layers.player then
        KEEP[#KEEP + 1] = name
        NONLAND[#NONLAND + 1] = name
      elseif t.autoplace_specification then
        WATER[#WATER + 1] = name
        NONLAND[#NONLAND + 1] = name
      end
    end
  end
  table.sort(WATER)
  table.sort(KEEP)
  table.sort(NONLAND)
end

  local gv = guards.geography_of(st.geo)
-- What the handler reads from the save's state; false when the shipped data does not serve it.
local function prepare(st)
  local m = cfg.maps[st.map]
  local masks = tabs and tabs.scales[st.scale]
  if not (masks and m and tabs.shared.width == m.width_px and tabs.shared.height == m.height_px
          and masks.scale == st.scale) then
    log("Terra Nauvis: Exact coastlines has no table for this save's map and scale; the handler stays off")
    return false
  end
  STATE, SHARED, MASKS, MAP = st, tabs.shared, masks, m
  local gv = guards.geography_of(st.geo)
  EDGE = (gv and gv.version and gv.version.edge) and cfg.coast.edge_band.mask_px or 0
  LUT = reach_lut(st.scale)
  THIN = thin_lut(st.scale, LUT)
  tile_lists()
  return true
end

local function register()
  local earth = storage.earth
  local st = earth and earth.bandfix
  if st and prepare(st) then
    script.on_event(defines.events.on_chunk_generated, M.on_chunk_generated)
  end
end

-- The save's band-fix state from its own Nauvis surface: nil unless the key is on and the shipped tables
-- serve its map, scale and geography (config.lua bandfix.tables). The city offset names are those of the
-- save's own geography version (its tn_geo, guards.geography_of), never the newest.
function M.state(surface, earth)
  local pen = surface.map_gen_settings.property_expression_names or {}
  if pen[B.key] ~= B.on then
    return nil
  end
  local key = map_of(earth.map)
  local geo = guards.geography_of(earth.geo)
  local g = key and geo and geo.map == key and geo.version
  local spec = key and (B.tables or {})[key]
  if not (g and spec and tabs and earth.scale and tabs.scales[earth.scale] and listed(spec.geographies, earth.geo)) then
    log("Terra Nauvis: the save carries the Exact coastlines key, but no shipped table serves its map, scale and "
        .. "geography; the handler stays off")
    return nil
  end
  local p = surface.calculate_tile_properties({g.cx, g.cy}, {{0, 0}})
  local cx, cy = p[g.cx] and p[g.cx][1], p[g.cy] and p[g.cy][1]
  if not (cx and cy) then
    log("Terra Nauvis: Exact coastlines could not read the city offset; the handler stays off")
    return nil
  end
  return {surface = surface.index, map = key, scale = earth.scale, geo = earth.geo,
          cx = floor(cx + 1 / 2), cy = floor(cy + 1 / 2)}
end

-- on_init, after guards.on_init has detected an Earth world and filled storage.earth.
function M.on_init()
  local earth = storage.earth
  local surface = game.surfaces["nauvis"]
  if not (earth and surface) then
    return
  end
  earth.bandfix = M.state(surface, earth) or false
  if earth.bandfix then
    log("Terra Nauvis: Exact coastlines on for this save (" .. earth.bandfix.map .. ", scale " ..
        earth.bandfix.scale .. ")")
  end
  register()
end

-- on_load: register again from the saved state; storage is read, never written (on_load must not write it).
function M.on_load()
  register()
end

-- Returns the tiles written (the event system ignores it; the checks' probe counts it).
function M.on_chunk_generated(e)
  if STATE and e.surface.index == STATE.surface then
    return fix_chunk(e.surface, e.position.x, e.position.y)
  end
  return 0
end

-- The tiles one chunk would have written now, without writing them (the checks' recheck: 0 once the
-- handler has run on it). tools/earth_test.py reads it from a staged test copy of the mod.
function M.pending(surface, chx, chy)
  if not STATE then
    return 0
  end
  plan_chunk(surface, chx, chy)
  return NW
end

-- The drift line (on_configuration_changed with changed startup settings): an Earth world keeps its key,
-- so where the setting now bakes something else for this world's map, one info line says so. The setting
-- acts only on the maps bandfix.maps lists; on any other map it changes nothing to report.
function M.on_configuration_changed(data)
  local earth, surface = storage.earth, game.surfaces["nauvis"]
  if not (data.mod_startup_settings_changed and earth and surface) then
    return
  end
  local key = map_of(earth.map)
  if not (key and listed(B.maps, key)) then
    return
  end
  local pen = surface.map_gen_settings.property_expression_names or {}
  local setting = cfg.settings[B.setting].name
  local was = pen[B.key] == B.on
  local now = settings.startup[setting].value == true
    local function state(on)
      return {MSG.section .. "." .. MSG.keys[on and "toggle_on" or "toggle_off"]}
    end
    log(msg)
    game.print(msg)
  end
end

return M
