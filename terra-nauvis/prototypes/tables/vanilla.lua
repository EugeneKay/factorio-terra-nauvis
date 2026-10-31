--
-- Pure data, like config.lua: the data stage reads it through require, the Python tools through
-- tools/tnconfig.py's loader. Alien Biomes nils the autoplace of the 15 living vanilla trees, the three
-- vanilla rock entities and eight rock and decal decoratives in its data stage, before any mod that
--   rocks     the autoplace of huge-rock, big-rock and big-sand-rock (simple entities) and of the rock
--             and decal decoratives (base/prototypes/decorative/decoratives.lua:4345, 4506, 4669, 4790,
--             4943, 5104, 5260, 5415, 5574, 6357 and 6558)
--   relist    vanilla decoratives Alien Biomes keeps with their autoplace but takes off Nauvis
--             (AB/prototypes/disables.lua:21-51, AB/prototypes/decorative/vegetation.lua:43-54)
--   extend    vanilla decoratives Alien Biomes restricts to its own tiles (AB vegetation.lua:15-35,
--             AB rocks.lua:56-107), and vanilla's dead and dry trees, which AB restricts the same way
--   dead_score  the base game's score of a dead tree around max() of the living trees dead_scores lists for it
--             (trees.lua:4215-4263; tree_dead_desert's two local terms are left out)
--   decor     the base game's score of the extended decoratives and of the two garballos, as M1 dumps them:
--             Alien Biomes rewrites nine and leaves six reading a scale it has moved, so beside it the
--             temperate band places these from these texts (config.lua trees.decor)
return {
  version = 1,
  game = "2.1.23",
  trees = {
    {
      tree = "tree-01", expression = "tree_01", control = "trees",
      order = "a[tree]-b[forest]-a[wet]-c[cold]",
    },
    {
      tree = "tree-02", expression = "tree_02", control = "trees",
      order = "a[tree]-b[forest]-b[moist]-b[cold]",
    },
    {
      tree = "tree-02-red", expression = "tree_02_red", control = "trees",
      order = "a[tree]-b[forest]-c[medium]-b[cold]",
    },
    {
      tree = "tree-03", expression = "tree_03", control = "trees",
      order = "a[tree]-b[forest]-b[moist]-c[hot]",
    },
    {
      tree = "tree-04", expression = "tree_04", control = "trees",
      order = "a[tree]-b[forest]-a[wet]-b[medium]",
    },
    {
      tree = "tree-05", expression = "tree_05", control = "trees",
      order = "a[tree]-b[forest]-a[wet]-a[hot]",
    },
    {
      tree = "tree-06", expression = "tree_06", control = "trees",
      order = "a[tree]-b[forest]-d[dry]-c[cold]",
    },
    {
      tree = "tree-06-brown", expression = "tree_06_brown", control = "trees",
      order = "a[tree]-b[forest]-e[verydry]-c[cold]",
    },
    {
      tree = "tree-07", expression = "tree_07", control = "trees",
      order = "a[tree]-b[forest]-b[moist]-a[medium]",
    },
    {
      tree = "tree-08", expression = "tree_08", control = "trees",
      order = "a[tree]-b[forest]-c[medium]-a[medium]",
    },
    {
      tree = "tree-08-brown", expression = "tree_08_brown", control = "trees",
      order = "a[tree]-b[forest]-d[dry]-b[medium]",
    },
    {
      tree = "tree-08-red", expression = "tree_08_red", control = "trees",
      order = "a[tree]-b[forest]-e[verydry]-b[medium]",
    },
    {
      tree = "tree-09", expression = "tree_09", control = "trees",
      order = "a[tree]-b[forest]-c[medium]-c[hot]",
    },
    {
      tree = "tree-09-brown", expression = "tree_09_brown", control = "trees",
      order = "a[tree]-b[forest]-d[dry]-a[hot]",
    },
    {
      tree = "tree-09-red", expression = "tree_09_red", control = "trees",
      order = "a[tree]-b[forest]-e[verydry]-a[hot]",
    },
  },
  tree_richness = "clamp(random_penalty_at(6, 1), 0, 1)",
  rocks = {
    {
      type = "simple-entity", name = "huge-rock",
      control = "rocks", order = "a[doodad]-a[rock]-a[huge]",
      probability_expression = "multiplier * control * (region_box + rock_density - penalty)",
      local_expressions = {
        control = "control:rocks:size",
        multiplier = 0.07,
        penalty = 1.7,
        region_box = "range_select_base(moisture, 0.35, 1, 0.2, -10, 0)",
      },
    },
    {
      type = "simple-entity", name = "big-rock",
      control = "rocks", order = "a[doodad]-a[rock]-b[big]",
      probability_expression = "multiplier * control * (region_box + rock_density - penalty)",
      local_expressions = {
        control = "control:rocks:size",
        multiplier = 0.17,
        penalty = 1.6,
        region_box = "range_select_base(moisture, 0.35, 1, 0.2, -10, 0)",
      },
    },
    {
      type = "simple-entity", name = "big-sand-rock",
      control = "rocks", order = "a[doodad]-a[rock]-b[big]",
      probability_expression = "multiplier * control * (region_box + rock_density - penalty)",
      local_expressions = {
        aux_range = "range_select_base(aux, 0.3, 1, 0.3, -10, 0)",
        control = "control:rocks:size",
        moisture_range = "range_select_base(moisture, 0, 0.3, 0.2, -10, 0)",
        multiplier = 0.1,
        penalty = 1.6,
        region_box = "min(aux_range, moisture_range)",
      },
    },
    {
      type = "optimized-decorative", name = "medium-rock",
      control = "rocks", order = "a[doodad]-a[rock]-c[medium]",
      probability_expression = "multiplier * control * (region_box + rock_density - penalty)",
      local_expressions = {
        control = "control:rocks:size",
        multiplier = 0.4,
        penalty = 1.4,
        region_box = "range_select_base(moisture, 0.35, 1, 0.2, -10, 0)",
      },
    },
    {
      type = "optimized-decorative", name = "small-rock",
      control = "rocks", order = "a[doodad]-a[rock]-d[small]",
      probability_expression = "multiplier * control * (region_box + rock_density - penalty)",
      local_expressions = {
        control = "control:rocks:size",
        multiplier = 0.5,
        penalty = 1.3,
        region_box = "range_select_base(moisture, 0.35, 1, 0.2, -10, 0)",
      },
    },
    {
      type = "optimized-decorative", name = "tiny-rock",
      control = "rocks", order = "a[doodad]-a[rock]-e[tiny]", placement_density = 2,
      probability_expression = "multiplier * control * (region_box + rock_density - penalty)",
      local_expressions = {
        control = "control:rocks:size",
        multiplier = 0.5,
        penalty = 1.2,
        region_box = "range_select_base(moisture, 0.35, 1, 0.2, -10, 0)",
      },
    },
    {
      type = "optimized-decorative", name = "medium-sand-rock",
      control = "rocks", order = "a[doodad]-a[rock]-c[medium]",
      probability_expression = "multiplier * control * (region_box + rock_density - penalty)",
      local_expressions = {
        aux_range = "range_select_base(aux, 0.3, 1, 0.3, -10, 0)",
        control = "control:rocks:size",
        moisture_range = "range_select_base(moisture, 0, 0.3, 0.2, -10, 0)",
        multiplier = 0.3,
        penalty = 1.5,
        region_box = "min(aux_range, moisture_range)",
      },
    },
    {
      type = "optimized-decorative", name = "small-sand-rock",
      control = "rocks", order = "a[doodad]-a[rock]-d[small]", placement_density = 2,
      probability_expression = "multiplier * control * (region_box + rock_density - penalty)",
      local_expressions = {
        aux_range = "range_select_base(aux, 0.3, 1, 0.3, -10, 0)",
        control = "control:rocks:size",
        moisture_range = "range_select_base(moisture, 0, 0.3, 0.2, -10, 0)",
        multiplier = 0.5,
        penalty = 1.4,
        region_box = "min(aux_range, moisture_range)",
      },
    },
    {
      type = "optimized-decorative", name = "red-desert-decal",
      probability_expression = "clamp(-1.5 + noise_layer_noise('red-desert-decal')+ min(range_select(moisture, 0.3, \z
        0.7, 0.05, -1, 1),range_select(aux, 0.7, 1, 0.05, -1, 1)),0, 0.01)",
    },
    {
      type = "optimized-decorative", name = "sand-decal",
      probability_expression = "clamp(-1.5 + noise_layer_noise('sand-decal')+ min(range_select(moisture, 0.1, 1, \z
        0.05, -1, 1),range_select(aux, 0.4, 0.9, 0.05, -1, 1)),0, 0.01)",
    },
    {
      type = "optimized-decorative", name = "sand-dune-decal",
      probability_expression = "-0.8 - 0.4 * min(0.5, abs(grass_noise)) + 0.04 * noise_layer_noise('sand-decal')+ \z
        min(range_select(moisture, 0, 0.15, 0.4, -10, 1),range_select(aux, 0.0, 0.25, 0.4, -10, 1))",
    },
  },
  relist = {
    "light-mud-decal", "green-asterisk", "green-asterisk-mini", "green-bush-mini", "green-carpet-grass",
    "green-croton", "green-desert-bush", "green-hairy-grass", "green-pita", "green-pita-mini",
    "green-small-grass",
  },
  extend = {
    "brown-asterisk", "brown-asterisk-mini", "brown-carpet-grass", "brown-fluff", "brown-fluff-dry",
    "brown-hairy-grass", "cracked-mud-decal", "dark-mud-decal", "red-asterisk", "red-croton",
    "red-desert-bush", "red-pita", "white-desert-bush",
  },
  dead_trees = {"dead-dry-hairy-tree", "dead-grey-trunk", "dead-tree-desert", "dry-hairy-tree", "dry-tree"},
  dead_score = "0.2 * max(%s) * clamp(1 - tree_small_noise, 0, 2)",
  dead_scores = {
    ["dead-dry-hairy-tree"] = {"tree-05", "tree-06", "tree-06-brown", "tree-09", "tree-09-brown", "tree-09-red"},
    ["dead-grey-trunk"] = {"tree-02", "tree-02-red", "tree-03", "tree-04"},
    ["dead-tree-desert"] = {"tree-08", "tree-08-brown", "tree-08-red"},
    ["dry-hairy-tree"] = {"tree-05", "tree-06", "tree-06-brown"},
    ["dry-tree"] = {"tree-01", "tree-09", "tree-09-brown", "tree-09-red"},
  },
  decor = {
    {
      name = "brown-asterisk",
      text = "-1.5 + rpi(0.2) + asterisk_noise - min(0, decorative_knockout) + region_box",
      box = "min(range_select{input = moisture, from = 0, to = 0.3, slope = 0.05, min = -10, max = \z
        1},range_select{input = aux, from = 0, to = 0.6, slope = 0.05, min = -10, max = \z
        1},range_select{input = temperature, from = 10, to = 15, slope = 0.5, min = -10, max = 1})",
    },
    {
      name = "brown-asterisk-mini",
      text = "-1.2 + rpi(0.2) + croton_noise + max(0, decorative_knockout) + region_box",
      box = "min(range_select{input = moisture, from = 0.25, to = 0.6, slope = 0.05, min = -10, max = \z
        1},range_select{input = temperature, from = 10, to = 14, slope = 0.5, min = -10, max = 1})",
    },
    {
      name = "brown-carpet-grass",
      text = "-1 + rpi(0.4) + pita_noise - 0.5 * min(0, decorative_knockout) + region_box",
      box = "range_select{input = moisture, from = 0.35, to = 0.8, slope = 0.1, min = -10, max = 1}",
    },
    {
      name = "brown-fluff",
      text = "-1.4 + rpi(0.7) + (garballo_noise - min(0, decorative_knockout)) + region_box",
      box = "min(range_select{input = moisture, from = 0.4, to = 1, slope = 0.05, min = -10, max = \z
        1},range_select{input = temperature, from = 15, to = 20, slope = 0.5, min = -10, max = 1})",
    },
    {
      name = "brown-fluff-dry",
      text = "-1.5 + rpi(0.5) + (croton_noise - min(0, decorative_knockout)) + region_box",
      box = "min(range_select{input = moisture, from = 0.1, to = 0.4, slope = 0.05, min = -10, max = \z
        1},range_select{input = temperature, from = 15, to = 20, slope = 0.5, min = -10, max = 1})",
    },
    {
      name = "brown-hairy-grass",
      text = "-1.2 + rpi(0.6) + (pita_noise - min(0, decorative_knockout)) + region_box",
      box = "max(range_select{input = moisture, from = 0.3, to = 0.6, slope = 0.1, min = -10, max = \z
        1},min(range_select{input = moisture, from = 0.1, to = 2, slope = 0.05, min = -10, max = \z
        1},range_select{input = aux, from = 0.6, to = 1, slope = 0.05, min = -10, max = \z
        1},range_select{input = temperature, from = 14, to = 20, slope = 0.5, min = -10, max = 1}))",
    },
    {
      name = "cracked-mud-decal",
      text = "clamp(-1.5 + noise_layer_noise('red-desert-decal')+ min(range_select(moisture, 0.45, 0.7, 0.05, -1, \z
        1),range_select(aux, 0, 0.7, 0.05, -1, 1)),0, 0.01)",
    },
    {
      name = "dark-mud-decal",
      text = "clamp(-1.2 + noise_layer_noise('red-desert-decal') + range_select(moisture, 0.7, 1, 0.05, -1, 1), 0, \z
        0.02)",
    },
    {
      name = "red-asterisk",
      text = "-1.5 + rpi(0.2) + asterisk_noise - min(0, decorative_knockout) + region_box",
      box = "min(range_select{input = moisture, from = 0.05, to = 0.55, slope = 0.05, min = -10, max = \z
        1},range_select{input = aux, from = 0.6, to = 1, slope = 0.05, min = -10, max = \z
        1},range_select{input = temperature, from = 10, to = 15, slope = 0.5, min = -10, max = 1})",
    },
    {
      name = "red-croton",
      text = "-1.5 + rpi(0.7) + (croton_noise - min(0, decorative_knockout)) + region_box",
      box = "min(range_select{input = moisture, from = 0.3, to = 1, slope = 0.05, min = -10, max = \z
        1},range_select{input = aux, from = 0.6, to = 1, slope = 0.05, min = -10, max = \z
        1},range_select{input = temperature, from = 15.5, to = 20, slope = 0.5, min = -10, max = 1})",
    },
    {
      name = "red-desert-bush",
      text = "-1.75 + rpi(0.8) + (garballo_noise - min(0, decorative_knockout)) + region_box",
      box = "min(range_select{input = moisture, from = 0.05, to = 0.3, slope = 0.1, min = -10, max = \z
        1},range_select{input = aux, from = 0.15, to = 1, slope = 0.05, min = -10, max = 1})",
    },
    {
      name = "red-pita",
      text = "-1.9 + (rpi(0.7) + (pita_noise - min(0, decorative_knockout))) + region_box",
      box = "clamp(min(range_select{input = moisture, from = 0.05, to = 0.3, slope = 0.05, min = -10, max = \z
        1},range_select{input = temperature, from = 14, to = 20, slope = 0.5, min = -10, max = \z
        1}),min(range_select{input = moisture, from = 0.8, to = 0.95, slope = 0.05, min = -10, max = \z
        1},range_select{input = temperature, from = 16, to = 20, slope = 0.5, min = -10, max = \z
        1}),range_select{input = aux, from = 0.5, to = 1, slope = 0.05, min = -10, max = 1})",
    },
    {
      name = "white-desert-bush",
      text = "-1.9 + asterisk_noise + max(0, decorative_knockout) + rpi(0.8) + region_box",
      box = "max(min(range_select{input = moisture, from = 0, to = 0.2, slope = 0.05, min = -10, max = \z
        1},range_select{input = aux, from = 0.1, to = 0.6, slope = 0.05, min = -10, max = \z
        1},range_select{input = temperature, from = 14, to = 20, slope = 0.5, min = -10, max = \z
        1}),min(range_select{input = moisture, from = 0.8, to = 1, slope = 0.05, min = -10, max = \z
        1},range_select{input = aux, from = 0.8, to = 1, slope = 0.05, min = -10, max = \z
        1},range_select{input = temperature, from = 10, to = 14, slope = 0.5, min = -10, max = 1}))",
    },
    {
      name = "garballo",
      text = "-1.7 + rpi(0.5) + (garballo_noise - min(0, decorative_knockout)) + region_box",
      box = "max(min(range_select{input = moisture, from = 0.3, to = 0.6, slope = 0.05, min = -10, max = \z
        1},range_select{input = temperature, from = 10, to = 15, slope = 0.5, min = -10, max = \z
        1}),min(range_select{input = moisture, from = 0.65, to = 0.95, slope = 0.05, min = -10, max = \z
        1},range_select{input = aux, from = 0.5, to = 0.8, slope = 0.05, min = -10, max = \z
        1},range_select{input = temperature, from = 14, to = 15, slope = 0.5, min = -10, max = 1}))",
    },
    {
      name = "garballo-mini-dry",
      text = "-1.5 + rpi(0.3) + (garballo_noise - min(0, decorative_knockout)) + region_box",
      box = "min(range_select{input = moisture, from = 0.15, to = 0.4, slope = 0.05, min = -10, max = \z
        1},range_select{input = temperature, from = 10, to = 15, slope = 0.5, min = -10, max = 1})",
    },
  },
}
