lib.versionCheck('Qbox-project/qbx_vehicleshop')
assert(lib.checkDependency('qbx_core', '1.17.2'), 'qbx_core v1.17.2 or higher is required')
assert(lib.checkDependency('qbx_vehicles', '1.4.1'), 'qbx_vehicles v1.4.1 or higher is required')

local config = require 'config.server'
local sharedConfig = require 'config.shared'
local financeStorage = require 'server.storage'
COREVEHICLES = exports.qbx_core:GetVehiclesByName()
local saleTimeout = {}
local testDrives = {}

---@param data {toVehicle: string}
RegisterNetEvent('qbx_vehicleshop:server:swapVehicle', function(data)
    if not CheckVehicleList(data.toVehicle) then return end
    TriggerClientEvent('qbx_vehicleshop:client:swapVehicle', -1, data)
end)

---@param vehicle string
RegisterNetEvent('qbx_vehicleshop:server:testDrive', function(vehicle)
    if not sharedConfig.enableTestDrive then return end
    local src = source

    if Player(src).state.isInTestDrive then
        return exports.qbx_core:Notify(src, locale('error.testdrive_alreadyin'), 'error')
    end

    local shopId = GetShopZone(src)
    local shop = sharedConfig.shops[shopId]
    if not shop then return end

    if not CheckVehicleList(vehicle, shopId) then
        return exports.qbx_core:Notify(src, locale('error.notallowed'), 'error')
    end

    local coords = GetClearSpawnArea(shop.vehicleSpawns)
    if not coords then
        return exports.qbx_core:Notify(src, locale('error.no_clear_spawn'), 'error')
    end

    local testDrive = shop.testDrive
    local plate = 'TEST'..lib.string.random('1111')

    local netId = SpawnVehicle(src, {
        modelName = vehicle,
        coords = coords,
        plate = plate
    })

    testDrives[src] = {
        netId = netId,
        endBehavior = testDrive.endBehavior,
        returnLocation = shop.returnLocation
    }

    Player(src).state:set('isInTestDrive', testDrive.limit, true)
    SetTimeout(testDrive.limit * 60000, function()
        Player(src).state:set('isInTestDrive', nil, true)
    end)
end)

---@param vehicle string
---@param playerId string|number
RegisterNetEvent('qbx_vehicleshop:server:customTestDrive', function(vehicle, playerId)
    local src = source
    local target = tonumber(playerId) --[[@as number]]

    if not exports.qbx_core:GetPlayer(target) then
        exports.qbx_core:Notify(src, locale('error.Invalid_ID'), 'error')
        return
    end

    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) < 3 then
        TriggerClientEvent('qbx_vehicleshop:client:testDrive', target, { vehicle = vehicle })
    else
        exports.qbx_core:Notify(src, locale('error.playertoofar'), 'error')
    end
end)

AddStateBagChangeHandler('isInTestDrive', nil, function(bagName, _, value)
    if value then return end

    local plySrc = GetPlayerFromStateBagName(bagName)
    if not plySrc then return end
    local testDrive = testDrives[plySrc]
    if not testDrive then return end
    local netId = testDrive.netId
    local endBehavior = testDrive.endBehavior
    if not netId or endBehavior == 'none' then return end

    local vehicle = NetworkGetEntityFromNetworkId(netId)

    if endBehavior == 'return' then
        local coords = testDrive.returnLocation
        local plyPed = GetPlayerPed(plySrc)
        if #(GetEntityCoords(plyPed) - coords) > 10 then -- don't teleport if they are standing near the spot
            SetEntityCoords(plyPed, coords.x, coords.y, coords.z, false, false, false, false)
        end
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    elseif endBehavior == 'destroy' then
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
    testDrives[plySrc] = nil
end)

AddEventHandler('onResourceStop', function (resourceName)
    if cache.resource ~= resourceName then return end

    for player, _ in pairs(testDrives) do
        Player(player).state:set('isInTestDrive', nil, true)
    end
end)

---@param vehicle string
RegisterNetEvent('qbx_vehicleshop:server:buyShowroomVehicle', function(vehicle)
    local src = source

    local shopId = GetShopZone(src)
    local shop = sharedConfig.shops[shopId]
    if not shop then return end

    if not CheckVehicleList(vehicle, shopId) then
        return exports.qbx_core:Notify(src, locale('error.notallowed'), 'error')
    end

    local coords = GetClearSpawnArea(shop.vehicleSpawns)
    if not coords then
        return exports.qbx_core:Notify(src, locale('error.no_clear_spawn'), 'error')
    end

    local player = exports.qbx_core:GetPlayer(src)
    local vehiclePrice = CheckPrice(vehicle)

    if not TakeStock(vehicle) then
        return exports.qbx_core:Notify(src, locale('error.stockempty'), 'error')
    end

    if not RemoveMoney(src, vehiclePrice, 'vehicle-bought-in-showroom') then
        ReturnStock(vehicle)
        return
    end

    local vehicleId = exports.qbx_vehicles:CreatePlayerVehicle({
        model = vehicle,
        citizenid = player.PlayerData.citizenid,
    })

    exports.qbx_core:Notify(src, locale('success.purchased'), 'success')

    SpawnVehicle(src, {
        coords = coords,
        vehicleId = vehicleId
    })
end)

