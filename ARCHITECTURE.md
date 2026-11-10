# Architecture

How Terra Nauvis is built, for a developer who wants to understand or change it. Version 1.0.0, Factorio 2.1.
Code comments cite this document by section name ("Module map", "Stable hooks", "Release versioning policy" and
others), so the headings below are stable.

## Overview

Terra Nauvis draws three maps of Earth on Nauvis. Five ideas carry the whole design:

1. **Noise draws the land.** Coast, rivers, climate, ridges and ore are noise expressions, the game's own
   language for map generation. The new-game preview shows the real map, nothing runs per tick, and every
   machine computes the same tiles. A coast is a fitted sum of about ten thousand small "tent" functions.
2. **A preset bakes a world.** A map-gen preset writes the map, the scale, the city and every setting into the
   world as constants and expression names. After that the world does not read the mod settings again.
3. **Released terrain never changes.** The text of every named noise expression is registered by hash in
   `tests/frozen.json` (2,272 records). A change ships under a new name, and presets point new worlds at it.
   A world made on any release keeps generating the chunks it always would have.
4. **The expensive part stays in one program.** The game compiles separate noise programs for tiles, entities and
   cliffs. The coast fit is read by the Tile program only; everything else knows land from one coarse field.
5. **Script does only what noise cannot.** The control stage has one per-chunk handler, which corrects coast tiles
   against the reference raster, and a handful of one-time jobs at world start.

Size, at this version: 55 Lua files and 23,125 lines outside the generated folders (six of the table files are
written by tools), 64 generated Lua files and 191,538 lines, and 31 Python tools.

## Module map

| Path | Responsibility |
|---|---|
| `terra-nauvis/info.json` | Mod identity. Needs `base >= 2.1.24`; optional `alien-biomes`, `cargo-ships-oil-rig`; hidden optional `rso-mod`, which only orders RSO first |
| `terra-nauvis/prototypes/config.lua` | The single source of names and constants. Pure data: it reads no `data`, `settings`, `game` or `script` and calls no function, so all three stages and the Python tools (through `tools/tnconfig.py`) read the same file |
| `terra-nauvis/settings.lua` | One loop that turns each row of `config.lua`'s `settings` into a setting prototype |
| `terra-nauvis/data.lua` | Requires the expression modules in order (waterways, coast, spawn, regions, climate, tiles, trees, ridges, climate_koppen, resources, hotspots_v2, enemies, destroyed, blue), then the presets. It extends `data` with the mod's own names only |
| `terra-nauvis/data-updates.lua` | Empty, reserved |
| `terra-nauvis/data-final-fixes.lua` | Everything that must read other mods' final prototypes: the hooks on shared tiles, trees and decoratives, the wrappers round live ore and enemy autoplace, the palm copies, the zone look |
| `terra-nauvis/control.lua` | Event wiring only |
| `terra-nauvis/prototypes/expressions/*.lua` | One module per layer of the expression graph |
| `terra-nauvis/prototypes/presets.lua` | The three map-gen presets and the Map type fallbacks |
| `terra-nauvis/prototypes/installed.lua` | What the data stage reads from the installed game and from other mods instead of shipping it: Alien Biomes' shared tile noise call, the base game's tree expressions and its enemy base expression. Each reading is held to a digest recorded in `config.lua` and `tables/vanilla.lua`; a changed text is logged and the caller falls back |
| `terra-nauvis/prototypes/tables/*.lua` | Data in degrees of latitude and longitude: cities, regions, ranges, hotspots, zone outlines. Converted to tiles in the data stage |
| `terra-nauvis/prototypes/generated/*.lua` | Tool output, never edited by hand: coast fits, coarse land fields, overlays, waterway sets per scale, spawn bearings |
| `terra-nauvis/scripts/*.lua` | Control stage: `guards`, `start`, `start_ore`, `bandfix`, `coastcover`, `markers` |
| `terra-nauvis/scripts/generated/*.lua` | Tool output: the Exact coastlines tables |
| `tools/` | Build tools, the static checks, the offline Lua data stage, and test mods under `tools/mods/` that never ship |
| `data-src/` | Sources of the generated files, each folder with a `PROVENANCE.md`: reference rasters, fit checkpoints, waterway courses, hotspot lists, ridge data, zone outlines |
| `tests/` | The frozen registry, measured complexity (`budgets.json`), the place oracle, baselines |

