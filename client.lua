local RSGCore = exports['rsg-core']:GetCoreObject()
-- Tables --
local pedstable = {}
local promptstable = {}
local blipsTable = {}
local JobsDone = {}
local JobCount = 0
local DropCount = 0
local BlipScale = 0.10

-- Checks --
local hasJob = false
local PickedUp = false
local AttachedProp = false

-- Blips & Prompts --
local dropBlip
local jobBlip
local closestJob = {}

-----------------------------------------
-------------- EXTRA --------------------
-----------------------------------------
-- REMOVE PROPS COMMAND --
if Config.StuckPropCommand then
    RegisterCommand('propstuck', function()
        for k, v in pairs(GetGamePool('CObject')) do
            if IsEntityAttachedToEntity(PlayerPedId(), v) then
                SetEntityAsMissionEntity(v, true, true)
                DeleteObject(v)
                DeleteEntity(v)
            end
        end
    end)
end

--------------------------------------
-------------- FUNCTIONS -------------
--------------------------------------

local function PickupWoodLocation()
    local player = PlayerPedId()
    local playercoords = GetEntityCoords(player)
    PickupLocation = math.random(1, #Config.Locations[closestJob]["WoodLocations"])

    if Config.Prints then
        print(closestJob)
    end

    jobBlip = N_0x554d9d53f696d002(1664425300, Config.Locations[closestJob]["WoodLocations"][PickupLocation].coords.x, Config.Locations[closestJob]["WoodLocations"][PickupLocation].coords.y, Config.Locations[closestJob]["WoodLocations"][PickupLocation].coords.z)

    SetBlipSprite(jobBlip, 1116438174, 1)
    SetBlipScale(jobBlip, 0.05)

    RSGCore.Functions.Notify('Go grab some lumber...', 'error')
    --TriggerEvent('rNotify:NotifyLeft', "          Go grab some lumber...", "", "generic_textures", "tick", 4500)
end

local function DropWoodLocation()
    local player = PlayerPedId()
    local playercoords = GetEntityCoords(player)
    DropLocation = math.random(1, #Config.Locations[closestJob]["DropLocations"])

    dropBlip = N_0x554d9d53f696d002(1664425300, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.x, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.y, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.z)

    SetBlipSprite(dropBlip, 1116438174, 0.5)
    SetBlipScale(dropBlip, 0.10)

    RSGCore.Functions.Notify('Head over to where the lumber is needed', 'error')
end

--------------------------------------
--------------- THREADS --------------
--------------------------------------
CreateThread(function()
	for _, v in pairs(Config.JobNpc) do
        local blip = N_0x554d9d53f696d002(1664425300, v["Pos"].x, v["Pos"].y, v["Pos"].z)
        SetBlipSprite(blip, 2305242038, 0.5)
		SetBlipScale(blip, 0.10)
		Citizen.InvokeNative(0x9CB1A1623062F402, blip, "Construction Job")
    end
    table.insert(blipsTable, blip)
end)

CreateThread(function()
    while true do
        Wait(0)
        if hasJob then
            local player = PlayerPedId()
            local coords = GetEntityCoords(player)
            if not PickedUp then
                if GetDistanceBetweenCoords(coords, Config.Locations[closestJob]["WoodLocations"][PickupLocation].coords.x, Config.Locations[closestJob]["WoodLocations"][PickupLocation].coords.y, Config.Locations[closestJob]["WoodLocations"][PickupLocation].coords.z, true) < 1.3  then
                    DrawText3D(Config.Locations[closestJob]["WoodLocations"][PickupLocation].coords.x, Config.Locations[closestJob]["WoodLocations"][PickupLocation].coords.y, Config.Locations[closestJob]["WoodLocations"][PickupLocation].coords.z, "[G] | Pickup Wood")
                    if IsControlJustReleased(0, Config.Keys["G"]) then
                        TriggerEvent('rsg-construction:PickupWood')
                        Wait(1000)
                    end
                end
            elseif PickedUp and not IsPedRagdoll(PlayerPedId()) then
                if Config.DisableSprintJump then
                    DisableControlAction(0, 0x8FFC75D6, true) -- Shift
                    DisableControlAction(0, 0xD9D0E1C0, true) -- Spacebar
                end
                if GetDistanceBetweenCoords(coords, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.x, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.y, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.z, true) < 1.5  then
                    DrawText3D(Config.Locations[closestJob]["DropLocations"][DropLocation].coords.x, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.y, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.z, "[G] | Place Wood")
                    if IsControlJustReleased(0, Config.Keys["G"]) then
                        TriggerEvent('rsg-construction:DropWood')
                    end
                end
            end
        end
    end
end)

--------------------------------------
--------------- EVENTS --------------
--------------------------------------

RegisterNetEvent('rsg-construction:StartJob', function()
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)

    if not hasJob then
        for k, v in pairs(Config.Locations) do
            if Config.Prints then
                print(k)
            end
            if GetDistanceBetweenCoords(coords, Config.Locations[k]["Location"].x, Config.Locations[k]["Location"].y, Config.Locations[k]["Location"].z, true) < 5 then
                closestJob = k
            end
        end
        PickupWoodLocation()
        hasJob = true

        if Config.Prints then
            print(hasJob)
        end

    else
        RSGCore.Functions.Notify('You already have this job!', 'error')
    end
end)

RegisterNetEvent('rsg-construction:EndJob', function()
    if hasJob then
        hasJob = false
        JobCount = 0
        DropCount = 0

        RemoveBlip(jobBlip)
        RemoveBlip(dropBlip)

        if Config.Prints then
            print(hasJob)
        end
    end
    RSGCore.Functions.Notify('You have stopped working!', 'error')
    --TriggerEvent('rNotify:NotifyLeft', "You Have Finished The Job", "", "generic_textures", "tick", 4500)
end)

RegisterNetEvent('rsg-construction:CollectPaycheck', function()
    print("Drop Count: "..DropCount)

    TriggerServerEvent('rsg-construction:GetDropCount', DropCount)
    Wait(100)
    if DropCount ~= 0 then
        RSGCore.Functions.TriggerCallback('rsg-construction:CheckIfPaycheckCollected', function(hasBeenPaid)
            if hasBeenPaid then
                TriggerEvent('rsg-construction:EndJob')
                RSGCore.Functions.Notify('You have been paid for your work!', 'error')

                if Config.Prints then
                    print(hasBeenPaid)
                end

            else -- Paid the money after initial check IE attempted to exploit
                RSGCore.Functions.Notify('You have been paid for your work!', 'error')

                if Config.Prints then
                    print(hasBeenPaid)
                end

            end
        end, source)
    else
        RSGCore.Functions.Notify('You didn\'t do any work!', 'error')
    end
end)

RegisterNetEvent('rsg-construction:PickupWood', function()
    local coords = GetEntityCoords(PlayerPedId())
    if hasJob then
        if not PickedUp then
            PickedUp = true
            local WoodProp = CreateObject(GetHashKey("p_woodplank01x"), coords.x, coords.y, coords.z, 1, 0, 1)
            SetEntityAsMissionEntity(WoodProp, true, true)
            RequestAnimDict("mech_carry_box")
            while not HasAnimDictLoaded("mech_carry_box") do
                Wait(100)
            end
            TaskPlayAnim(PlayerPedId(), "mech_carry_box", "idle", 2.0, -2.0, -1, 67109393, 0.0, false, 1245184, false, "UpperbodyFixup_filter", false)
            Citizen.InvokeNative(0x6B9BBD38AB0796DF, WoodProp, PlayerPedId(), GetEntityBoneIndexByName(PlayerPedId(),"SKEL_L_Hand"), 0.1, 0.15, 0.0, 90.0, 90.0, 20.0, true, true, false, true, 1, true)
            AttachedProp = true
            RemoveBlip(jobBlip)

            Wait(500)
            for _,v in pairs(promptstable) do
                PromptDelete(promptstable[v].PickupWoodPrompt)
            end

            DropWoodLocation()
        end
    end
end)

RegisterNetEvent('rsg-construction:DropWood', function()
    local coords = GetEntityCoords(PlayerPedId())
    
    if hasJob and DropCount <= Config.DropCount then
        for k, v in pairs(GetGamePool('CObject')) do
            if IsEntityAttachedToEntity(PlayerPedId(), v) then
                SetEntityAsMissionEntity(v, true, true)
                DeleteObject(v)
                DeleteEntity(v)
            end
        end
        ClearPedTasks(PlayerPedId())
        Wait(100)
        PickedUp = false

        -- START ANIMATION --
        TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('world_player_dynamic_kneel'), -1, true, false, false, false)
        RSGCore.Functions.Progressbar("placewood", "Placing Wood...", (Config.PlaceTime * 1000), false, true, {
            disableMovement = true,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Done

            DropCount = DropCount + 1

            if Config.Prints then
                print("Drop Count: "..DropCount)
            end

            RemoveBlip(dropBlip)

            Wait(100)

            if DropCount < Config.DropCount then
                PickupWoodLocation()
            else
                RSGCore.Functions.Notify('Work Completed! Go Get Your Check', 'error') 
            end
        end) 
    else
        RSGCore.Functions.Notify('Work done! Collect Your Check!', 'error') 
    end
end)

--------------------------------------
--------------- JOB MENU -------------
--------------------------------------

RegisterNetEvent('rsg-construction:OpenJobMenu', function()

    if not hasJob then

        jobMenu = {
            {
                header = "| Construction Job |",
                isMenuHeader = true,
            },
            {
                header = "Start Construction Job",
                txt = "",
                params = {
                    event = 'rsg-construction:StartJob',
                }
            },
            {
                header = "Close Menu",
                txt = '',
                params = {
                    event = '[X] Close Menu',
                }
            },
        }

    elseif hasJob then

        jobMenu = {
            {
                header = "| Construction Job |",
                isMenuHeader = true,
            },
            {
                header = "Finish Job",
                txt = "",
                params = {
                    event = 'rsg-construction:CollectPaycheck',
                }
            },
            {
                header = "[X] Close Menu",
                txt = '',
                params = {
                    event = 'rsg-menu:closeMenu',
                }
            },
        }

    end

    exports['rsg-menu']:openMenu(jobMenu)
end)

--------------------------
------- PED SPAWNING -----
--------------------------

function SET_PED_RELATIONSHIP_GROUP_HASH ( iVar0, iParam0 )
    return Citizen.InvokeNative( 0xC80A74AC829DDD92, iVar0, _GET_DEFAULT_RELATIONSHIP_GROUP_HASH( iParam0 ) )
end

function _GET_DEFAULT_RELATIONSHIP_GROUP_HASH ( iParam0 )
    return Citizen.InvokeNative( 0x3CC4A718C258BDD0 , iParam0 );
end

function modelrequest( model )
    CreateThread(function()
        RequestModel( model )
    end)
end

CreateThread(function()
    for z, x in pairs(Config.JobNpc) do
        while not HasModelLoaded( GetHashKey(Config.JobNpc[z]["Model"]) ) do
            Wait(500)
            modelrequest( GetHashKey(Config.JobNpc[z]["Model"]) )
        end
        local npc = CreatePed(GetHashKey(Config.JobNpc[z]["Model"]), Config.JobNpc[z]["Pos"].x, Config.JobNpc[z]["Pos"].y, Config.JobNpc[z]["Pos"].z - 1, Config.JobNpc[z]["Heading"], false, false, 0, 0)
        while not DoesEntityExist(npc) do
            Wait(300)
        end
        exports['rsg-target']:AddTargetModel(Config.JobNpc[z]["Model"], {
            options = {
                {
                    type = "client",
                    event = "rsg-construction:OpenJobMenu",
                    icon = "fas fa-person-digging",
                    style = "",
                    label = "Construction Job",
                },
            },
            distance = 2.5
        })
        Citizen.InvokeNative(0x283978A15512B2FE, npc, true)
        FreezeEntityPosition(npc, false)
        SetEntityInvincible(npc, true)
        TaskStandStill(npc, -1)
        Wait(100)
        SET_PED_RELATIONSHIP_GROUP_HASH(npc, GetHashKey(Config.JobNpc[z]["Model"]))
        SetEntityCanBeDamagedByRelationshipGroup(npc, false, `PLAYER`)
        SetEntityAsMissionEntity(npc, true, true)
        SetModelAsNoLongerNeeded(GetHashKey(Config.JobNpc[z]["Model"]))
        table.insert(pedstable, npc)

    end
end)

------------------------------------
------------ DRAWTEXT --------------
------------------------------------

function DrawText3D(x, y, z, text)
	local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)
	local px,py,pz=table.unpack(GetGameplayCamCoord())
	local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
	local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
	if onScreen then
	  SetTextScale(0.30, 0.30)
	  SetTextFontForCurrentCommand(1)
	  SetTextColor(255, 255, 255, 215)
	  SetTextCentre(1)
	  DisplayText(str,_x,_y)
	  local factor = (string.len(text)) / 225
	  DrawSprite("feeds", "hud_menu_4a", _x, _y+0.0125,0.015+ factor, 0.03, 0.1, 35, 35, 35, 190, 0)
	end
end

------------------------------------
------- RESOURCE START / STOP -----
------------------------------------

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _,v in pairs(pedstable) do
            DeletePed(v)
        end
        for _,v in pairs(blipsTable) do
            RemoveBlip(v)
        end
        for k,_ in pairs(promptstable) do
			PromptDelete(promptstable[k].name)
		end
        RemoveBlip(jobBlip)
        RemoveBlip(dropBlip)
    end
end)
