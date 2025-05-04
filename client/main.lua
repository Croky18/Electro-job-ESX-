ESX = exports['es_extended']:getSharedObject()
local isWorking = false
local currentStep = 0
local spawnedVehicle = nil
local currentBlip = nil
local hasNotified = false

CreateThread(function()
    local model = GetHashKey(Config.NPC.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local ped = CreatePed(0, model, Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1, Config.NPC.heading, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    local blip = AddBlipForCoord(Config.NPC.coords)
    SetBlipSprite(blip, 761)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Electro Job")
    EndTextCommandSetBlipName(blip)

    local npcCoords = vector3(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z)

    CreateThread(function()
        while true do
            Wait(0)
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - npcCoords)

            if distance < 2.0 then
                DrawText3D(npcCoords.x, npcCoords.y, npcCoords.z + 1.0, "[E] Open Menu")
                if IsControlJustReleased(0, 38) then
                    lib.registerContext({
                        id = 'electro_job_menu',
                        title = 'Electro Job',
                        options = {
                            {
                                title = 'Start Elektriciteitsklus',
                                description = 'Start Electro job',
                                icon = 'truck',
                                onSelect = function()
                                    TriggerEvent('electrojob:start')
                                end
                            },
                            {
                                title = 'Stop Elektriciteitsklus',
                                description = 'Stop Electro job',
                                icon = 'xmark',
                                disabled = not isWorking,
                                onSelect = function()
                                    TriggerEvent('electrojob:stop')
                                end
                            }
                        }
                    })
                    lib.showContext('electro_job_menu')
                end
            end
        end
    end)
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

RegisterNetEvent("electrojob:start", function()
    if isWorking then
        return ESX.ShowNotification("~r~Je bent al aan het werk!")
    end

    local playerData = ESX.GetPlayerData()
    if playerData.job.name ~= Config.RequiredJob then
        return ESX.ShowNotification("~r~Geen toegang tot deze job.")
    end

    ESX.ShowNotification("~g~Voertuig wordt gespawned...")

    local vehicleModel = GetHashKey(Config.Vehicle.model)
    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Wait(500)
    end

    spawnedVehicle = CreateVehicle(vehicleModel, Config.Vehicle.spawnPoint.x, Config.Vehicle.spawnPoint.y, Config.Vehicle.spawnPoint.z, Config.Vehicle.spawnPoint.w, true, false)
    SetVehicleOnGroundProperly(spawnedVehicle)
    SetEntityAsMissionEntity(spawnedVehicle, true, true)

    if not DoesEntityExist(spawnedVehicle) then
        ESX.ShowNotification("~r~Probleem bij het spawnen van voertuig.")
        return
    end

    isWorking = true
    currentStep = 1
    GoToNextLocation()
end)

function GoToNextLocation()
    if currentBlip then RemoveBlip(currentBlip) end
    if currentStep > #Config.Locations then
        ESX.ShowNotification("~b~Breng het voertuig terug.")
        SetGpsBlipForReturn()
        return
    end

    local coords = Config.Locations[currentStep]
    currentBlip = AddBlipForCoord(coords)
    SetBlipRoute(currentBlip, true)

    CreateThread(function()
        while isWorking do
            Wait(0)
            local playerCoords = GetEntityCoords(PlayerPedId())
            if #(playerCoords - coords) < 2.0 then
                if not hasNotified then
                    ESX.ShowNotification("~g~Press [E] to start washing zekerings!")
                    hasNotified = true
                end

                if IsControlJustPressed(0, 38) then
                    TaskStartScenarioInPlace(PlayerPedId(), "world_human_welding", 0, true)
                    StartProgress(9000, "Bezig met elektrische restauratie......")
                    ClearPedTasks(PlayerPedId())

                    TriggerServerEvent("electrojob:addMoney")

                    currentStep = currentStep + 1
                    GoToNextLocation()
                    break
                end
            elseif hasNotified then
                hasNotified = false
            end
        end
    end)
end

function StartProgress(duration, label)
    exports['mythic_progbar']:Progress({
        name = "electrojob_progress",
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = false,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
    }, function(status)

    end)
    Wait(duration)
    return true
end

function SetGpsBlipForReturn()
    if not Config.VehicleReturn then return end
    currentBlip = AddBlipForCoord(Config.VehicleReturn.x, Config.VehicleReturn.y, Config.VehicleReturn.z)
    SetBlipRoute(currentBlip, true)

    CreateThread(function()
        while true do
            Wait(500)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - vector3(Config.VehicleReturn.x, Config.VehicleReturn.y, Config.VehicleReturn.z))
            if distance < 2.0 then
                ESX.ShowNotification("~g~Ga terug naar de NPC om te stoppen.")
                RemoveBlip(currentBlip)
                break
            end
        end
    end)
end

RegisterNetEvent("electrojob:stop", function()
    if not isWorking then return ESX.ShowNotification("~r~Je werkt niet.") end

    if DoesEntityExist(spawnedVehicle) then
        DeleteVehicle(spawnedVehicle)
    end

    isWorking = false
    currentStep = 0
    if currentBlip then RemoveBlip(currentBlip) end
    ESX.ShowNotification("~y~End of job.")
end)