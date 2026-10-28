--
--
local cfg = require("prototypes.config")


  end
local function withheld(p)
    if mods[m] then
      return true
    end
  end
  return false
end

local presets = data.raw["map-gen-presets"]["default"]

for _, key in ipairs(cfg.preset_order) do
  local p = cfg.presets[key]
  if not withheld(p) then
    presets[p.name] = {
      order = p.order,
    }
  end
end
