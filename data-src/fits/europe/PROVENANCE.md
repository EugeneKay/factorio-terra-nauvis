# Europe coast fit: provenance

The checkpoints here are the inputs of `tools/build_geo.py` for Europe (ARCHITECTURE.md, "Build-time
data flow", step 2). The static data-src row re-hashes every file of this folder
against the table below, and the gate's `geo_emit` row re-emits the two generated bodies from them
twice and compares each byte for byte with the committed Lua.

## Source

The one-sided multilevel tent fit of Europe, made by the original experimental fitter (not part of
this repository; `tools/build_geo.py fit` is a port of it) with Python 3.13, numpy 2.5.1 and
Pillow 12.2.0, and kept byte for byte. Its settings: family `mr`, mode `onesided`, D 4, growth 1.25,
at most 524,288 terms, stopping at the agreement bar, then a re-evaluation of every checkpoint.

Target: the reference signed distance soft-saturated as `4 * tanh(sdf / 4)` px, thin water filled as
land with weight 0; tents on dyadic grids from 1 to 1024 px (K 10); greedy selection growing 1.25
times per step; one-sided refit with margin 1 px (`curve.json` holds every parameter).

The curve record (`curve.json`, offline, thin water excluded, 8-connected islands):

| Checkpoint | Terms | Agreement | Coast p99 | Coast max | Islands of 65 px or more present |
|---|---|---|---|---|---|
| `model-256.npz` | 256 | 0.945443 | 14.58 px | 46.52 px | 26 of 80 |
| `model-8192.npz` | 8,192 | 0.991836 | 1.58 px | 7.11 px | 79 of 80 |

## The local island refit

`model-8192.npz` misses one reference land component of 65 px or more: 66 px (8-connected) near
70.30 N, 22.69 E (rows 71 to 75, columns 1504 to 1529), where the model reads -1.85 to 0.29 px. The
recorded local refit adds one level-0 tent at each of its 66 pixel centres, raising each to +1 px
(the fit's margin) and leaving every other pixel centre unchanged, so that every reference land
component of 65 px or more is present:

```
python tools/build_geo.py refit-islands --map europe
```

It writes `model-8192-t1e.npz` (8,258 terms). Offline, with t1_metrics' own definitions
(`python tools/build_geo.py offline --map europe`): agreement 0.991846, coast p99 1.58 px, max
7.11 px, and every land component of 65 px or more present, 86 of 86 4-connected and 80 of 80
8-connected. numpy's `savez` stamps the zip entries with the run's time, so a rerun writes other
bytes holding the same arrays; the committed file is the input of record.

## Emission

```
python tools/build_geo.py emit --map europe
```

`fit.json` names the checkpoint of each body; the tool writes
`terra-nauvis/prototypes/generated/geo_europe_v1.lua` (from `model-8192-t1e.npz`) and
`terra-nauvis/prototypes/generated/land_coarse_europe_v1.lua` (from `model-256.npz`, the coarse land
field) and records terms, factors, row groups, input and output sha256 in
`manifest.json`.

## Files and sha256

| File | sha256 | Source |
|---|---|---|
| `curve.json` | `9505803403ce7b6be7880874be8db4e449dd05c2a3fe702a677b07ecf99ad6a3` | byte copy of `curve.json` from the first Europe fit (multi-resolution, one-sided) |
| `model-8192.npz` | `00409051847b9a2c1063d9bb8e7d61dfcadd60c076645c0b5c0eb3c30b31bbed` | byte copy of `model-8192.npz` from the first Europe fit (multi-resolution, one-sided) |
| `model-256.npz` | `e2d2a2c5bb1191394e42bd0048f232e7b1dfdfb248e70110bbf14ef5dfb82b14` | byte copy of `model-256.npz` from the first Europe fit (multi-resolution, one-sided) |
| `model-4096.npz` | `f2d3c08fe6b585ce661ccfb293497a2627c3571b9df54962fc92e993aa381365` | byte copy of `model-4096.npz` from the first Europe fit (multi-resolution, one-sided); never shipped: the first-column hitch experiment's cheaper coast (offline 0.986675, under T1's bar) |
| `model-8192-t1e.npz` | `6147b5cda6b11c730905afcac68b21cd10b1801f56ad5e7f7d4611b5be134dd8` | `build_geo.py refit-islands` over `model-8192.npz` |
| `fit.json` | `fba17eac34798675ed3cc38fc1c2645bfa512b36e7e9f7c7e6cf3aaa4a99fdd9` | the emitter's input: which checkpoint each body uses |
| `manifest.json` | `547c4303f13605b3abbfd933ee79ac2f3472bdd9da74ea6c3b0ceadc6e3de469` | `build_geo.py emit` |
