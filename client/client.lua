-- Variables

local QBCore = exports['qb-core']:GetCoreObject()
local fuelSynced = false
local inBlacklisted = false
local inGasStation = false
local haveNozzle = false
local isNearPump = false
local NozzlePrice = Config.nozzleprice
local props = {
	'prop_gas_pump_1d',
	'prop_gas_pump_1a',
	'prop_gas_pump_1b',
	'prop_gas_pump_1c',
	'prop_vintage_pump',
	'prop_gas_pump_old2',
	'prop_gas_pump_old3',
}
local CurrentWeaponData = {}

-- Functions

local function ManageFuelUsage(vehicle)
	if not DecorExistOn(vehicle, Config.FuelDecor) then
		SetFuel(vehicle, math.random(200, 800) / 10)
	elseif not fuelSynced then
		SetFuel(vehicle, GetFuel(vehicle))
		fuelSynced = true
	end
	if IsVehicleEngineOn(vehicle) then
		SetFuel(vehicle, GetVehicleFuelLevel(vehicle) - Config.FuelUsage[Round(GetVehicleCurrentRpm(vehicle), 1)] * (Config.Classes[GetVehicleClass(vehicle)] or 1.0) / 10)
		SetVehicleEngineOn(veh, true, true, true)
	else
		SetVehicleEngineOn(veh, true, true, true)
	end
end

-- Threads

CreateThread(function()
	while true do
		Wait(500)

		local pumpObject, pumpDistance = FindNearestFuelPump()

		if pumpDistance < 2.5 then
			isNearPump = pumpObject
			-- currentCash = QBCore.Functions.GetPlayerData().money['cash']
			Wait(500)
		else
			isNearPump = false
			if haveNozzle == true then
				QBCore.Functions.Notify(Lang:t("notify.broke_nozle"), "error")
				TriggerServerEvent('qb-fuel:server:PayForFuel', NozzlePrice)
				DeleteEntity(Nozzle)
				DeleteObject(Nozzle)
				haveNozzle = false
			end
			Wait(2000)
		end
	end
end)

CreateThread(function()
	local bones = {
		"petroltank",
		"petroltank_l",
		"petroltank_r",
		"wheel_rf",
		"wheel_rr",
		"petrolcap ",
		"seat_dside_r",
		"engine",
		}
	exports['qb-target']:AddTargetBone(bones, {
		options = {
		{
			type = "client",
			event = "qb-fuel:client:SendMenuToServer",
			icon = "fas fa-gas-pump",
			label = "Refuel Vehicle",
			canInteract = function()
				return haveNozzle == true
			end
		}
	},
		distance = 1.5,
	})
end)

if Config.LeaveEngineRunning then
	CreateThread(function()
		while true do
			Wait(100)
			local ped = GetPlayerPed(-1)
			if DoesEntityExist(ped) and IsPedInAnyVehicle(ped, false) and IsControlPressed(2, 75) and not IsEntityDead(ped) and not IsPauseMenuActive() then
				local engineWasRunning = GetIsVehicleEngineRunning(GetVehiclePedIsIn(ped, true))
				Wait(1000)
				if DoesEntityExist(ped) and not IsPedInAnyVehicle(ped, false) and not IsEntityDead(ped) and not IsPauseMenuActive() then
					local veh = GetVehiclePedIsIn(ped, true)
					if engineWasRunning then
						SetVehicleEngineOn(veh, true, true, true)
					end
				end
			end
		end
	end)
end

if Config.ShowNearestGasStationOnly then
    CreateThread(function()
	local currentGasBlip = 0
	while true do
		local coords = GetEntityCoords(PlayerPedId())
		local closest = 1000
		local closestCoords

		for _, gasStationCoords in pairs(Config.GasStationsBlips) do
			local dstcheck = #(coords - gasStationCoords)
			if dstcheck < closest then
				closest = dstcheck
				closestCoords = gasStationCoords
			end
		end
		if DoesBlipExist(currentGasBlip) then
			RemoveBlip(currentGasBlip)
		end
		currentGasBlip = CreateBlip(closestCoords)
		Wait(10000)
	end
end)

elseif Config.ShowAllGasStations then
    CreateThread(function()
        for _, gasStationCoords in pairs(Config.GasStationsBlips) do
            CreateBlip(gasStationCoords)
        end
    end)
end

CreateThread(function()
	DecorRegister(Config.FuelDecor, 1)
	for index = 1, #Config.Blacklist do
		if type(Config.Blacklist[index]) == 'string' then
			Config.Blacklist[GetHashKey(Config.Blacklist[index])] = true
		else
			Config.Blacklist[Config.Blacklist[index]] = true
		end
	end
	for index = #Config.Blacklist, 1, -1 do
		Config.Blacklist[index] = nil
	end
	while true do
		Wait(1000)
		local ped = PlayerPedId()
		if IsPedInAnyVehicle(ped) then
			local vehicle = GetVehiclePedIsIn(ped)
			if Config.Blacklist[GetEntityModel(vehicle)] then
				inBlacklisted = true
			else
				inBlacklisted = false
			end
			if not inBlacklisted and GetPedInVehicleSeat(vehicle, -1) == ped then
				ManageFuelUsage(vehicle)
			end
		else
			if fuelSynced then
				fuelSynced = false
			end
			if inBlacklisted then
				inBlacklisted = false
			end
		end
	end
end)

