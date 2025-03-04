local vehicles = {}
local blocklist = {}
local VEHICLES = lib.callback.await('qbx_vehicleshop:server:getVehicles', false)
local sharedConfig = require 'config.shared'.vehicles
local groupdigits = lib.math.groupdigits
local count = 0

local function insertVehicle(vehicleData, shopType)
    count += 1
    vehicles[count] = {
        shopType = shopType,
        category = vehicleData.category,

        title = ('%s %s'):format(vehicleData.brand, vehicleData.name),
        description = ('%s%s'):format(locale('menus.veh_price'), groupdigits(vehicleData.price)),
        serverEvent = 'qbx_vehicleshop:server:swapVehicle',
        args = {
            toVehicle = vehicleData.model,
        }
    }
end

local function LoadVehicles()
    vehicles = {}
    blocklist = {}
    count = 0

    for i = 1, #sharedConfig.blocklist or {} do
        local blockveh = sharedConfig.blocklist[i]
        blocklist[blockveh] = true
    end

    for k, vehicle in pairs(VEHICLES) do
        local vehicleShop = sharedConfig.models and sharedConfig.models[k] or sharedConfig.categories and sharedConfig.categories[vehicle.category] or sharedConfig.default

        if blocklist[k] then
            lib.print.debug('Vehicle is blocked. Skipping: ' .. k)
        elseif not vehicleShop then
            lib.print.debug('Vehicle not found in config. Skipping: ' .. k)
        else
            if type(vehicleShop) == 'table' then
                for i = 1, #vehicleShop do
                    insertVehicle(vehicle, vehicleShop[i])
                end
            else
                insertVehicle(vehicle, vehicleShop)
            end
        end
    end

    table.sort(vehicles, function(a, b)
        return a.title < b.title
    end)

    lib.print.info("Lista de veículos carregada com sucesso! Total: " .. count)
end

function GetVehiclesFromServer()
    if count == 0 then
        LoadVehicles()
    end
    return {
        vehicles = vehicles,
        count = count
    }
end

function RefreshVehicles()
    VEHICLES = lib.callback.await('qbx_vehicleshop:server:getVehicles', false)
    LoadVehicles()
    lib.print.info("Lista de veículos foi atualizada!")
end

LoadVehicles()

RegisterNetEvent('qbx_vehicleshop:client:refreshVehicles', function()
    RefreshVehicles()
end)