---@param src number
---@param target table
---@param price number
---@param downPayment number
---@return boolean success
function SellShowroomVehicleTransact(src, target, price, downPayment)
    local player = exports.qbx_core:GetPlayer(src)

    if not RemoveMoney(target.PlayerData.source, downPayment, 'vehicle-bought-in-showroom') then
        exports.qbx_core:Notify(src, locale('error.notenoughmoney'), 'error')
        return false
    end

    local commission = lib.math.round(price * config.commissionRate)
    config.addPlayerFunds(player, 'bank', commission, 'vehicle-commission')
    exports.qbx_core:Notify(src, locale('success.earned_commission', lib.math.groupdigits(commission)), 'success')

    config.addSocietyFunds(player.PlayerData.job.name, price)
    exports.qbx_core:Notify(target.PlayerData.source, locale('success.purchased'), 'success')

    return true
end

---@param vehicle string
---@param playerId string|number
RegisterNetEvent('qbx_vehicleshop:server:sellShowroomVehicle', function(vehicle, playerId)
    local src = source
    local target = exports.qbx_core:GetPlayer(tonumber(playerId))

    if not target then
        return exports.qbx_core:Notify(src, locale('error.Invalid_ID'), 'error')
    end

    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target.PlayerData.source))) >= 3 then
        return exports.qbx_core:Notify(src, locale('error.playertoofar'), 'error')
    end

    local shopId = GetShopZone(target.PlayerData.source)
    local shop = sharedConfig.shops[shopId]
    if not shop then return end

    if not CheckVehicleList(vehicle, shopId) then
        return exports.qbx_core:Notify(src, locale('error.notallowed'), 'error')
    end

    local coords = GetClearSpawnArea(shop.vehicleSpawns)
    if not coords then
        return exports.qbx_core:Notify(src, locale('error.no_clear_spawn'), 'error')
    end

    local vehiclePrice = CheckPrice(vehicle)
    local cid = target.PlayerData.citizenid

    if not SellShowroomVehicleTransact(src, target, vehiclePrice, vehiclePrice) then return end

    local vehicleId = exports.qbx_vehicles:CreatePlayerVehicle({
        model = vehicle,
        citizenid = cid,
    })

    SpawnVehicle(playerId, {
        coords = coords,
        vehicleId = vehicleId
    })
end)

