-- Variables

local QBCore = exports['qb-core']:GetCoreObject()

-- Server Events

QBCore.Functions.CreateCallback('qb-fuel:server:fuelCan', function(source, cb)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local itemData = Player.Functions.GetItemByName("weapon_petrolcan")
    cb(itemData)
end)

RegisterNetEvent("qb-fuel:server:PayForFuel", function(data, refillCost)
	local src = source
	local PayTable = json.encode(data)
	local PayData = json.decode(PayTable)
	
	if not src then return end
	local player = QBCore.Functions.GetPlayer(src)
	if not player then return end
	player.Functions.RemoveMoney(PayData.MoneyType, refillCost)
end)
