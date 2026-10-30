# Ridge vertex heights: provenance

`vertex-heights.json` gives every crest vertex of the ridge geography (the crest polylines `tools/build_ranges.py`
raster: the EarthMaps rasters carry land classes only, the fit rasters land and water, and the crest geography one
highest point per range. So the values here are the published elevations of the peaks and passes the vertices
name, entered by hand and rounded to the metre. A vertex that names an area rather than a summit (a plateau,
massif, gorge, cape or peninsula) has a representative height. They only set a ridge's width, so a few metres
either way change nothing a player can see.

`tools/build_ranges.py` checks one value per vertex and that no vertex tops its range's `highest_elevation_m` by
more than 1 m, copies them into `prototypes/tables/ranges.lua`, and records this file's sha256 in the table's
header.
