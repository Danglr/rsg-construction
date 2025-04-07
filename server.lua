local RSGCore = exports['rsg-core']:GetCoreObject()
local DropCount = 0


RegisterNetEvent('rsg-construction:GetDropCount', function(count)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    DropCount = count
end)


RSGCore.Functions.CreateCallback('rsg-construction:CheckIfPaycheckCollected', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local identifier = Player.PlayerData.citizenid
    exports.oxmysql:execute("SELECT level FROM player_xp WHERE identifier = ?", {identifier}, function(result)
        local level = 1
        if result[1] then
            level = result[1].level
        end
      
        local bonusMultiplier = 1 + ((level - 1) * Config.CashBonusPerLevel)
        local payment = (DropCount * Config.PayPerDrop) * bonusMultiplier
        if Player.Functions.AddMoney(Config.Moneytype, payment) then
            DropCount = 0
            cb(true)
        else
            cb(false)
        end
    end)
end)


RegisterNetEvent('rsg-construction:AddXP', function(xpAmount, performanceMultiplier)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player then
        local multiplier = performanceMultiplier or 1.0
        xpAmount = math.floor(xpAmount * multiplier * Config.XPRewardMultiplier)
        local identifier = Player.PlayerData.citizenid

        exports.oxmysql:execute(
            "INSERT INTO player_xp (identifier, xp, level) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE xp = xp + ?",
            {identifier, xpAmount, 1, xpAmount},
            function(rowsChanged)
                print("Added " .. xpAmount .. " XP to player " .. identifier)
             
                exports.oxmysql:execute("SELECT xp, level FROM player_xp WHERE identifier = ?", {identifier}, function(result)
                    if result[1] then
                        local newXP = result[1].xp
                        local currentLevel = result[1].level
                        local leveledUp = false
                        while newXP >= (currentLevel * Config.XPPerLevel) and currentLevel < Config.MaxLevel do
                            currentLevel = currentLevel + 1
                            leveledUp = true
                        end
                        if leveledUp then
                            exports.oxmysql:execute("UPDATE player_xp SET level = ? WHERE identifier = ?", {currentLevel, identifier})
                            TriggerClientEvent('rsg-construction:Notify', src, "Congratulations! You leveled up to Level " .. currentLevel)
                        end
                    end
                end)
            end
        )
    end
end)


RSGCore.Functions.CreateCallback('rsg-construction:CheckXP', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player then
        local identifier = Player.PlayerData.citizenid
        exports.oxmysql:execute("SELECT xp, level FROM player_xp WHERE identifier = ?", {identifier}, function(result)
            local xp = 0
            local level = 1
            if result[1] then
                xp = result[1].xp
                level = result[1].level
            end
            cb({xp = xp, level = level})
        end)
    else
        cb({xp = 0, level = 1})
    end
end)
