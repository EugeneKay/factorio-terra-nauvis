-- registration row allows only the events of ARCHITECTURE.md's event table ("Events"): never on_tick or
-- guards: world detection and the Map type notice in on_init, the missing-name guard and the drift
-- line in on_configuration_changed, the withheld-preset warning in both, and the notice and the
local guards = require("scripts.guards")
local start = require("scripts.start")

script.on_init(function()
  guards.on_init()
  guards.sweep_surfaces()
end)

script.on_configuration_changed(function(data)
  guards.on_configuration_changed(data)
  guards.sweep_surfaces()
end)

script.on_event(defines.events.on_surface_created, guards.on_surface_created)
script.on_event(defines.events.on_player_created, guards.on_player_created)