The mod id `terra-nauvis` and the expression prefix `tn_` are two locals in `config.lua` that every name derives
from. Maps have ids: Europe 1, Atlantic 2, Old World 3 (key `olde_world` in code). The reference rasters are
2,400 x 1,704, 15,689 x 6,524 and 8,963 x 5,847 pixels at 45 pixels per degree. Map scale is tiles per pixel.

## Build-time data flow

1. **Reference rasters.** `tools/earthmaps_decode.py` decodes the world data of EarthMaps into three rasters per
   map under `data-src/earthmaps/`: tile classes, land, and thin water.
2. **Coast fit.** `tools/build_geo.py fit` fits the land raster as a sum of tent functions and keeps checkpoints
   under `data-src/fits/<map>/`. `emit` writes `prototypes/generated/geo_<map>_v<n>.lua` and the 256-term
   `land_coarse_<map>_v<n>.lua`; `overlay` writes the land and water overlays used past scale 6; `emit --bandfix`
   writes the Exact coastlines tables.
3. **Waterways.** `tools/build_waterways.py` smooths each river course for each scale, sets widths and fords, and
   writes one `waterways_<map>_s<scale>_v<n>.lua` per map and scale.
4. **Tables.** `tools/build_regions.py`, `build_ranges.py` and `build_hotspots.py` write the region, range and
   hotspot tables from `data-src/`; `tools/build_spawn.py` writes the spawn lake bearing of every city and scale.
   Each has a `check` subcommand that re-emits and compares byte for byte.
5. **Data stage.** `data.lua` loads every generated version that `config.lua`'s `release_registry` lists.
6. **Freeze.** The sha256 of every named noise expression the mod defines is registered in `tests/frozen.json`
   (see "Release versioning policy"). Registration reads a data dump from the game.
7. **Zip.** `tools/build_zip.py` packages `terra-nauvis/` into a byte-reproducible zip: sorted entries, a fixed
   timestamp, fixed attributes, no compression. `--release` first refuses any unregistered or changed body.

## Expression graph

### Programs and the firewall

The game compiles a Tile, an Entity and a Cliff noise program for a surface, and an expression costs once in
every program that reaches it. The **fine field** is each map's elevation entry and every term only it reads:
the coast fit, the far-field box, waterways, fords, inland lakes and offshore stamps. The firewall rule (the code
calls it constraint S-3): no Entity, decorative or Cliff root on a preset may reach the fine field. Everything
outside the Tile program knows land from one coarse field, `tn_land_coarse`, the 256-term checkpoint of the same
fit. `config.lua`'s `firewall` group lists the fine names per map, and a test twin whose coast is a constant
(`tools/mods/ea-coast-twin`) shows that the Entity and Cliff programs do not move when the coast does.

Two vanilla readers would break the rule, so presets redirect them: the starting-ore lake mask reads elevation
inside every ore's spot noise, and Alien Biomes' palms read elevation in the Entity program.

### The coordinate chain

Every geography read goes through one chain of named expressions per geography version:

```
gx = x + cx                  cx, cy: the per-world city offset, so the chosen city sits at world (0, 0)
u  = (gx - floor(s / 2)) / s + wr      s: map scale; u, v in reference pixels, pixel centres at integers
```

Names follow `tn_cx_<map>_v<n>`, `tn_gx_...`, `tn_u_...`. The `floor(s / 2)` term makes the tile corner the game
samples read the fit exactly at a pixel centre at every integer scale. `tools/earthgeo.py` mirrors the chain.
Layers that span the whole map (regions, climate, ridges) read the chain of an older release kept as a frame
(`layer_chain_geo` in `config.lua`), so a new coast version does not move them.

### Elevation composition

An elevation entry `tn_elevation_<map>_v<n>` composes, in this order (`prototypes/expressions/coast.lua`):

1. The coast fit: a sum of tents `c * T(u/h - i) * T(v/h - j)` with `T(t) = max(0, 1 - |t|)` on grids of spacing
   `h = 2^k` pixels. Listed geographies read it at warped coordinates (two octaves per axis), which gives a crisp
   coast instead of a dithered one.
