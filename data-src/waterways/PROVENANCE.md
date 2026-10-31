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
`route`. Each `manifest-<map>.json` is written by `python tools/build_waterways.py emit` beside the
generated files it describes. A cut under the waterway cut order (the tool's `cuts` subcommand) is an
edit to `<map>.json` (a river removed from the bottom of its list, or a tolerance raised) regenerated
in the same commit, and the commit cites the timed run that called for it.

| File | sha256 | Role |
|---|---|---|
| `europe.json` | `32fb091c247b7436c03f158fe557d9e28b93bc02e5b5d5b55ac956d4f9253e4e` | tool input |
| `manifest-europe.json` | `c49f8302f788cc6401f6acea3b314d2b1caf3dd7e075abb9c21177a3b55b436b` | emission manifest |
