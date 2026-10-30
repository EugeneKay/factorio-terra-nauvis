-- Destroyed Europe's spawn cities (ARCHITECTURE.md, "Module map": prototypes/tables/; slice
-- destroyed-europe).
--
-- Pure data, like config.lua: no function call and no global, so the data stage reads it through require
--
return {
  version = 1,
  zone_cities = {
    atlantic = {"prague"},
    olde_world = {"prague", "frankfurt", "aachen"},
  },
}