2. The shore transfer: gains for land and water so the tile class equals the sign, with beach and deep-water lines.
3. `min` with the far-field box: deep water beyond the map's extent, behind a noise-warped edge band.
4. `max` with the start land (radius 16 tiles), then `min` with the spawn lake and the inland lakes.
5. Waterways: `min(max(e, dams), carves)`, with the scale's river, canal and dam sets picked by name.
6. Where the Oil Rig is installed, the offshore field stamps.

No term reads the water slider: presets bake `water_level`, `segmentation_multiplier` and
`nauvis_segmentation_multiplier` as constants.

Tent counts per fit: Europe 8,258; Atlantic 10,400, and 11,000 past scale 6 with overlays of 37,147 land and
1,085 water terms; Old World 9,360, and 10,100 past scale 6 with overlays of 11,957 and 6,564. The overlays are
level-0 tents drawn straight from the raster for the islands and inlets a fit of that size misses. Scale is a
folded constant, so a world compiles one branch. Past scale 6 a short tile-scale noise frays the coast
(`coast_fray.lua`), because one reference pixel is then 12 or 24 tiles wide.

### Expression inventory

| Layer | Module | Main names | Reads | Reaches the game through |
|---|---|---|---|---|
| Elevation | `coast.lua`, `coast_fray.lua` | `tn_elevation_<map>_v<n>`, `tn_geo_<map>_v<n>`, `tn_shore_*`, `tn_far_*`, `tn_land_coarse_<map>_v<n>` | chain, generated fits | preset key `elevation`; key `tn_land_coarse` |
| Waterways | `waterways.lua` | `tn_ww_<map>_s<scale>_v<n>`, `tn_canals_*`, `tn_dams_*`, `tn_fords_*`, `tn_warp_x_*` | chain, generated sets | inside elevation; fords through the `water-shallow` hook |
| Spawn | `spawn.lua` | `tn_city_index_<map>_v1`, `tn_city_cx_*`, `tn_distance_v1`, `tn_start_mask_v2`, `tn_spawn_lake_*`, `tn_inland_lakes_*` | `map_seed`, city tables, spawn bearings | preset keys `distance`, `starting_resources_lake_mask` |
| Regions | `regions.lua` | `tn_forest_w_*`, `tn_tree_mult_v1`, `tn_marsh_w_*`, `tn_hotspot_w_v1`, `tn_enemy_mult_v1`, `tn_delta_*` | region tables | consumers read the interface names |
| Climate | `climate.lua` | `tn_lat_v1`, `tn_lon_v1`, `tn_temperature_ab_*` and `tn_temperature_fb_v1`, moisture and aux alike, `tn_north_snow_w_v1` | frame chain | preset keys `temperature`, `moisture`, `aux` |
| Tiles | `tiles.lua` | `tn_vtile_<tile>`, `tn_ab_exclude`, `tn_tile_mix_<n>_v1`, `tn_marsh_water_mud`, `tn_frozen_ground_v3` | climate, regions | hooks on tile autoplace |
| Trees | `trees.lua` | `tn_tree_lift_*`, `tn_palm_const_v1` | regions, climate | hook on every living tree Nauvis places; palm keys |
| Ridges | `ridges.lua` | `tn_cliff_elevation_v2`, `tn_cliffiness_v1`, `tn_crest_<map>_v<n>` | range tables | preset keys `cliff_elevation`, `cliffiness` |
| Resources | `resources.lua`, `hotspots_v2.lua`, `ore_curves.lua` | `tn_hs_<ore>_v1`, `tn_ore_<ore>_p_v2`, `tn_offshore_p_v1`, `tn_fields_<map>_v1` | hotspot tables, `tn_land_coarse` | wrappers round each ore's live autoplace; keys `entity:<ore>:probability` |
| Enemies | `enemies.lua` | `tn_enemy_layer_v2`, `tn_enemy_v1` | hotspot footprints | preset key `enemy_base_probability` |
| Zones | `destroyed.lua`, `blue.lua`, `zone_look.lua`, `zone_exclusion.lua` | `tn_destroyed_*`, `tn_blue`, `tn_moscow` | regions, zone outlines | wrap the climate fields; tile scores; prototype edits |

Notes on single layers:

