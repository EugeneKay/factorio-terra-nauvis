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
      default_value = "random",
      allowed_values = {
      default_value = "random",
      allowed_values = {
  },

  -- Map-gen presets, sorted right after Default ("a") and before Rich resources ("b").
  -- withheld_with lists the mods whose presence withholds a preset (presets.lua defines no such
  presets = {
  },

  -- The per-save keys: map, scale and geography release are numbers every Earth preset bakes;
  -- are the vanilla properties the presets redirect (distance from spawn-cities: vanilla's starting
  -- ore and enemy-free start follow the spawn through it); spawn_lake and spawn_bias name the
  -- map's spawn lake and starting-ore bias for the shared start mask v2 (spawn-cities).
  keys = {
    map = K_MAP, scale = K_SCALE, geo = K_GEO, land_coarse = K_LAND_COARSE,
    elevation = "elevation", start_mask = "starting_resources_lake_mask", distance = "distance",
    spawn_lake = K_SPAWN_LAKE, spawn_bias = K_SPAWN_BIAS,
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
          spawn = {
            city_setting = "spawn_city_europe", city = EU_CITY, city_index = EU_CITY_INDEX,
          fallbacks = {
            {name = K_SCALE, map_qualified = false},
          fallbacks = {
            {name = K_SCALE, map_qualified = false},
          fallbacks = {
            {name = K_SCALE, map_qualified = false},
          fallbacks = {
            {name = K_SCALE, map_qualified = false},
      },
    },
  },

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
                 "water_level", "segmentation_multiplier", "nauvis_segmentation_multiplier",

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

  -- Control-stage messages: the locale section and keys (locale/en/terra-nauvis.cfg). notice_withheld
  -- is the Map type notice where the map's preset is withheld (presets.withheld_with); drift_update
  -- is the drift line for a Map type fallback that moved with the mod itself rather than with a
  -- startup setting (a frozen fallback never should: the line is a tripwire); withheld_beside warns
  -- an Earth world whose preset is withheld beside a mod it now loads with; start is the start
  -- message, rso the RSO warning and drift_city the drift line for a changed spawn-city
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
    },
  },

  -- Toggles, keyed like settings: key -> {setting = <settings key>, preset_key = <key>, default,
  -- mechanism = "name switch" or "hook gate", on = <name>, off = <name>, maps = {<map keys>}};
}
