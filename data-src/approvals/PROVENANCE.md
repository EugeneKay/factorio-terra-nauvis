# Approval data: provenance

`approvals-data.json` holds the adopted design data (hotspots, cities, forests, marshes, ranges and passes, canals,
rivers and world sizes per map) that the table emitters read into `terra-nauvis/prototypes/tables/`. It was
generated once by a planning script that is not part of this repository; since then only its free-text rule
notes were reworded. A flipped row is a data edit to this file, never a code change.

| File | sha256 | Source |
|---|---|---|
| `approvals-data.json` | `244cd5e533d5c6e52e1afcef2a1e5dc51a4cafce87b8eadcc1609e431eb2b2c1` | the adopted design tables, their values unchanged since they were generated |
| `destroyed-zone.json` | `28453b5577c471136c420c7a996fb436046d5b7657f0269d2c9446228ad570ab` | the destroyed-Europe zone's outline, written by hand; it supersedes `approvals-data.json` `destroyed_europe_polygon` |