-- Transfer vehicle to player in passenger seat
lib.addCommand('transfervehicle', {
    help = locale('general.command_transfervehicle'),
    params = {
        {
            name = 'id',
            type = 'playerId',
            help = locale('general.command_transfervehicle_help')
        },
        {
            name = 'amount',
            type = 'number',
            help = locale('general.command_transfervehicle_amount'),
            optional = true
        }
    }
}, function(source, args)
    local buyerId = args.id
    local sellAmount = args.amount or 0

    if source == buyerId then
        return exports.qbx_core:Notify(source, locale('error.selftransfer'), 'error')
    end
    if saleTimeout[source] then
        return exports.qbx_core:Notify(source, locale('error.sale_timeout'), 'error')
    end
    if buyerId == 0 then
        return exports.qbx_core:Notify(source, locale('error.Invalid_ID'), 'error')
    end

    local ped = GetPlayerPed(source)
    local targetPed = GetPlayerPed(buyerId)
    if targetPed == 0 then
        return exports.qbx_core:Notify(source, locale('error.buyerinfo'), 'error')
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        return exports.qbx_core:Notify(source, locale('error.notinveh'), 'error')
    end

    local vehicleId = Entity(vehicle).state.vehicleid or exports.qbx_vehicles:GetVehicleIdByPlate(GetVehicleNumberPlateText(vehicle))
    if not vehicleId then
        return exports.qbx_core:Notify(source, locale('error.notowned'), 'error')
    end

    local player = exports.qbx_core:GetPlayer(source)
    local target = exports.qbx_core:GetPlayer(buyerId)
    local row = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)
    local isFinanced = sharedConfig.finance.enable and financeStorage.fetchIsFinanced(vehicleId)

    if not row then return end

    if config.finance.preventSelling and isFinanced then
        return exports.qbx_core:Notify(source, locale('error.financed'), 'error')
    end

    if row.citizenid ~= player.PlayerData.citizenid then
        return exports.qbx_core:Notify(source, locale('error.notown'), 'error')
    end

    if #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) > 5.0 then
        return exports.qbx_core:Notify(source, locale('error.playertoofar'), 'error')
    end

    local targetcid = target.PlayerData.citizenid
    if not target then
        return exports.qbx_core:Notify(source, locale('error.buyerinfo'), 'error')
    end

    saleTimeout[source] = true

    SetTimeout(config.saleTimeout, function()
        saleTimeout[source] = false
    end)

    if isFinanced then
        local financeData = financeStorage.fetchFinancedVehicleEntityById(vehicleId)
        local confirmFinance = lib.callback.await('qbx_vehicleshop:client:confirmFinance', buyerId, financeData)
        if not confirmFinance then
            return exports.qbx_core:Notify(source, locale('error.buyerdeclined'), 'error')
        end
    end

    lib.callback('qbx_vehicleshop:client:confirmTrade', buyerId, function(approved)
        if not approved then
            exports.qbx_core:Notify(source, locale('error.buyerdeclined'), 'error')
            return
        end

        if sellAmount > 0 then
            local currencyType = FindChargeableCurrencyType(sellAmount, target.PlayerData.money.cash, target.PlayerData.money.bank)

            if not currencyType then
                return exports.qbx_core:Notify(source, locale('error.buyertoopoor'), 'error')
            end

            config.addPlayerFunds(player, currencyType, sellAmount, 'vehicle-sold-to-player')
            config.removePlayerFunds(target, currencyType, sellAmount, 'vehicle-bought-from-player')
        end

        exports.qbx_vehicles:SetPlayerVehicleOwner(row.id, targetcid)
        config.giveKeys(buyerId, row.plate, vehicle)

        local sellerMessage = sellAmount > 0 and locale('success.soldfor') .. lib.math.groupdigits(sellAmount) or locale('success.gifted')
        local buyerMessage = sellAmount > 0 and locale('success.boughtfor') .. lib.math.groupdigits(sellAmount) or locale('success.received_gift')

        exports.qbx_core:Notify(source, sellerMessage, 'success')
        exports.qbx_core:Notify(buyerId, buyerMessage, 'success')
        if isFinanced then
            SetHasFinanced(buyerId, true)
        end
    end, GetEntityModel(vehicle), sellAmount)
end)

local VEHICLES_DATA = {}
local vehiclesLoaded = false

function LoadVehiclesData()
    VEHICLES_DATA = {}
    local result = MySQL.query.await('SELECT * FROM vehicles_data')
    local count = 0
    for _, v in pairs(result) do
        if v.model then
            VEHICLES_DATA[v.model] = {
                stock = v.stock,
                price = v.price,
                model = v.model,
                name = v.name,
                brand = v.brand,
                category = v.category
            }
            count = count + 1
        end
    end
    return count
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        PrepareDatabase()
    end
end)

lib.callback.register('qbx_vehicleshop:server:getVehicles', function(source)
    while not vehiclesLoaded do Wait(100) end
    return VEHICLES_DATA
end)

function CheckStock(vehicle)
    local result = MySQL.query.await('SELECT stock FROM vehicles_data WHERE model = ?', {vehicle})
    return result and result[1] and result[1].stock or 0
end

---@param vehicle string
---@return boolean
function TakeStock(vehicle)
    return MySQL.update.await('UPDATE vehicles_data SET stock = stock - 1 WHERE model = ? AND stock > 0', { vehicle }) > 0
end

---@param vehicle string
function ReturnStock(vehicle)
    MySQL.update.await('UPDATE vehicles_data SET stock = stock + 1 WHERE model = ?', { vehicle })
end

function CheckPrice(vehicle)
    local result = MySQL.query.await('SELECT price FROM vehicles_data WHERE model = ?', {vehicle})
    return result and result[1] and result[1].price or 0
end

lib.callback.register('qbx_vehicleshop:server:checkstock', function(source, vehicle)
    return CheckStock(vehicle)
end)

lib.callback.register('qbx_vehicleshop:server:checkprice', function(source, vehicle)
    return CheckPrice(vehicle)
end)

lib.callback.register('qbx_vehicleshop:server:getCategories', function(source)
    local categories = {}
    local result = MySQL.query.await('SELECT DISTINCT category FROM vehicles_data')

    for _, v in pairs(result) do
        if v.category and v.category ~= "" then
            table.insert(categories, { label = v.category, value = v.category })
        end
    end

    return categories
end)

