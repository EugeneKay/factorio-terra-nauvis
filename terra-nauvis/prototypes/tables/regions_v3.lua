-- The third region table (config.lua regions_v3; 1.0.0): the river deltas. Hand-kept pure data, like config.lua.
-- A marsh row is a delta the first two tables lack; prototypes/expressions/regions.lua gives it the first table's
-- three bodies and sums it into the third marsh aggregate and the delta weight. A channel row is one distributary:
-- a polyline from its river, or from another channel, to past the coast, a least-cost route through the water and
-- thin water of the map's reference raster (data-src/earthmaps), smoothed over 5 px and simplified to 1 px, so
-- its bends are the raster's. A river's shipped course differs by map and scale (its smoothing window does), so a
-- row that leaves a river holds starts: per map, for each offered scale in config.lua scales.values' order, the
-- point of that river's course (data-src/waterways manifests) nearest the row's first vertex, where the channel
-- begins. Its last vertex lies up to 10 px out to sea, more than the warps move it. width is the row's share of
-- config.lua regions_v3.channel's half-width. Fields as in the first table.
return {
  rows = {
    {
      id = "nile_delta", layer = "marsh", shape = "polygon", warp = 0, radius_km = 30,
      maps = {"atlantic", "olde_world"},
      latlon = {
        {30.05, 31.25}, {31.15, 29.9}, {31.45, 30.35}, {31.6, 31.1}, {31.5, 31.85}, {31.25, 32.3},
      },
      source = "Nile delta from Cairo to Alexandria and Port Said; radius_km sets the outline noise only",
    },
    {
      id = "amazon_mouth", layer = "marsh", shape = "disc", warp = 0, lat = -0.2, lon = -50.2, radius_km = 120,
      maps = {"atlantic"},
      source = "Amazon mouth: Marajo's flooded north-east with Caviana and Mexiana, a disc of that extent",
    },
    {
      id = "niger_delta", layer = "marsh", shape = "disc", warp = 0, lat = 4.8, lon = 6.4, radius_km = 85,
      maps = {"atlantic", "olde_world"},
      source = "Niger delta between the Forcados and the Bonny, a disc of its extent",
    },
    {
      id = "indus_delta", layer = "marsh", shape = "disc", warp = 0, lat = 24.03, lon = 67.83, radius_km = 50,
      maps = {"olde_world"},
      source = "Indus delta, its creeks south-east of the mouth, a disc of that extent",
    },
    {
      id = "mississippi_delta", layer = "marsh", shape = "disc", warp = 0, lat = 29.45, lon = -90.2, radius_km = 90,
      maps = {"atlantic"},
      source = "Mississippi delta plain south of New Orleans, a disc of its extent",
    },
    {
      id = "orinoco_delta", layer = "marsh", shape = "disc", warp = 0, lat = 9.17, lon = -61.85, radius_km = 75,
      maps = {"atlantic"},
      source = "Orinoco delta between the Manamo and the Rio Grande, a disc of its extent",
    },
    {
      id = "nile_damietta", layer = "channel", shape = "path", warp = 0, width = 1,
      maps = {"atlantic", "olde_world"},
      starts = {
        atlantic = {
          {30.0392, 31.0598}, {30.0845, 31.1317}, {30.0956, 31.1588}, {30.0958, 31.1594}, {30.0996, 31.1698},
          {30.0958, 31.1596}, {30.1037, 31.1724}, {30.1035, 31.1724},
        },
        olde_world = {
          {30.1078, 31.1236}, {30.0809, 31.1092}, {30.0811, 31.1099}, {30.0827, 31.1275}, {30.0884, 31.145},
          {30.0931, 31.1557}, {30.0828, 31.1279}, {30.0927, 31.1556},
        },
      },
      latlon = {
        {30.1222, 31.1889}, {30.2333, 31.1133}, {30.3445, 31.1}, {30.5889, 31.2511}, {30.7889, 31.2333},
        {30.9222, 31.2689}, {31.1, 31.4333}, {31.1933, 31.6066}, {31.4333, 31.7889}, {31.6103, 31.9232},
      },
      source = "Nile, Damietta branch",
    },
    {
      id = "nile_alexandria", layer = "channel", shape = "path", warp = 0, width = 0.7,
      maps = {"atlantic", "olde_world"},
      starts = {
        atlantic = {
          {30.6999, 30.7288}, {30.7137, 30.789}, {30.7181, 30.797}, {30.7183, 30.7978}, {30.7196, 30.8018},
          {30.7182, 30.7978}, {30.7203, 30.8046}, {30.7179, 30.8162},
        },
        olde_world = {
          {30.7613, 30.8784}, {30.7181, 30.7992}, {30.718, 30.7989}, {30.7139, 30.7891}, {30.7083, 30.776},
          {30.7182, 30.7976}, {30.7139, 30.7892}, {30.7181, 30.7975},
        },
      },
      latlon = {
        {30.7222, 30.8111}, {31.0778, 30.3889}, {31.1133, 30.1666}, {31.2111, 29.9889}, {31.3182, 29.7942},
      },
      source = "Nile, the canal from the Rosetta branch to Alexandria",
    },
    {
      id = "amazon_north", layer = "channel", shape = "path", warp = 0, width = 1,
      maps = {"atlantic"},
      starts = {
        atlantic = {
          {-1.4812, -51.7611}, {-1.4808, -51.762}, {-1.4814, -51.7615}, {-1.4814, -51.7617}, {-1.4818, -51.7614},
          {-1.482, -51.7612}, {-1.4806, -51.7625}, {-1.4795, -51.7635},
        },
      },
      latlon = {
        {-1.5, -51.7444}, {-1.0111, -51.2688}, {-0.6333, -51.1444}, {-0.2555, -51.1444}, {-0.0555, -51.1},
        {0.0334, -50.9222}, {0.5445, -50.4111}, {0.6156, -50.2555}, {0.7889, -50.0688}, {1.1, -49.8955},
        {1.2111, -49.7888}, {1.3714, -49.6349},
      },
      source = "Amazon, Canal do Norte past Macapa",
    },
    {
      id = "amazon_para", layer = "channel", shape = "path", warp = 0, width = 1,
      maps = {"atlantic"},
      starts = {
        atlantic = {
          {-0.9, -51.1289}, {-0.8568, -51.202}, {-0.8348, -51.187}, {-0.8355, -51.1864}, {-0.8369, -51.1852},
          {-0.8374, -51.1849}, {-0.8394, -51.1833}, {-0.8403, -51.1824},
        },
      },
      latlon = {
        {-0.9, -51.1222}, {-0.9, -50.9444}, {-0.9444, -50.86}, {-1.5222, -50.7888}, {-1.7889, -50.5888},
        {-1.9355, -50.3222}, {-1.8555, -50.0333}, {-1.8511, -49.5888}, {-1.6822, -49.1666}, {-1.6644, -49.0111},
        {-1.1311, -48.4377}, {-1.0111, -48.3844}, {-0.9, -48.2777}, {-0.7266, -48.0777}, {-0.6778, -47.9222},
        {-0.6111, -47.7102},
      },
      source = "Amazon, the Breves narrows and the Para river south of Marajo",
    },
    {
      id = "niger_forcados", layer = "channel", shape = "path", warp = 0, width = 1,
      maps = {"atlantic", "olde_world"},
      starts = {
        atlantic = {
          {5.1517, 6.3498}, {5.1522, 6.3487}, {5.152, 6.3501}, {5.152, 6.3491}, {5.1519, 6.3493}, {5.152, 6.3501},
          {5.1521, 6.3488}, {5.1521, 6.3488},
        },
        olde_world = {
          {5.1547, 6.3434}, {5.1548, 6.3432}, {5.1544, 6.3446}, {5.1548, 6.343}, {5.1548, 6.3431}, {5.1543, 6.3448},
          {5.1553, 6.3421}, {5.1556, 6.3416},
        },
      },
      latlon = {
        {5.1667, 6.3222}, {5.2778, 6.4022}, {5.3178, 6.3666}, {5.1578, 6.1666}, {5.1089, 6.0378}, {5.1667, 5.8555},
        {5.1445, 5.4778}, {5.1314, 5.2559},
      },
      source = "Niger, Forcados branch",
    },
    {
      id = "niger_nun", layer = "channel", shape = "path", warp = 0, width = 0.9,
      maps = {"atlantic", "olde_world"},
      starts = {
        atlantic = {
          {5.2655, 6.4116}, {5.2657, 6.411}, {5.2664, 6.4105}, {5.2655, 6.4114}, {5.2656, 6.4112}, {5.2664, 6.4105},
          {5.2655, 6.4112}, {5.2655, 6.4112},
        },
        olde_world = {
          {5.2673, 6.4074}, {5.2673, 6.4073}, {5.2679, 6.4069}, {5.2672, 6.4074}, {5.2675, 6.407}, {5.2678, 6.4071},
          {5.2678, 6.4064}, {5.2681, 6.4059},
        },
      },
      latlon = {
        {5.2778, 6.3889}, {5.4556, 6.5222}, {5.4822, 6.5666}, {5.4556, 6.6066}, {5.3445, 6.6066}, {5.0111, 6.4378},
        {4.9222, 6.5578}, {4.7667, 6.6022}, {4.5889, 6.7311}, {4.3445, 6.7}, {4.124, 6.6719},
      },
      source = "Niger, the eastern branch to the Nun's mouths",
    },
    {
      id = "niger_brass", layer = "channel", shape = "path", warp = 0, width = 0.7,
      maps = {"atlantic", "olde_world"},
      latlon = {
        {4.7222, 6.6333}, {4.6378, 6.74}, {4.7178, 6.7666}, {4.3667, 6.8555}, {4.1513, 6.9101},
      },
      source = "Niger, the creek east of it towards Brass",
    },
    {
      id = "indus_kori", layer = "channel", shape = "path", warp = 0, width = 0.8,
      maps = {"olde_world"},
      starts = {
        olde_world = {
          {24.0805, 67.5828}, {24.0674, 67.5975}, {24.0805, 67.5828}, {24.0677, 67.5972}, {24.0684, 67.5967},
          {24.0835, 67.5835}, {24.0667, 67.5979}, {24.0665, 67.5981},
        },
      },
      latlon = {
        {24.0778, 67.5889}, {23.9711, 67.8333}, {23.9889, 67.9889}, {23.7267, 68.0689}, {23.7133, 68.1178},
        {23.7933, 68.1622}, {23.7, 68.2111}, {23.5819, 68.273},
      },
      source = "Indus, the creeks east of the mouth",
    },
    {
      id = "indus_hajamro", layer = "channel", shape = "path", warp = 0, width = 0.7,
      maps = {"olde_world"},
      latlon = {
        {24.0111, 67.7666}, {23.8333, 67.6333}, {23.7267, 67.5533},
      },
      source = "Indus, the short creek beside the mouth",
    },
    {
      id = "mississippi_lafourche", layer = "channel", shape = "path", warp = 0, width = 0.8,
      maps = {"atlantic"},
      starts = {
        atlantic = {
          {30.1412, -90.9816}, {30.1458, -90.9677}, {30.1473, -90.9643}, {30.1477, -90.9631}, {30.15, -90.9625},
          {30.1438, -90.9628}, {30.1446, -90.9613}, {30.1337, -90.9846},
        },
      },
      latlon = {
        {30.0556, -91.0333}, {29.8467, -90.9533}, {29.7089, -90.6111}, {29.5222, -90.3488}, {29.2778, -90.22},
        {29.1, -90.2111}, {28.8781, -90.2},
      },
      source = "Mississippi, Bayou Lafourche",
    },
    {
      id = "mississippi_loutre", layer = "channel", shape = "path", warp = 0, width = 0.7,
      maps = {"atlantic"},
      starts = {
        atlantic = {
          {29.1647, -89.3145}, {29.1844, -89.3114}, {29.1863, -89.3067}, {29.1847, -89.3041}, {29.185, -89.3072},
          {29.1803, -89.3013}, {29.1731, -89.2974}, {29.1704, -89.2967},
        },
      },
      latlon = {
        {29.1889, -89.2777}, {29.1, -89.0111}, {29.0438, -88.8424},
      },
      source = "Mississippi, Pass a Loutre",
    },
    {
      id = "mississippi_north", layer = "channel", shape = "path", warp = 0, width = 0.7,
      maps = {"atlantic"},
      starts = {
        atlantic = {
          {29.2216, -89.3519}, {29.2199, -89.3358}, {29.219, -89.3368}, {29.2186, -89.3375}, {29.2174, -89.3389},
          {29.218, -89.3383}, {29.2166, -89.3399}, {29.2157, -89.3409},
        },
      },
      latlon = {
        {29.2556, -89.3}, {29.2289, -89.26}, {29.2889, -89.1777}, {29.2778, -89.1444}, {29.2216, -88.9757},
      },
      source = "Mississippi, the north pass of the bird foot",
    },
    {
      id = "orinoco_manamo", layer = "channel", shape = "path", warp = 0, width = 0.8,
      maps = {"atlantic"},
      starts = {
        atlantic = {
          {8.5795, -62.1441}, {8.5917, -62.1442}, {8.569, -62.1433}, {8.5885, -62.1445}, {8.5811, -62.1441},
          {8.5702, -62.1433}, {8.5917, -62.1446}, {8.5924, -62.1446},
        },
      },
      latlon = {
        {8.6334, -62.1444}, {8.8334, -62.0288}, {8.9445, -62.0777}, {9.0467, -62.0688}, {9.1311, -62.2066},
        {9.2378, -62.2955}, {9.5, -62.4288}, {9.7667, -62.2555}, {9.9157, -62.1586},
      },
      source = "Orinoco, Cano Manamo",
    },
    {
      id = "orinoco_macareo", layer = "channel", shape = "path", warp = 0, width = 0.8,
      maps = {"atlantic"},
      latlon = {
        {9.0778, -62.0333}, {9.1711, -61.8911}, {9.5445, -61.7577}, {9.6778, -61.7488}, {9.7667, -61.8111},
        {9.8941, -61.9003},
      },
      source = "Orinoco, Cano Macareo",
    },
    {
      id = "orinoco_east", layer = "channel", shape = "path", warp = 0, width = 0.7,
      maps = {"atlantic"},
      starts = {
        atlantic = {
          {8.5832, -61.5216}, {8.5954, -61.5217}, {8.5798, -61.5205}, {8.5874, -61.5224}, {8.5842, -61.5217},
          {8.5806, -61.5206}, {8.5888, -61.5226}, {8.5891, -61.5227},
        },
      },
      latlon = {
        {8.6778, -61.5222}, {8.6111, -61.54}, {8.5711, -61.5}, {8.5934, -61.22}, {8.9222, -61.1088},
        {9.0778, -61.0111}, {9.2659, -60.8928},
      },
      source = "Orinoco, the channel north of the Rio Grande",
    },
    {
      id = "lena_olenyok", layer = "channel", shape = "path", warp = 0, width = 1,
      maps = {"olde_world"},
      starts = {
        olde_world = {
          {72.2283, 126.9978}, {72.3472, 126.8041}, {72.3476, 126.7565}, {72.3721, 126.732}, {72.3502, 126.7362},
          {72.3614, 126.7557}, {72.3472, 126.7308}, {72.3445, 126.7302},
        },
      },
      latlon = {
        {72.3445, 126.4778}, {72.9914, 125.1}, {73.0111, 124.4778}, {73.1222, 123.8555}, {73.0827, 123.5889},
        {73.1889, 123.1444}, {73.2405, 122.9283},
      },
      source = "Lena, Olenyok channel; smoothed over 9 px and simplified to 2 px",
    },
    {
      id = "lena_tumat", layer = "channel", shape = "path", warp = 0, width = 0.8,
      maps = {"olde_world"},
      starts = {
        olde_world = {
          {72.2801, 127.0094}, {72.3472, 126.8041}, {72.3915, 126.7561}, {72.4014, 126.7288}, {72.3936, 126.7353},
          {72.3938, 126.7537}, {72.3911, 126.7303}, {72.3889, 126.7302},
        },
      },
      latlon = {
        {72.3889, 126.5222}, {72.4259, 126.3691}, {72.5519, 126.3123}, {72.9025, 126.3543}, {73.063, 126.6778},
        {73.3667, 126.5889}, {73.58, 126.5264},
      },
      source = "Lena, Tumat channel; smoothed over 9 px and simplified to 2 px",
    },
    {
      id = "lena_trofimov", layer = "channel", shape = "path", warp = 0, width = 0.8,
      maps = {"olde_world"},
      starts = {
        olde_world = {
          {72.35, 127.025}, {72.4189, 126.8477}, {72.4455, 126.789}, {72.453, 126.7556}, {72.4615, 126.7706},
          {72.4346, 126.7746}, {72.4659, 126.765}, {72.4653, 126.7639},
        },
      },
      latlon = {
        {72.5222, 126.6778}, {72.3519, 126.6629}, {72.3272, 126.5889}, {72.4556, 126.4728}, {72.5691, 126.5024},
        {72.7222, 126.895}, {72.8333, 126.8654}, {72.9914, 127.1889}, {73.0729, 127.8333}, {73.2778, 128.3444},
        {73.3605, 128.5507},
      },
      source = "Lena, Trofimov channel; smoothed over 9 px and simplified to 2 px",
    },
  },
}
