# Notices

Terra Nauvis
Copyright (C) 2026 Jake Mismas

This program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License version 3 as published by the Free Software Foundation. It comes with no
warranty. See LICENSE. This covers the whole repository, with two limits: data derived from the
sources under "Third-party data" also stays under its source's licence, and the items under "Not
covered by the GPL" are not offered under it.

## Modified work

Terra Nauvis is a modified work based on EarthMaps by HySpeed
(https://github.com/HySpeed/EarthMaps), GPLv3, version 2.1.2, commit 23c647b8. Modified by Jake
Mismas since 2026-10-26; terra-nauvis/changelog.txt dates each version. EarthMaps' world data was
decoded into rasters, its rivers were traced, and its coastlines were refitted as noise expressions and
exact-coast tables. The decoder (tools/earthmaps_decode.py) is a port of EarthMaps' tile decoding,
which comes from Factorio World by TheOddler. EarthMaps' own thanks go to TheOddler, OARC, MojoD,
Loren1350, RedRafe, Nexela, jmatya and its testers. EarthMaps descends from Factorio World by TheOddler
(GPLv3).

The spawn cities are EarthMaps' city lists: their names, countries, order and positions, with a few
cities dropped and a few added. EarthMaps took the positions from Mapcarta. They are approximate.

## Third-party data

Ecoregions: forest and marsh outlines, centres and areas, and the islets the EarthMaps raster lacks,
are derived from RESOLVE Ecoregions 2017. Dinerstein, E. et al. (2017), An Ecoregion-Based Approach to
Protecting Half the Terrestrial Realm, BioScience 67(6), 534-545,
https://doi.org/10.1093/biosci/bix014. Data: https://ecoregions.appspot.com/, licensed under CC BY 4.0
(https://creativecommons.org/licenses/by/4.0/). Changed: polygons simplified, centroids and areas
computed, islets rasterised to the map grid.

OpenStreetMap: the Suez, Kiel and Corinth canal routes and two points at the Strait of Gibraltar use
data (c) OpenStreetMap contributors, available under the Open Database License
(https://www.openstreetmap.org/copyright). Changed: simplified and snapped to the map grid.

Wikipedia: place coordinates, lengths, heights, areas, water depths and some deposit figures were
available under CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/). Text taken from
Wikipedia was shortened and reworded; its authors are the contributors to the cited articles, listed in
each article's history.

Ore hotspots: places and sizes are facts, cited per row in data-src/hotspots/deposits-research.md. Its
country tables quote the USGS Mineral Commodity Summaries 2026 data release, a United States government
work in the public domain. Figures credited to Global Energy Monitor are cited to its pages; Global
Energy Monitor offers its tracker data under CC BY 4.0 unless it notes otherwise.

## Not covered by the GPL

Factorio is (c) Wube Software Ltd. Some texts and numbers in the mod come from the Factorio base game:

- terra-nauvis/prototypes/tables/vanilla.lua holds the autoplace texts of the base game's rocks, rock
  and decal decoratives and fifteen ground decoratives, its trees' autoplace order, control and
  richness, and a score adapted from its dead trees. Alien Biomes clears or rewrites these before any
  other mod loads, so the mod cannot read them from the installed game.
- terra-nauvis/prototypes/config.lua holds short fragments of the base game's resource autoplace
  function, which the mod uses as search strings on its load-time copy of that function
  (resources.natural), with three of its placement numbers, and four numbers of the base game's enemy
  radius and intensity expressions (hotspots_v2.nests), which the mod compares the installed radius with.

These belong to Wube Software, are not offered under the GPL, and are included under the Factorio
Terms of Service (https://factorio.com/terms-of-service), which let a mod include adaptations of
Factorio assets. Wube Software keeps all rights and may ask for their removal. Screenshots in this
repository show Factorio's interface and art, which are also Wube Software's.

The screenshots and GIFs under docs/images also show the art of Alien Biomes by Earendel
(https://mods.factorio.com/mod/alien-biomes) and of other mods installed in the test pack. That art
belongs to its authors, is not offered under the GPL, and appears here only as pictures of the game, as
the Alien Biomes licence allows.


## Read at load time, not shipped

The mod reads the following from the installed game and mods when it loads, holds each to a digest
recorded when the version was tested, and ships none of their text or values
(terra-nauvis/prototypes/installed.lua; tools/build_installed.py prints the digests from a dump):

- the base game's fifteen living-tree expressions (tree_01 to tree_09_red), from which it builds the
  restored trees;
- the base game's enemy base expression (enemy_base_probability), from whose parts it builds the
  enemy layer of the ore hotspots;
- beside Alien Biomes, the noise call of its land tiles' scores, from which it builds twelve shared
  noise fields in its own seeds, and its palms' autoplace, from which it builds the palm copies.

A text that differs from its digest is logged. The trees and the enemy layer then follow the installed
text; the palms and the shared noise fall back to neutral bodies, and the tiles keep their own noise.

The offline checks need the same texts. tests/vanilla-raw.json (tools/make_vanilla_raw.py) and
tests/alien-biomes-raw.json (tools/make_ab_raw.py) are made locally from the installed game and
the installed Alien Biomes. Both hold their owners' text, so neither belongs in the published source,
and the second is ignored by git and never committed.

## Other mods

Terra Nauvis can work beside Alien Biomes by Earendel (https://mods.factorio.com/mod/alien-biomes),
Cargo Ships, Cargo Ships: Oil Rig and Resource Spawner Overhaul. The mod ships none of their code, text
or art. It names some of their prototypes, and when they are installed it reads their prototypes at
load time and wraps some of their autoplace expressions in its own.

Beside Alien Biomes it builds its palms and its shared tile noise from the installed mod, as said
above, and finds each land tile's own noise call by comparing its arguments with the call it read from
the installed tiles. From 1.0.0 it holds no argument of that call. Versions 0.3.0 to 0.4.0 held the
call's five fixed arguments as numbers in terra-nauvis/prototypes/config.lua, and versions up to 0.2.0
held the call's text there. Three numbers in terra-nauvis/prototypes/config.lua
(climate.temperature.ab.shift_per_unit and min, and the ab_bias of moisture and aux) match Alien Biomes'
climate sliders, so its hot, cold, moisture and aux sliders move the Earth climate at Alien Biomes' own
strength per unit.

The offshore oil fields use the offshore-oil density, spot size and additional richness of Cargo Ships:
Oil Rig by robot256 (GPLv3, https://mods.factorio.com/mod/cargo-ships-oil-rig), so they match that
mod's wells.

## Thumbnail

terra-nauvis/thumbnail.png is a crop of a whole-map render of the mod's own world.

## Trademarks

Factorio is a trademark of Wube Software Ltd. Terra Nauvis is an unofficial mod, not made or endorsed
by Wube Software.
