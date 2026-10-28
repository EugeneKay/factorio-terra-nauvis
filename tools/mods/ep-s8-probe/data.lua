-- Sampled through the test harness (calculate_tile_properties) by tools/game_selftest.py. Nothing here is
-- wired into map generation, so previews and real maps stay vanilla.
data:extend{
  {type = "noise-expression", name = "ep_s8_x", expression = "x"},
  {type = "noise-expression", name = "ep_s8_y", expression = "y"},
  -- Land disc of radius 200 tiles around the origin, in elevation convention (water below 0).
  {type = "noise-expression", name = "ep_s8_disc", expression = "200 - sqrt(x * x + y * y)"},
}
