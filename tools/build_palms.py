#!/usr/bin/env python3
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

import tnconfig  # noqa: E402

AB = "alien-biomes"
QUOTED = re.compile(r"'[^']*'|\"[^\"]*\"")
IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_:]*")


class PalmError(RuntimeError):
    pass




def digest(data):


def idents(text):
    if not isinstance(text, str):
        return set()
    return set(IDENT.findall(QUOTED.sub(" ", text)))


def palm_table(dump, trees):
    """{"trees": {tree: {probability_expression, richness_expression, local_expressions}}, "functions":
    or a field is missing, or a text reads a named expression the copies cannot carry."""
    nf = dump.get("noise-function") or {}
    ne = dump.get("noise-expression") or {}
    out = {"trees": {}, "functions": {}}
    pending = []
    for tree in trees:
        ap = ((dump.get("tree") or {}).get(tree) or {}).get("autoplace")
        if not ap:
            raise PalmError(f"the dump has no autoplace for {tree}")
        rec = {}
        for field in ("probability_expression", "richness_expression"):
            if ap.get(field) is None:
                raise PalmError(f"{tree} has no {field}")
            rec[field] = ap[field]
        rec["local_expressions"] = dict(ap.get("local_expressions") or {})
        out["trees"][tree] = rec
        texts = [rec["probability_expression"], rec["richness_expression"]] + list(rec["local_expressions"].values())
        pending.append((tree, set(rec["local_expressions"]), texts))
    seen = set()
    while pending:
        where, local, texts = pending.pop()
        for text in texts:
            for n in idents(text):
                    continue
                if n in nf:
                    if n not in seen:
                        seen.add(n)
                        f = nf[n]
                        rec = {"parameters": list(f.get("parameters") or []), "expression": f.get("expression")}
                        if f.get("local_expressions"):
                            rec["local_expressions"] = dict(f["local_expressions"])
                        if f.get("local_functions"):
                        out["functions"][n] = rec
                        pending.append((n, set(rec["parameters"]) | set(rec.get("local_expressions") or {}),
                                        [rec["expression"]] + list((rec.get("local_expressions") or {}).values())))
                elif n in ne:
    return out


def trees_of(cfg):
    return list(dict.fromkeys(c["tree"] for c in cfg["tiles"]["palm"]["copies"]))


def check(cfg=None):
    cfg = cfg or tnconfig.load()
    out = []
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--dump", help="a dump-data run directory of a modset holding Alien Biomes")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args(argv)
    cfg = tnconfig.load()
    if a.check:
        print(f"PALMS {'ok' if not f else 'fail'} {f[:3]}")


if __name__ == "__main__":
    sys.exit(main())