function PrepareDatabase()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS vehicles_data (
            model VARCHAR(50) PRIMARY KEY,
            stock INT DEFAULT 0,
            price INT NOT NULL,
            name VARCHAR(100),
            brand VARCHAR(50),
            category VARCHAR(50),
            hash BIGINT
        )
    ]])

    local existing = {}
    for _, row in pairs(MySQL.query.await('SELECT model FROM vehicles_data')) do
        existing[row.model] = true
    end

    local inserted = 0
    for k, v in pairs(exports.qbx_core:GetVehiclesByName()) do
        if not existing[k] then
            inserted = inserted + 1
            MySQL.insert.await("INSERT INTO vehicles_data (model, stock, price, name, brand, category, hash) VALUES (?, ?, ?, ?, ?, ?, ?)",
                { k, 0, v.price, v.name, v.brand, v.category, v.hash })
        end
    end

    local count = LoadVehiclesData()
    vehiclesLoaded = true
    TriggerClientEvent('qbx_vehicleshop:client:refreshVehicles', -1)
    lib.print.info(('%s veículos carregados (%s novos cadastrados com estoque 0)'):format(count, inserted))
end


lib.addCommand("loadstock", {
    help = locale("general.command_loadstock"),
    params = {},
    restricted = { "admin" },
}, function(source)
    PrepareDatabase()
    exports.qbx_core:Notify(source, "Tabela de veículos carregada.", "success")
end)

lib.addCommand("setstock", {
    help = locale("general.command_setstock"),
    params = {},
    restricted = { "admin" },
}, function(source)
    local ped = GetPlayerPed(source)
    local veh = GetVehiclePedIsIn(ped, false)
    local vehicleModel = nil

    if veh > 0 then
        local vehicleHash = GetEntityModel(veh)
        local vehicleData = exports.qbx_core:GetVehiclesByHash(vehicleHash)
        vehicleModel = vehicleData and vehicleData.model

        if not vehicleModel then
            exports.qbx_core:Notify(source, "Veículo não encontrado", "error")
            return
        end
    else
        local vehicles = exports.qbx_core:GetVehiclesByName()
        local vehicleList = {}

        for _, v in pairs(vehicles) do
            table.insert(vehicleList, { label = string.format('%s (%s)', v.name, v.model), value = v.model })
        end

        vehicleModel = lib.callback.await("qbx_vehicleshop:dialog:selectVehicle", source, vehicleList)

        if not vehicleModel then
            exports.qbx_core:Notify(source, "Nenhum veículo selecionado", "error")
            return
        end
    end

    local vehicleInfo = MySQL.query.await("SELECT * FROM vehicles_data WHERE model = ?", { vehicleModel })

    if not vehicleInfo or not vehicleInfo[1] then
        exports.qbx_core:Notify(source, "Veículo não encontrado na base de dados", "error")
        return
    end

    vehicleInfo = vehicleInfo[1]

    local input = lib.callback.await("qbx_vehicleshop:dialog:updateStock", source, vehicleInfo)

    if input and input.reset then
        local vehData = exports.qbx_core:GetVehiclesByName()[vehicleModel]

        if not vehData then
            exports.qbx_core:Notify(source, "Erro ao buscar os dados do veículo!", "error")
            return
        end

        MySQL.update("DELETE FROM vehicles_data WHERE model = ?", { vehicleModel })
        MySQL.insert("INSERT INTO vehicles_data (model, stock, price, name, brand, category, hash) VALUES (?, ?, ?, ?, ?, ?, ?)", {
            vehicleModel, 0, vehData.price, vehData.name, vehData.brand, vehData.category, vehData.hash
        })
        VEHICLES_DATA[vehicleModel] = { stock = 0, price = vehData.price, model = vehicleModel, name = vehData.name, brand = vehData.brand, category = vehData.category }
        TriggerClientEvent('qbx_vehicleshop:client:refreshVehicles', -1)

        exports.qbx_core:Notify(source, "Veículo " .. vehicleModel .. " redefinido!", "success")
    elseif input and tonumber(input.stock) and tonumber(input.price) and input.name and input.brand and input.category then
        MySQL.update("UPDATE vehicles_data SET stock = ?, price = ?, name = ?, brand = ?, category = ? WHERE model = ?", {
            tonumber(input.stock), tonumber(input.price), input.name, input.brand, input.category, vehicleModel
        })
        VEHICLES_DATA[vehicleModel] = { stock = tonumber(input.stock), price = tonumber(input.price), model = vehicleModel, name = input.name, brand = input.brand, category = input.category }
        TriggerClientEvent('qbx_vehicleshop:client:refreshVehicles', -1)

        exports.qbx_core:Notify(source, "Dados de " .. vehicleModel .. " atualizados com sucesso!", "success")
    else
        exports.qbx_core:Notify(source, "Nenhum valor válido inserido", "error")
    end
end)
