-- What the mod reads from the installed game and from other mods at load time, in place of shipping their
-- values or texts (NOTICE.txt, "Read at load time, not shipped").
--
-- Each reading is held to a digest recorded when this version was tested (config.lua and the tables name
-- them; tools/build_installed.py prints them from a dump), so a text that changed since, through a newer
-- game or a newer mod, is seen and logged, and the reader falls back as its caller says. The digest is the
-- palm switch's: two 32-bit FNV-1a hashes, whose constants config.lua tiles.palm.digest holds.
local cfg = require("prototypes.config")

local M = {}
local D = cfg.tiles.palm.digest

local function num(v)
  return string.format(cfg.number_format, v)
end

local function trim(s)
  return (string.match(s, "^%s*(.-)%s*$"))
end

function M.digest(text)
  local out = {}
  for i, base in ipairs(D.bases) do
    local h = base
    for j = 1, #text do
      h = bit32.bxor(h, string.byte(text, j))
      h = (h * D.prime_low + bit32.lshift(h, D.prime_shift)) % D.word
    end
    out[i] = string.format(D.hex, h)
  end
  return table.concat(out)
end

-- A call's named arguments and the order they stand in; nil when one is unnamed or stands twice.
function M.arguments(body)
  local args, order = {}, {}
  for part in string.gmatch(body .. ",", "([^,]*),") do
    local k, v = string.match(part, "^%s*([%a_][%w_]*)%s*=%s*(.-)%s*$")
    if k == nil or args[k] ~= nil then
      return nil
    end
    args[k] = v
    order[#order + 1] = k
  end
  return args, order
end

-- What tells one call from another: every argument but `own`, by name, spaces dropped.
function M.signature(args, own)
  local keys = {}
  for k in pairs(args) do
    if k ~= own then
      keys[#keys + 1] = k
    end
  end
  table.sort(keys)
  local out = {}
  for i, k in ipairs(keys) do
    out[i] = k .. "=" .. (string.gsub(args[k], "%s+", ""))
  end
  return table.concat(out, ",")
end

-- Every call of `fn` in a text that nests no other call: visit(body).
local function calls(text, fn, visit)
  local open, pos = fn .. "{", 1
  while true do
    local s, e = string.find(text, open, pos, true)
    local close = s and string.find(text, "}", e + 1, true)
    if not close then
      break
    end
    local body = string.sub(text, e + 1, close - 1)
    if not (s > 1 and string.find(string.sub(text, s - 1, s - 1), "[%w_]")) and not string.find(body, "{", 1, true) then
      visit(body)
    end
    pos = e + 1
  end
end

-- The noise call of the land tiles' own scores (config.lua tiles.noise_share): of the calls of C.fn with a
-- whole-number C.own in the probability expressions of the tiles named by `prefixes`, grouped by signature, the
-- group the most tiles hold, each exactly once. Other tiles under the same prefixes (an expansion's, another mod's)
-- hold no such call and do not count against it. Returns {args, order, signature}, or nil and why: no tile, no
-- such group, two groups as large, or a signature whose digest is not C.digest.
function M.tile_noise(tiles, prefixes, C)
  local names = {}
  for name, tile in pairs(tiles or {}) do
    if type(tile.autoplace and tile.autoplace.probability_expression) == "string" then
      for _, p in ipairs(prefixes) do
        if string.sub(name, 1, #p) == p then
          names[#names + 1] = name
          break
        end
      end
    end
  end
  if #names == 0 then
    return nil, "no land tile to read"
  end
  table.sort(names)
  local held, first = {}, {}
  for _, name in ipairs(names) do
    local seen = {}
    calls(tiles[name].autoplace.probability_expression, C.fn, function(body)
      local args, order = M.arguments(body)
      if args and args[C.own] and string.match(args[C.own], "^%d+$") then
        local signature = M.signature(args, C.own)
        seen[signature] = (seen[signature] or 0) + 1
        first[signature] = first[signature] or {args = args, order = order, signature = signature}
      end
    end)
    for signature, n in pairs(seen) do
      -- a tile that holds the call twice takes the group out for good
      held[signature] = (held[signature] or 0) + (n == 1 and 1 or #names + 1)
    end
  end
  local found, most, tied = nil, 0, false
  for signature, n in pairs(held) do
    if n <= #names and n > most then
      found, most, tied = first[signature], n, false
    elseif n == most then
      tied = true
    end
  end
  if not found or tied then
    return nil, "no one call stands once in most of the " .. #names .. " tiles"
  end
  local digest = M.digest(found.signature)
  if digest ~= C.digest then
    return nil, "its arguments read " .. digest .. ", this version knows " .. C.digest
  end
  return found
end

-- A named noise expression's text as installed (`expressions` is data.raw["noise-expression"]), and whether it is
-- the text `digest` was taken from; nil where the installed game has no text under the name.
function M.expression(expressions, name, digest)
  local proto = (expressions or {})[name]
  local text = proto and proto.expression
  if type(text) ~= "string" then
    return nil
  end
  return text, M.digest(text) == digest
end

-- An argument as the mod prints it: a number through the number format, numbers divided in turn as the first
-- over the product of the rest, anything else as it stands.
local function value(v)
  local parts = {}
  for part in string.gmatch(v, "[^/]+") do
    local n = tonumber(trim(part))
    if n == nil then
      return trim(v)
    end
    parts[#parts + 1] = n
  end
  if #parts == 0 then
    return trim(v)
  end
  local divisor = 1
  for i = 2, #parts do
    divisor = divisor * parts[i]
  end
  return num(parts[1]) .. (#parts > 1 and (" / " .. num(divisor)) or "")
end

-- The found call as this mod's text, its arguments in the order they stood, with `seed` for C.own.
function M.call_text(found, C, seed)
  local parts = {}
  for i, k in ipairs(found.order) do
    parts[i] = k .. " = " .. (k == C.own and num(seed) or value(found.args[k]))
  end
  return C.fn .. "{" .. table.concat(parts, ", ") .. "}"
end

-- A read call {fn, args, order} as this mod's text: each argument as it stood, or what `own` makes of it.
function M.render(call, own)
  local parts = {}
  for i, k in ipairs(call.order) do
    parts[i] = k .. " = " .. (own[k] and own[k](call.args[k]) or value(call.args[k]))
  end
  return call.fn .. "{" .. table.concat(parts, ", ") .. "}"
end

-- `text` cut at the commas that stand outside every bracket.
local function split(text)
  local parts, depth, start = {}, 0, 1
  for i = 1, #text do
    local c = string.sub(text, i, i)
    if c == "(" or c == "{" then
      depth = depth + 1
    elseif c == ")" or c == "}" then
      depth = depth - 1
    elseif c == "," and depth == 0 then
      parts[#parts + 1] = string.sub(text, start, i - 1)
      start = i + 1
    end
  end
  parts[#parts + 1] = string.sub(text, start)
  return parts
end

-- A whole call, name{arguments}, whose values may hold brackets, as {fn, args, order}; nil for anything else.
local function whole_call(text)
  local fn, body = string.match(text, "^%s*([%a_][%w_]*){(.*)}%s*$")
  if not fn then
    return nil
  end
  local args, order = {}, {}
  for _, part in ipairs(split(body)) do
    local k, v = string.match(part, "^%s*([%a_][%w_]*)%s*=%s*(.-)%s*$")
    if k == nil or args[k] ~= nil then
      return nil
    end
    args[k] = v
    order[#order + 1] = k
  end
  return {fn = fn, args = args, order = order}
end

-- A number, or numbers divided in turn, as one number; nil for anything else.
local function quotient(v)
  local q
  for part in string.gmatch(v, "[^/]+") do
    local n = tonumber(trim(part))
    if n == nil then
      return nil
    end
    q = q and q / n or n
  end
  return q
end

local function sorted_keys(t)
  local keys = {}
  for k in pairs(t) do
    keys[#keys + 1] = k
  end
  table.sort(keys)
  return keys
end

-- What the digest of the enemy base expression reads: its text, its local expressions by name, and the texture
-- function's parameters and text (tools/build_installed.py enemy_text writes the same lines).
local function enemy_text(proto, texture)
  local lines = {"e " .. proto.expression}
  for _, k in ipairs(sorted_keys(proto.local_expressions)) do
    lines[#lines + 1] = "l " .. k .. " " .. tostring(proto.local_expressions[k])
  end
  lines[#lines + 1] = "f " .. table.concat(texture.parameters, ",")
  lines[#lines + 1] = "e " .. texture.expression
  return table.concat(lines, "\n")
end

-- The texture terms that follow the spot call: every call of the texture function with its arguments as plain
-- numbers, the first argument of each in `scales`, and the last added term that opens with C.start.
local function enemy_texture(tail, C)
  local scales, plain = {}, true
  local texture = string.gsub(tail, C.texture .. "%(([^(),]+),%s*([^(),]+)%)", function(a, b)
    local scale, gain = quotient(a), quotient(b)
    if not (scale and gain) then
      plain = false
      return nil
    end
    scales[#scales + 1] = scale
    return C.texture .. "(" .. num(scale) .. ", " .. num(gain) .. ")"
  end)
  local start = string.match(tail, "^.*( %+ " .. C.start .. "%(.*)$")
  if not (plain and start and #scales > 0) then
    return nil
  end
  return texture, scales, start
end

-- The spot call a text opens with and the terms added after it, or nil for any other shape.
local function enemy_spot(text, C)
  local close = string.find(text, "}", 1, true)
  local spot = close and whole_call(string.sub(text, 1, close))
  local tail = close and string.match(string.sub(text, close + 1), "^%s*%+%s*(.+)$")
  if not (spot and spot.fn == C.fn and spot.args[C.basement] and tail) then
    return nil
  end
  return spot, tail
end

-- The texture function's call and a copy of its parameters, or nil where it is no call with a C.own.
local function enemy_noise(texture, C)
  local noise = whole_call(texture.expression)
  if not (noise and noise.args[C.own]) then
    return nil
  end
  local parameters = {}
  for i, p in ipairs(texture.parameters) do
    parameters[i] = p
  end
  return noise, parameters
end

-- The base game's enemy base expression (config.lua enemies.base) in the parts the enemy layer is built from
-- (expressions/enemies.lua): the spot call it opens with, the texture terms added to it, the two local expressions
-- and the texture function. Returns the parts, with `known` saying whether the installed text is the one
-- C.digest was taken from, or nil and why where the expression has not that shape.
function M.enemy_base(expressions, C)
  local proto = (expressions or {})[C.name]
  local locals, texture = proto and proto.local_expressions, proto and (proto.local_functions or {})[C.texture]
  if not (proto and type(proto.expression) == "string" and locals and texture and texture.parameters and
          type(texture.expression) == "string") then
    return nil, "the installed " .. C.name .. " lacks a text, local expressions or the function " .. C.texture
  end
  local spot, tail = enemy_spot(proto.expression, C)
  local noise, parameters = enemy_noise(texture, C)
  local radius, quantity = locals[C.radius], locals[C.quantity]
  if not (spot and noise and type(radius) == "string" and type(quantity) == "string") then
    return nil, "the installed " .. C.name .. " is not a " .. C.fn .. " call plus texture terms"
  end
  local terms, scales, start = enemy_texture(tail, C)
  if not terms then
    return nil, "the installed " .. C.name .. "'s texture terms are not calls of " .. C.texture .. " on plain numbers"
  end
  return {
    known = M.digest(enemy_text(proto, texture)) == C.digest,
    spot = spot, texture = terms, scales = scales, start = start, basement = value(spot.args[C.basement]),
    radius = radius,
    -- a leading pi over a number as pi times its inverse, as the mod prints a factor
    quantity = (string.gsub(quantity, "^pi%s*/%s*([%d.]+)", function(n)
      return "pi * " .. num(1 / tonumber(n))
    end)),
    noise = noise, parameters = parameters,
  }
end

return M
