Config = {}

Config.RequiredItem = 'candy'        -- item bonbons
Config.RequiredCount = 1             -- quantité a donner par clown

Config.DistanceInteraction = 1.8     -- distance d'interaction
Config.DistanceSpawn = 50.0          -- distance d'apparition
Config.DistanceDespawn = 70.0        -- distance de disparition

Config.PedModel = `s_m_y_clown_01`   -- ped du clown

Config.speech = true                 -- activer la voix du clown

Config.RobberyChance = 50            -- pourcentage de chance qu'un clown braque le joueur
Config.RobberyAimTime = 10000        -- temps max pendant le braquage
Config.WeaponModel = `WEAPON_DAGGER` -- arme du clown

Config.PlayerAnim = {                -- animation "donner" du joueur
    dict = 'mp_common',
    anim = 'givetake2_a',
    duration = 2500
}

Config.ClownSadAnim = { -- animation du clown en tristesse
    dict = 'misschinese2_crystalmaze',
    anim = '2int_loop_a_taocheng'
}

Config.ClownHappyAnim = { -- animation du clown content
    dict = 'rcm_barry2',
    anim = 'clown_idle_0'
}

Config.EnableBlips = true -- affiche la pos des clown sur la map
Config.BlipSettings = {
    sprite = 102,
    color = 7,
    scale = 0.8,
    name = "Clown Triste"
}

Config.Notifications = { -- ShowHelpNotification et notifications
    missionStart =
    "Mission ~o~d'Halloween~s~ : Des clowns ~r~tristes~s~ errent en ville. Trouvez-les et offrez-leur des bonbons !",
    pressE = "Appuyez sur ~INPUT_CONTEXT~ pour parler au clown.",
    pressELoot = "Appuyez sur ~INPUT_CONTEXT~ pour recuperer vos bonbons volés.",
    robberyChoice =
    "~INPUT_CONTEXT~ pour vous rendre et donner les bonbons\n~INPUT_VEH_DUCK~ pour combattre.",
    noCandy = "~r~Vous n'avez pas de bonbon d'Halloween sur vous !",
    success = "~g~Le clown a retrouvé le sourire ! Il vous a laissé un cadeau.",
    robbery = "~r~Le clown vous braque avec une arme !",
    surrendered = "~o~Vous vous êtes rendu. Le clown s'enfuit avec tous vos bonbons !",
    recovered = "~g~Vous avez recuperé vos bonbons sur le clown !",
    noVehicle = "~r~Vous ne pouvez pas réaliser cette action à bord d'un véhicule !"
}

Config.Rewards = { -- table des récompenses
    { type = 'money',       amount = 1500,  chance = 40 },
    { type = 'black_money', amount = 500,   chance = 20 },
    { type = 'item',        item = 'bread', count = 3,  chance = 20 },
    { type = 'item',        item = 'water', count = 3,  chance = 20 }
}

Config.Clowns = { -- table des pos des clowns
    [1] = vector4(188.0, -1283.0, 29.4, 337.0),
    [2] = vector4(-155.0, -1351.0, 30.0, 273.0),
    [3] = vector4(-181.0, -1519.0, 34.0, 6.0),
    [4] = vector4(66.0, -1625.0, 29.4, 98.0)
}
