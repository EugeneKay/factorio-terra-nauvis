#!/usr/bin/env python3
"""Write tests/alien-biomes-raw.json, Alien Biomes' land tiles as the installed mod defines them, for the offline
Alien Biomes data stage.

  python tools/make_ab_raw.py --dump FILE        reduce a data-raw-dump.json of the base game plus Alien Biomes
  python tools/make_ab_raw.py --dump FILE --out OTHER

The mod ships none of the arguments of Alien Biomes' tile noise: its data stage reads them from the installed
tiles (terra-nauvis/prototypes/installed.lua). The offline data stage (tools/tnlua.py, the bodies, release_zip
and fixtures rows and build_zip.py --release) therefore needs those tiles too, and reads them from this file,
beside tests/vanilla-raw.json. The file holds Alien Biomes' own text, which its licence does not let anyone
distribute, so it is made locally from the installed mod, is ignored by git and is never committed or
published. A checkout without it (a CI runner always) runs the offline Alien Biomes stage on the mod flag alone and
reports the bodies built from the tile noise as skipped, never as passed; the gate's frozen row compares them with
Alien Biomes loaded.

The dump must come from `--dump-data` of Factorio 2.1 with the base game, Alien Biomes and Alien Biomes Graphics
and nothing else (through the local test harness, not part of this repository: its `modset <name> --add <the
two zips>`, then `dump-data --instance <name> --modset <name> --out <new folder>`; the dump is
<folder>/data-raw-dump.json). A dump that holds this
mod's prototypes is refused: its hooks have rewritten the tiles. The reduction keeps, of every tile the base
game does not define and config.lua climate.grain.prefixes names, the name, type and autoplace
(tnlua.AB_RAW_FIELDS). The output is sorted JSON, so the same mod gives the same bytes.

Prints one RESULT line with the tile-noise digest the file gives; exit 0 only when the file was written.
"""
import argparse
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent
sys.path.insert(0, str(HERE))

import build_installed  # noqa: E402
import tnconfig  # noqa: E402
import tnlua  # noqa: E402

OUT = tnlua.AB_RAW
NOTE = ("Alien Biomes' land tiles (name, type, autoplace) from a --dump-data of the base game plus Alien Biomes, for "
        "the offline Alien Biomes data stage (tools/tnlua.py ab_base). Local to this machine: it holds Alien Biomes' "
        "own text and is never committed or published. Regenerate with tools/make_ab_raw.py after an Alien Biomes "
        "update.")


class MakeError(Exception):
    pass


def reduce_dump(dump, cfg=None, vanilla=None):
    """{"format", "note", "raw"} from a whole data-raw-dump.json of the base game plus Alien Biomes."""
    cfg = cfg or tnconfig.load()
    vanilla = tnlua.vanilla_raw() if vanilla is None else vanilla
    prefix = cfg["keys"]["on"].split("_")[0] + "_"
    ours = sorted(n for n in (dump.get("noise-expression") or {}) if n.startswith(prefix))
    if ours:
        raise MakeError(f"the dump holds this mod's prototypes ({ours[0]} and {len(ours) - 1} more): dump the base "
                        f"game plus Alien Biomes alone")
    prefixes = tuple(cfg["climate"]["grain"]["prefixes"])
    tiles = {}
    for name, tile in (dump.get("tile") or {}).items():
        if name.startswith(prefixes) and name not in (vanilla.get("tile") or {}):
            tiles[name] = {k: tile[k] for k in tnlua.AB_RAW_FIELDS if k in tile}
    if not tiles:
        raise MakeError("the dump holds no Alien Biomes land tile: is Alien Biomes in the modset?")
    return {"format": tnlua.AB_RAW_FORMAT, "note": NOTE, "raw": {"tile": tiles}}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--dump", required=True, help="a data-raw-dump.json of the base game plus Alien Biomes")
    ap.add_argument("--out", default=str(OUT), help="the file to write (default tests/alien-biomes-raw.json)")
    a = ap.parse_args(argv)
    try:
        cfg = tnconfig.load()
        data = reduce_dump(json.loads(Path(a.dump).read_text(encoding="utf-8")), cfg)
        text = json.dumps(data, indent=1, sort_keys=True) + "\n"
        out = Path(a.out)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(text.encode("utf-8"))
        problem = tnlua.ab_raw_problem(out)
        if problem:
            raise MakeError(f"the written file does not read back: {problem}")
        sig, n = build_installed.tile_noise(data["raw"], cfg)
        got = build_installed.digest(sig, cfg)
    except (MakeError, build_installed.InstalledError, tnlua.LuaError, OSError, ValueError) as e:
        print(f"RESULT fail {e}")
        return 1
    want = cfg["tiles"]["noise_share"]["call"]["digest"]
    print(f"RESULT ok out={out} bytes={len(text.encode('utf-8'))} tiles={n} tile_noise_digest={got} "
          f"config={'equal' if got == want else 'differs: ' + want}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
