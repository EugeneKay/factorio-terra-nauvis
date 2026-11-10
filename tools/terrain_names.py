#!/usr/bin/env python3
"""The names a Terra Nauvis preset shows in the new-game Terrain tab, and the check that each has a label.

The map generator's Terrain tab has a dropdown for each property a noise expression declares as its
intended_property (elevation, and beside Alien Biomes temperature, moisture and aux). A preset that selects
an expression there shows that expression's name, which the game looks up as [noise-expression] <name> in
the locale; a name without that key reads `Unknown key: "noise-expression.<name>"`. config.lua
`terrain_tab.names` lists every expression a Terra Nauvis preset can select under `terrain_tab.properties`,
the locale file gives each one a label, and tools/tn_static.py's locale row requires that label. The elevation
names are the Map type entries, which carry their own labels.

This tool collects those names by running the mod's data stage offline (tools/tnlua.py), on the base game and
with Alien Biomes' flag (and its installed land tiles from tests/alien-biomes-raw.json where that file exists),
over every settings combination that can change them: the settings in CROSSED in every combination with each
other, every other setting's values one at a time, and every scale with the zones off and on. Koppen biomes is
hidden and pinned off for new worlds, but worlds made with 0.4.0 can still name its expressions, so the
collection includes it on.

Usage:
  python tools/terrain_names.py collect                 print the collected names per property
  python tools/terrain_names.py check                   fail unless config.lua's list equals the collection
  python tools/terrain_names.py check --dump <file>...  also read the presets of game dumps (data-raw-dump.json)
  python tools/terrain_names.py check --quick           skip the spawn city values (the full run takes minutes)

Every command prints one RESULT line last. Exit 0 on success, 1 on a finding, 2 when the stage cannot run.
"""
import argparse
import itertools
import json
import os
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import tnconfig  # noqa: E402
import tnlua  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
MOD = REPO / "terra-nauvis"
AB_MODS = {"alien-biomes": "0.8.0"}

# The settings presets.lua reads when it picks the climate names (the zones' values, the north snow points, the
# forests' moisture and Koppen's names). They are crossed with each other; every other setting varies alone, and
# a change from one of those is reported, since it would mean this list is short.
CROSSED = ("destroyed_europe", "blue_corrupted", "moscow_zone", "north_snow", "great_forests", "koppen")
ZONES_ON = ({"destroyed_europe": True, "blue_corrupted": True, "moscow_zone": "chaos"},
            {"destroyed_europe": True, "blue_corrupted": True, "moscow_zone": "corrupted"})


def setting_values(s):
    if s.get("type") == "bool-setting":
        return [True, False]
    return list(s.get("allowed_values") or [s.get("default_value")])


def combinations(cfg, quick=False):
    """[(label, {setting key: value})], every combination the collection runs, defaults first."""
    sets = cfg["settings"]
    out = [("defaults", {})]
    for values in itertools.product(*(setting_values(sets[k]) for k in CROSSED)):
        combo = {k: v for k, v in zip(CROSSED, values) if v != sets[k].get("default_value")}
        if combo:
            out.append(("crossed " + " ".join(f"{k}={v}" for k, v in sorted(combo.items())), combo))
    for key, s in sets.items():
        if key in CROSSED or (quick and key.startswith("spawn_city")):
            continue
        for v in setting_values(s):
            if v != s.get("default_value"):
                out.append((f"single {key}={v}", {key: v}))
    for v in setting_values(sets["scale"]):
        for zones in ZONES_ON:
            combo = dict(zones, scale=v)
            out.append(("scale " + " ".join(f"{k}={x}" for k, x in sorted(combo.items())), combo))
    return out


def preset_names(dump, cfg, properties):
    """{preset name: {property: expression name}} of the Terra Nauvis presets in a dump."""
    ours = {p["name"] for p in cfg["presets"].values()}
    out = {}
    for name, p in (dump.get("map-gen-presets", {}).get("default") or {}).items():
        if name in ours and isinstance(p, dict):
            pen = (p.get("basic_settings") or {}).get("property_expression_names") or {}
            out[name] = {prop: pen[prop] for prop in properties if prop in pen}
    return out


_STAGE = {}


