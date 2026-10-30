-- Terra Nauvis: the single source of names and constants (ARCHITECTURE.md, "Module map").
--
-- Pure data: this file reads no data, settings, game or script and calls no function, so the
-- settings, data and control stages (through require) and the Python tools (tools/tnconfig.py,
-- through luaparser) all read this one file. Every name the mod defines derives from ID or NOISE,
-- so renaming the mod is an edit here. No other Lua file spells an Earth name or a map
-- coordinate (the static name scan and the design rules check it).

local ID = "terra-nauvis"
local NOISE = "tn_"

-- Per-save keys every Earth preset bakes (ARCHITECTURE.md, "Preset redirects"). tn_map and tn_geo
-- have no prototype: a preset world that lacks one fails loudly instead of drifting, and
-- control code reads them from the surface. tn_scale is read by every map's elevation entry, so it
-- also has a prototype-level fallback (the Map type route); tn_land_coarse is a preset key only.
local K_MAP = NOISE .. "map"
local K_SCALE = NOISE .. "scale"
local K_GEO = NOISE .. "geo"
local K_LAND_COARSE = NOISE .. "land_coarse"
-- spawn-cities: the keys the shared start mask v2 reads, which each Earth preset maps to its map's
-- spawn lake and starting-ore bias (preset keys only, like tn_land_coarse).
local K_SPAWN_LAKE = NOISE .. "spawn_lake"
local K_SPAWN_BIAS = NOISE .. "spawn_bias"

-- The generated files (tools/build_geo.py): name-free data that a geography version's fit bodies
-- bind to its own chain, so a later version binds the same files instead of emitting new ones.
local EU_GEO_FILE = "prototypes/generated/geo_europe_v1.lua"
local EU_LAND_COARSE_FILE = "prototypes/generated/land_coarse_europe_v1.lua"
local AT_LAND_COARSE_FILE = "prototypes/generated/land_coarse_atlantic_v1.lua"
local OW_LAND_COARSE_FILE = "prototypes/generated/land_coarse_olde_world_v1.lua"

-- The spawn bodies (spawn.lua). The city number is a map-qualified per-save number that mirrors the
-- map's spawn-city setting (0 random, k the k-th city of the setting); the fold turns it, or the
-- folded hash of map_seed, into the resolved index control reads back at (0, 0) and the tile offset
-- of the city's pixel centre. The inland lakes read the version's chain, so each version that has
-- them takes its own; the other spawn bodies read no chain and serve every version that names them.
local EU_CITY = NOISE .. "city_europe"
local EU_CITY_INDEX = NOISE .. "city_index_europe_v1"
local EU_CITY_CX = NOISE .. "city_cx_europe_v1"
local EU_CITY_CY = NOISE .. "city_cy_europe_v1"
local START_LAND = NOISE .. "start_land_v1"
local DISTANCE = NOISE .. "distance_v1"
-- The spawn bearings per city and scale (tools/build_spawn.py): name-free data.
local EU_SPAWN_FILE = "prototypes/generated/spawn_europe_v1.lua"

local START_MASK2 = NOISE .. "start_mask_v2"

-- rivers, straits and turning basins (ww), canals, dams and fords, name-free data that waterways.lua
-- binds to the chain of the geography version that composes them. The hook gate tn_on, the ford key
-- tn_fords and the canals switch tn_canals are shared keys; tn_one and tn_zero are the switch's
-- neutral bodies.
local K_ON = NOISE .. "on"
local K_FORDS = NOISE .. "fords"
local K_CANALS = NOISE .. "canals"
local ONE = NOISE .. "one"
local ZERO = NOISE .. "zero"
local EU_WW_FILES = {"prototypes/generated/waterways_europe_s1_v1.lua",
                     "prototypes/generated/waterways_europe_s2_v1.lua",
                     "prototypes/generated/waterways_europe_s3_v1.lua",
                     "prototypes/generated/waterways_europe_s4_v1.lua",
                     "prototypes/generated/waterways_europe_s5_v1.lua",
                     "prototypes/generated/waterways_europe_s6_v1.lua"}

-- fixed names; a row's own names come from the row name stems below and the row's id.
local RG_V = "_v1"
local RG_DESTROYED_SD = NOISE .. "destroyed_sd" .. RG_V
local RG_DESTROYED_W = NOISE .. "destroyed_w" .. RG_V
local RG_DESTROYED_DEPTH = NOISE .. "destroyed_depth" .. RG_V
local RG_FOREST_W = NOISE .. "forest_w" .. RG_V
local RG_FOREST_SUM = NOISE .. "forest_sum" .. RG_V
local RG_TREE_MULT = NOISE .. "tree_mult" .. RG_V
local RG_MARSH_W = NOISE .. "marsh_w" .. RG_V
local RG_HOTSPOT_W = NOISE .. "hotspot_w" .. RG_V
local RG_ENEMY_MULT = NOISE .. "enemy_mult" .. RG_V
local RG_U = NOISE .. "region_u"
local RG_V_ = NOISE .. "region_v"
local RG_OX = NOISE .. "region_ox" .. RG_V
local RG_OY = NOISE .. "region_oy" .. RG_V
local RG_AX = NOISE .. "region_ax" .. RG_V
local RG_AY = NOISE .. "region_ay" .. RG_V
local RG_WK = NOISE .. "region_wk" .. RG_V
local RG_WX = NOISE .. "region_wx" .. RG_V
local RG_WY = NOISE .. "region_wy" .. RG_V
local RG_ROUGH = NOISE .. "region_rough" .. RG_V

-- The Earth climate: latitude and longitude on the map's chain, the dry belts, the temperature core and
-- the Alien Biomes and fallback variants the presets redirect temperature, moisture and aux to.

-- The tile hooks: one key per restored vanilla land tile (prototype -inf), all pointed by the presets at
-- one shared bonus body; the Alien Biomes exclusion key (prototype 0) and its body; the marsh keys
-- (prototype -inf) and their bodies; the palm constant and the Earth copies of AB's palm autoplace.
-- climate-tiles' names (one table: Lua allows 200 locals in config.lua's main function)
local CT = {
  CL_LAT = NOISE .. "lat_v1",
  CL_LON = NOISE .. "lon_v1",
  CL_DRY = NOISE .. "dry_v1",
  CL_CORE = NOISE .. "t_core_v1",
  CL_T_AB = NOISE .. "temperature_ab_v1",
  CL_M_AB = NOISE .. "moisture_ab_v1",
  CL_A_AB = NOISE .. "aux_ab_v1",
  CL_T_FB = NOISE .. "temperature_fb_v1",
  CL_M_FB = NOISE .. "moisture_fb_v1",
  CL_A_FB = NOISE .. "aux_fb_v1",
  VT_GRASS_1 = NOISE .. "vtile_grass_1",
  VT_GRASS_2 = NOISE .. "vtile_grass_2",
  VT_GRASS_3 = NOISE .. "vtile_grass_3",
  VT_GRASS_4 = NOISE .. "vtile_grass_4",
  VT_DRY_DIRT = NOISE .. "vtile_dry_dirt",
  VT_DIRT_1 = NOISE .. "vtile_dirt_1",
  VT_DIRT_2 = NOISE .. "vtile_dirt_2",
  VT_DIRT_3 = NOISE .. "vtile_dirt_3",
  VT_DIRT_4 = NOISE .. "vtile_dirt_4",
  VT_DIRT_5 = NOISE .. "vtile_dirt_5",
  VT_DIRT_6 = NOISE .. "vtile_dirt_6",
  VT_DIRT_7 = NOISE .. "vtile_dirt_7",
  VT_SAND_1 = NOISE .. "vtile_sand_1",
  VT_SAND_2 = NOISE .. "vtile_sand_2",
  VT_SAND_3 = NOISE .. "vtile_sand_3",
  VT_RED_0 = NOISE .. "vtile_red_desert_0",
  VT_RED_1 = NOISE .. "vtile_red_desert_1",
  VT_RED_2 = NOISE .. "vtile_red_desert_2",
  VT_RED_3 = NOISE .. "vtile_red_desert_3",
  VT_BONUS = NOISE .. "vtile_bonus_v1",
  AB_EXCLUDE = NOISE .. "ab_exclude",
  AB_EXCLUDE_BODY = NOISE .. "ab_exclude_v1",
  MARSH_MUD = NOISE .. "marsh_water_mud",
  MARSH_MUD_BODY = NOISE .. "marsh_water_mud_v1",
  MARSH_SHALLOW = NOISE .. "marsh_water_shallow",
  MARSH_SHALLOW_BODY = NOISE .. "marsh_water_shallow_v1",
  MARSH_GRASS = NOISE .. "marsh_grass",
  MARSH_GRASS_BODY = NOISE .. "marsh_grass_v1",
  PALM_CONST = NOISE .. "palm_const_v1",
  PALM_A_P = NOISE .. "palm_a_p_v1",
  PALM_A_R = NOISE .. "palm_a_r_v1",
  PALM_B_P = NOISE .. "palm_b_p_v1",
  PALM_B_R = NOISE .. "palm_b_r_v1",
  PALM_A_P_KEY = "entity:tree-palm-a:probability",
  PALM_A_R_KEY = "entity:tree-palm-a:richness",
  PALM_B_P_KEY = "entity:tree-palm-b:probability",
  PALM_B_R_KEY = "entity:tree-palm-b:richness",
}

-- 0 by the setting) and the multiplier key (prototype 1; Earth presets name the region layer's
-- multiplier) of the boost hook on every living tree; the vanilla-scale temperature the restored vanilla
-- trees read; per restored vanilla tree a probability and a richness key (prototype 0) and its Earth
-- body, every richness key naming one shared body; per rebuilt vanilla rock or decal a key (prototype 0)
-- and its body; per re-listed vanilla decorative a key (prototype -inf), all naming one shared body; and
-- the palms' second probability versions, which take the boost around climate-tiles' registered copies.
-- trees-forests' single names (one table: the 200-local limit)
local TFN = {
  K_FORESTS_ON = NOISE .. "forests_on",
  K_TREE_MULT = NOISE .. "tree_mult",
  TF_VTEMP = NOISE .. "temperature_vanilla_v1",
  TF_VTREE_R = NOISE .. "vtree_r_v1",
  TF_VDECO = NOISE .. "vdeco_v1",
  PALM_A_P2 = NOISE .. "palm_a_p_v2",
  PALM_B_P2 = NOISE .. "palm_b_p_v2",
}
local VT = NOISE .. "vtree_"
local TF_TREES = {
  ["tree-01"] = {p = VT .. "tree_01_p", r = VT .. "tree_01_r", body = VT .. "tree_01_p_v1"},
  ["tree-02"] = {p = VT .. "tree_02_p", r = VT .. "tree_02_r", body = VT .. "tree_02_p_v1"},
  ["tree-02-red"] = {p = VT .. "tree_02_red_p", r = VT .. "tree_02_red_r", body = VT .. "tree_02_red_p_v1"},
  ["tree-03"] = {p = VT .. "tree_03_p", r = VT .. "tree_03_r", body = VT .. "tree_03_p_v1"},
  ["tree-04"] = {p = VT .. "tree_04_p", r = VT .. "tree_04_r", body = VT .. "tree_04_p_v1"},
  ["tree-05"] = {p = VT .. "tree_05_p", r = VT .. "tree_05_r", body = VT .. "tree_05_p_v1"},
  ["tree-06"] = {p = VT .. "tree_06_p", r = VT .. "tree_06_r", body = VT .. "tree_06_p_v1"},
  ["tree-06-brown"] = {p = VT .. "tree_06_brown_p", r = VT .. "tree_06_brown_r", body = VT .. "tree_06_brown_p_v1"},
  ["tree-07"] = {p = VT .. "tree_07_p", r = VT .. "tree_07_r", body = VT .. "tree_07_p_v1"},
  ["tree-08"] = {p = VT .. "tree_08_p", r = VT .. "tree_08_r", body = VT .. "tree_08_p_v1"},
  ["tree-08-brown"] = {p = VT .. "tree_08_brown_p", r = VT .. "tree_08_brown_r", body = VT .. "tree_08_brown_p_v1"},
  ["tree-08-red"] = {p = VT .. "tree_08_red_p", r = VT .. "tree_08_red_r", body = VT .. "tree_08_red_p_v1"},
  ["tree-09"] = {p = VT .. "tree_09_p", r = VT .. "tree_09_r", body = VT .. "tree_09_p_v1"},
  ["tree-09-brown"] = {p = VT .. "tree_09_brown_p", r = VT .. "tree_09_brown_r", body = VT .. "tree_09_brown_p_v1"},
  ["tree-09-red"] = {p = VT .. "tree_09_red_p", r = VT .. "tree_09_red_r", body = VT .. "tree_09_red_p_v1"},
}
local VR = NOISE .. "vrock_"
local TF_ROCKS = {
  ["medium-rock"] = {key = VR .. "medium_rock", body = VR .. "medium_rock_v1"},
  ["small-rock"] = {key = VR .. "small_rock", body = VR .. "small_rock_v1"},
  ["tiny-rock"] = {key = VR .. "tiny_rock", body = VR .. "tiny_rock_v1"},
}
local VD = NOISE .. "vdeco_"
local TF_DECO = {
  ["light-mud-decal"] = VD .. "light_mud_decal", ["green-asterisk"] = VD .. "green_asterisk",
  ["green-asterisk-mini"] = VD .. "green_asterisk_mini", ["green-bush-mini"] = VD .. "green_bush_mini",
  ["green-carpet-grass"] = VD .. "green_carpet_grass", ["green-croton"] = VD .. "green_croton",
  ["green-desert-bush"] = VD .. "green_desert_bush", ["green-hairy-grass"] = VD .. "green_hairy_grass",
  ["green-pita"] = VD .. "green_pita", ["green-pita-mini"] = VD .. "green_pita_mini",
  ["green-small-grass"] = VD .. "green_small_grass",
}

