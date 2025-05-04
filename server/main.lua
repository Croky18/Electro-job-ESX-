ESX = exports['es_extended']:getSharedObject()

RegisterServerEvent("electrojob:addMoney", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        local amount = math.random(Config.RewardPerWindow.min, Config.RewardPerWindow.max)
        xPlayer.addMoney(amount)
        TriggerClientEvent('esx:showNotification', src, "~g~Je hebt $" .. amount .. " ontvangen voor de electro werk!")
    end
end)

RegisterServerEvent("electrojob:server:payPlayer", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        local amount = math.random(50, 150)
        xPlayer.addMoney(amount)
        TriggerClientEvent('esx:showNotification', src, "~g~Je hebt $" .. amount .. " verdiend voor het afronden van je electro werk!")
    end
end)