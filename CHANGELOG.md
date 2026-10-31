# Changelog

All notable changes to Terra Nauvis are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/). The changelog players see in the game is
`terra-nauvis/changelog.txt`.

## [0.1.0] - 2026-10-30

First release of Terra Nauvis, for Factorio 2.1.

### Summary

- Three Earth maps as map-gen presets and Map type entries: Terra Nauvis: Europe, Atlantic and Old World, with
  real coastlines at map scales 1 to 6 in an endless deep ocean. Exact coastlines, on by default on Atlantic
  and Old World, holds every shore to the reference with islets, and written land carries trees and ground
  cover.
- A spawn at a chosen or random city on every map (40, 50 and 33 cities), with land around it, a lake nearby,
  the starting ore and an enemy-free start.
- Waterways: great rivers with walkable fords that narrow with the map scale and carry ships at scale 6,
  straits and canals that ships can sail at every scale, and bays and headlands where a map's frame cuts
  through land.
- Earth climate with or without Alien Biomes, Alien Biomes ground by real region, marshes, 16 great forests,
  and the base game's trees, rocks and plants beside Alien Biomes.
- Cliff ridges along 16 mountain ranges with passes, the only cliffs on a map, and highlands of rocks, stony
  ground, and beside Alien Biomes grey rock and snow. Beside Alien Biomes every Nauvis world's cliffs use its
  grey stone art.
- Regular ore in lobed fields gathered in provinces, historic ore hotspots with heavier biters that ignore the
  map sliders, and offshore oil fields with the Oil Rig mod.
- Options: Canals, Great forests, Ridges, Ore hotspots, Ore hotspot amount, Inland lakes, Destroyed Europe
  with Alien Biomes, Exact coastlines, and City markers on the map view.
- Noise draws almost all of the terrain, so the new-game preview shows the map, with the noise coast. Control
  scripts handle what noise cannot: the start of a new world, the guards and warnings, the city markers and
  the Exact coastlines handler.
- Compatibility: Alien Biomes is optional, Space Age works and its other planets stay as they are, RSO is not
  supported and the game warns when it is active.
- Tooling: the static rows, the frozen body registry, reproducible zips, CI on every push and a release built
  by a `v*` tag.
- Verification before release: one security review pass and the in-game playability checks. No multiplayer
  desync test had run, so 0.1.0 was for single player.

### Added

- Ore hotspot amount startup setting: 50, 100, 200 or 400 percent, default 100. It multiplies hotspot richness
  and nothing else, so no hotspot moves or grows.
- Destroyed Europe grows south and differs every seed: the zone runs from France through Switzerland, southern
  Germany, Austria and Slovenia to Ljubljana and down Italy to about Rome, keeping the old zone's coverage
  north of the Alps. The outline lives in `data-src/approvals/destroyed-zone.json`: 15 vertices, each moved
  per seed by up to its own jitter of 30 to 110 km. Three keep paths (Britain, Denmark with the Kiel Canal,
  the Carpathian crest) replace the six exclusion rows. The random pool skips every city the outline can reach
  at any seed (266 km): 18 of Europe's 40. The heat noise runs at 24 tiles instead of 96.
- Start ore guarantee: `scripts/start_ore.lua`, called once from `start.on_init` on an Earth or Map-type-only
  world, floods the land the spawn reaches on foot (water tiles block, within 160 tiles) and, for iron,
  copper, coal and stone, places one patch of half vanilla's mean starting amount on that land where the
  reached amount within 150 tiles is under half of it (config.lua `start_ore`). It is skipped for an ore
  control at size 0 and with RSO's "Ore in starting area" off; beside RSO it adds only what that start lacks.
  It fixes the ore-starved starts of Stockholm (scales 1 to 3) and Athens (scale 5). No noise body changes.
- Climate grain on all three maps beside Alien Biomes: Alien Biomes' tile scores read frayed copies of
  temperature, moisture and aux through `tn_tile_temperature`, `tn_tile_moisture` and `tn_tile_aux`, each
  adding `noise_layer_noise(19)`, the call that frays grass-1's own edges, outside the temperate band. Every
  base world keeps its program, and trees and decoratives keep the plain fields. It is not free: paired CPU
  reads a median 2.2 percent slower at Frankfurt and 1.5 at Moscow. `climate.grain.maps = {}` in config.lua
  turns it off.
