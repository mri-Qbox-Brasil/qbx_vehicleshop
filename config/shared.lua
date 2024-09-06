return {
    finance = {
        minimumDown = 10, -- minimum percentage allowed down
        maximumPayments = 24, -- maximum payments allowed
    },
    shops = {
        --[[shop = { -- Needs to be unique
            type = '', -- If 'free-use', no player-to-player interaction required to purchase. If 'managed', caresalesman required for purchase
            job = '', -- If shop is 'free-use', remove this option. If shop is 'managed', put required job
            zone = {
                shape = { -- Polygon that surrounds the shop
                    vec3(0.0, 0.0, 0.0),
                    vec3(0.0, 0.0, 0.0),
                    vec3(0.0, 0.0, 0.0),
                    vec3(0.0, 0.0, 0.0),
                },
                size = vec3(0.0, 0.0, 0.0), -- Size of the vehicles zones (x, y, z)
                targetDistance = 1, -- Defines targeting distance. Only works if useTarget is enabled
            },
            blip = {
                label = '', -- Blip label
                coords = vec3(0.0, 0.0, 0.0), -- Blip coordinates
                show = true, -- Enables/disables the blip being shown
                sprite = 0, -- Blip sprite
                color = 0, -- Blip color
            },
            categories = { -- Categories available to browse
                sedans = 'Sedans',
                coupes = 'Coupes',
                suvs = 'SUVs',
                offroad = 'Offroad',
            },
            testDrive = {
                limit = 5.0, -- Time in minutes allotted for the test drive
                spawn = vec4(0.0, 0.0, 0.0, 0.0), -- Spawn location for the test drive
            },
            returnLocation = vec3(0.0, -1082.58, 26.68), -- Location to return vehicle only if the vehicleshop is managed
            vehicleSpawn = vec4(0.0, 0.0, 0.0, 0.0), -- Spawn location when vehicle is purchased
            showroomVehicles = {
                [1] = {
                    coords = vec4(0.0, 0.0, 0.0, 0.0), -- where the vehicle will spawn on display
                    vehicle = '', -- Model name of display vehicle. Is dynamically changed when swapping vehicles
                },
                [2] = {
                    coords = vec4(0.0, 0.0, 0.0, 0.0), -- where the vehicle will spawn on display
                    vehicle = '', -- Model name of display vehicle. Is dynamically changed when swapping vehicles
                },
            },
        },]]--
        pdm = {
            type = 'free-use',
            zone = {
                shape = {
                    vec3(-56.727394104004, -1086.2325439453, 26.0),
                    vec3(-60.612808227539, -1096.7795410156, 26.0),
                    vec3(-58.26834487915, -1100.572265625, 26.0),
                    vec3(-35.927803039551, -1109.0034179688, 26.0),
                    vec3(-34.427627563477, -1108.5111083984, 26.0),
                    vec3(-32.02657699585, -1101.5877685547, 26.0),
                    vec3(-33.342102050781, -1101.0377197266, 26.0),
                    vec3(-31.292987823486, -1095.3717041016, 26.0)
                },
                size = vec3(3, 3, 4),
                targetDistance = 1,
            },
            blip = {
                label = 'Premium Deluxe Motorsport',
                coords = vec3(-45.67, -1098.34, 26.42),
                show = true,
                sprite = 326,
                color = 3,
            },
            categories = {
                sportsclassics = 'Sports Classics',
                sedans = 'Sedans',
                coupes = 'Coupes',
                suvs = 'SUVs',
                offroad = 'Offroad',
                muscle = 'Muscle',
                compacts = 'Compacts',
                motorcycles = 'Motorcycles',
                vans = 'Vans',
                cycles = 'Bicycles'
            },
            testDrive = {
                limit = 5.0,
                spawn = vec4(-7.84, -1081.35, 26.67, 121.83),
            },
            returnLocation = vec3(-44.74, -1082.58, 26.68),
            vehicleSpawn = vec4(-31.69, -1090.78, 26.42, 328.79),
            showroomVehicles = {
                [1] = {coords = vec4(-45.65, -1093.66, 25.44, 69.5), vehicle = 'adder'},
                [2] = {coords = vec4(-48.27, -1101.86, 25.44, 294.5), vehicle = 'schafter2'},
                [3] = {coords = vec4(-39.6, -1096.01, 25.44, 66.5), vehicle = 'comet2'},
                [4] = {coords = vec4(-51.21, -1096.77, 25.44, 254.5), vehicle = 'vigero'},
                [5] = {coords = vec4(-40.18, -1104.13, 25.44, 338.5), vehicle = 't20'},
                [6] = {coords = vec4(-43.31, -1099.02, 25.44, 52.5), vehicle = 'bati'},
                [7] = {coords = vec4(-50.66, -1093.05, 25.44, 222.5), vehicle = 'bati'},
                [8] = {coords = vec4(-44.28, -1102.47, 25.44, 298.5), vehicle = 'bati'}
            },
        },

        luxury = {
            type = 'managed',
            job = 'cardealer',
            zone = {
                shape = {
                    vec3(-1260.6973876953, -349.21334838867, 36.91),
                    vec3(-1268.6248779297, -352.87365722656, 36.91),
                    vec3(-1274.1533203125, -358.29794311523, 36.91),
                    vec3(-1273.8425292969, -362.73715209961, 36.91),
                    vec3(-1270.5701904297, -368.6716003418, 36.91),
                    vec3(-1266.0561523438, -375.14080810547, 36.91),
                    vec3(-1244.3684082031, -362.70278930664, 36.91),
                    vec3(-1249.8704833984, -352.03326416016, 36.91),
                    vec3(-1252.9503173828, -345.85726928711, 36.91)
                },
                size = vec3(3, 3, 4),
                targetDistance = 1,
            },
            blip = {
                label = 'Luxury Vehicle Shop',
                coords = vec3(-1255.6, -361.16, 36.91),
                show = true,
                sprite = 326,
                color = 3,
            },
            categories = {
                super = 'Super',
                sports = 'Sports'
            },
            testDrive = {
                limit = 5.0,
                spawn = vec4(-1232.81, -347.99, 37.33, 23.28),
            },
            returnLocation = vec3(-1231.46, -349.86, 37.33),
            vehicleSpawn = vec4(-1231.46, -349.86, 37.33, 26.61),
            showroomVehicles = {
                [1] = {coords = vec4(-1265.31, -354.44, 35.91, 205.08), vehicle = 'italirsx'},
                [2] = {coords = vec4(-1270.06, -358.55, 35.91, 247.08), vehicle = 'italigtb'},
                [3] = {coords = vec4(-1269.21, -365.03, 35.91, 297.12), vehicle = 'nero'},
                [4] = {coords = vec4(-1252.07, -364.2, 35.91, 56.44), vehicle = 'bati'},
                [5] = {coords = vec4(-1255.49, -365.91, 35.91, 55.63), vehicle = 'carbonrs'},
                [6] = {coords = vec4(-1249.21, -362.97, 35.91, 53.24), vehicle = 'hexer'},
            }
        },

        boats = {
            type = 'free-use',
            zone = {
                shape = {
                    vec3(-729.39, -1315.84, 0),
                    vec3(-766.81, -1360.11, 0),
                    vec3(-754.21, -1371.49, 0),
                    vec3(-716.94, -1326.88, 0)
                },
                size = vec3(8, 8, 6),
                targetDistance = 10,
            },
            blip = {
                label = 'Marina Shop',
                coords = vec3(-738.25, -1334.38, 1.6),
                show = true,
                sprite = 410,
                color = 3,
            },
            categories = {
                boats = 'Boats'
            },
            testDrive = {
                limit = 5.0,
                spawn = vec4(-722.23, -1351.98, 0.14, 135.33),
            },
            returnLocation = vec3(-714.34, -1343.31, 0.0),
            vehicleSpawn = vec4(-727.87, -1353.1, -0.17, 137.09),
            showroomVehicles = {
                [1] = {coords = vec4(-727.05, -1326.59, -0.50, 229.5), vehicle = 'seashark'},
                [2] = {coords = vec4(-732.84, -1333.5, -0.50, 229.5), vehicle = 'dinghy'},
                [3] = {coords = vec4(-737.84, -1340.83, -0.50, 229.5), vehicle = 'speeder'},
                [4] = {coords = vec4(-741.53, -1349.7, -0.50, 229.5), vehicle = 'marquis'},
            },
        },

        air = {
            type = 'free-use',
            zone = {
                shape = {
                    vec3(-1607.58, -3141.7, 12.99),
                    vec3(-1672.54, -3103.87, 12.99),
                    vec3(-1703.49, -3158.02, 12.99),
                    vec3(-1646.03, -3190.84, 12.99)
                },
                size = vec3(10, 10, 8),
                targetDistance = 5,
            },
            blip = {
                label = 'Air Shop',
                coords = vec3(-1652.76, -3143.4, 13.99),
                show = true,
                sprite = 251,
                color = 3,
            },
            categories = {
                helicopters = 'Helicopters',
                planes = 'Planes'
            },
            testDrive = {
                limit = 5.0,
                spawn = vec4(-1625.19, -3103.47, 13.94, 330.28),
            },
            returnLocation = vec3(-1628.44, -3104.7, 13.94),
            vehicleSpawn = vec4(-1617.49, -3086.17, 13.94, 329.2),
            showroomVehicles = {
                [1] = {coords = vec4(-1651.36, -3162.66, 12.99, 346.89), vehicle = 'volatus'},
                [2] = {coords = vec4(-1668.53, -3152.56, 12.99, 303.22), vehicle = 'luxor2'},
                [3] = {coords = vec4(-1632.02, -3144.48, 12.99, 31.08), vehicle = 'nimbus'},
                [4] = {coords = vec4(-1663.74, -3126.32, 12.99, 275.03), vehicle = 'frogger'},
            },
        },
    },
}