-- Client Events

RegisterNetEvent('qb-fuel:client:SendMenuToServer', function()
	local vehicle = QBCore.Functions.GetClosestVehicle()
	local CurFuel = GetVehicleFuelLevel(vehicle)
	local refillCost = Round(Config.RefillCost - CurFuel) * Config.CostMultiplier
	local ped = PlayerPedId()
		if haveNozzle == true then
		    if CurFuel < 95 then
		     	TriggerServerEvent('qb-fuel:server:OpenMenu', refillCost, inGasStation, false)
	     	else
			   QBCore.Functions.Notify(Lang:t("notify.vehicle_full"), "error")
		    end
		else
			QBCore.Functions.Notify(Lang:t("notify.no_nozzle"), "error")
		end
end)

RegisterNetEvent('qb-fuel:client:RefuelVehicle', function(refillCost)
	local ped = PlayerPedId()
	local vehicle = QBCore.Functions.GetClosestVehicle()
	local ped = PlayerPedId()
	local CurFuel = GetFuel(vehicle)
	local time = (100 - CurFuel) * 400
	local vehicleCoords = GetEntityCoords(vehicle)
			if isCloseVeh() then
				if QBCore.Functions.GetPlayerData().money['cash'] <= refillCost then 
					QBCore.Functions.Notify(Lang:t("notify.no_money"), "error")
				else
				RequestAnimDict("friends@")
				while not HasAnimDictLoaded('friends@') do Wait(100) end
				TaskPlayAnim(ped, "friends@", "pickupwait", 8.0, 1.0, -1, 1, 0, 0, 0, 0 )
				if GetIsVehicleEngineRunning(vehicle) and Config.VehicleBlowUp then
					local Chance = math.random(1, 100)
				if Chance <= Config.BlowUpChance then
					AddExplosion(vehicleCoords, 5, 50.0, true, false, true)
						return
					end
				end
				TriggerEvent('qb-fuel:deleteNozzle')
				QBCore.Functions.Progressbar("refuel-car", "Refueling", time, false, true, {
					disableMovement = true,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
				}, {}, {}, {}, function() -- Done
					TriggerServerEvent('qb-fuel:server:PayForFuel', refillCost, GetPlayerServerId(PlayerId()))
					SetFuel(vehicle, 100)
					PlaySound(-1, "5_SEC_WARNING", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
					StopAnimTask(ped, "weapon@w_sp_jerrycan", "fire", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
					TriggerEvent('qb-fuel:createNozzle')
				end, function() -- Cancel
					QBCore.Functions.Notify(Lang:t("notify.refuel_cancel"), "error")
					TriggerEvent('qb-fuel:createNozzle')
					StopAnimTask(ped, "weapon@w_sp_jerrycan", "fire", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
					end)
				end
			end
end)

-- fuel Nozzle

RegisterNetEvent('qb-fuel:createNozzle', function (model)
	local ped = PlayerPedId()
	local model = 'prop_cs_fuel_nozle'
	local boneId = 28422
	local modelHash = type(model) == 'string' and GetHashKey(model) or model
    local bone = GetPedBoneIndex(ped, boneId)

	if haveNozzle == false then
    QBCore.Functions.LoadModel(modelHash)
    Nozzle = CreateObject(modelHash, -50.0, -50.0, 5.0, 4, 10)
    AttachEntityToEntity(Nozzle, ped, bone, 0.04, 0.0, -0.03, 10.0, -60.0, -100.0, false, false, false, false, 2, true)
    SetModelAsNoLongerNeeded(modelHash)
	haveNozzle = true
	else
		QBCore.Functions.Notify(Lang:t("notify.cant_havenozzle"), "error")
	end
end)

RegisterNetEvent('qb-fuel:deleteNozzle', function ()
	if haveNozzle == true then
    DeleteEntity(Nozzle)
	DeleteObject(Nozzle)
	haveNozzle = false
	else
		QBCore.Functions.Notify(Lang:t("notify.cant_dontnozzle"), "error")
	end
end)

RegisterNetEvent('qb-fuel:pumpmenu', function ()
        local myMenu = {
                {
                    header = "Fuel Pump",
                    icon = 'fas fa-gas-pump',
                    txt = "",
                    isMenuHeader = true
                },
                {
                    id = 1,
                    header = "Take Nozzle",
                    icon = 'fas fa-hand',
                    txt = "",
                    params = {
                        event = "qb-fuel:createNozzle",
                    }
                },
				{
                    id = 1,
                    header = "Put Nozzle",
                    icon = 'fas fa-hand-back-fist',
                    txt = "",
                    params = {
                        event = "qb-fuel:deleteNozzle",
                    }
                },
                {
                    id = 7,
                    header = 'close',
                    icon = 'fas fa-x',
                    params = {
                        event = 'qb-menu:client:closeMenu',
                    }
                },
            }
            exports['qb-menu']:openMenu(myMenu)

end)

-- Target Export

exports['qb-target']:AddTargetModel(props, {
	options = {
		{
			type = "client",
			event = "qb-fuel:pumpmenu",
			icon = "fas fa-burn",
			label = "Use Pump",
			
		},
	},
	distance = 2.0
})