- The list hook: beside Alien Biomes, Earth maps stop walking its long tile restrictions on every vanilla land
  tile. 111 decoratives and 64 trees take the vanilla land tiles at the front of the list and multiply their
  probability by the new body `tn_ab_keep_v1`, 0 where vanilla land may lie, so those tiles add no placement;
  the 13 extended decoratives and 5 dead trees take the same front, order only. Tiles do not move. Decoratives
  and trees only Alien Biomes has lose their placements on adopted tiles and water-mud where vanilla land may
  also lie, and thin along the temperate band's edges: about 7 percent of them over nine edge windows.
- Spawn cities on Atlantic and Old World: their geography version 6 (`tn_geo` 17 and 18) carries the spawn
  city, with the city tables `prototypes/tables/cities_atlantic.lua` and `cities_olde_world.lua` merged by
  `prototypes/city_tables.lua`, the city fold, the spawn lake, start mask version 2, the soft map edge, and
  bearings from `tools/build_spawn.py`. Old World's table moves Prague to the real city and appends Frankfurt,
  Aachen and Moscow. 84 new bodies are registered. `tools/tnlua.py` gains Lua patterns (find, match, gmatch,
  gsub) and seeds data.raw from a reduced copy of the base game's prototypes.
- Map type start: a world made from a Map type entry alone gets the start a preset world gets. `start.on_init`
  reads the city back at (0, 0) through the fold the entry reads, sets the start message with the world size
  at the scale read back there as freeplay's intro, and records the RSO warning; `guards.map_type_geography`
  names the version whose entry the world reads. The cliff reset and the warning without Alien Biomes stay
  Earth-only, and a world that is neither gets nothing.
- Spawn correctness: a world made from the Atlantic or Old World Map type entry alone reads the layer chain's
  offset fallbacks (`tn_cx/cy_<map>_v2`), which now name the city fold, so its offshore stamp sits on the
  spawn's ground (before, the chain was 28,266 tiles off at Frankfurt). Destroyed Europe's random pool is now
  defined for Atlantic (`tn_city_pool_atlantic_v1`) and Old World (`tn_city_pool_olde_world_v1`), and Old
  World's zone list adds Frankfurt and Aachen, which lie inside the polygon: 20 Old World seeds with the zone
  on spawned outside it, and a 400-seed sweep per map picked no zone city.
- Europe's real coastline at map scales 1 to 6: `tools/build_geo.py` emits the coast fit from
  `data-src/fits/europe/` as `geo_europe_v1.lua` (8,192 tents plus a local refit of 66) and
  `land_coarse_europe_v1.lua` (256 tents). The Terra Nauvis: Europe preset bakes `tn_map`, `tn_scale`,
  `tn_geo` and the city offset and holds the water slider's three readers, so the slider moves nothing on a
  preset world. `tn_elevation_europe_v1` puts deep water beyond the 14,400 x 10,224 tiles of scale 6.
  `scripts/guards.lua` adds the Map type notice and the drift line. Twelve bodies are registered.
- Mod skeleton and tooling: the `terra-nauvis` 0.1.0 mod with `prototypes/config.lua` as the single source of
  names and constants, the Map scale startup setting (1 to 6, default 6), the GPLv3 `LICENSE` and a written
  source offer. `tools/build_zip.py` builds byte-reproducible zips, and its `--release` refuses any Earth body
  `tests/frozen.json` does not register. Also the test runner `tools/earth_test.py`, the static rows of
  `tools/tn_static.py`, the lint toolchain (luacheck 1.2.0, luaparser 4.2.0), EarthMaps' reference rasters in
  `data-src/earthmaps/`, and the `ci.yml` and `release.yml` GitHub workflows.
- Spawn at a chosen city on Europe: the startup setting "Spawn city: Europe" (Random, the default, plus 40 of
  the 41 EarthMaps Europe cities), the city table `prototypes/tables/cities.lua` and the city fold
  (`tn_city_europe`, baked per save). The base game's starting ore and enemy-free start follow the spawn
  through the `distance` redirect. A spawn lake lies about 72 tiles out on an inland bearing from
  `tools/build_spawn.py`, land is guaranteed within 16 tiles, and sparse inland lakes come by spot noise (8
  per 1,024-tile region). Also the start message, the RSO warning, `tn_geo` 2 and 20 new bodies (32 in all).
