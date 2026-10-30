# Old World coast fit: provenance

The checkpoints here are the inputs of `tools/build_geo.py` for Old World (ARCHITECTURE.md,
"Build-time data flow", step 2). The static data-src row re-hashes every file of
this folder against the table below, and the gate's `geo_emit` row re-emits the two generated bodies
from them twice and compares each byte for byte with the committed Lua.

## Source


```
python tools/build_geo.py fit --map olde_world --work <work folder>
python tools/build_geo.py curve --map olde_world --work <work folder>
```

Target: the reference signed distance soft-saturated as `4 * tanh(sdf / 4)` px, thin water
filled as land with weight 0; tents on dyadic grids from 1 to 1024 px (K 10); greedy selection
growing 1.25 times per step from 64 terms; one-sided refit with margin 1 px (lam 0.0001, 4 Newton

python tools/build_geo.py emit --map olde_world
```

## Emission

```
python tools/build_geo.py emit --map olde_world
```


## Files and sha256

| File | sha256 | Source |
|---|---|---|