- **Waterways.** Sources per map: Europe 22 rivers, Atlantic 32, Old World 37, nine straits each, and 2, 4 and 3
  canals. A river is `max(floor, k * s)` tiles wide by class. Fords are `water-shallow`, which characters can
  walk. The river warp is a named expression, not a local: the game copies a local into every call that
  reads it, and as a local it cost 6.8 seconds at every start.
- **Spawn.** The city number a preset bakes (0 for Random) becomes an index (Random is a fold of `map_seed`) and a
  tile offset. `distance` is redirected to the distance from the origin, so the base game's starting ore and
  enemy-free start follow the city. Cities: Europe 40, Atlantic 52, Old World 33.
- **Climate.** Temperature, moisture and aux are an Earth mean by latitude and longitude plus a seeded spread, in
  a variant in Alien Biomes' units and a fallback for the base game. North snow bakes 0, 1 or 2 and moves the
  Eurasian snow line 0, 6 or 9 degrees south. `climate_koppen.lua` holds a per-tile Koppen classifier of 14
  classes. It was an experiment in 0.4.0 and is shelved: its setting is hidden and forced off, and its
  expressions stay defined for worlds made with it on.
- **Load-time reads.** The mod ships no text of the base game or of Alien Biomes that it builds on. The tree
  layer reads the base game's named tree expressions, the enemy layer its enemy base expression, and the tile
  scores Alien Biomes' shared noise call, all from the installed prototypes through `installed.lua`. Each text is
  held to a digest (two 32-bit FNV-1a hashes) that `tools/build_installed.py` prints from a data dump, so a newer
  game or Alien Biomes version that changed the text is seen and logged instead of silently read.
- **Tiles.** The mod adds one tile, `terra-nauvis-frozen-ground`, a copy of `dirt-4` with its own picture, used
  for the frozen north on the base game. Its art is drawn by `tools/build_frozen_tile.py`.
- **Ridges.** Each range is a band of cliffs round a crest polyline with openings (adopted passes, and a gap at
  least every 400 km). Two tables hold 16 and 24 ranges; new worlds read both. Ridges are the only cliffs on a
  preset world, and the toggle off gives none. Beside each range, rocks thicken and tall ranges turn to grey
  ground and snow.
- **Resources.** Ordinary ore is the base game's own autoplace, wrapped: the probability is
  `max(live * ridge clearance, hotspot term)`. A hotspot is a disc from a table (27 fields on Europe, 180 on
  Atlantic, 136 on Old World) with its own spot noise. Regional scarcity keeps 0 or 1 per 1,024-tile spot region
  outside a resource's provinces, so whole patches drop out. Biter nests are denser inside a hotspot.
- **Zones.** Destroyed Europe, Blue corrupted UK and the Moscow zone exist only beside Alien Biomes. A zone wraps
  the climate fields inside its outline so Alien Biomes' own tiles follow, and `zone_look.lua` tints creep and
  decals and sets pollution absorption and walking speed on the zone's ground.

### Region layer

Every per-region quantity comes from one layer. Each row of a region table (a disc, a polygon or a buffered path,
in degrees) becomes three expressions: a signed distance, a weight `clamp(mid + sd / width, 0, 1)` and a depth.
Aggregates sum the rows per kind. The first table (`regions.lua`, written by `tools/build_regions.py`) holds 109
rows: 77 hotspots, 16 forests, 12 marshes and the Destroyed Europe polygon. `regions_v2.lua` adds 6 forests and 3
marshes outside Europe, and `regions_v3.lua` adds the river deltas: 6 marsh rows and 18 channel rows, each
channel a distributary traced through the thin water of the reference raster. The layer reads only `x`, `y`,
`map_seed` and per-world constants, so the Entity program may read it.

### Preset redirects