- `tools/tnlua.py` runs the settings and data stages offline, so CI checks registered bodies without the game.
- The Atlantic and Old World maps: the presets "Terra Nauvis: Atlantic" and "Terra Nauvis: Old World", each
  from its own native-resolution fit (Old World 4,096 tents at 0.991420, Atlantic 8,674 at 0.991198). Their
  Map type entries are `tn_elevation_atlantic_v1` and `tn_elevation_olde_world_v1`. `tools/build_geo.py` gains
  `fit`, `curve` and `adopt`. Geography version 1 is `tn_geo` 3 for Atlantic and 4 for Old World, with 22 new
  bodies. The startup settings `terra-nauvis-spawn-city-atlantic` (random plus 50 cities) and
  `terra-nauvis-spawn-city-old-world` (random plus 30) default to random.
- Waterways on every map at every scale: rivers, nine straits and canals, carved by `tools/build_waterways.py`
  from `data-src/waterways/` into 18 generated files. Rivers are `max(7, k x scale)` tiles wide by class (18
  and 12 at scale 6); Gibraltar, Dover and the Great Belt are two-way at 11 tiles. Every river has a walkable
  `water-shallow` ford every 60 reference px, 8 tiles long. The startup setting Canals (`terra-nauvis-canals`,
  default on) covers Kiel and Corinth on every map, Suez on Atlantic and Old World and Panama on Atlantic.
  Atlantic keeps all 32 rivers at scale 1, 24 at scale 2 and Europe's 22 from scale 3.
- The shared region layer that marshes, great forests, hotspots, the biter multiplier and Destroyed Europe
  read by name: 112 rows in `prototypes/tables/regions.lua` (the destroyed polygon with six exclusion rows, 16
  forests, 12 marshes, 77 hotspots), written by `tools/build_regions.py`. Each row's signed distance, weight
  and depth and the layer aggregates (`tn_tree_mult`, `tn_marsh_w`, `tn_hotspot_w`, `tn_enemy_mult` and
  others) are built in `prototypes/expressions/regions.lua` in one region frame for all three maps, with one
  shared warp. 515 bodies are registered. Nothing read the layer yet, so no map changed.
- Earth climate on every preset, after EarthMaps' layout: temperature from latitude with Eurasia's continental
  cold and seven dry belts cut from EarthMaps' painted sand, in an Alien Biomes variant and a fallback without
  it, reached through the presets' `temperature`, `moisture` and `aux` redirects, each the Earth mean plus a
  seeded spread. Beside Alien Biomes the 19 vanilla land tiles are re-listed with a temperate lean and its
  palms move to Earth copies that read a constant (`tools/build_palms.py`). The 12 marshes come from the
  region layer's marsh weight, with water-mud pools on land. `tn_geo` 8 to 10.
- Great forests: the startup setting Great forests (default on, baked per save as `tn_forests_on`) puts every
  living tree's own probability under the hook `if(tn_forests_on > 0.5, min(1, (own) * tn_tree_mult), own)`,
  which Earth presets point at the region layer's multiplier for the 16 forests (boost 2). The base game's
  dead and dry trees are left alone. Beside Alien Biomes the base game's 15 living trees, its rocks and its
  decals are rebuilt from `prototypes/tables/vanilla.lua` and restricted to vanilla land, and the 11 vanilla
  decoratives Alien Biomes takes off Nauvis are re-listed. 85 bodies are registered in `tests/frozen.json`.
- Cliff ridges along the 16 ranges, the only cliffs on a map: `prototypes/tables/ranges.lua` (crest polylines,
  54 passes and 53 unnamed gaps), written by `tools/build_ranges.py`, and the cliff bodies in
  `prototypes/expressions/ridges.lua` in contour units, so the frequency, continuity and richness sliders are
  inert. Openings are 20-tile slots across the crest, and the start disc `max(150, starting_area_radius) + 8`
  is ridge-free. The startup setting Ridges (on; off gives 0 cliffs) is baked per save as `tn_ridges`. An ore
  clearance keeps iron, copper, coal, stone, uranium and crude oil off a crest band.
