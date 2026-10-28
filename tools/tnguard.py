#!/usr/bin/env python3
"""
import json
import os
from pathlib import Path



def ws_root():
    # absolute, so a relative FACTORIO_WS cannot mean one folder here and another in a subprocess
    # that runs with the workspace as its working directory
    return Path(os.path.abspath(os.environ.get("FACTORIO_WS") or DEFAULT_WS))


def out_root(ws=None):
    return Path(ws or ws_root()) / "previews" / "earth-build"


def absolute_output(path, base=None):
    """The absolute path a tool writes for `path`: a relative one joined to `base` (the folder the
    p = Path(os.fspath(path))
    if p.is_absolute():
        return Path(os.path.abspath(p))
    return Path(os.path.abspath(Path(base) / p if base is not None else p))


def run_breach(out_dir=None, result=""):
    """Why a finished game run shows it may have left its instance, or None: its RESULT line reads
    fail-NOT-ISOLATED, isolated=NO or isolated=unknown, or a run.json under its --out (the run's
    own, or a scenario's create or bench step) records isolated as anything but true (the harness:
    the game named a write-data path other than its instance's, or none), or a scenario step that is
    not isolated. A launch the harness refused writes no run.json and is no breach. Every caller
    stops all further game runs on a breach: a run that used another write-data, likely the player's
    own profile, would only repeat its writes."""
    res = result or ""
    for word in ("fail-NOT-ISOLATED", "isolated=NO", "isolated=unknown"):
        if word in res:
            return f"its RESULT line reads {word}: {res.strip()[:240]}"
    if out_dir is None:
        return None
    d = Path(out_dir)
    for rj in (d / "run.json", d / "create" / "run.json", d / "bench" / "run.json"):
        if not rj.is_file():
            continue
        try:
            meta = json.loads(rj.read_text(encoding="utf-8"))
        except (OSError, ValueError) as e:
            return f"{rj} is unreadable ({e}), so the run's isolation is unproven"
        if not isinstance(meta, dict) or meta.get("isolated") is not True:
            seen = meta.get("write_data_seen") if isinstance(meta, dict) else None
            return (f"{rj} records isolated={meta.get('isolated') if isinstance(meta, dict) else None} "
                    f"(write data seen: {seen})")
        for sub in ("create", "bench"):
            if isinstance(meta.get(sub), dict) and meta[sub].get("isolated") is False:
                return f"{rj} records its {sub} step as not isolated (write data seen: {meta[sub].get('write_data_seen')})"
    return None