-- switch to waterways' neutral bodies tn_one and tn_zero (the canals switch reads the same pair); the
-- per-map keys tn_crest and tn_openings name the map's crest distance and openings bodies, so the
-- cliff properties, the effective crest distance, the ridge-free start disc, the ore clearance and
-- the ore wrappers are one body each on every map.
local RD_V = "_v1"
local ORE = NOISE .. "ore_"
-- ridges' names (one table: the 200-local limit)
local RDN = {
  K_RIDGES = NOISE .. "ridges",
  K_CREST = NOISE .. "crest",
  K_OPENINGS = NOISE .. "openings",
  K_BAND = NOISE .. "band",
  RD_FREE = NOISE .. "ridge_free" .. RD_V,
  RD_CLIFFINESS = NOISE .. "cliffiness" .. RD_V,
  RD_CLEAR = NOISE .. "ridge_clear" .. RD_V,
  EU_BAND = NOISE .. "band_europe" .. RD_V,
  AT_BAND = NOISE .. "band_atlantic" .. RD_V,
  OW_BAND = NOISE .. "band_olde_world" .. RD_V,
  ORE_IRON = ORE .. "iron_ore_p" .. RD_V,
  ORE_COPPER = ORE .. "copper_ore_p" .. RD_V,
  ORE_COAL = ORE .. "coal_p" .. RD_V,
  ORE_STONE = ORE .. "stone_p" .. RD_V,
  ORE_URANIUM = ORE .. "uranium_ore_p" .. RD_V,
  ORE_OIL = ORE .. "crude_oil_p" .. RD_V,
}

-- The hotspots toggle tn_hotspots is a name switch to tn_one and tn_zero, read by the Entity bodies
-- through a folded `if`; each map's elevation entry reads its offshore stamp through the map-qualified
-- key tn_fields_<map>, a Map type fallback, so the entry stays a Map type entry (ARCHITECTURE.md,
-- "Map type entries"). Every hotspot body reads the region layer's rows and tn_land_coarse only.
local RE_V = "_v1"
local HS = NOISE .. "hs_"
-- The wrappers of the pack's live autoplace, built in data-final-fixes.lua: the ore probability
-- wrappers' next version (ridges' _v1 stay defined), the richness wrappers, the enemy wrapper and,
-- with the Oil Rig loaded, its offshore-oil wrappers.
-- Each map's offshore field stamp (Tile only, a firewall body) and the map-qualified key its
-- elevation entry reads it through; the entry's next version wraps the previous one in the stamp.

-- resources-enemies' names (one table: the 200-local limit)
local REN = {
  K_HOTSPOTS = NOISE .. "hotspots",
  HS_BLOB = HS .. "blob" .. RE_V,
  HS_IRON = HS .. "iron_ore" .. RE_V,
  HS_IRON_P = HS .. "iron_ore_p" .. RE_V,
  HS_IRON_R = HS .. "iron_ore_r" .. RE_V,
  HS_COPPER = HS .. "copper_ore" .. RE_V,
  HS_COPPER_P = HS .. "copper_ore_p" .. RE_V,
  HS_COPPER_R = HS .. "copper_ore_r" .. RE_V,
  HS_COAL = HS .. "coal" .. RE_V,
  HS_COAL_P = HS .. "coal_p" .. RE_V,
  HS_COAL_R = HS .. "coal_r" .. RE_V,
  HS_STONE = HS .. "stone" .. RE_V,
  HS_STONE_P = HS .. "stone_p" .. RE_V,
  HS_STONE_R = HS .. "stone_r" .. RE_V,
  HS_URANIUM = HS .. "uranium_ore" .. RE_V,
  HS_URANIUM_P = HS .. "uranium_ore_p" .. RE_V,
  HS_URANIUM_R = HS .. "uranium_ore_r" .. RE_V,
  HS_OIL = HS .. "crude_oil" .. RE_V,
  HS_OIL_P = HS .. "crude_oil_p" .. RE_V,
  HS_OIL_R = HS .. "crude_oil_r" .. RE_V,
  HS_OFFSHORE = HS .. "offshore_oil" .. RE_V,
  HS_OFFSHORE_P = HS .. "offshore_oil_p" .. RE_V,
  HS_OFFSHORE_R = HS .. "offshore_oil_r" .. RE_V,
  RAMP = NOISE .. "ore_ramp" .. RE_V,
  SEA = NOISE .. "sea" .. RE_V,
  ENEMY_LAYER = NOISE .. "enemy_layer" .. RE_V,
  ENEMY = NOISE .. "enemy" .. RE_V,
  ORE_IRON_P2 = ORE .. "iron_ore_p_v2",
  ORE_IRON_R = ORE .. "iron_ore_r" .. RE_V,
  ORE_COPPER_P2 = ORE .. "copper_ore_p_v2",
  ORE_COPPER_R = ORE .. "copper_ore_r" .. RE_V,
  ORE_COAL_P2 = ORE .. "coal_p_v2",
  ORE_COAL_R = ORE .. "coal_r" .. RE_V,
  ORE_STONE_P2 = ORE .. "stone_p_v2",
  ORE_STONE_R = ORE .. "stone_r" .. RE_V,
  ORE_URANIUM_P2 = ORE .. "uranium_ore_p_v2",
  ORE_URANIUM_R = ORE .. "uranium_ore_r" .. RE_V,
  ORE_OIL_P2 = ORE .. "crude_oil_p_v2",
  ORE_OIL_R = ORE .. "crude_oil_r" .. RE_V,
  OFFSHORE_P = NOISE .. "offshore_p" .. RE_V,
  OFFSHORE_R = NOISE .. "offshore_r" .. RE_V,
  EU_FIELDS_KEY = NOISE .. "fields_europe",
  EU_FIELDS = NOISE .. "fields_europe" .. RE_V,
  AT_FIELDS_KEY = NOISE .. "fields_atlantic",
  AT_FIELDS = NOISE .. "fields_atlantic" .. RE_V,
  OW_FIELDS_KEY = NOISE .. "fields_olde_world",
  OW_FIELDS = NOISE .. "fields_olde_world" .. RE_V,
}

-- edge-and-lakes' names (one table: the 200-local limit)
local ELN = {
  K_INLAND_LAKES = NOISE .. "inland_lakes",
  EU6_GX = NOISE .. "gx_europe_v6",
  EU6_GY = NOISE .. "gy_europe_v6",
  EU6_U = NOISE .. "u_europe_v6",
  EU6_V = NOISE .. "v_europe_v6",
  EU6_CX = NOISE .. "cx_europe_v6",
  EU6_CY = NOISE .. "cy_europe_v6",
}
-- is a name switch to tn_one and tn_zero, baked on only when its setting is on and Alien Biomes is loaded
-- (without Alien Biomes the switch drops at the data stage). The key (K) and the bodies, one table so this
-- file stays under Lua's 200 locals per function: the zone (the region layer's zone depth cut by the start
-- disc), its heat, the next version of climate-tiles' Alien Biomes temperature, which lifts the zone above
-- 100, and per map with a city fold the random pick over the cities outside the zone.
local DE = {
  K = NOISE .. "destroyed",
  zone = NOISE .. "destroyed_zone_v1",
  heat = NOISE .. "destroyed_heat_v1",
  temperature = NOISE .. "temperature_ab_v2",
  pool_europe = NOISE .. "city_pool_europe_v1",
}

