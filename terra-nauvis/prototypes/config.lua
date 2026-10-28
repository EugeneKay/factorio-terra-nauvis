-- Terra Nauvis: the single source of names and constants (ARCHITECTURE.md, "Module map").
--
-- Pure data: this file reads no data, settings, game or script and calls no function, so the
-- settings, data and control stages (through require) and the Python tools (tools/tnconfig.py,
-- through luaparser) all read this one file. Every name the mod defines derives from ID or NOISE,
-- so renaming the mod is an edit here. No other Lua file spells an Earth name or a map
-- coordinate (the static name scan and the design rules check it).

local ID = "terra-nauvis"
local NOISE = "tn_"

return {
  identity = {
    id = ID,
    title = "Terra Nauvis",
    author = "Jake Mismas",
    factorio_version = "2.1",
    setting_prefix = ID .. "-",
    noise_prefix = NOISE,
  },

  -- Reference-pixel conventions, mirrored by tools/earthgeo.py: plate carree at
  -- px_per_degree; pixel (col, row) spans [col, col + 1) with its centre at
  -- lon = lon_left_edge + (col + 0.5) / px_per_degree and lat = lat_top_edge - (row + 0.5) / px_per_degree.
  coordinates = {
    px_per_degree = 45,
    origin = "floor",
    corner_offset_divisor = 2,
  },

  -- The one number formatter every expression string uses, so the text is byte-stable.
  number_format = "%.9g",

  -- EarthMaps reference rasters (data-src/earthmaps/<key>.json): size, EarthMaps radii and edges.
  maps = {
    europe = {
      width_px = 2400, height_px = 1704, wr = 1200, hr = 852,
      lon_left_edge = -11.0222, lat_top_edge = 71.9333,
    },
    atlantic = {
      width_px = 15689, height_px = 6524, wr = 7844, hr = 3262,
      lon_left_edge = -168.6444, lat_top_edge = 87.1778,
    },
    olde_world = {
      width_px = 8963, height_px = 5847, wr = 4481, hr = 2923,
      lon_left_edge = -19.1778, lat_top_edge = 82.0889,
    },
  },
  map_order = {"europe", "atlantic", "olde_world"},


  -- Mod settings. Values are short ASCII tokens, so labels can change without invalidating stored
  settings = {
    scale = {
      name = ID .. "-scale", type = "string-setting", setting_type = "startup",
    },
  },

  -- Map-gen presets, sorted right after Default ("a") and before Rich resources ("b").
  presets = {
  },

  --
  },





  -- Toggles, keyed like settings: key -> {setting = <settings key>, preset_key = <key>, default,
  -- mechanism = "name switch" or "hook gate", on = <name>, off = <name>, maps = {<map keys>}};
}
