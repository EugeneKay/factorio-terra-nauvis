# Contributing

Bug reports, proposals and pull requests are welcome. This page says what a useful report holds, how to build the
mod, which checks run from a clone, and the one rule every terrain change must follow.

## Report a bug

Open a [bug report](https://github.com/jakemismas/factorio-terra-nauvis/issues/new?template=bug_report.yml). A
world generation bug can only be found again in the same world, so the form asks for:

- the mod version and the Factorio version (and whether Space Age is enabled);
- the map preset, the map scale and the spawn city the world was created with;
- the map seed: type `/seed` in the game's chat;
- every Terra Nauvis setting that is not at its default, and the other enabled mods with their versions;
- what you saw and what you expected, with a map position if the bug is at a place;
- for a crash or an error, the lines round it from `factorio-current.log` in the game's user data folder;
- a screenshot of the map view and one in the world.

Two things are not bugs. A world keeps the terrain it was created with, so a fix in a new version shows in new
worlds only. And a world made from a Map type entry alone (picked in the Terrain tab without the preset) has the
map's coast, rivers and spawn with the base game's climate, and it follows the mod settings at every load.

## Propose a change

Open a [feature request](https://github.com/jakemismas/factorio-terra-nauvis/issues/new?template=feature_request.yml)
before you write code, so the approach can be agreed first. For a new place (a city, a range, a deposit, a river
course) give the source of its position and size and the source's licence: every table in the mod is built from
recorded sources, listed in the `PROVENANCE.md` files under `data-src/` and in [NOTICE.md](NOTICE.md).

## Set up

You need Factorio 2.1.24 or newer, Python 3.13 and git.

```
git clone https://github.com/jakemismas/factorio-terra-nauvis.git
cd factorio-terra-nauvis
pip install -r tools/lint/requirements.txt
python tools/build_zip.py
```

`tools/lint/requirements.txt` pins luaparser 4.2.0, which the build and the checks use to read
`terra-nauvis/prototypes/config.lua`. The geometry tools also import numpy, Pillow and scipy, which are not pinned.
`build_zip.py` writes `dist/terra-nauvis_<version>.zip` and prints one `RESULT ok` line with its sha256. Two builds
of the same tree give the same bytes. Copy the zip into the game's mods folder, with no other `terra-nauvis_*.zip`
beside it, and start the game.

### What runs from a clone

| Command | Needs | What it tells you |
|---|---|---|
| `python tools/build_zip.py` | luaparser | The mod packages, and which sha256 it has |
| `python tools/tnconfig.py` | luaparser | `config.lua` parses; prints it as JSON |
| `python tools/build_hotspots.py check` | luaparser | The three hotspot tables re-emit byte for byte from `data-src/hotspots/` |
| `python tools/build_ranges.py check2` | luaparser | The second range table re-emits from `data-src/ridges/ranges-v2.json` |
| `python tools/build_spawn.py check --map europe` | numpy | The spawn bearings re-emit (also `atlantic`, `olde_world`) |
| `python tools/build_palms.py --check` | luaparser | The palm digest in `config.lua` is consistent |
| `python tools/t1_metrics.py selftest`, `oracle.py selftest`, `dump_render.py selftest`, `nav.py selftest` | numpy, Pillow | The measuring tools agree with their own analytic cases |

### What needs a file you build yourself

`python tools/earth_test.py static` runs the 23 static rows: lint, the mod's `info.json`, locale, event
registrations, names, the frozen registry and others. None of them starts the game. Several rows run the mod's
settings and data stages offline in `tools/tnlua.py`, a Lua interpreter written in Python, and that needs the
base game's prototypes in `tests/vanilla-raw.json`. The file holds text that belongs to Wube Software, so it is
not in the repository and `.gitignore` lists it. Build your own from your installed game:

1. Run Factorio once with `--dump-data` and only the base mod enabled. It writes `data-raw-dump.json` to the
   `script-output` folder of its user data folder.
2. Run `python tools/make_vanilla_raw.py --dump <path to data-raw-dump.json>`. It writes `tests/vanilla-raw.json`
   and prints one `RESULT ok` line.

The lint row needs luacheck 1.2.0: `python tools/lint/fetch_linter.py --dest <folder>` downloads the Windows
binary named in `tools/lint/manifest.json` and checks its sha256; point the `TN_LUACHECK` environment variable at
it.

The same file lets `python tools/terrain_names.py check` run: it runs the data stage offline over every settings
combination that changes what the presets select for temperature, moisture and aux, and checks that each
selected expression is listed in `config.lua`'s `terrain_tab` (and so has its name in the new-game Terrain tab).

Even then, a clone does not pass every row. The rows `locale`, `regions` and `ranges` read research notes that are
not published, and `workflow_scan` and `fixtures` read workflow files this repository does not carry. A failing
row among those five is not your change. `python tools/build_zip.py --release` runs the release checks and has the same
needs.

### What needs the game harness

Everything that runs the game is driven by a test harness that is not in this repository: it starts Factorio
headless on an isolated profile, so a test can never touch a player's saves. That covers
`earth_test.py gate`, `suite`, `install-check`, `baseline` and `freeze`, `game_selftest.py`, `sa_compat.py`,
`dump_render.py run`, `contact_sheet.py` and the test mods under `tools/mods/`. They are published so the method
can be read, and they run before a terrain change is merged. Registering a new
noise expression in `tests/frozen.json` is one of those steps (`earth_test.py freeze`), so a pull request does not
need to do it.

## The append-only rule

A player's world stores the names of the noise expressions it was created with, and the game generates every new
chunk from whatever those names mean in the installed version. If a name's text changes, new chunks no longer
meet old ones. So:

1. **The text of a released noise expression never changes.** `tests/frozen.json` holds the sha256 of every one,
   and the checks fail on a changed or missing record.
2. **Changed behaviour ships under a new name.** Copy the expression to `<name>_v<n+1>`, change the copy, and make
   the presets in `terra-nauvis/prototypes/presets.lua` point new worlds at it. The old name stays defined for
   the worlds that hold it.
3. **Released tables and generated files are never edited.** A new city list, range table or coast fit is a new
   file (`cities_atlantic_v2.lua`, `ranges_v2.lua`, `geo_olde_world_v4.lua`), and the old file stays.
4. **Ids and orders only grow.** A `tn_geo` id is never reused, and a spawn city is appended to its setting's
   list, never inserted: a world stores the city's number.
5. **The text of a hook on a shared prototype never changes** (see "Stable hooks" in ARCHITECTURE.md).

The practical test: load a save made with the last release on your build, explore new chunks, and look for a seam.
Say in the pull request that you did, with the map, scale, city and seed.

## Conventions

- `terra-nauvis/prototypes/config.lua` is pure data and the single source of names and constants. Add a name
  there, not as a string in another file; the `names` row holds every Lua string to it.
- Every noise expression is named `tn_...`, every prototype and setting `terra-nauvis-...`.
- Prefer noise to script. A noise expression shows in the map preview, costs nothing per tick and is the same on
  every machine. The control stage registers no `on_tick`, and `scripts/bandfix.lua` holds the only per-chunk
  handler.
- Look at a visual change in the game at player zoom. The preview hides what the ground looks like.
- Shipped text files hold no dash characters other than the hyphen and no emoji; the `dashes` row checks it.
- Commit subjects are imperative and under 70 characters. Add a line to `CHANGELOG.md` and to
  `terra-nauvis/changelog.txt` for a change a player can see.

## Licence

Terra Nauvis is under the GNU General Public License version 3, and a contribution is accepted under the same
licence. Data you add must come from a source whose licence allows it, recorded in a `PROVENANCE.md` beside the
data and in NOTICE.md. Do not copy expression text, tables or art from the base game or from another mod: where
the mod needs another mod's values, it reads them from the installed mod at load time.
