local playerProgress = {}
local webhook = ""

local function sendDiscordLog(title, fields, color)
    if not webhook or webhook == '' then return end

    local description = ""
    if type(fields) == "table" then
        for _, data in ipairs(fields) do
            description = description .. ("**%s :** %s\n"):format(data.key, data.value)
        end
    else
        description = fields
    end

    local embed = {
        {
            ["color"] = color or 5763719,
            ["title"] = title,
            ["description"] = description,
            ["footer"] = {
                ["text"] = os.date('%d/%m/%Y %H:%M:%S')
            }
        }
    }

    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST',
        json.encode({ username = 'OldXBlunt', embeds = embed, avatar_url = 'https://i.goopics.net/sek245.png' }),
        { ['Content-Type'] = 'application/json' })
end



local function selectRandomReward()
    local roll = math.random(1, 100)
    local cumulative = 0

    for _, reward in ipairs(Config.Rewards) do
        cumulative = cumulative + reward.chance
        if roll <= cumulative then
            return reward
        end
    end

    return Config.Rewards[1]
end

local function giveReward(xPlayer, reward)
    if reward.type == 'money' then
        xPlayer.addMoney(reward.amount)
    elseif reward.type == 'black_money' then
        xPlayer.addAccountMoney('black_money', reward.amount)
    elseif reward.type == 'item' then
        xPlayer.addInventoryItem(reward.item, reward.count)
    end
    sendDiscordLog("old_sadClown", {
        { key = "Joueur",     value = GetPlayerName(xPlayer.source) },
        { key = "Action",     value = "a été récompensé par le clown" },
        { key = "Récompense", value = reward.type },
        { key = "Montant",    value = reward.amount }
    }, 5763719)
end

ESX.RegisterServerCallback('old_sadClown:checkCandy', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false)
        return
    end

    local item = xPlayer.getInventoryItem(Config.RequiredItem)
    local count = item and item.count or 0

    cb(count >= Config.RequiredCount)
end)

RegisterNetEvent('old_sadClown:playerLoaded', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    if not playerProgress[identifier] then
        playerProgress[identifier] = {}
    end

    TriggerClientEvent('old_sadClown:syncCompleted', src, playerProgress[identifier])
end)

RegisterNetEvent('old_sadClown:giveCandy', function(clownId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    if not playerProgress[identifier] then
        playerProgress[identifier] = {}
    end

    if playerProgress[identifier][clownId] then
        TriggerClientEvent('old_sadClown:failed', src)
        return
    end

    local clownCoords = Config.Clowns[clownId]
    if not clownCoords then
        TriggerClientEvent('old_sadClown:failed', src)
        return
    end

    local playerPed = GetPlayerPed(src)
    local pCoords = GetEntityCoords(playerPed)
    local dist = #(pCoords - clownCoords.xyz)

    if dist > (Config.DistanceInteraction + 5.0) then
        TriggerClientEvent('old_sadClown:failed', src)
        return
    end

    local item = xPlayer.getInventoryItem(Config.RequiredItem)
    local totalCandies = item and item.count or 0

    if totalCandies < Config.RequiredCount then
        xPlayer.showNotification(Config.Notifications.noCandy)
        TriggerClientEvent('old_sadClown:failed', src)
        return
    end

    playerProgress[identifier][clownId] = true

    local isRobbery = math.random(1, 100) <= Config.RobberyChance

    if isRobbery then
        TriggerClientEvent('old_sadClown:robbed', src, clownId, totalCandies)
    else
        xPlayer.removeInventoryItem(Config.RequiredItem, Config.RequiredCount)
        local chosenReward = selectRandomReward()
        giveReward(xPlayer, chosenReward)
        TriggerClientEvent('old_sadClown:validated', src, clownId)
    end
end)

RegisterNetEvent('old_sadClown:surrenderCandies', function(clownId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local item = xPlayer.getInventoryItem(Config.RequiredItem)
    local totalCandies = item and item.count or 0

    if totalCandies > 0 then
        xPlayer.removeInventoryItem(Config.RequiredItem, totalCandies)
        sendDiscordLog("old_sadClown", {
            { key = "Joueur",  value = GetPlayerName(xPlayer.source) },
            { key = "Action",  value = "s'est rendu et a donné les bonbons" },
            { key = "Montant", value = totalCandies }
        }, 16705372)
    end
end)

RegisterNetEvent('old_sadClown:recoverCandy', function(clownId, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local recoverCount = tonumber(amount) or 0
    if recoverCount > 0 then
        xPlayer.addInventoryItem(Config.RequiredItem, recoverCount)
        TriggerClientEvent('old_sadClown:recovered', src)
        sendDiscordLog("old_sadClown", {
            { key = "Joueur",  value = GetPlayerName(xPlayer.source) },
            { key = "Action",  value = "a récupéré ses bonbons" },
            { key = "Montant", value = recoverCount }
        }, 3447003)
    end
end)

AddEventHandler('esx:playerDropped', function(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
end)