- Ore hotspots, offshore fields, a richness ramp, sparser base ore and heavier biters inside hotspots:
  `prototypes/tables/hotspots.lua` holds 77 rows (Europe 21, Atlantic 77, Old World 63), written by
  `tools/build_hotspots.py`. `prototypes/expressions/` holds `resources.lua` (one spot noise per resource over
  its rows' footprints, with the ramp `1 + 0.5 clamp((d - 450) / 3550, 0, 1)` on the four solid ores) and
  `enemies.lua` (multiplier 4 inside each footprint). The startup setting Ore hotspots (on) is baked as
  `tn_hotspots`, and ore frequency is 0.75 for the six base resources in every preset.
- Soft map edge and the Inland lakes switch: each map's next geography version (Europe's v6, `tn_geo` 14;
  Atlantic's and Old World's v5, 15 and 16) sinks land the map's box cuts into deep water across a
  noise-warped band 4 to 20 reference px inside the box (config.lua `coast.edge_band`: width 12 px, warp 8 px
  from three basis octaves of 32, 12 and 4 px), so the cut reads as a wavy coastline with a beach and a
  deepwater line. Europe's v6 reads its inland lakes through the per-save toggle `tn_inland_lakes` (startup
  setting Inland lakes, default off).
- The optional Destroyed Europe zone: the startup setting `terra-nauvis-destroyed-europe` (default off), baked
  as `tn_destroyed`, on only with the setting and Alien Biomes. `prototypes/expressions/destroyed.lua` holds
  the zone `tn_destroyed_zone_v1` (a 14-vertex polygon less its six exclusion rows, cut by the start disc) and
  its heat `tn_destroyed_heat_v1` (a heat-1 rim at 100.5 climbing over 61 tiles to a core near 130).
  `prototypes/tables/destroyed.lua` lists the zone cities per map (Europe 7 of 40, Atlantic and Old World
  Prague), and the pool `tn_city_pool_europe_v1` keeps a random spawn off a zone city.
- Exact coastlines, acting on no map yet: the startup setting Exact coastlines (`terra-nauvis-exact-coast`,
  default off) and the per-save switch `tn_bandfix`, which a map's preset bakes only when the setting is on
  and config.lua's `bandfix.maps` lists the map. `scripts/bandfix.lua`, the only per-chunk handler, acts on
  Nauvis alone: it corrects the wrong tiles of the K pixels outside the half-pixel band, never kept water,
  waterway footprints or the spawn keep disc. `tools/build_geo.py emit --bandfix` writes one K+ table per map
  for every scale plus per-scale mask tables in `scripts/generated/`, priced in `data-src/bandfix/`.
- Compatibility and completeness checks, with no new feature: suite rows for a full mod pack, the base game's
  completeness rules, a benchmark against vanilla, EarthMaps and Factorio World, and Space Age
  (`tools/sa_compat.py`). The test-only probe `tools/mods/ea-cc-probe` is new, and
  `tools/mods/ea-sa-probe` gains a wide block set and cargo pod landings.
- City markers and size context: the runtime-global setting City markers (`terra-nauvis-city-markers`, default
  off) and `scripts/markers.lua` draw one rendering object in chart mode per city of an Earth world's map, the
  city's name at the tile holding its reference pixel centre, drawn or removed when the setting changes. Every
  scale label, the scale tooltip and every preset description carry two footprints, a 1k SPM factory core of
  683 x 813 tiles and a 9.45k SPM megabase map of 10,000 x 6,000 tiles. One poster per map comes from
  `tools/contact_sheet.py poster`, 2,400 px wide with a legend and scale bars.

### Changed

- Destroyed Europe turns red: a macro noise over the depth gives a class per tile, so lava, black ash, red
  rock and rim red grass mix with no contour. The heat rises to a mean of 142 and starts 30 px in, so the rim
  keeps the climate's trees. Heat-4 covers 16 to 28 percent of the land sampled.
- Beside Alien Biomes the ground follows Earth's biomes instead of latitude alone (`climate.tile_belts`): the
  Congo, the Amazon and South-East Asia are deep green, the Sahara golden with some red rock, Central Asia and
  the Gobi pale sand and gravel, Tibet cold grey and Greenland white. Orange grass is gone.
- Regular ore patches on Earth presets read as natural mineral fields: lobed outlines with satellites, a few
  large fields among many small ones, gathered in provinces, and a richness plateau with pockets instead of a
  cone. Default worlds are unchanged (`resources.natural`).
