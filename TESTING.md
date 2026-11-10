# Testing

This file is the release smoke test: about 15 minutes in the real game, run on the zip that is about to be
released. The automated checks are described in [ARCHITECTURE.md](ARCHITECTURE.md#test-layers) and
[CONTRIBUTING.md](CONTRIBUTING.md#set-up).

Record the result on the release's issue: the zip's version and sha256, the commit it was built from, and each
step below as pass, fail or not run.

## Before you start

1. Back up `mod-list.json` and `mod-settings.dat` from your mods folder (`%APPDATA%\Factorio\mods` on Windows).
2. Build the zip with `python tools/build_zip.py`. It prints one `RESULT ok` line with the zip's path and sha256.
   With a local `tests/vanilla-raw.json`, run `python tools/earth_test.py static` and
   `python tools/build_zip.py --release` instead; see CONTRIBUTING.md for what those need.
3. Copy the zip to the mods folder, with no other `terra-nauvis_*.zip` beside it.
4. Install Alien Biomes for step 10 and the Terrain tab check of step 4. Every other step runs on the base game
   alone.

## Smoke checklist

1. **Mods menu.** Open Mods. "Terra Nauvis: Earth Maps" 1.0.0 shows its description and thumbnail, and enabling
   it shows no error.
2. **Startup settings.** Open Settings > Mod settings > Startup. Twelve settings are listed: Map scale, Spawn
   city: Europe, Spawn city: Atlantic, Spawn city: Old World, Ore hotspots, Regional scarcity, Ridges, Inland
   lakes, Destroyed Europe, Blue corrupted UK, Moscow zone and North snow. Map scale offers 1 to 6, 12 and 24
   with every map's world size in each label. The spawn city lists offer Random plus 40 cities for Europe, 52
   for Atlantic and 33 for Old World. Koppen biomes, Canals, Exact coastlines, Great forests and Ore hotspot
   size are not listed. Every setting has a tooltip, and no text reads "Unknown key".
3. **Runtime setting.** The Map tab of the mod settings lists City markers, off. With step 2 that makes 13
   visible settings.
4. **New-game screen.** Open Single player > New game. The preset list shows Terra Nauvis: Europe, Atlantic and
   Old World right after Default. Picking one sets the Terrain tab's Map type to the entry of the same name, so
   no second choice is needed. With Alien Biomes enabled the Terrain tab's Temperature, Moisture and Aux
   dropdowns read Terra Nauvis for each Terra Nauvis preset, and none reads "Unknown key".
5. **Preview.** Pick Terra Nauvis: Old World at seed 1000. The preview shows the map around the spawn. Move the
   water slider to none and to its maximum: the preview does not change. Move moisture: the biomes shift and the
   coast stays.
6. **Start.** Set Map scale 6 and Spawn city: Old World to Frankfurt, then start a Terra Nauvis: Old World game.
   The intro names the city and the world size, 53,778 x 35,082 tiles. You stand on land with a lake nearby,
   iron, copper, coal and stone on land you can walk to, and no biters in the starting area.
7. **Explore.** Travel for five minutes in one direction. The game does not crash, the terrain has no seams
   between chunks, and rivers, fords and forests look right on the map view. The Black Forest lies
   south-south-west of the Frankfurt spawn: beside Alien Biomes its ground is forest ground under dense trees.
8. **Saved settings.** Save, change Map scale, and load the save. A message says the world keeps its scale, and
   exploring further shows no seam. Set Map scale back.
9. **City markers.** In a running game, switch City markers on. The map view names the cities. Switch it off and
   the names go.
10. **Zones.** With Alien Biomes enabled, set Destroyed Europe on and start a Terra Nauvis: Old World game at
    Frankfurt. Frankfurt lies inside the zone, so you start in it on cooler ground with the starting ore, and
    the Alps south of it keep their snow. Then disable Alien Biomes, keep the setting on and start again: a
    warning in the chat says the zone needs Alien Biomes. Turn the setting back off.
11. **RSO, if installed.** With RSO active, a Terra Nauvis world shows the RSO warning in the chat and the game
    continues.
12. **Space Age, if you own it.** Start a Terra Nauvis game with Space Age enabled. Nauvis is Earth, and the
    other planets generate as they do without Terra Nauvis.

## Not in this smoke test

- **Multiplayer.** The checklist is single player. The one script that changes tiles per chunk is written to give
  the same result on every machine (see ARCHITECTURE.md, "Control stage"), but this repository records no desync
  test. Before a multiplayer release, host a game, have a second player join and explore new chunks on both
  machines.
- **Exact coastlines.** It acts as chunks generate on Old World and Atlantic at scales 1 to 6, so step 7 reaches
  it only if the route meets a coast. To check it, travel along a coast on either map: channels and islets the
  preview lacks appear, and land written by it carries trees. Europe's map and scales 12 and 24 keep their noise
  coast.
- **River deltas.** They are on new Atlantic and Old World worlds. To check one, start on Old World and travel
  to the mouth of the Nile: the river fans out into several shallow channels across green ground.
- **Old saves.** A world made with 0.3.x or 0.4.0 must load and keep its terrain. Keep one save from each
  released version and load it on the new zip: no message reports a missing name, and exploring new chunks shows
  no seam against the old ones.