A preset is `{order, basic_settings = {property_expression_names, autoplace_controls}}`. `presets.lua` reads
`settings.startup` at the data stage and writes, among others: `elevation` (the entry's name),
`starting_resources_lake_mask`, `tn_land_coarse`, `tn_map`, `tn_scale`, `tn_geo`, the city number and offset
names, `distance`, `temperature`, `moisture`, `aux`, `cliff_elevation`, `cliffiness`, `enemy_base_probability`,
`tn_on = 1`, and one key per toggle (`tn_ridges`, `tn_hotspots`, `tn_inland_lakes`, `tn_destroyed`, `tn_blue`,
`tn_canals`, `tn_forests_on`, `tn_koppen`) whose value is the name `tn_one` or `tn_zero`. A toggle is read
through a folded `if()`, so only the chosen branch compiles.

Values stored on a surface beat prototype names, so a world keeps what its preset baked whatever the settings
say later. `tn_map` and `tn_geo` have no prototype at all: only a preset world holds them, which is how control
code recognises one. `config.lua`'s `preset_keys` lists every key a preset may set.

### Map type entries

Each map's newest elevation entry also carries `intended_property = "elevation"`, so it appears in the Terrain
tab's Map type dropdown. Since 0.4.0 a preset names the matching entry at every scale, so picking a preset is
the only choice a player makes. A world made from a Map type entry alone sets only `elevation`: every other name
the entry reads has a prototype-level fallback valued as the preset would bake it under the current settings.
Such a world has the map's coast, rivers and spawn with the base game's climate, no fords, ridges or hotspots,
and it follows the settings at every load. Fallbacks that mirror no setting are frozen and registered.

The Terrain tab shows the expression a preset selects for temperature, moisture and aux in a dropdown of its
own. Each such expression has the locale name "Terra Nauvis": `config.lua`'s `terrain_tab` lists them, and
`tools/terrain_names.py` runs the data stage offline over every settings combination that changes them and
checks the list against what the presets select.

### Stable hooks

Every edit to a prototype the mod shares with the base game or another mod has one form:

```
if(tn_on > 0.5, <on branch>, <off value>)
```

The gate `tn_on` is 0 as a prototype and 1 on a preset world. The on branch reads a key with a neutral default
that presets map to a versioned expression; the off value is the prototype's own expression. On any world that is
not a Terra Nauvis preset world the hook folds to the off value at the same complexity as before. The gate is
outermost on purpose: placed inside a tile score it cost default worlds 7,489 in Tile complexity. Hook text never
changes after release.

## Release versioning policy

The append-only rule. A world stores expression names, not expression text, so the text behind a released name
must never change. `tests/frozen.json` holds one record per registered body: its type, the sha256 over its
generation fields (`type`, `name`, `expression`, `local_expressions`, `local_functions`, `parameters`), the dump
it is read from and the date. `tools/tnfrozen.py` is the one reader of that contract.

1. A body's text is immutable from registration on. The checks fail on a missing, changed or unregistered body.
2. Changes ship under new names (`_v<n+1>`), presets point new worlds at them, and old names stay defined.
3. The rule covers every expression a released body reads, vanilla ones included: the mod copies them under its
   own names. The exception is the wrappers round live ore, enemy and offshore oil autoplace, which wrap the
   installed text on purpose so other mods' changes keep acting.
4. `tn_geo` is one id space across all maps. Each geography release takes the next unused integer and keeps it;
   no id is reused. Control code keys release-coupled data by a save's `tn_geo` through `release_registry`,
   never by "newest". `tn_map` ids follow the same rules.
5. A released table file is never edited. A change creates the next file.
6. One generated file per released version. Tools refuse to overwrite a released one.
7. Hook text on shared prototypes never changes after release.
8. A registered body is never changed in place, before the first release either.
9. The expression prefix `tn_` is part of every registered name and is fixed.
10. Only the newest elevation entry of a map carries the GUI fields, which the hash does not cover, so moving
    them edits no registered body.
11. A terrain release takes the lightest version that can hold it. A thin version is a new entry over the older
    one plus a term, with the next `tn_geo`; a full version has its own chain, fit and waterway sets and costs
    megabytes of noise text parsed at every start.
12. A climate or tile change is a re-point, not a geography release: a new body, named by new presets over the
    old one.
13. A change to what Exact coastlines writes keys on the save's `tn_geo`, never on the mod version.
14. A layer that no geography name reads moves by a re-point. This covers the ridges and the hotspot tables: the
    preset value changes, the old bodies stay defined, and a save keeps the names it was made with.
15. A new hotspot table names its bodies over each released name it moves, never reads the name it replaces, and
    a world without the new keys keeps the first table.
16. The game copies a noise local at every read, so a heavy term read from a repeated term takes a name.

One removal is on record. At 0.3.0 each map was cut to one geography version, which made the game start about
4.5 seconds faster with a large mod pack; worlds made before 0.3.0 do not load. `tests/collapsed.json` names the
312 records and 30 files that left, and the checks excuse exactly those. Since then every released world loads.

Current geography versions:

| Map | `tn_geo` | Entry | Role |
|---|---|---|---|
| Europe | 23 | `tn_elevation_europe_v7` | Preset and Map type entry, all scales |
| Atlantic | 22 | `tn_elevation_atlantic_v8` | The version a preset bakes |
| Atlantic | 25 | `tn_elevation_atlantic_v9` | Map type version: frayed coast past scale 6, composition of 22 at or below |
| Old World | 21 | `tn_elevation_olde_world_v8` | The version a preset bakes |
| Old World | 24 | `tn_elevation_olde_world_v9` | Map type version, as Atlantic's |

Who enforces the rule: the static rows `frozen_static`, `bodies` and `append_only` (which compares the tree with
`main` and every release tag), and `tools/build_zip.py --release`, which refuses to build.

## Control stage

### Events

| Event | Script | Work |
|---|---|---|
| `on_init` | guards, bandfix, start, markers | Detect the world, record its map, scale and geography, fix the start chunks, pick the start, draw markers |
| `on_load` | bandfix | Re-register the chunk handler from the stored record. It writes nothing |
| `on_configuration_changed` | guards, bandfix | Missing-name check, drift messages, surface sweep |
| `on_surface_created` | guards | The surface guard |
| `on_player_created` | guards | Send each stored message to the new player once |
| `on_runtime_mod_setting_changed` | markers | Draw or remove city markers |
| `on_chunk_generated` | bandfix | Exact coastlines, only on a world whose preset baked `tn_bandfix` |

`on_tick` and `on_nth_tick` are never registered, and no per-chunk event exists outside `scripts/bandfix.lua`;
the static `registration` row checks registrations against this table. Control code reads save state only (the
surface's expression names, `storage`, `calculate_tile_properties`, `script.active_mods`) and never calls
`math.random`.

### Guards

`scripts/guards.lua` recognises a preset world by `tn_geo` on the Nauvis surface and a Map-type-only world by its
elevation entry. It stores `storage.earth` (map, scale, geography, warnings) or `storage.map_type`. At a
configuration change it checks that every name the world holds is still defined, and prints a drift line when a
changed setting cannot reach a preset world. `record_warning` is the only writer of the stored warnings, and
each is delivered to every player once, because a message printed in `on_init` reaches nobody.

### D33 surface guard

A surface made after the world starts inherits the save's default expression names, so another planet would
inherit Earth. On every surface other than Nauvis the guard removes each key of `preset_keys` whose value equals
the save's default; a planet that sets a key itself keeps it. D33 is the name the code uses for this rule.

### Exact coastlines

`scripts/bandfix.lua` holds the coast to the reference raster on Atlantic and Old World at scales 1 to 6. For
each new chunk it maps tiles to reference pixels, returns early when the chunk holds no coast pixel, finds the
tiles of the wrong class, decides by the reference blurred over each pixel's 3 x 3 neighbourhood plus a smooth
wobble, and makes one `set_tiles` call. It never writes within 24 tiles of the spawn or inside a river, strait or
canal footprint. Its tables are in `scripts/generated/`: one shared table per map and one mask table per scale.
`scripts/coastcover.lua` then gives land written over water the trees, rocks and decoratives of the land beside
it, from a generator seeded by the map seed and the chunk position. The game's own `regenerate_entity` and
`regenerate_decorative` cost 7 to 90 ms a chunk on Old World, which is why this exists.

The handler is a pure function of the chunk's position, its generated tiles and the shipped tables. It writes no
storage per chunk and reads no player state; its decoded rows are a cache of shipped data, so a peer that joins
with an empty cache computes the same tiles.

At world start, `scripts/start.lua` reads the resolved city back with `calculate_tile_properties`, sets the intro
message, and stores the RSO and zone warnings. `scripts/start_ore.lua` floods the land the player can reach on
foot within 160 tiles and places a patch of any starting ore that land lacks.

## Compatibility

### Alien Biomes

Optional, and the three zones need it. Beside it the presets redirect the climate to the variant in its units,
re-list the 19 vanilla land tiles behind the gate, keep its other land tiles out of the temperate band, and
rewrite its tile scores to read twelve shared noise fields, built from the noise call the installed land tiles
hold (read at load time, as the notes under "Expression inventory" describe). Its two palms read `elevation` in the Entity program,
so presets point them at copies that read a constant. The copies are built at load from the installed palms and
compared with a digest in `config.lua`; on a mismatch each copy becomes the neutral body and the log says why, so
a new Alien Biomes version loads without error. The vanilla cliff is re-pointed at Alien Biomes' cliff sheets.

### Space Age, Cargo Ships, RSO

- **Space Age.** Hooks apply only to prototypes Nauvis places, a re-listed decorative keeps the tiles of every
  other planet that places it, and the surface guard keeps Earth off other surfaces.
- **Cargo Ships and the Oil Rig.** Canals and straits are sea-level channels. Where `offshore-oil` exists the mod
  wraps its autoplace with a sea mask and adds offshore fields as deep-water stamps; the coast never moves.
- **RSO.** Not supported. It replaces the map's ore; the game warns at the start and continues.

## Test layers

| Layer | Command | Needs | Checks |
|---|---|---|---|
| Static rows | `python tools/earth_test.py static` | Python, luaparser, luacheck; no game | 23 rows: lint, `info.json`, locale, event registrations, names, design rules, data provenance, the frozen registry, table re-emission, zip reproducibility, and fixtures that each rule must fail |
| Offline data stage | `tools/tnlua.py` (library) | `tests/vanilla-raw.json` | A Lua 5.2 subset interpreter in Python runs the mod's settings and data stages and returns every prototype, so each body's hash is checked without the game |
| Frozen registry | rows `frozen_static`, `bodies`, `append_only` | git history | 2,272 records; no registered body changes or leaves |
| Tool self-tests | `t1_metrics.py selftest`, `oracle.py selftest`, `dump_render.py selftest`, `nav.py selftest` | numpy, Pillow | The measuring tools against analytic cases: 62, 760, 10 and 13 checks |
| Game-backed | `earth_test.py gate`, `suite`, `install-check`, `baseline`, `freeze` | the game and a test harness | Previews, forced generation, dumps and timing on an isolated game instance, compared with the oracle and the stored baselines |

`tests/oracle/` names places with their latitude and longitude and what must be true there (308 places on
Europe, 452 on Atlantic, 390 on Old World): a city on land, a strait open, a pass through a range, a hotspot at
its site. `tests/budgets.json` holds measured complexity, never thresholds.

What runs from a clone of this repository: the zip build, the table checks and the tool self-tests. The offline
data stage needs `tests/vanilla-raw.json`, which holds base game text and is not published; a contributor builds
it from an installed game with `tools/make_vanilla_raw.py`. The game-backed layer needs a harness that starts the
game headless on an isolated profile and is not in this repository. CONTRIBUTING.md has the details.

## Performance

Noise program complexity as the game reports it, recorded in `tests/budgets.json` (64 px previews, seed 1000,
scale 6, every toggle on, game build 2.1.24):

| World | Tile | Entity | Cliff |
|---|---|---|---|
| Base game, default preset | 10,068 | 8,549 | 287 |
| Terra Nauvis: Europe | 105,853 | 17,898 | 667 |
| Terra Nauvis: Atlantic | 148,260 | 24,594 | 1,483 |
| Terra Nauvis: Old World | 140,845 | 22,777 | 1,138 |
| Alien Biomes alone | 68,924 | 24,377 | 287 |
| Old World beside Alien Biomes | 152,848 | 45,094 | 1,138 |

With the mod installed, a world made from the default preset has the base game's own numbers: the hooks fold
away. The Tile program carries the coast; the Entity program grows by a factor of two to three, not ten, because
of the firewall.

The settings tooltips state each layer's cost at Old World scale 12: ridges terrain +2 percent and entities +1
percent, ore hotspots entities +6 percent, inland lakes terrain +0.3 percent, Destroyed Europe terrain +2 and
entities +7 percent, Blue corrupted UK terrain +1.5 and entities +4.5 percent.

Startup cost is text. The game parses every expression at each start, at about 0.5 microseconds a byte, and
expands every function call there. Three changes came from that: one geography version per map (about 4.5 seconds
with a large mod pack), names instead of locals for heavy shared terms (6.8 seconds), and the thin Map type
versions of rule 11.