- Hotspots listen only to the mod's settings: no map slider reaches them, and size none no longer removes
  them.
- A hotspot's ore never leaves its disc, at any scale, seed or amount; a row's disc is an exact circle of
  radius R about its centre. Regular ore of every kind stays out of hotspot discs and different ores' hotspots
  never interleave, by a test on each spot's candidate, so the rules add almost nothing per tile.
- Hotspot jitter is halved, so a disc stands at most a quarter of its radius off its real site.
- Mountain ranges read as highlands, not as a cliff line on grass: big rocks thicken round each range, clear
  of its passes and of every start; the ground leans to dry dirt, and beside Alien Biomes the tops of tall
  ranges turn to grey ground and snow (`ridges.high`, `ridges.ground`, `ridges.rocks`).
- The map's outline reads as a natural ocean margin: where the box cuts land (Europe's North Africa, Russia
  and Anatolia, and Chukotka on Atlantic and Old World) land ends in bays and headlands up to a few hundred
  tiles deep at scale 6, and every spawn city keeps its ground at every seed (`coast.edge_band.outline`).
- Europe's coast is one crisp line too: its geography reads the fit through the coast warp, which ends the
  dark spray on cold coasts, with a thinner shallow rim. Its land agreement with the reference moves from
  97.68 to 97.65 percent at scale 1 (`coast.warp`).
- The soft map edge's strip holds no flat run on Europe and Atlantic: the warp's sum folds back at its bounds
  instead of clamping there (`coast.edge_band.fold_geographies`).
- On Atlantic, Exact coastlines takes written land from a lattice shared across chunk borders and from the
  chunk's corners, so it draws no rectangles of one tile along chunk borders (`bandfix.smooth.corners`).
- Small marshes on Europe and Atlantic read the shared roughness harder, so the Danube delta's outline is no
  disc edge. No noise call is added and Old World keeps its bodies' values (`regions.marsh.edge_gain`).
- Old World's and Atlantic's coasts are crisp lines: their geography versions read the coast fit at warped
  coordinates instead of adding the lattice detail, which dithered a low-slope fit into a band of speckles up
  to 24 tiles wide, and their shallows narrow to a rim like Europe's (`coast.warp`).
- Beside Alien Biomes, temperate ground keeps the base game's plants: every vanilla decorative and dead tree
  reads the vanilla-scale temperature and the base game's own score where vanilla land lies. Brown asterisks
  no longer carpet the ground outside it (`trees.decor`).
- Exact coastlines acts on Old World and Atlantic and is on by default. Atlantic gains K+ tables. The handler
  queries only wrong tiles and writes along a blurred, wobbling reference instead of the raster's stairs;
  written land takes the ground around it and false islands sink into deep water.
- Land Exact coastlines writes takes the trees, rocks and decoratives of the land beside it, so a written
  coast no longer runs as a bare strip: `scripts/coastcover.lua` reads a rate and a sample from the chunk and
  draws per tile with a generator seeded per chunk.
- `tools/build_geo.py emit --map <map> --bandfix --masks-only` rewrites the mask tables from the committed K+
  table in about a minute, for a change that moves waterways only.
- Exact coastlines holds every shore to the reference alike: the write band narrows from half a pixel to about
  a fifth, K covers every coast pixel, the sea's thin water opens as channels and inlets, and islets the
  raster lost return from a vector coastline (`tools/build_islets.py`, `data-src/bandfix/islets-<map>.json`).
- Beside Alien Biomes, razor edges are gone: a cold spot in temperate land frays; a marsh has no dark rim of
  one width and its edge wanders with the pools; aux folds back at its cap, so dry land keeps its tile mix;
  natural moisture stops at 0.92, so forests fill in instead of ringing a moisture peak.
- Destroyed Europe's start disc has an irregular edge and only widens past its 150 tiles.
- Old World's and Atlantic's vanilla land tiles each add a noise of their own beside Alien Biomes, so dry land
  is a patchwork instead of concentric bands with an even dark rim. Europe keeps its look.
- A river thins to a stream at its source instead of ending in a round finger, on all three maps.
- Beside Alien Biomes an Earth preset's land tiles read two of twelve shared noise fields instead of a
  six-octave noise each, which takes Old World's Tile complexity at scale 6 under the generation cost knee.
  Land and water do not move; patches of Alien Biomes ground fall in new places (`tiles.noise_share`).
