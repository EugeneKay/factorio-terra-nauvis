## What this changes

<!-- One or two sentences a player or a developer understands. Link the issue: "Closes #123". -->

## Kind of change

- [ ] Terrain (anything a noise expression, a table or a generated file decides)
- [ ] Control stage script
- [ ] Settings or locale
- [ ] Tools or tests
- [ ] Documentation

## Checks

- [ ] `python tools/build_zip.py` prints `RESULT ok`.
- [ ] The mod loads in Factorio 2.1 and a new world starts from each preset I touched.
- [ ] `CHANGELOG.md` and `terra-nauvis/changelog.txt` each have a line for a change a player can see.

For a terrain change:

- [ ] It applies to new worlds only. No registered noise expression changed its text: changed behaviour ships
      under a new name (`_v<n+1>`) and the presets point new worlds at it.
- [ ] No released table or generated file was edited: a new version is a new file.
- [ ] I looked at it in the game at player zoom, not only in the preview. Screenshots are below, before and
      after, with the map, scale, spawn city and seed.

## Screenshots

<!-- Before and after. Say the map preset, map scale, spawn city and seed of each. -->
