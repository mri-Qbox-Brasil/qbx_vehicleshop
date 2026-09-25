local blocklist = {}
local sharedConfig = require 'config.shared'.vehicles
local allowed = {
    vehicles = {},
    count = 0,
}

for i = 1, #sharedConfig.blocklist do
    local blockveh = sharedConfig.blocklist[i]
    blocklist[blockveh] = true
end

local function insertVehicle(vehicleData, shopType)
    allowed.count += 1
    allowed.vehicles[allowed.count] = {
        shopType = shopType,
        category = vehicleData.category,
        model = vehicleData.model,
    }
end

local function build()
    allowed.vehicles = {}
    allowed.count = 0

    for k, vehicle in pairs(exports.qbx_core:GetVehiclesByName()) do
        local vehicleShop = sharedConfig.models[k] or sharedConfig.categories[vehicle.category] or sharedConfig.default

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
end

build()

-- Rebuilds when vehicles are added/edited/removed at runtime (qbx_core mri/)
local rebuildPending = false
AddEventHandler('qbx_core:server:onVehicleUpdate', function()
    if rebuildPending then return end
    rebuildPending = true
    SetTimeout(500, function()
        rebuildPending = false
        build()
    end)
end)

return allowed