- Rivers scale down with the map: a river is `max(3, k s)` tiles wide, k 3 for a major river and 2 for the
  rest, so scales 1 to 3 draw rivers of about 3 to 9 tiles where they drew 11, and only scale 6 still carries
  boats everywhere. A river under scale 4 takes no turning basin.
- Rivers, lakes and turning basins read as natural water: `tools/build_waterways.py` smooths a river by at
  least 12 reference px and draws a basin as a short capsule; `waterways.lua` reads every set through one
  shared warp, so the banks wander. Old World at scale 6 ships 926 river segments against 1,339.
- One geography version per map: Europe v6 (tn_geo 14), Atlantic v6 (17) and Old World v6 (18) stay and every
  superseded version goes. 442 bodies dropped, 18 re-registered, noise text 6.50 MB to 3.55 MB, and time to
  load mods falls from 12.0 s to 2.81 s (vanilla 0.52 s). 36 of 36 previews are pixel-identical.
- Until the first release, `tests/unreleased-moves.json` names every landed record that moved and
  `tools/refreeze.py` writes it with the registry from fresh dumps; the release build excuses a record only at
  a listed hash, and a release tag voids the file.
- The climate noise (temperature, moisture, aux, fallback and Alien Biomes) takes a seed1 shift folded from
  the city offset, so each spawn city of a seed has its own tile texture, at no per-tile cost.
- A startup toggle's drift line for Great forests, Ridges, Ore hotspots and Destroyed Europe says the setting
  applies to new worlds only (`drift-toggle-new-only`).
- The north without Alien Biomes: the fallback climate keeps the boreal belt moist and warm enough for
  vanilla's cold trees up to a treeline near 70N, and the great-forests hook gains a boreal lift
  (`tn_tree_lift_v1`). On Old World at scale 6, seed 1000, sand in Siberia goes from 21.7 to 0 percent.
- Startup: each repeated geography body is defined once per chain class, so the newest version of a class
  keeps the coast fit, coarse land field and waterway sets and every older one names them. The dumped noise
  text drops from 13.5 MB to 5.64 MB and "Time to load mods" from 8.24 s to 3.22 s (vanilla 0.46 s).
- The startup setting Exact coastlines (`terra-nauvis-exact-coast`) is hidden (`hidden = true`, default still
  off, the handler and its tables kept): `bandfix.maps` is empty, so it acts on no map and a visible switch
  would mislead. settings.lua now passes a setting's `hidden` field.
- Old World's coasts of Britain, Ireland, the Channel, Denmark and the Baltic: its coast fit grows from 4,096
  to 8,192 terms with Europe weighted 16 times, so the new terms go to Europe's coasts (Europe box agreement
  0.973 to 0.988, worst coast error in Britain 10.5 to 3.5 px).
- Test runs rely on isolated game instances alone to protect the player's own profile, and
  `tools/build_zip.py --out-dir` takes any folder, the game's mods folder included.
- The test runner's game build pin moves to Factorio 2.1.24 build 87808 after Steam's 2026-10-29 update:
  `tests/baselines/build-87808.json` and `tests/budgets.json` re-measured equal to 2.1.23's in every value,
  with no body re-registered.
- The test runner re-derives the suite evidence of every pending feature before it lands. `tools/oracle.py`
  parses the city table once per file content and `tools/tn_static.py` keeps each Lua file's parse per text,
  which cut the static rows from 66 s to 19 s.

### Removed

- Geography versions 1 to 5 of each map (tn_geo 1 to 13, 15 and 16), start mask version 1, and the chain class
  routing and layer chain redirect that served them.
- The river-safe starts files `prototypes/generated/starts_<map>_v1.lua`: no code read them, and Old World's
  file still held Prague's old grid point and lacked Frankfurt, Aachen and Moscow. `build_waterways.py` no
  longer emits them; the manifests keep each city's per-scale start record.
- The placeholder Terra Nauvis: Europe preset, its two noise bodies, its config group and every placeholder
  text.
- The chained profile guard (snapshot and check, the journal) and `earth_test.py guard-rebaseline`; the
  guard-bracket token that `game_selftest.py`, `dump_render.py run` and `oracle.py probe` checked; and the
  write guards (`tnguard.live_output_problem`, `refuse_live_outputs`) in every tool.
