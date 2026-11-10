#!/usr/bin/env python3
"""The digests of what the mod reads from the installed game and from other mods at load time
(terra-nauvis/prototypes/installed.lua; NOTICE.md, "Read at load time, not shipped").

  python tools/build_installed.py --dump <dump-data run dir>   print the digests a dump gives
  python tools/build_installed.py --check [--dump <run>]       the recorded digests are well formed; a dump matches them

The mod ships neither the arguments of Alien Biomes' tile noise nor the base game's tree expressions and enemy
base expression. Its data stage reads them from the installed prototypes and holds each to a digest recorded in
config.lua (tiles.noise_share.call.digest, enemies.base.digest) and prototypes/tables/vanilla.lua (each tree
row's digest), so a newer Alien Biomes or a game update is seen and logged. This tool computes the same digests
from a data-raw-dump.json, so the records can be made and checked without the text entering the repository:

  tile noise  a dump of a modset holding Alien Biomes and not this mod: the one noise call the most land tiles'
              scores hold, each once (installed.lua tile_noise), reduced to its signature
  trees       any dump: the base game's named tree expressions (vanilla.lua trees[].expression)
  enemies     any dump without this mod: the base game's enemy base expression, its local expressions and its
              texture function (installed.lua enemy_text)

The digest is build_palms.py's: two 32-bit FNV-1a hashes over the UTF-8 text.
"""
import argparse
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

import build_palms  # noqa: E402
import tnconfig  # noqa: E402

VANILLA = REPO / "terra-nauvis" / "prototypes" / "tables" / "vanilla.lua"
HEX16 = re.compile(r"[0-9a-f]{16}")
ARG = re.compile(r"\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*", re.S)


class InstalledError(RuntimeError):
    pass


def digest(text, cfg=None):
    d = (cfg or tnconfig.load())["tiles"]["palm"]["digest"]
    return "".join(d["hex"] % build_palms.fnv(text, b, d) for b in d["bases"])


def arguments(body):
    """installed.lua arguments: {name: value} in the order written, or None."""
    args = {}
    for part in body.split(","):
        m = ARG.fullmatch(part)
        if not m or m.group(1) in args:
            return None
        args[m.group(1)] = m.group(2)
    return args


def signature(args, own):
    return ",".join(k + "=" + "".join(args[k].split()) for k in sorted(args) if k != own)


def calls(text, fn):
    """installed.lua calls: the body of every call of `fn` that nests no other call."""
    opener, pos = fn + "{", 0
    while True:
        s = text.find(opener, pos)
        if s < 0:
            return
        e = s + len(opener)
        close = text.find("}", e)
        if close < 0:
            return
        body = text[e:close]
        if not (s > 0 and re.match(r"[A-Za-z0-9_]", text[s - 1])) and "{" not in body:
            yield body
        pos = e


def tile_noise(dump, cfg):
    """installed.lua tile_noise without the digest test: the found call's signature and how many tiles hold it."""
    C = cfg["tiles"]["noise_share"]["call"]
    prefixes = tuple(cfg["climate"]["grain"]["prefixes"])
    texts = {}
    for name, tile in (dump.get("tile") or {}).items():
        text = (tile.get("autoplace") or {}).get("probability_expression")
        if isinstance(text, str) and name.startswith(prefixes):
            texts[name] = text
    if not texts:
        raise InstalledError("the dump holds no land tile of config.lua climate.grain.prefixes (is Alien Biomes in it?)")
    held = {}
    for name in sorted(texts):
        seen = {}
        for body in calls(texts[name], C["fn"]):
            args = arguments(body)
            if args and re.fullmatch(r"[0-9]+", args.get(C["own"], "")):
                sig = signature(args, C["own"])
                seen[sig] = seen.get(sig, 0) + 1
        for sig, n in seen.items():
            held[sig] = held.get(sig, 0) + (1 if n == 1 else len(texts) + 1)
    once = {sig: n for sig, n in held.items() if n <= len(texts)}
    most = max(once.values(), default=0)
    found = [sig for sig, n in once.items() if n == most]
    if len(found) != 1:
        raise InstalledError(f"no one call stands once in most of the {len(texts)} tiles")
    return found[0], most


