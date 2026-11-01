# Waterways: provenance

The inputs and the emission manifests of `tools/build_waterways.py` (ARCHITECTURE.md, "Build-time data
flow", step 3). The static gate's data provenance row re-hashes every file of this folder against the
table below, and the gate's `ww_emit` row re-emits the generated sets from the inputs twice and
compares each byte for byte with the committed Lua.

## Source

Each `<map>.json` is written by `python tools/build_waterways.py import` from an earlier extraction
of every feature's path (`<map>-features.json` at commit `45c86d706c2124f48112c195813d5a0f696931e0`,
read with `git show`; that history is not part of this repository), drawn over the EarthMaps
reference rasters, and from `data-src/approvals/approvals-data.json`: the adopted rivers in
priority order with their class, the nine straits the extraction drew, and the canals and dams
the approvals put on the map.
Atlantic's ten rivers beyond Europe are routed again at import through `RIVER_WAYPOINTS` with the same
least-cost method over the same rasters, keeping the extracted sea end: each carries its waypoints in
`route`. Each `manifest-<map>.json` is written by `python tools/build_waterways.py emit` beside the
generated files it describes. A cut under the waterway cut order (the tool's `cuts` subcommand) is an
edit to `<map>.json` (a river removed from the bottom of its list, or a tolerance raised) regenerated
in the same commit, and the commit cites the timed run that called for it.

| File | sha256 | Role |
|---|---|---|
| `atlantic.json` | `af03276b2c6a04702e9321a7837214e3005d402a93cc4ebdca6d4ccde13f75fa` | tool input |
| `europe.json` | `32fb091c247b7436c03f158fe557d9e28b93bc02e5b5d5b55ac956d4f9253e4e` | tool input |
| `manifest-atlantic-past.json` | `3ccff8d102ddb18db64507c585c5749d2cf6689ddd33e903daf42b1a9e52d48a` | emission manifest |
| `manifest-atlantic.json` | `c191bb1f42264d0eae0f31909b92683d7dec2a24546d27e1275659ef5272fc47` | emission manifest |
| `manifest-europe-past.json` | `72c4b6ef9ec95175cc7857630375d64c155abad8dbf25a1375a95f4601b9fddb` | emission manifest |
| `manifest-europe.json` | `c49f8302f788cc6401f6acea3b314d2b1caf3dd7e075abb9c21177a3b55b436b` | emission manifest |
| `manifest-olde_world-next.json` | `cc993ee540d4b0ad30bb3f7681919741db76d31079fbce4686d47865e4ccd5fc` | emission manifest |
| `manifest-olde_world-past.json` | `0cc175914477043b18f73f42f07506353043a29cd650185427051ea997096ee8` | emission manifest |
| `manifest-olde_world.json` | `44d58c2912402f2700f0ca7079092dda8e5d250293d3d3054e42fffffe8b9b30` | emission manifest |
| `olde_world.json` | `a23f5c0bb0d62efd39d61532aec11ce7b20e5abc21606fbc584257cb18953f26` | tool input |