-- neutral body tn_one, only when the startup setting is on and that map passed all four flip checks
-- the destroyed-europe names are (Lua's 200 locals per function).
local BFN = {
  K = NOISE .. "bandfix",
}

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
  -- At scale s, tile t samples pixel floor(t / s + wr) (the floor origin). The integer-corner
  -- offset is floor(s / corner_offset_divisor) tiles: the coordinate chain reads the fit at
  -- u = (gx - floor(s / 2)) / s + wr, so the tile holding a pixel centre, evaluated at its integer
  -- corner, reads the fit exactly at that centre at every integer scale (the coordinate tests prove it
  -- at scales 1, 3 and 6 against a test build without it). This is the one copy of the
  -- constant; tools/earthgeo.py reads it from here.
  coordinates = {
    px_per_degree = 45,
    origin = "floor",
    corner_offset_divisor = 2,
  },

  -- The one number formatter every expression string uses, so the text is byte-stable.
  number_format = "%.9g",

  -- EarthMaps reference rasters (data-src/earthmaps/<key>.json): size, EarthMaps radii and edges.
  -- id is the map's tn_map value (control code reads the map from it): a positive integer, one per
  -- map, never reused or changed once landed, because saves hold it (tnconfig's id-space check and
  -- the static append-only check against main and origin/main; ARCHITECTURE.md, "Release versioning
  -- policy", rule 4).
  maps = {
    europe = {
      key = "europe", id = 1, setting_key = "europe", display = "Europe",
      width_px = 2400, height_px = 1704, wr = 1200, hr = 852,
      lon_left_edge = -11.0222, lat_top_edge = 71.9333,
    },
    atlantic = {
      key = "atlantic", id = 2, setting_key = "atlantic", display = "Atlantic",
      width_px = 15689, height_px = 6524, wr = 7844, hr = 3262,
      lon_left_edge = -168.6444, lat_top_edge = 87.1778,
    },
    olde_world = {
      key = "olde_world", id = 3, setting_key = "old-world", display = "Old World",
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
    -- The spawn city per map (default random; Luxembourg is not offered):
    -- "random", then every city of the map's table in prototypes/tables/cities.lua. A value's
    -- position gives the per-save number the preset bakes (random 0, the first city 1), so this
    -- order is the fold's order and never changes once landed (saves hold the number).
    spawn_city_europe = {
      name = ID .. "-spawn-city-europe", type = "string-setting", setting_type = "startup",
      default_value = "random",
      allowed_values = {
        "random", "tirana", "andorra-la-vella", "vienna", "minsk", "brussels", "sarajevo", "sofia", "zagreb",
        "prague", "tallinn", "helsinki", "paris", "berlin", "athens", "budapest", "rome", "pristina", "riga",
        "vaduz", "vilnius", "chisinau", "monaco", "podgorica", "amsterdam", "skopje", "oslo", "warsaw",
        "lisbon", "bucharest", "moscow", "san-marino", "belgrade", "bratislava", "ljubljana", "madrid",
        "stockholm", "bern", "ankara", "kyiv", "london",
      },
      order = "b-a",
    },
    spawn_city_atlantic = {
      name = ID .. "-spawn-city-atlantic", type = "string-setting", setting_type = "startup",
      default_value = "random",
      allowed_values = {
        "random", "prague", "madrid", "london", "kovdor", "munguy", "xeta", "yakutia", "zyryanka", "kharkiv",
        "huambo", "mongo", "dangila", "bamako", "akka", "waddan", "johannesburg", "songea", "tabuk", "chengdu",
        "nanchang", "songling", "delhi", "hampi", "bam", "aktobe", "semey", "moron", "bangkok", "mexico-city",
        "ellesmere-island", "fort-liard", "hearst", "mid-baffin", "okak", "saskatoon", "yellowknife", "qaanaaq",
        "summit-camp", "uranienborg", "albany", "boise", "minneapolis", "el-paso", "hughes", "montgomery", "cordoba",
        "palmas", "iquitos", "griffith", "newman",
      },
      order = "b-b",
    },
    spawn_city_olde_world = {
      name = ID .. "-spawn-city-old-world", type = "string-setting", setting_type = "startup",
      default_value = "random",
      allowed_values = {
        "random", "prague", "madrid", "london", "kovdor", "munguy", "xeta", "yakutia", "zyryanka", "kharkiv",
        "huambo", "mongo", "dangila", "bamako", "akka", "waddan", "johannesburg", "songea", "tabuk", "chengdu",
        "nanchang", "songling", "delhi", "hampi", "bam", "aktobe", "semey", "moron", "bangkok", "griffith", "newman",
      },
      order = "b-c",
    },
    -- Old World and Atlantic, Panama on Atlantic, open at max(7, scale) tiles; off keeps every
    -- isthmus closed, the drawn leaks under a dam. Baked per save through the toggle tn_canals.
    canals = {
      name = ID .. "-canals", type = "bool-setting", setting_type = "startup", default_value = true, order = "c-d",
    },
    -- the region layer hold about twice the trees of the land around them. Baked per save through the hook
    -- gate tn_forests_on.
    great_forests = {
      name = ID .. "-great-forests", type = "bool-setting", setting_type = "startup", default_value = true,
    },
    -- rail-width passes, the only cliffs on a Terra Nauvis world. Baked per save through the toggle
    -- tn_ridges; off gives 0 cliffs (a constant crest distance places none).
    ridges = {
      name = ID .. "-ridges", type = "bool-setting", setting_type = "startup", default_value = true, order = "c-c",
    },
    -- hotspots with heavier biters and the offshore fields' deepwater discs and wells. Baked per save
    -- through the toggle tn_hotspots and each map's offshore stamp key.
    hotspots = {
      name = ID .. "-hotspots", type = "bool-setting", setting_type = "startup", default_value = true, order = "c-a",
    },
    -- sparse random inland lakes. Off leaves the spawn lake at the chosen city, the rivers and the real
    -- lakes of the coast fit as the only fresh water. Baked per save through the toggle tn_inland_lakes.
    inland_lakes = {
      name = ID .. "-inland-lakes", type = "bool-setting", setting_type = "startup", default_value = false,
      order = "c-e",
    },
    -- ground inside the zone's polygon, its edges moving with the map seed, never at the spawn. It needs Alien
    -- toggle tn_destroyed.
    destroyed_europe = {
      name = ID .. "-destroyed-europe", type = "bool-setting", setting_type = "startup", default_value = false,
      order = "c-f",
    },
    exact_coast = {
    },
  },

  -- Map-gen presets, sorted right after Default ("a") and before Rich resources ("b").
  -- withheld_with lists the mods whose presence withholds a preset (presets.lua defines no such
  -- preset while one is loaded). From europe-coast to region-layer every preset listed Alien Biomes:
  -- its 0.8.0 palms (tree-palm-a, tree-palm-b) read elevation in the Entity program, so beside it a
  -- firewall"), so the preset was withheld beside Alien Biomes. climate-tiles ships the palm switch
  -- (every Earth preset points each palm's keys at an Earth copy that reads the palm constant where
  -- AB reads elevation; tiles.palm), so the lists are empty and the presets are
  -- offered beside Alien Biomes again. Withholding acted on new worlds only: a world made from a
  -- preset that later loads beside a listed mod still names its fine field, so control code warns
  -- once and records it while a list names that mod (scripts/guards.lua). A save made before the
  -- switch keeps its palms on its fine field for life: no load writes the palm keys into it.
  presets = {
    europe = {name = ID .. "-europe", map = "europe", order = "a-tn-a", withheld_with = {}},
    atlantic = {name = ID .. "-atlantic", map = "atlantic", order = "a-tn-b", withheld_with = {}},
    olde_world = {name = ID .. "-old-world", map = "olde_world", order = "a-tn-c", withheld_with = {}},
  },
  preset_order = {"europe", "atlantic", "olde_world"},

  -- The per-save keys: map, scale and geography release are numbers every Earth preset bakes;
  -- are the vanilla properties the presets redirect (distance from spawn-cities: vanilla's starting
  -- ore and enemy-free start follow the spawn through it); spawn_lake and spawn_bias name the
  -- map's spawn lake and starting-ore bias for the shared start mask v2 (spawn-cities).
  keys = {
    map = K_MAP, scale = K_SCALE, geo = K_GEO, land_coarse = K_LAND_COARSE,
    elevation = "elevation", start_mask = "starting_resources_lake_mask", distance = "distance",
    spawn_lake = K_SPAWN_LAKE, spawn_bias = K_SPAWN_BIAS,
    -- waterways: the hook gate (prototype off, Earth presets on), the ford key (prototype off, Earth
    -- presets name the map's ford set for the save's scale) and the canals switch (a toggle)
    on = K_ON, fords = K_FORDS, canals = K_CANALS,
    -- ridges: the toggle, the map's crest and openings keys, and the two cliff properties the presets
    -- redirect
    ridges = RDN.K_RIDGES, crest = RDN.K_CREST, openings = RDN.K_OPENINGS, band = RDN.K_BAND,
    cliff_elevation = "cliff_elevation", cliffiness = "cliffiness",
    -- resources-enemies: the hotspots toggle, each map's offshore stamp key and the enemy property
    fields = {europe = REN.EU_FIELDS_KEY, atlantic = REN.AT_FIELDS_KEY, olde_world = REN.OW_FIELDS_KEY},
    -- edge-and-lakes: the inland lakes switch (a toggle)
    inland_lakes = ELN.K_INLAND_LAKES,
    -- destroyed-europe: the zone toggle
    destroyed = DE.K,
    -- coast-band-fix: the band-fix key (no prototype; control only)
    bandfix = BFN.K,
  },

  -- Each map's geography (ARCHITECTURE.md, "Map type entries"): map_type_order, the order of the
  --
  -- geo_id is the version's geography release, the number its preset bakes as tn_geo. tn_geo is
  -- one id space across every map: each geography release of any map takes the next unused
  -- integer and keeps it for good, so no two maps or versions share one, and release_registry
  -- names each with its map, which is how control code resolves a save's tn_geo (ARCHITECTURE.md,
  geography = {
    europe = {
      map_type_order = "3000-tn-a",
      versions = {
          start_mask = START_MASK2,
          fits = {geo = EU_GEO_FILE, land_coarse = EU_LAND_COARSE_FILE},
          fallbacks = {
            {name = K_SCALE, map_qualified = false},
            {name = EU_CITY, map_qualified = true},
            {name = K_CANALS, map_qualified = false},
            {name = REN.EU_FIELDS_KEY, map_qualified = true},
            {name = ELN.K_INLAND_LAKES, map_qualified = false},
          },
          spawn = {
            city_setting = "spawn_city_europe", city = EU_CITY, city_index = EU_CITY_INDEX,
          fields = REN.EU_FIELDS_KEY,
          edge = true,
          lakes = ELN.K_INLAND_LAKES,
        },
      },
    },
    atlantic = {
      map_type_order = "3000-tn-b",
      versions = {
          fallbacks = {
            {name = K_SCALE, map_qualified = false},
            {name = K_CANALS, map_qualified = false},
            {name = REN.AT_FIELDS_KEY, map_qualified = true},
            {name = ELN.K_INLAND_LAKES, map_qualified = false},
          },
          spawn = {
          fields = REN.AT_FIELDS_KEY,
          edge = true,
          lakes = ELN.K_INLAND_LAKES,
        },
          fallbacks = {
            {name = K_SCALE, map_qualified = false},
            {name = K_CANALS, map_qualified = false},
            {name = REN.AT_FIELDS_KEY, map_qualified = true},
            {name = ELN.K_INLAND_LAKES, map_qualified = false},
          },
          spawn = {
          fields = REN.AT_FIELDS_KEY,
          edge = true,
          lakes = ELN.K_INLAND_LAKES,
        },
      },
    },
    olde_world = {
      map_type_order = "3000-tn-c",
      versions = {
          fallbacks = {
            {name = K_SCALE, map_qualified = false},
            {name = K_CANALS, map_qualified = false},
            {name = REN.OW_FIELDS_KEY, map_qualified = true},
            {name = ELN.K_INLAND_LAKES, map_qualified = false},
          },
          spawn = {
          fields = REN.OW_FIELDS_KEY,
          edge = true,
          lakes = ELN.K_INLAND_LAKES,
        },
          fallbacks = {
            {name = K_SCALE, map_qualified = false},
            {name = K_CANALS, map_qualified = false},
            {name = REN.OW_FIELDS_KEY, map_qualified = true},
            {name = ELN.K_INLAND_LAKES, map_qualified = false},
          },
          spawn = {
          fields = REN.OW_FIELDS_KEY,
          edge = true,
          lakes = ELN.K_INLAND_LAKES,
        },
      },
    },
  },

  -- The chain every map-wide layer reads (the region layer, the climate and the layers after them):
  -- own.

  -- The water slider (inert on Earth presets). Vanilla 2.1.23 reads control:water:* in exactly
  -- three named expressions (core/prototypes/noise-programs.lua): water_level (10 * log2 of the
  -- size), segmentation_multiplier (the frequency) and nauvis_segmentation_multiplier (1.5 times
  -- the frequency). Earth elevation reads none of them, but vanilla cliffs, moisture and aux still
  -- do on an Earth preset, so every Earth preset bakes each as its value at the default slider: the
  -- slider then moves nothing, and at the default slider nothing changes. The gate's water_inert row
  -- walks every root of each preset for any other reader and previews the slider's extremes.
  water_slider = {
    {key = "water_level", value = 0},
    {key = "segmentation_multiplier", value = 1},
    {key = "nauvis_segmentation_multiplier", value = 1.5},
  },

  -- Every property_expression_names key any Earth preset sets, for every geography version (each
  -- version's own city offset names join it; tnconfig checks every key a version's preset bakes is
  -- here): the missing-name guard, the isolation walker (t14_walker) and the Nauvis-only surface guard
  -- read it, which strips exactly these keys from every other surface (ARCHITECTURE.md, "D33 surface
  -- guard"). From climate-tiles also the climate redirects,
  -- the marsh keys, the palm keys, and with Alien Biomes the vanilla tile keys and the exclusion key
  -- (absent keys are by design on a world without AB).
                 "water_level", "segmentation_multiplier", "nauvis_segmentation_multiplier",
                 "temperature", "moisture", "aux", CT.MARSH_MUD, CT.MARSH_SHALLOW, CT.MARSH_GRASS,
                 CT.VT_GRASS_1, CT.VT_GRASS_2, CT.VT_GRASS_3, CT.VT_GRASS_4, CT.VT_DRY_DIRT, CT.VT_DIRT_1,
                 CT.VT_DIRT_2, CT.VT_DIRT_3,
                 CT.VT_DIRT_4, CT.VT_DIRT_5, CT.VT_DIRT_6, CT.VT_DIRT_7, CT.VT_SAND_1, CT.VT_SAND_2, CT.VT_SAND_3,
                 CT.VT_RED_0, CT.VT_RED_1,
                 CT.PALM_A_R_KEY, CT.PALM_B_P_KEY, CT.PALM_B_R_KEY,
                 -- trees-forests: the great-forests gate and multiplier key, and with Alien Biomes the restored
                 -- vanilla trees', rocks' and decoratives' keys
                 TF_TREES["tree-01"].p, TF_TREES["tree-01"].r, TF_TREES["tree-02"].p, TF_TREES["tree-02"].r,
                 TF_TREES["tree-02-red"].p, TF_TREES["tree-02-red"].r, TF_TREES["tree-03"].p, TF_TREES["tree-03"].r,
                 TF_TREES["tree-04"].p, TF_TREES["tree-04"].r, TF_TREES["tree-05"].p, TF_TREES["tree-05"].r,
                 TF_TREES["tree-06"].p, TF_TREES["tree-06"].r, TF_TREES["tree-06-brown"].p,
                 TF_TREES["tree-06-brown"].r, TF_TREES["tree-07"].p, TF_TREES["tree-07"].r, TF_TREES["tree-08"].p,
                 TF_TREES["tree-08"].r, TF_TREES["tree-08-brown"].p, TF_TREES["tree-08-brown"].r,
                 TF_TREES["tree-08-red"].p, TF_TREES["tree-08-red"].r, TF_TREES["tree-09"].p, TF_TREES["tree-09"].r,
                 TF_TREES["tree-09-brown"].p, TF_TREES["tree-09-brown"].r, TF_TREES["tree-09-red"].p,
                 TF_TREES["tree-09-red"].r,
                 TF_ROCKS["huge-rock"].key, TF_ROCKS["big-rock"].key, TF_ROCKS["big-sand-rock"].key,
                 TF_ROCKS["medium-rock"].key, TF_ROCKS["small-rock"].key, TF_ROCKS["tiny-rock"].key,
                 TF_ROCKS["medium-sand-rock"].key, TF_ROCKS["small-sand-rock"].key, TF_ROCKS["red-desert-decal"].key,
                 TF_ROCKS["sand-decal"].key, TF_ROCKS["sand-dune-decal"].key,
                 TF_DECO["light-mud-decal"], TF_DECO["green-asterisk"], TF_DECO["green-asterisk-mini"],
                 TF_DECO["green-bush-mini"], TF_DECO["green-carpet-grass"], TF_DECO["green-croton"],
                 TF_DECO["green-desert-bush"], TF_DECO["green-hairy-grass"], TF_DECO["green-pita"],
                 TF_DECO["green-pita-mini"], TF_DECO["green-small-grass"],
                 -- ridges: the toggle, the map's ridge keys, the two cliff properties and the Earth ores'
                 -- probability keys (data-final-fixes.lua points them at the clearance wrappers)
                 RDN.K_RIDGES, RDN.K_CREST, RDN.K_OPENINGS, RDN.K_BAND, "cliff_elevation", "cliffiness",
                 "entity:iron-ore:probability", "entity:copper-ore:probability", "entity:coal:probability",
                 "entity:stone:probability", "entity:uranium-ore:probability", "entity:crude-oil:probability",
                 -- resources-enemies: the richness keys, the enemy property, the hotspots toggle, each map's
                 -- offshore stamp key and, with the Oil Rig loaded, the offshore-oil keys
                 "entity:iron-ore:richness", "entity:copper-ore:richness", "entity:coal:richness",
                 "entity:stone:richness", "entity:uranium-ore:richness", "entity:crude-oil:richness",
                 "enemy_base_probability", REN.K_HOTSPOTS, REN.EU_FIELDS_KEY, REN.AT_FIELDS_KEY, REN.OW_FIELDS_KEY,
                 "entity:offshore-oil:probability", "entity:offshore-oil:richness",
                 -- edge-and-lakes: the inland lakes switch and the new versions' city offset names
                 -- destroyed-europe: the zone toggle (temperature and the city numbers are listed above)
                 DE.K,
                 -- coast-band-fix: the band-fix key, on presets whose map the setting acts on

  -- decorative or Cliff root on a Terra Nauvis preset may reach one. The start land guarantee is
  -- analytic but belongs to the field by ARCHITECTURE.md's firewall rule; the spawn lake, the bias,
  -- distance and the city fold are firewall-clean (the start mask reads the lake and the bias).
  firewall = {
  },

  -- Per geography release: {release = <version>, map = <map key>, geography = <tn_geo id>, names =
  -- {<noise names>}, files = {<generated files>}}. Every name here is registered in
  -- names one geography id with the map it belongs to; an id appears in one row only and never
  -- moves to another map, and each geography version's geo_id has its row under its map
  -- (tnconfig's id-space check).
  release_registry = {
    -- releases every name regions.lua composes from it (a stem of regions.names.row, a row id and the
    -- suffix; a warped query point per share). It belongs to no geography. tools/tnconfig.py composes
    -- those names by the same rule, so the dump facts, the static rows and build_zip.py --release see each.
    {
      release = "0.1.0",
      names = {RG_DESTROYED_SD, RG_DESTROYED_W, RG_DESTROYED_DEPTH, RG_FOREST_W, RG_FOREST_SUM, RG_TREE_MULT,
               RG_MARSH_W, RG_HOTSPOT_W, RG_ENEMY_MULT, RG_U .. RG_V, RG_V_ .. RG_V, RG_OX, RG_OY, RG_AX, RG_AY, RG_WK,
      files = {"prototypes/tables/regions.lua"},
    },
    -- The climate and tile bodies (climate-tiles). They belong to no geography: every map's preset names
    -- them. The hook keys hold their off values. The Alien Biomes variants read AB's hot and cold
    -- controls, so they exist only with Alien Biomes and are registered from the M2 dump.
    {
      release = "0.1.0",
      CT.CL_M_FB, CT.CL_A_FB,
               CT.VT_GRASS_1, CT.VT_GRASS_2, CT.VT_GRASS_3, CT.VT_GRASS_4, CT.VT_DRY_DIRT, CT.VT_DIRT_1, CT.VT_DIRT_2,
               CT.VT_DIRT_3,
               CT.VT_DIRT_4, CT.VT_DIRT_5, CT.VT_DIRT_6, CT.VT_DIRT_7, CT.VT_SAND_1, CT.VT_SAND_2, CT.VT_SAND_3,
               CT.VT_RED_0, CT.VT_RED_1,
               CT.MARSH_SHALLOW_BODY, CT.MARSH_GRASS, CT.MARSH_GRASS_BODY},
    },
    {
      release = "0.1.0",
      names = {CT.PALM_CONST, CT.PALM_A_P, CT.PALM_A_R, CT.PALM_B_P, CT.PALM_B_R},
    },
    -- The tree bodies (trees-forests). They belong to no geography. The hook keys and the gate hold their
    -- off values; the palms' second versions wrap climate-tiles' copies, defined on every load as the
    -- copies are (trees.lua).
    {
      release = "0.1.0",
      TFN.PALM_B_P2,
               TF_TREES["tree-01"].p, TF_TREES["tree-01"].r, TF_TREES["tree-01"].body,
               TF_TREES["tree-02"].p, TF_TREES["tree-02"].r, TF_TREES["tree-02"].body,
               TF_TREES["tree-02-red"].p, TF_TREES["tree-02-red"].r, TF_TREES["tree-02-red"].body,
               TF_TREES["tree-03"].p, TF_TREES["tree-03"].r, TF_TREES["tree-03"].body,
               TF_TREES["tree-04"].p, TF_TREES["tree-04"].r, TF_TREES["tree-04"].body,
               TF_TREES["tree-05"].p, TF_TREES["tree-05"].r, TF_TREES["tree-05"].body,
               TF_TREES["tree-06"].p, TF_TREES["tree-06"].r, TF_TREES["tree-06"].body,
               TF_TREES["tree-06-brown"].p, TF_TREES["tree-06-brown"].r, TF_TREES["tree-06-brown"].body,
               TF_TREES["tree-07"].p, TF_TREES["tree-07"].r, TF_TREES["tree-07"].body,
               TF_TREES["tree-08"].p, TF_TREES["tree-08"].r, TF_TREES["tree-08"].body,
               TF_TREES["tree-08-brown"].p, TF_TREES["tree-08-brown"].r, TF_TREES["tree-08-brown"].body,
               TF_TREES["tree-08-red"].p, TF_TREES["tree-08-red"].r, TF_TREES["tree-08-red"].body,
               TF_TREES["tree-09"].p, TF_TREES["tree-09"].r, TF_TREES["tree-09"].body,
               TF_TREES["tree-09-brown"].p, TF_TREES["tree-09-brown"].r, TF_TREES["tree-09-brown"].body,
               TF_TREES["tree-09-red"].p, TF_TREES["tree-09-red"].r, TF_TREES["tree-09-red"].body,
               TF_ROCKS["huge-rock"].key, TF_ROCKS["huge-rock"].body, TF_ROCKS["big-rock"].key,
               TF_ROCKS["big-rock"].body, TF_ROCKS["big-sand-rock"].key, TF_ROCKS["big-sand-rock"].body,
               TF_ROCKS["medium-rock"].key, TF_ROCKS["medium-rock"].body, TF_ROCKS["small-rock"].key,
               TF_ROCKS["small-rock"].body, TF_ROCKS["tiny-rock"].key, TF_ROCKS["tiny-rock"].body,
               TF_ROCKS["medium-sand-rock"].key, TF_ROCKS["medium-sand-rock"].body, TF_ROCKS["small-sand-rock"].key,
               TF_ROCKS["small-sand-rock"].body, TF_ROCKS["red-desert-decal"].key, TF_ROCKS["red-desert-decal"].body,
               TF_ROCKS["sand-decal"].key, TF_ROCKS["sand-decal"].body, TF_ROCKS["sand-dune-decal"].key,
               TF_ROCKS["sand-dune-decal"].body,
               TF_DECO["light-mud-decal"], TF_DECO["green-asterisk"], TF_DECO["green-asterisk-mini"],
               TF_DECO["green-bush-mini"], TF_DECO["green-carpet-grass"], TF_DECO["green-croton"],
               TF_DECO["green-desert-bush"], TF_DECO["green-hairy-grass"], TF_DECO["green-pita"],
               TF_DECO["green-pita-mini"], TF_DECO["green-small-grass"]},
    },
    -- prototypes/tables/ranges.lua, and the shared bodies with the toggle's neutral pair (waterways') read
    -- them.
    {
      release = "0.1.0",
      files = {"prototypes/tables/ranges.lua"},
    },
    -- with the Oil Rig loaded, so tests/frozen.json registers them from the M3 dump with the "live"
    -- mask (their own composition; the Oil Rig text they wrap follows the pack, versioning rule 3).
    {
      release = "0.1.0",
      names = {REN.HS_BLOB, REN.HS_IRON, REN.HS_IRON_P, REN.HS_IRON_R, REN.HS_COPPER, REN.HS_COPPER_P,
      REN.HS_COPPER_R, REN.HS_COAL, REN.HS_COAL_P,
               REN.HS_COAL_R, REN.HS_STONE, REN.HS_STONE_P, REN.HS_STONE_R, REN.HS_URANIUM, REN.HS_URANIUM_P,
               REN.HS_URANIUM_R, REN.HS_OIL, REN.HS_OIL_P,
               REN.HS_OIL_R, REN.HS_OFFSHORE, REN.HS_OFFSHORE_P, REN.HS_OFFSHORE_R, REN.RAMP, REN.SEA,
               REN.ENEMY_LAYER, REN.ENEMY, REN.ORE_IRON_P2,
               REN.ORE_IRON_R, REN.ORE_COPPER_P2, REN.ORE_COPPER_R, REN.ORE_COAL_P2, REN.ORE_COAL_R, REN.ORE_STONE_P2,
               REN.ORE_STONE_R,
      files = {"prototypes/tables/hotspots.lua"},
    },
    {
      release = "0.1.0",
      map = "europe",
      geography = 14,
    },
    {
      release = "0.1.0",
      map = "atlantic",
    {
      release = "0.1.0",
      map = "olde_world",
    -- The Destroyed Europe bodies (destroyed-europe). They belong to no geography: the zone and its heat
    -- read the region layer's zone depth and the spawn distance; the temperature's next version reads
    -- climate-tiles' Alien Biomes temperature, so it exists only with Alien Biomes and is registered from
    -- the M2 dump; each pool reads its map's city fold hash and prototypes/tables/destroyed.lua.
    {
      release = "0.1.0",
      files = {"prototypes/tables/destroyed.lua"},
    },
  },

  -- Elevation composition tunables (ARCHITECTURE.md, "Elevation composition"):
  --   transfer: e = tn_scale * c + if(c > 0, offset, -offset) with c clamped to +-clamp_px, so the
  --     tile class is the sign of c (vanilla land beat water down to elevation -0.027);
  --   detail: lattice detail of amplitude_px, zero at every pixel-centre tile (basis noise is 0 on
  --     its lattice), one octave per row, each with its own seed1 and lattice frequency
  --     per reference pixel;
  --   far_floor: the elevation beyond the map's extent, deep water out to any distance;
  --   edge_water, edge_min_scale: the elevation of the extent's outermost tile ring at scales from
  --     edge_min_scale up. The game lets deepwater border only water (its allowed_neighbors), so a
  --     land tile on the extent's edge turns the first tile beyond it to plain water; plain water
  --     (deepwater wins only below -2) on that ring keeps deep water from 1 tile out. From scale 3
  --     the ring tile is never the tile that holds a pixel centre, so the pixel-centre coast check is
  --     unchanged; at scales 1 and 2 it would be, and there the reference pixel keeps its class.
  coast = {
    transfer_offset = 0.1,
    transfer_clamp_px = 16,
    detail_amplitude_px = 0.45,
    detail_clamp = 1,
    detail_octaves = {
      {seed1 = 7101, frequency = 1, weight = 1},
      {seed1 = 7102, frequency = 2, weight = 0.5},
      {seed1 = 7103, frequency = 4, weight = 0.25},
    },
    far_floor = -100,
    edge_water = -1,
    edge_min_scale = 3,
    -- edge = true replaces its box's inside (inf, and the edge_water ring) with a second coast, the
    -- version's own transfer of b = clamp(d / tn_scale + warp - width_px, -transfer_clamp_px,
    -- transfer_clamp_px), d the box distance in tiles, so land sinks into deep water where b < 0 with
    -- the same beach and deepwater profile as a real coast. warp = warp_px * clamp(sum of the octaves,
    -- -1, 1), each octave a basis noise in geo tiles with its own seed1 and wavelength in reference px,
    -- so the cut reads as a wavy coastline that moves with the map seed. The band's water edge lies
    -- between width_px - warp_px and width_px + warp_px reference px inside the box: never closer than
    -- 4 px, so every land column the box cuts ends in water before it, and never deeper than 20 px,
    -- short of the nearest land the box does not cut (Cyprus 22 px, Alaska 24 px, Ireland and Stewart
    -- Island 25 px). The pixel-centre coast check masks reference land within width_px + warp_px + 1
    edge_band = {
      width_px = 12,
      warp_px = 8,
      mask_px = 21,
      octaves = {
        {seed1 = 7401, wavelength_px = 32, weight = 1},
        {seed1 = 7402, wavelength_px = 12, weight = 0.5},
        {seed1 = 7403, wavelength_px = 4, weight = 0.25},
      },
    },
  },

  -- scale, and keeps starting ore off the spawn lake as vanilla's mask does with its own lake:
  -- clamp((min(coarse_gain * tn_land_coarse, tn_spawn_lake) - floor) / span, 0, 1) * tn_spawn_bias.
  start_mask = {
    versions = {
      {name = START_MASK2, formula = 2, floor = 1, span = 10, coarse_gain = 2},
    },
  },

  -- builds every spawn body from (the names are each geography version's own, in its spawn record).
  --   hash: random is (map_seed_small * small_mult + floor(map_seed / high_div) * high_mult) % N + 1
  --     over the map's N cities. Every intermediate stays below 2^24, so float32 folds it
  --     exactly; map_seed itself is a float32, so seed 4294967295 reads as 4294967296 (its city
  --     differs from the integer hash's), which is why control reads the index back and never
  --     recomputes it.
  --   lake: the spawn lake, vanilla's starting-lake shape magnitude * ((d + n) / divisor - offset),
  --     d the distance from a centre `distance` tiles from the spawn on the city's generated bearing
  --     at the save's scale (one of `bearings` steps of a turn), n one basis-noise octave; water
  --     where d + n < offset * divisor (about 1,850 water tiles, nearest water 42.6 tiles). The
  --     bearing points at land reached on foot (tools/build_spawn.py): a seed-folded angle put
  --     the lake in open water north of coastal cities. Analytic in x, y, map_seed and per-save
  --     numbers, so it is firewall-clean and the start mask reads it too.
  --   bias: where the generated table turns it on, the start mask is multiplied by the half-plane
  --     clamp(1 + (x, y) . b / w, 0, 1), b the city's generated bias bearing and w its width (one of
  --     `widths` tiles), else by 1. Vanilla's starting ore does not know the sea (at scale 1
  --     Tallinn's copper and Helsinki's stone landed across the Gulf of Finland), and it takes, per
  --     ore, the best of about 11 spot-noise candidates in the start disc, so tools/build_spawn.py
  --     picks each city's bearing and width, or none, by the share of starting patches left off the
  --     city's own land over `layouts` random candidate layouts (from `seed`: `ores` ores of
  --     `candidates` candidates in a `region`-tile square, at least `spacing` apart), scored with
  --     this start mask and vanilla's favorability (the mask term 0 within `excluder` tiles, the
  --     start disc `radius` tiles); a patch is lost when under `share` of its centre and its rings
  --     at `patch` tiles lie on that land, and the bias goes on only where it lowers the lost share
  --     by more than `margin`. The draw is fixed, so the table does not depend on the map seed.
  --   land: the start land guarantee, (radius - distance) * slope + the transfer offset inside
  --     `radius` tiles of the spawn and -inf beyond, joined to the elevation by max after the
  --     far-field box and before dams and carves, so a named waterway still cuts it. The
  --     tile correction step waters the guarantee's outer ring next to the sea, so 16 keeps 12 dry.
  --   inland_lakes: sparse lakes at a fixed density: spot noise in geo tiles places exactly
  --     per_region conical spots of `radius` tiles and peak 1 in every square region of `region`
  --     tiles (hard_region_target_quantity), at random points at least about `spacing` apart; water
  --     where gain * (level - spot) + shore noise < 0 (a spot's quantity is its cone volume,
  --     pi radius^2 peak / cone_divisor), a lake of about radius * (1 - level) tiles (16 at 24 and
  --     1/3), so the design water fraction is per_region * pi * (radius * (1 - level))^2 / region^2
  --     (0.61 percent). Kept coast_px reference pixels inside the coast fit (no lake on a shore, a
  --     small island or an isthmus) and out of start_radii start radii of the spawn.
  spawn = {
    random_value = "random",
    hash = {small_mult = 157, high_mult = 97, high_div = 65536},
    lake = {distance = 72, bearings = 16, magnitude = 2.5, offset = 3, divisor = 8,
    bias = {radius = 150, excluder = 40, widths = {50, 75, 100, 150}, seed = 7203, layouts = 150, ores = 4,
            candidates = 32, region = 450, spacing = 30, patch = {7, 14}, share = 0.5, margin = 0.005},
    land = {radius = 16, slope = 0.5},
    inland_lakes = {
      seed1 = 7202, region = 1024, per_region = 8, radius = 24, level = 1 / 3, gain = 12, candidates = 32,
      spacing = 128, cone_divisor = 3,
      shore = {seed1 = 7204, wavelength = 8, amplitude = 1},
      coast_px = 2.5, coast_gain = 20, start_radii = 1.5, start_slope = 0.25,
    },
  },

  -- ridge bodies use; prototypes/expressions/ridges.lua builds them from prototypes/tables/ranges.lua:
  --   cliffiness   the cliffiness of a ridge cell; 0 inside an opening and inside the ridge-free start
  --   pass_tiles   an opening's cliffiness gap along the crest (at least 12, for 8 tiles
  --              clear; a 16-tile gap once measured 16 clear, but a 16-tile slot read 7.5 at Verecke
  --   edge_tiles, edge_reach_tiles   a range cut by a map's edge with no pass on that map: no ridge cell
  --              within edge_tiles of the edge and edge_reach_tiles of the crossing
  --   start      the ridge-free disc round the spawn: max(radius_tiles, starting_area_radius) plus
  --              find 0 cliffs and 0 ridge cliffiness within 150 tiles)
  --   ore_clear_tiles   no ore within this of a crest outside the start disc, past the
  --              flank cliffs' boxes, so no ore entity stands on a ridge cell
  --   band_max_angle_degrees   the ore clearance reads, in the Entity program, each map's crest band: a
  --              superset of the tiles within ore_clear_tiles of a crest, built from crest pieces monotone
  --              along one axis whose segments lie within this angle of it, each a piecewise-linear
  --              function of that axis (3 operations per segment against 14 for an exact distance, which
  --              measured Entity +3,028 on Europe), its half-height ore_clear_tiles over the cosine of the
  --              piece's steepest angle
  --   centre_tiles   where the band is read inside a tile: the Entity program samples a tile at its
  --              integer corner while an ore entity stands at the tile's centre, half a tile on in x and
  --              y (an in-game check found ore 23.4 to 23.97 tiles from a crest by centre, every one with
  --              its corner outside 24), so the band reads the centre
  --   switch_threshold   the toggle reads on above it (its bodies are 1 and 0)
  --   reset_size   the cliff control's size the on_init reset writes when the slider was none
  --   ores       the Earth ores whose live probability is wrapped (resource, preset key, wrapper)
  --              baked on every Earth preset at their default-slider values
  ridges = {
    flank_tiles = 16.37,
    cliffiness = 10,
    reach_tiles = 32,
    tip_tiles = 24,
    edge_tiles = 16,
    edge_reach_tiles = 256,
    start = {radius_tiles = 150, margin_tiles = 8},
    ore_clear_tiles = 24,
    band_max_angle_degrees = 60,
    centre_tiles = 0.5,
    switch_threshold = 0.5,
    reset_size = 1,
    max_arguments = 255,
    names = {
      clear = RDN.RD_CLEAR,
      band = {europe = RDN.EU_BAND, atlantic = RDN.AT_BAND, olde_world = RDN.OW_BAND},
    },
    ores = {
      {resource = "iron-ore", key = "entity:iron-ore:probability", name = RDN.ORE_IRON},
      {resource = "copper-ore", key = "entity:copper-ore:probability", name = RDN.ORE_COPPER},
      {resource = "coal", key = "entity:coal:probability", name = RDN.ORE_COAL},
      {resource = "stone", key = "entity:stone:probability", name = RDN.ORE_STONE},
      {resource = "uranium-ore", key = "entity:uranium-ore:probability", name = RDN.ORE_URANIUM},
      {resource = "crude-oil", key = "entity:crude-oil:probability", name = RDN.ORE_OIL},
    },
  },

  -- presets' frequency for the six base resources (planet entries stay neutral), the richness ramp
  -- 1 + gain * clamp((distance - from) / span, 0, 1) on the four solid ores (1.01, 1.09, 1.23
  -- and 1.50 at 512, 1024, 2048 and 4096 tiles, 1.000 inside 450), each Earth ore's wrapper names
  -- (p_v1 is ridges' probability wrapper, which the next version reads), the Oil Rig's offshore-oil
  -- wrappers and the random offshore-oil sea mask: tn_land_coarse below minus threshold_px, the
  -- smallest whole threshold at which no reference river pixel more than 16 px from the sea lies in
  -- the mask on any map.
  resources = {
    frequency = 0.75,
    controls = {"iron-ore", "copper-ore", "coal", "stone", "uranium-ore", "crude-oil"},
    ramp = {name = REN.RAMP, from = 450, span = 3550, gain = 0.5},
    ramped = {"iron-ore", "copper-ore", "coal", "stone"},
    ores = {
      {resource = "iron-ore", probability = "entity:iron-ore:probability", richness = "entity:iron-ore:richness",
      {resource = "copper-ore", probability = "entity:copper-ore:probability",
      {resource = "coal", probability = "entity:coal:probability", richness = "entity:coal:richness",
      {resource = "stone", probability = "entity:stone:probability", richness = "entity:stone:richness",
      {resource = "uranium-ore", probability = "entity:uranium-ore:probability",
      {resource = "crude-oil", probability = "entity:crude-oil:probability", richness = "entity:crude-oil:richness",
    },
    offshore = {resource = "offshore-oil", probability = "entity:offshore-oil:probability",
                richness = "entity:offshore-oil:richness", p = REN.OFFSHORE_P, r = REN.OFFSHORE_R},
    sea = {name = REN.SEA, threshold_px = 7},
  },

  -- rows are prototypes/tables/hotspots.lua (tools/build_hotspots.py writes it from its source data):
  -- each row's disc is the region layer's row of the same id, jittered per seed there. At scale s a
  -- row's footprint radius is R = min(max(r * s, floor_tiles), cap * s) tiles (r its radius and cap
  -- r + 50 km, both in reference pixels: a floor at small scales, capped where it would
  -- pass the city-removal distance), read through the region layer's depth, so the footprint is the
  -- disc's roughened distance under R:
  --   core_share   spots start at land candidates inside a row's start disc, core_share of R (the
  --              reference design had core 112 of a 160-tile disc; here 0.75, so the smallest holds
  --              about 4 candidates at scale 1) and at most the disc holding spot.max_spots
  --              candidates, and reach at most the
  --              rest of R, so ore stays inside R
  --   enemy_share   extra bases start inside this share of R (the reference design: 40 tiles inside a
  --              160-tile disc)
  --   patches    the reference design's spots per hotspot (4 of 5 M): the blob's reference spot height only
  --   land_px, sea_px   a candidate is land where tn_land_coarse is above land_px, and sea (offshore
  --              coarse field's zero contour runs inland of narrow coasts, so the land gate sits 4 px
  --              seaward of it (an offline probe of every adopted core at scales 1 and 6: at 0, 22
  --              cores pass under 0.6 of their reference land, Pentelicus none of it; at -4 none)
  --   land_grade_px   favourability rises over this many px of tn_land_coarse past the gate, so a
  --              region places its most inland candidates first
  --   spot       one spot_noise per resource, each with its own seed1, region_size tiles, its
  --              candidates per region (candidates_fine at scales up to fine_scale, where footprints
  --              are smallest, so even the smallest core holds several candidates), at most max_spots
  --              per row, and a hard region target equal to the sum of its land candidates' quantities,
  --              so every one is placed and rows of a resource sharing a region never draw on each
  --              other's target (a shared target let Marmara's candidates take all of Pentelicus' and
  --              Kryvbas' all of Kursk's on one Europe seed at scale 1); a region places its most
  --              inland candidates first
  --   target     a row's amount: strength * share * per_km2 / spots_per_km2 * base_density * mean_size *
  --              size * f(d) * ramp(d) with f vanilla's patch quantity and richness factor at the
  --              candidate's distance d (core/prototypes/noise-functions.lua:205-207, 264-280;
  --              core/lualib/resource-autoplace.lua:115-120), share the disc's land share (water share
  --              reference_factor give the blob's typical spot height; density_floor raises a large
  --              footprint's amount to that many times vanilla's mean amount per tile over its area
  --              (base_density times frequency, the lowest measured ratio 15), so a disc of hundreds
  --              of tiles at scale 6 still holds the density the ore checks ask (Kursk at strength 3 held 4.95
  --              times vanilla's mean over its 243-tile footprint without it)
  --   blob       the shared texture on every spot: three basis noises, added as
  --              (blob - mean) * height / divisor where a spot is positive
  --   resources  per resource its seed1, vanilla's base_density, spots per km2, rq factor and mean
  hotspots = {
    floor_tiles = 48,
    core_share = 0.75,
    enemy_share = 0.75,
    patches = 4,
    land_px = -4,
    sea_px = 0,
    land_grade_px = 8,
    spot = {region_size = 512, candidates = 512, candidates_fine = 1024, fine_scale = 1, spacing = 16,
            spacing_fine = 8, max_spots = 32, basement = -100000, basement_radius = 128, min_radius = 1,
    target = {fade_from = 150, fade_span = 300, double_from = 300, double_span = 1300, rich_offset = 1000,
              rich_span = 2600, per_km2 = 1000000, reference_strength = 2, reference_factor = 2,
              density_floor = 15},
            octaves = {{input_scale = 1 / 8, output_scale = 1}, {input_scale = 1 / 24, output_scale = 1},
                       {input_scale = 1 / 64, output_scale = 1.5}}},
    resources = {
      {resource = "iron-ore", seed1 = 7301, base_density = 10, spots_per_km2 = 2.5, rq = 0.11, mean_size = 1.125,
       names = {v = REN.HS_IRON, p = REN.HS_IRON_P, r = REN.HS_IRON_R}},
      {resource = "copper-ore", seed1 = 7311, base_density = 8, spots_per_km2 = 2.5, rq = 0.11, mean_size = 1.125,
       names = {v = REN.HS_COPPER, p = REN.HS_COPPER_P, r = REN.HS_COPPER_R}},
      {resource = "coal", seed1 = 7321, base_density = 8, spots_per_km2 = 2.5, rq = 0.1, mean_size = 1.125,
       names = {v = REN.HS_COAL, p = REN.HS_COAL_P, r = REN.HS_COAL_R}},
      {resource = "stone", seed1 = 7331, base_density = 4, spots_per_km2 = 2.5, rq = 0.1, mean_size = 1.125,
       names = {v = REN.HS_STONE, p = REN.HS_STONE_P, r = REN.HS_STONE_R}},
      {resource = "uranium-ore", seed1 = 7341, base_density = 0.9, spots_per_km2 = 1.25, rq = 0.1, mean_size = 3,
       names = {v = REN.HS_URANIUM, p = REN.HS_URANIUM_P, r = REN.HS_URANIUM_R}},
      {resource = "crude-oil", seed1 = 7351, base_density = 8.2, spots_per_km2 = 1.8, rq = 0.1, mean_size = 1,
       fluid = {penalty = 48, additional = 220000, seed = 7352},
       names = {v = REN.HS_OIL, p = REN.HS_OIL_P, r = REN.HS_OIL_R}},
      {resource = "offshore-oil", seed1 = 7361, base_density = 10, spots_per_km2 = 1.8, rq = 0.1, mean_size = 3.5,
       fluid = {penalty = 100, additional = 350000, seed = 7362}, sea = true,
       names = {v = REN.HS_OFFSHORE, p = REN.HS_OFFSHORE_P, r = REN.HS_OFFSHORE_R}},
    },
  },

  -- stamp_elevation inside every adopted offshore row's footprint grown by cover_px (the region
  -- layer's edge roughness plus a well's box), else 0, and the map's newer elevation entry takes
  -- min(elevation, stamp) where the ground is already water, so every well the Entity program places
  -- inside the footprint stands on deepwater. A row's centre is the region layer's jittered centre
  -- moved onto the map's own chain by the map's whole-pixel frame offset (hotspots.lua). -6 is
  -- deepwater with and without Alien Biomes.
  fields = {
    stamp_elevation = -6,
    cover_px = 4,
    names = {europe = REN.EU_FIELDS, atlantic = REN.AT_FIELDS, olde_world = REN.OW_FIELDS},
  },

  -- vanilla's enemy_base_probability (base/prototypes/noise-expressions.lua:19-50) in its own seed1,
  -- density (mult - 1) times vanilla's at candidates inside enemy_share of a hotspot footprint, on land,
  -- active only beyond start_factor times starting_area_radius; the wrapper takes max(live, layer), so
  -- bobenemies' intensity cap reaches it through enemy_base_radius and enemy_base_frequency.
  enemies = {
    layer = REN.ENEMY_LAYER,
    wrapper = REN.ENEMY,
    seed1 = 7123,
    start_factor = 2,
  },

  -- prototypes/expressions/destroyed.lua builds, from the region layer's interface names only:
  --   heat   where the zone is positive, clamp(rim + min(per_tile * zone, ramp) + noise, rim, cap) in Alien
  --          Biomes units: a heat-1 rim (100 to 120) that climbs within ramp / per_tile tiles to a core
  --          mixing heat-1 to heat-4 (heat-2 from 120, heat-3 from 135, heat-4 from 145 to 150; a small
  --          disc ramped 0.49 per tile to its cap, which on this zone would pave it with heat-4);
  --   temperature   the Alien Biomes temperature's next version: max(climate-tiles' first version, heat)
  --          with the toggle on, the first version alone off (a folded `if` on the switch)
  --   pools  per map with a city fold, its random pick over the cities outside the zone: the fold's hash
  --          modulo the pool's size, then the pool's k-th city (prototypes/tables/destroyed.lua lists the
  --          zone cities); a preset with the toggle on and the spawn city at random bakes it as the map's
  --          city number, so the first fold reads it and resolves it as a chosen city
  destroyed = {
    switch_threshold = 0.5,
  },

  -- Control-stage messages: the locale section and keys (locale/en/terra-nauvis.cfg). notice_withheld
  -- is the Map type notice where the map's preset is withheld (presets.withheld_with); drift_update
  -- is the drift line for a Map type fallback that moved with the mod itself rather than with a
  -- startup setting (a frozen fallback never should: the line is a tripwire); withheld_beside warns
  -- an Earth world whose preset is withheld beside a mod it now loads with; start is the start
  -- message, rso the RSO warning and drift_city the drift line for a changed spawn-city
  -- setting on an Earth world (spawn-cities); destroyed_no_ab is the warning for Destroyed Europe on
  -- without Alien Biomes (destroyed-europe). Messages name a world's
  -- map by its preset's name, which no version changes. A stored warning keeps its key here
  -- (scripts/guards.lua record_warning; ARCHITECTURE.md, "Guards", stored records), so a key that
  -- saves can hold is never removed or renamed: retire a message by leaving its key and locale
  -- entry in place (the static append-only check tests these keys against main and origin/main).
  messages = {
    section = ID,
    keys = {
      notice = "map-type-notice",
      notice_withheld = "map-type-notice-withheld",
      drift_scale = "drift-scale",
      drift_follows = "drift-follows",
      drift_update = "drift-update",
      missing_name = "missing-name",
      withheld_beside = "withheld-beside",
      start = "start-message",
      rso = "rso-warning",
      drift_city = "drift-city",
      drift_toggle = "drift-toggle",
      toggle_on = "toggle-on",
      toggle_off = "toggle-off",
      cliff_reset = "cliff-reset",
      destroyed_no_ab = "destroyed-no-ab",
    },
  },

  -- Toggles, keyed like settings: key -> {setting = <settings key>, preset_key = <key>, default,
  -- mechanism = "name switch" or "hook gate", on = <name>, off = <name>, maps = {<map keys>}};
  toggles = {
    -- Canals (waterways): a name switch read by every waterways version's entry through a folded `if`, so
    -- only the selected branch compiles (Tile 19,620 off and 20,161 on at scale 1).
    canals = {setting = "canals", preset_key = K_CANALS, default = true, mechanism = "name switch",
    -- Great forests (trees-forests): the hook gate of the boost on every living tree, outermost in the
    -- hook, so on every other world the hook folds to the tree's own autoplace. Its values are the
    -- numbers 1 and 0 as strings, so a save reads them back as it stored them and the drift line
    -- compares like with like.
    great_forests = {setting = "great_forests", preset_key = TFN.K_FORESTS_ON, default = true, mechanism = "hook gate",
                     on = "1", off = "0", maps = {"europe", "atlantic", "olde_world"}},
    -- compiles to a constant crest distance and 0 cliffs.
    ridges = {setting = "ridges", preset_key = RDN.K_RIDGES, default = true, mechanism = "name switch",
              on = ONE, off = ZERO, maps = {"europe", "atlantic", "olde_world"}},
    -- through a folded `if`, so hotspots off compiles each wrapper to the live expression alone; each
    -- map's offshore stamp key follows the same setting (presets.lua).
    hotspots = {setting = "hotspots", preset_key = REN.K_HOTSPOTS, default = true, mechanism = "name switch",
                on = ONE, off = ZERO, maps = {"europe", "atlantic", "olde_world"}},
    -- folded `if`, so off compiles to the spawn lake alone (the spot noise is never evaluated) and on to
    -- the previous version's composition. Every map lists it: a map's version without a spawn
    -- record bakes it unread.
    inland_lakes = {setting = "inland_lakes", preset_key = ELN.K_INLAND_LAKES, default = false,
    -- Destroyed Europe (destroyed-europe): a name switch read by the temperature's next version through a
    -- folded `if`, so the zone off compiles to climate-tiles' temperature alone. `requires` names the mod
    -- without which a preset bakes it off whatever the setting says, and the drift line
    -- compares with the same rule.
    destroyed_europe = {setting = "destroyed_europe", preset_key = DE.K, default = false,
                        mechanism = "name switch", on = ONE, off = ZERO, maps = {"europe", "atlantic", "olde_world"},
                        requires = "alien-biomes"},
              on = ONE, off = ZERO, maps = {"europe", "atlantic", "olde_world"}},
  },

  -- Stable hooks on shared prototypes (ARCHITECTURE.md, "Stable hooks"): if(gate > threshold, on
  -- branch, off value), whose outermost `if` folds away on worlds without the gate. The gate's
  -- prototype holds gate_off, Earth presets gate_on; the ford key's prototype holds its off value.
  hooks = {
    threshold = 0.5, gate_off = 0, gate_on = 1,
    fords = {tile = "water-shallow", key = K_FORDS, off = "-inf"},
  },
  -- The canals switch's neutral bodies.
  neutral = {one = ONE, zero = ZERO},

  -- composition" steps 5 and 6). tools/build_waterways.py reads every number below; the mod reads
  -- the set names and the hook values.
  --   sets: per map, the generated set names by scale (index = scale): ww (rivers, straits and
  --     turning basins, min into the entry), canals (min, canals on), dams (max, canals off) and
  --     fords (the water-shallow hook's on branch, through tn_fords). The geography version that
  --     composes a map's sets names the same table as its `waterways` field, and the sets bind to
  --     that version's chain, so one version per map composes them.
  --     w s / (2 km_per_px)) with floor two_way_tiles for the two-way straits; a canal max(floor / 2
  --     + margin, s / 2); a dam max(dam.floor_tiles, dam.per_scale s).
  --   depth: the carve's floor, plain water in vanilla and Alien Biomes for rivers and canals,
  --     deepwater for straits; slope: elevation per tile from the carve's edge.
  --     fit fills as land) keep their drawn course unsmoothed, their drawn points (a strait's waypoints
  --     and narrowest point, a canal's route vertices) held within their half-width less one tile;
  --     bend: the bend rule, no window_tiles
  --     stretch turning more than limit_degrees; basin_tiles: the turning basin where it still fails.
  --     carve plus margin_tiles, its banks bank_tiles beyond the carve on reference land; score
  --     beats every water tile's autoplace inside it.
  --     with clear_tiles of land around it; radius_tiles is the start area the bank masks cover.
  waterways = {
    version = 1,
    river_k = {major = 3, minor = 2},
    km_per_px = 2.471,
    depth = {river = -2.2, strait = -6, canal = -2.2},
    slope = 4,
    dam = {floor_tiles = 1.5, per_scale = 0.5},
    bend = {window_tiles = 17, limit_degrees = 90},
    basin_tiles = 30,
    vertex_grid = 16,
    start = {clear_tiles = 12, radius_tiles = 150},
  },

  -- exact signed distances in reference pixels at a query point on the coordinate chain, displaced by
  -- one shared domain warp and roughened by
  -- one shared edge noise, with each layer's aggregates. Every row is evaluated in the frame map's
  -- reference pixels: each map's raster sits on that grid at px_per_degree (Europe is an exact crop of
  -- Atlantic's raster; Old World's edges are whole pixels away), so a map's own chain moves into the
  -- frame by a whole-pixel offset and a row sits at its geography on every map and at every scale.
  --   warp      two multi-octave noises (seed1 per axis), wavelength_px the finest octave, amplitude_px
  --             times the noise, the vector clamped to clamp_px in length; a row follows its share
  --   rough     one multi-octave noise added to every signed distance, clamped to +-clamp_px
  --   octave_shift_px  each octave's x shift per octave index (its own lattice: no shared zero); every
  --             octave is a basis_noise anchored to the frame (multioctave_noise offsets are not
  --   ramp      membership weight clamp(mid + sd / width_px, 0, 1)
  --   jitter    a hotspot's centre moves by up to its jitter radius per seed: a linear fold of
  --             map_seed_small and the seed's high bits, plus the row's phase (no new noise)
  --   names     the interface and internal names; a row's names are row.<kind> .. <row id> .. suffix
  regions = {
    frame = "europe",
    frame_tolerance_px = 0.01,
    km_per_px = 2.471,
    warp = {amplitude_px = 12, clamp_px = 24, wavelength_px = 96, octaves = 3, persistence = 0.5, seed1_x = 7801,
            seed1_y = 7802},
    rough = {amplitude_px = 1.5, clamp_px = 3, wavelength_px = 6, octaves = 2, persistence = 0.5, seed1 = 7803},
    ramp = {mid = 0.5, width_px = 6},
    share_hundredths = 100,
    octave_shift_px = 10000.37,
    max_arguments = 255,
    forest_boost = 2,
    names = {
      suffix = RG_V,
      row = {sd = NOISE .. "sd_", w = NOISE .. "w_", depth = NOISE .. "depth_", hu = NOISE .. "hu_",
      share = "_k",
      destroyed_sd = RG_DESTROYED_SD, destroyed_w = RG_DESTROYED_W, destroyed_depth = RG_DESTROYED_DEPTH,
      forest_w = RG_FOREST_W, forest_sum = RG_FOREST_SUM, tree_mult = RG_TREE_MULT, marsh_w = RG_MARSH_W,
      hotspot_w = RG_HOTSPOT_W, enemy_mult = RG_ENEMY_MULT,
      -- the query point: u, v .. suffix unwarped; u, v .. share .. <hundredths> .. suffix for a share
      u = RG_U, v = RG_V_, ox = RG_OX, oy = RG_OY, ax = RG_AX, ay = RG_AY, wk = RG_WK, wx = RG_WX, wy = RG_WY,
    },
  },

  -- with Alien Biomes): the sign-offset transfer of v1 with its own land and water
  -- gains, so the tile class is still the sign of c (the pixel-centre coast check is unchanged) while
  --   land  e = max(land.min, land.per_scale * s) * c + offset: elevation 5, where AB's shore term ends,
  --         sits about 4 tiles inland at scale 2 and up and 2 tiles at scale 1 (the beach band);
  --   water e = max(water.min, water.per_scale * s) * c - offset: AB's deepwater line, -5.5,
  --         sits about 6 tiles offshore at scale 3 and up and 2.7 tiles at scale 1, where the fit's
  --         saturation (about 4 px) left v1's open sea at -4.1, shallow water under AB.
  -- c, its clamp and the far-field box are v1's (the coast group above); the carves and dams of v2 keep
  -- their absolute depths, so rivers stay plain water and straits deep in vanilla and AB alike.
  -- Each version that composes it names its own shore body (geography.<map>.versions[n].shore).
  shore = {
    land = {per_scale = 1.25, min = 2.5},
    water = {per_scale = 0.9, min = 2},
  },

  -- Temperature is in Alien Biomes units (below 0 frozen, 25 to 65 temperate,
  -- 65 hot, above 100 volcanic) in both variants; the fallback hands vanilla consumers scale times it.
  --   lat, lon  degrees on the map's own chain: lat_top_edge - (v + 1/2) / px_per_degree and
  --             lon_left_edge + (u + 1/2) / px_per_degree, folded on tn_map; the latitude meanders by up
  --             to degrees times one basis noise octave of wavelength_px (seed1)
  --   temperature  ref_t at ref_lat, per_degree warmer toward the equator, clamped to min and cap; minus
  --             continental.t at full continentality (longitude lon_start + lon_span and east, latitude
  --             lat_start + lat_span and north: the cold Russian interior); plus desert_heat in the dry
  --             belts; plus noise; Alien Biomes adds its hot and cold shift, shift_per_unit per slider unit
  --             as its own average, and scales the noise input by their mean frequency
  --   moisture  the Earth mean (base, plus equatorial within the equatorial latitude ramp, minus dry in
  --             the dry belts; the fallback caps the mean by temperature: the dry north) plus the
  --             spread and bias times the moisture bias; with Alien Biomes the marsh weight lifts it to
  --             marsh times the weight
  --   aux       the Earth mean (base; the fallback pulls cold land toward cold_aux and dry land down by
  --             dry_pull) plus the spread, capped (Alien Biomes: ab_cap, under AB's alien palette
  --             from 0.6; the fallback's cold land: cold_cap, under vanilla red desert), then bias times
  --             the aux bias; with Alien Biomes dry temperate land is lifted by red.lift (vanilla red
  --             desert, where non-adopted AB tiles are excluded)
  --   spread    every real climate zone is a patchwork of several tiles that changes with the seed
  --             noise after its caps and pulls, so they move the mean and never flatten the noise. Its
  --             sd is about 0.7 times amplitude (normalized multioctave_noise): moisture about 0.22,
  --             aux 0.14 and temperature 4.2 AB units, against vanilla's about 0.39 moisture and 0.2 aux
  --             (core noise-programs.lua: moisture_noise and aux_noise), whose coarsest octaves the
  --             Earth layout replaces. The moisture spread shrinks by spread.dry times the dry weight, so
  --             the dry belts stay hot desert, and on the fallback by spread.cold times the coldness
  --             (clamp((cold.t - core) / cold.span, 0, 1)), so the far north stays dry and dead ground
  -- Every noise call keeps x = x, y = y with its wavelength in reference pixels through input_scale: the
  -- finest octave is wavelength_px, each further octave twice as large (multioctave_noise).
  climate = {
    -- the pixel centre in reference pixels (lat_top_edge - (v + centre_px) / px_per_degree)
    centre_px = 0.5,
    temperature = {
      ref_lat = 54, ref_t = 25, per_degree = 2.2, min = -20, cap = 78,
      continental = {t = 6, lon_start = 15, lon_span = 45, lat_start = 35, lat_span = 10},
      desert_heat = 12,
      noise = {amplitude = 6, wavelength_px = 40, octaves = 3, persistence = 0.6, seed1 = 7602},
      ab = {shift_per_unit = 20.8333333, min = -20, max = 99},
    },
    moisture = {
      base = 0.68, equatorial = 0.12, equatorial_lat = 4, equatorial_ramp = 8, dry = 0.55, marsh = 0.9,
      noise = {amplitude = 0.32, wavelength_px = 40, octaves = 3, persistence = 0.6, seed1 = 7603},
    },
    aux = {
      base = 0.35,
      noise = {amplitude = 0.2, wavelength_px = 48, octaves = 3, persistence = 0.6, seed1 = 7604},
      ab_bias = 2.2, ab_cap = 0.5,
      red = {lift = 0.5, t_lo = 25, t_hi = 65, ramp = 5},
    },
    -- the coldness the fallback's pulls and spread read: 0 at core cold.t and warmer, 1 at
    -- cold.t - cold.span and colder
    cold = {t = 10, span = 30},
    -- The dry belts after EarthMaps' painted sand: the sand share of land per 10 x 10
    -- degree cell of the Atlantic raster (classes s and S) is 61 to 99 percent from 10 to 30 N between
    -- 20 W and 70 E, 42 to 82 percent from 30 to 40 N there, 24 to 82 percent from 40 to 50 N between
    -- 40 E and 120 E, 30 to 61 percent in North America's south-west, 45 to 76 percent in the Namib and
    -- Kalahari, 25 to 56 percent in Australia and 18 to 49 percent along the southern Andes, and 0 to 29
    -- percent in East Asia, India's east and the Americas' east. Each belt is
    -- a latitude and longitude box with soft edges: full weight ramp degrees inside each edge, 0 at it;
    -- the dry weight is the largest belt weight. A map reads only the belts that reach its extent.
    dry_belts = {
      {id = "sahara_arabia", lat = {9, 38}, lon = {-20, 80}, ramp = {3, 4}},
      {id = "horn_of_africa", lat = {-3, 13}, lon = {38, 53}, ramp = {3, 3}},
      {id = "central_asia", lat = {35, 51}, lon = {46, 120}, ramp = {3, 5}},
      {id = "north_america_sw", lat = {22, 44}, lon = {-122, -100}, ramp = {3, 4}},
      {id = "southern_africa", lat = {-30, -15}, lon = {11, 27}, ramp = {3, 3}},
      {id = "australia", lat = {-35, -17}, lon = {113, 147}, ramp = {3, 4}},
      {id = "south_america_sw", lat = {-56, -16}, lon = {-76, -63}, ramp = {3, 3}},
    },
             ab = {temperature = CT.CL_T_AB, moisture = CT.CL_M_AB, aux = CT.CL_A_AB},
             fallback = {temperature = CT.CL_T_FB, moisture = CT.CL_M_FB, aux = CT.CL_A_FB}},
    -- The climate bands the oracle (t3_oracle) and the climate checks read, in Alien Biomes units.
    bands = {frozen_below = 0, cold_below = 25, hot_from = 65, dry_below = 0.4},
  },

  -- if(tn_on > threshold, <on branch>, <off value>), so worlds without an Earth
  -- preset compile the off value alone (a gate inside the score cost default worlds Tile
  -- +7,489).
  --   vanilla   with Alien Biomes: the 19 vanilla land tiles AB takes off Nauvis, re-listed;
  --             on branch (vanilla score) + the tile's key, off value -inf; every key names one bonus
  --             body: +bonus on land where the temperate lean plus patch noise passes (lean
  --             1 - |T - lean_t| / lean_span), 0 elsewhere in the exclusion's temperate band, -inf
  --             outside it, on water and inside marshes (marsh_cut)
  --   exclude   with Alien Biomes: every AB land tile (by prefix) outside the adopted set (ab_adopted); on
  --             branch (AB score) + the key, off value AB's score; the body is -inf from temperate_from
  --             to temperate_below outside marshes, 0 elsewhere (only the adopted AB tiles in
  --             temperate bands)
  --   marsh     water-mud (registered on Nauvis without AB) and water-shallow (the ford hook's tile):
  --             on branch max(the key, AB's own expression where AB defines one); water-mud pools on
  --             land inside marshes where pool noise passes a cut that falls with the marsh weight,
  --             outside the start clearing; water-shallow along open water down to shallow_depth;
  --             without Alien Biomes grass-1 (the grass between the pools) behind a gated hook,
  --             (score) + the grass key, its own score off: the key's body gives +bonus on land inside
  --             marshes (marsh_cut), 0 elsewhere (with AB the vanilla tile keys keep vanilla out of
  --             marshes, so AB's wetland grass lies between the pools)
  --   palm      with or without Alien Biomes (so a world that gains it later meets the switch too):
  --             Earth presets point each AB palm's
  --             entity:<tree>:probability and :richness keys at Earth copies of its expressions with
  --             every local expression, the
  --             constant where AB reads elevation (the richness too: its locals are in its scope, so
  --             the isolation walk reads them with it)
  --             The plain hook form (a key whose prototype
  --             is elevation) added one processed expression to M2's default Entity program, which the
  tiles = {
    vanilla = {
      tiles = {"grass-1", "grass-2", "grass-3", "grass-4", "dry-dirt", "dirt-1", "dirt-2", "dirt-3", "dirt-4",
               "dirt-5", "dirt-6", "dirt-7", "sand-1", "sand-2", "sand-3", "red-desert-0", "red-desert-1",
               "red-desert-2", "red-desert-3"},
      keys = {["grass-1"] = CT.VT_GRASS_1, ["grass-2"] = CT.VT_GRASS_2, ["grass-3"] = CT.VT_GRASS_3,
      ["grass-4"] = CT.VT_GRASS_4,
              ["dry-dirt"] = CT.VT_DRY_DIRT, ["dirt-1"] = CT.VT_DIRT_1, ["dirt-2"] = CT.VT_DIRT_2,
              ["dirt-3"] = CT.VT_DIRT_3,
              ["dirt-4"] = CT.VT_DIRT_4, ["dirt-5"] = CT.VT_DIRT_5, ["dirt-6"] = CT.VT_DIRT_6,
              ["dirt-7"] = CT.VT_DIRT_7,
              ["sand-1"] = CT.VT_SAND_1, ["sand-2"] = CT.VT_SAND_2, ["sand-3"] = CT.VT_SAND_3,
              ["red-desert-0"] = CT.VT_RED_0,
              ["red-desert-1"] = CT.VT_RED_1, ["red-desert-2"] = CT.VT_RED_2, ["red-desert-3"] = CT.VT_RED_3},
      off = "-inf",
      bonus = 10, lean_t = 45, lean_span = 30, lean_cut = 0.5,
      patch = {amplitude = 0.36, clamp = 0.45, wavelength_px = 10, octaves = 3, persistence = 0.5, seed1 = 7605},
    },
    -- The adopted Alien Biomes tiles: six land tiles plus water-mud.
    ab_adopted = {"vegetation-turquoise-grass-1", "vegetation-olive-grass-2", "mineral-grey-dirt-1",
                  "mineral-beige-dirt-1", "mineral-cream-sand-1", "mineral-grey-sand-1", "water-mud"},
    exclude = {
      prefixes = {"vegetation-", "mineral-"},
    },
    marsh = {
      water_shallow = {key = CT.MARSH_SHALLOW, off = "-inf", body = CT.MARSH_SHALLOW_BODY},
      grass = {tile = "grass-1", key = CT.MARSH_GRASS, off = "0", body = CT.MARSH_GRASS_BODY, bonus = 10},
      score = 50, shallow_score = 300, shallow_depth = 1.5, start_clear_tiles = 64,
    },
            copies = {{tree = "tree-palm-a", field = "probability", key = CT.PALM_A_P_KEY, body = CT.PALM_A_P},
                      {tree = "tree-palm-a", field = "richness", key = CT.PALM_A_R_KEY, body = CT.PALM_A_R},
                      {tree = "tree-palm-b", field = "probability", key = CT.PALM_B_P_KEY, body = CT.PALM_B_P},
                      {tree = "tree-palm-b", field = "richness", key = CT.PALM_B_R_KEY, body = CT.PALM_B_R}}},
  },

  --   boost     every living tree's probability becomes if(gate > hooks.threshold, min(cap, (own) * key),
  --             own): the gate's prototype holds gate_off and Earth presets bake the great-forests toggle;
  --             the key's prototype holds key_off (a neutral multiplier) and Earth presets name the region
  --             layer's multiplier (regions.names.tree_mult: 1 + forest boost 2 times the forest sum).
  --             The base game's dead and dry trees are left alone (prototypes/tables/vanilla.lua),
  --             and so are Alien Biomes' palm prototypes (tiles.palm.copies' trees stay AB's)
  --   palm      on Earth presets with Alien Biomes the palms read their Earth copies (tiles.palm), so each
  --             palm's probability key names its second version, the boost's formula around the
  --   restore   with Alien Biomes, the base game's living trees, rocks and decals AB takes off Nauvis,
  --             rebuilt from prototypes/tables/vanilla.lua: each behind the gate keys.on with its key, whose
  --             prototype holds the off value and which Earth presets point at its body, restricted to the
  --             vanilla land tiles (tiles.vanilla.tiles), so AB's land keeps AB's own. The restored trees
  --             read the Earth temperature on the vanilla scale (temperature, from the fallback climate's
  --             scale and clamp), and every richness key names one shared body. The decoratives AB keeps but
  --             takes off Nauvis are re-listed as (own score) + key, the key's prototype -inf and its body
  --             deco_on; the vanilla decoratives and dead trees AB restricts to its tiles get the vanilla land
  trees = {
    temperature = TFN.TF_VTEMP,
    restore = {
      trees = TF_TREES, tree_off = "0", richness = TFN.TF_VTREE_R,
      rocks = TF_ROCKS, rock_off = "0",
      decoratives = TF_DECO, deco_off = "-inf", deco_body = TFN.TF_VDECO, deco_on = "0",
    },
  },

  -- Exact coastlines (ARCHITECTURE.md, "Exact coastlines"). On a save whose Nauvis surface carries the key,
  -- scripts/bandfix.lua's on_chunk_generated handler rewrites, where the generated land or water is wrong,
  -- the tiles of the K
  --   setting, key, on  the startup bool, the per-save name switch and its value when on: a map's preset
  --       carries the key only when the setting is on and the map is listed in maps; absent means off
  --       is never listed
  --   checks  each flip-checked map's measured configuration, its scale
  --   tables  per map with K+ tables: the geography ids (tn_geo) they serve. They follow the coast fit, the
  --   float_margin_px  float32 slack over the lattice detail's bound (coast.detail_amplitude_px times
  --       coast.detail_clamp): a tile counts as possibly wrong unless the fit alone is right by more
  --   correction_tiles  the game's own tile stage grows water so every water tile lies in a 2 x 2 block of
  --       water (measured on Europe at scale 6: no generated water tile outside one, 1,078 tiles the fit
  --       makes land for sure turned water, every one within 2 tiles of possible water), so a tile also
  --       counts as possibly wrong while a tile of the other possible class lies within this many tiles
  --   mask_margin_tiles  waterway, canal, dam and basin footprints grow by this many tiles before they mask
  --       pixels; a ford spans its carve plus waterways.ford.margin_tiles
  --   spawn_keep_tiles  no tile within this radius of the spawn (world 0, 0) is written, so spawn-cities'
  --       start land guarantee and the spawn tile keep what the noise draws
  --   fill  K pixels whose band region holds no 2 x 2 block of tiles (an islet or a channel narrower than
  --       a pixel) are written whole instead of as a one-tile line; the tool marks them
  --   encoding  each table row is its first column, then runs (length - 1) * #symbol_order + symbol index
  --       (0-based in symbol_order), every number a varint of varint_base digits written in alphabet (a
  --       digit at or above varint_base continues the number); a decoded row is one symbol character per
  --       pixel: none (outside K+), water, land, a K pixel of either class (band), a fill pixel of either
  --       class, thin water, and a pixel of either class inside a waterway footprint (masked)
  bandfix = {
    setting = "exact_coast", key = BFN.K, on = ONE,
    version = 1,
    float_margin_px = 0.01,
    correction_tiles = 2,
    mask_margin_tiles = 3,
    spawn_keep_tiles = 24,
    chunk_tiles = 32,
    row_cache = 2048,
    neighbours = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}, {1, 1}, {-1, 1}, {1, -1}, {-1, -1}},
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
    varint_base = 32,
    symbols = {none = "a", water = "b", land = "c", water_k = "d", land_k = "e", water_fill = "f",
               land_fill = "g", thin = "h", water_masked = "i", land_masked = "j"},
    symbol_order = {"none", "water", "land", "water_k", "land_k", "water_fill", "land_fill", "thin",
                    "water_masked", "land_masked"},
  },
}