def tree_digests(dump, cfg, table=None):
    """{expression name: digest} of the base game's tree expressions vanilla.lua names."""
    table = table or tnconfig.load(VANILLA)
    ne = dump.get("noise-expression") or {}
    out = {}
    for row in table["trees"]:
        text = (ne.get(row["expression"]) or {}).get("expression")
        if not isinstance(text, str):
            raise InstalledError(f"the dump has no text for the named expression {row['expression']}")
        out[row["expression"]] = digest(text, cfg)
    return out


def enemy_digest(dump, cfg):
    """installed.lua enemy_text and its digest: the enemy base expression's text, its local expressions by name
    and the texture function's parameters and text."""
    C = cfg["enemies"]["base"]
    proto = (dump.get("noise-expression") or {}).get(C["name"]) or {}
    texture = (proto.get("local_functions") or {}).get(C["texture"]) or {}
    if not isinstance(proto.get("expression"), str) or not isinstance(texture.get("expression"), str):
        raise InstalledError(f"the dump has no {C['name']} with a text and the function {C['texture']}")
    lines = ["e " + proto["expression"]]
    lines += [f"l {k} {build_palms.text_of(v)}" for k, v in sorted((proto.get("local_expressions") or {}).items())]
    lines += ["f " + ",".join(texture.get("parameters") or []), "e " + texture["expression"]]
    return digest("\n".join(lines), cfg)


def check(cfg=None, table=None):
    """Findings for the records: each a digest of this tool's form."""
    cfg = cfg or tnconfig.load()
    table = table or tnconfig.load(VANILLA)
    out = []
    C = (cfg["tiles"]["noise_share"].get("call") or {})
    if not C.get("version") or not HEX16.fullmatch(str(C.get("digest"))):
        out.append("config.lua tiles.noise_share.call does not record Alien Biomes' version and a digest from this tool")
    B = (cfg.get("enemies") or {}).get("base") or {}
    if not B.get("game") or not HEX16.fullmatch(str(B.get("digest"))):
        out.append("config.lua enemies.base does not record the game's version and a digest from this tool")
    for row in table["trees"]:
        if not HEX16.fullmatch(str(row.get("digest"))):
            out.append(f"vanilla.lua's row of {row.get('tree')} records no digest from this tool")
        if "text" in row:
            out.append(f"vanilla.lua's row of {row.get('tree')} holds the base game's text")
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--dump", help="a dump-data run directory (with Alien Biomes for the tile noise)")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args(argv)
    if not a.dump and not a.check:
        ap.error("--dump or --check")
    cfg = tnconfig.load()
    table = tnconfig.load(VANILLA)
    f = check(cfg, table) if a.check else []
    if a.dump:
        dump = json.loads((Path(a.dump) / "data-raw-dump.json").read_text(encoding="utf-8"))
        try:
            sig, n = tile_noise(dump, cfg)
            got = digest(sig, cfg)
            print(f"INSTALLED tile-noise digest {got} tiles={n}")
            if a.check and got != cfg["tiles"]["noise_share"]["call"]["digest"]:
                f.append(f"the dump's tile noise reads {got}, config.lua records "
                         f"{cfg['tiles']['noise_share']['call']['digest']}")
        except InstalledError as e:
            print(f"INSTALLED tile-noise none ({e})")
            if a.check:
                f.append(f"the dump gives no tile noise: {e}")
        try:
            for name, got in tree_digests(dump, cfg, table).items():
                print(f"INSTALLED tree {name} digest {got}")
                want = next(r.get("digest") for r in table["trees"] if r["expression"] == name)
                if a.check and got != want:
                    f.append(f"the dump's {name} reads {got}, vanilla.lua records {want}")
        except InstalledError as e:
            print(f"INSTALLED trees none ({e})")
            if a.check:
                f.append(str(e))
        try:
            got = enemy_digest(dump, cfg)
            print(f"INSTALLED enemy-base digest {got}")
            if a.check and got != cfg["enemies"]["base"]["digest"]:
                f.append(f"the dump's enemy base expression reads {got}, config.lua records "
                         f"{cfg['enemies']['base']['digest']}")
        except InstalledError as e:
            print(f"INSTALLED enemy-base none ({e})")
            if a.check:
                f.append(str(e))
    if a.check:
        print(f"INSTALLED {'ok' if not f else 'fail'} {f[:3]}")
    return 0 if not f else 1


if __name__ == "__main__":
    sys.exit(main())