def _run(job):
    """One offline data stage: (label, ab, combo) -> (label, ab, {preset: {property: name}})."""
    label, ab, combo = job
    cfg = _STAGE.get("cfg") or tnconfig.load(MOD / "prototypes" / "config.lua")
    _STAGE["cfg"] = cfg
    reader = _STAGE.get("reader") or tnlua.reader_for(MOD)
    _STAGE["reader"] = reader
    values = {cfg["settings"][k]["name"]: v for k, v in combo.items()}
    if ab:
        base = None if tnlua.ab_raw_problem() else tnlua.ab_base()
        dump = tnlua.data_stage(reader, values, {**tnlua.DEFAULT_MODS, **AB_MODS}, base)
    else:
        dump = tnlua.data_stage(reader, values)
    props = cfg["terrain_tab"]["properties"] + ["elevation"]
    return label, ab, preset_names(dump, cfg, props)


def collect(cfg, quick=False, workers=None):
    """({property: {name: first label that named it}}, {setting key: labels whose names differ from defaults})."""
    jobs = [(label, ab, combo) for ab in (False, True) for label, combo in combinations(cfg, quick)]
    workers = workers or max(1, min(4, (os.cpu_count() or 2) // 4))
    found, results = {}, {}
    with ProcessPoolExecutor(max_workers=workers) as pool:
        for label, ab, names in pool.map(_run, jobs, chunksize=4):
            results[(label, ab)] = names
            for per in names.values():
                for prop, name in per.items():
                    found.setdefault(prop, {}).setdefault(name, f"{label} ({'Alien Biomes' if ab else 'base game'})")
    moved = {}
    for (label, ab), names in results.items():
        if label.startswith("single ") and names != results[("defaults", ab)]:
            moved.setdefault(label.split()[1].split("=")[0], []).append(label)
    return found, moved


def dump_names(paths, cfg):
    """{property: {name: dump path}} of the Terra Nauvis presets in game dumps."""
    props = cfg["terrain_tab"]["properties"] + ["elevation"]
    found = {}
    for p in paths:
        dump = json.loads(Path(p).read_text(encoding="utf-8"))
        for per in preset_names(dump, cfg, props).values():
            for prop, name in per.items():
                found.setdefault(prop, {}).setdefault(name, str(p))
    return found


def labelled_elevation(cfg):
    """The elevation names that carry their own label: each map's Map type entries and the scale extensions."""
    out = {g["map_type_entry"] for g in tnconfig.geography(cfg).values()}
    out |= {x["entry"] for x in (cfg.get("scale_extensions") or {}).values()}
    return out


def findings(cfg, found):
    tab = cfg["terrain_tab"]
    listed = set(tab["names"])
    collected = {n for prop in tab["properties"] for n in found.get(prop, {})}
    out = [f"{n} is selected ({where}) but not in config.lua terrain_tab.names"
           for prop in tab["properties"] for n, where in sorted(found.get(prop, {}).items()) if n not in listed]
    out += [f"config.lua terrain_tab.names lists {n}, which no combination selects" for n in sorted(listed - collected)]
    elev = labelled_elevation(cfg)
    out += [f"elevation {n} is selected ({where}) and is not a Map type entry with its own label"
            for n, where in sorted(found.get("elevation", {}).items()) if n not in elev]
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("cmd", choices=("collect", "check"))
    ap.add_argument("--dump", nargs="*", default=[], help="game dumps whose presets are read as well")
    ap.add_argument("--quick", action="store_true", help="skip the spawn city values")
    ap.add_argument("--workers", type=int)
    a = ap.parse_args(argv)
    cfg = tnconfig.load(MOD / "prototypes" / "config.lua")
    try:
        found, moved = collect(cfg, a.quick, a.workers)
    except tnlua.LuaError as e:
        print(f"RESULT fail the offline data stage did not run: {e}")
        return 2
    runs = 2 * len(combinations(cfg, a.quick))
    if a.cmd == "collect":
        for prop in sorted(found):
            for name, where in sorted(found[prop].items()):
                print(f"{prop} {name}  first: {where}")
    fails = [] if a.cmd == "collect" else findings(cfg, found)
    fails += [f"{k} is not in CROSSED but changes the names ({', '.join(v)})" for k, v in sorted(moved.items())]
    if a.dump:
        from_dumps = dump_names(a.dump, cfg)
        for prop, names in sorted(from_dumps.items()):
            for name, where in sorted(names.items()):
                if name not in found.get(prop, {}):
                    fails.append(f"{prop} {name} is selected in {where} but the offline collection never selects it")
    for f in fails:
        print(f"FAIL {f}")
    n = sum(len(found.get(p, {})) for p in cfg["terrain_tab"]["properties"])
    print(f"RESULT {'fail' if fails else 'ok'} {a.cmd} runs={runs} names={n} dumps={len(a.dump)} findings={len(fails)}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
