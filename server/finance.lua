---@param request InsertVehicleEntityWithFinanceRequest
local function insertVehicleEntityWithFinance(request)
    local insertVehicleEntityRequest = request.insertVehicleEntityRequest
    local vehicleFinance = request.vehicleFinance
    local vehicleId = exports.qbx_vehicles:CreatePlayerVehicle({
        model = insertVehicleEntityRequest.model,
        citizenid = insertVehicleEntityRequest.citizenId,
    })

    MySQL.insert('INSERT INTO vehicle_financing (vehicleId, balance, paymentamount, paymentsleft, financetime) VALUES (?, ?, ?, ?, ?)', {
        vehicleId,
        vehicleFinance.balance,
        vehicleFinance.payment,
        vehicleFinance.paymentsLeft,
        vehicleFinance.timer
    })

    return vehicleId
end

---@param time number
---@param vehicleId integer
local function updateVehicleEntityFinanceTime(time, vehicleId)
    MySQL.update('UPDATE vehicle_financing SET financetime = ? WHERE vehicleId = ?', {time, vehicleId})
end

---@param vehicleFinance VehicleFinanceServer
---@param vehicleId number
local function updateVehicleFinance(vehicleFinance, vehicleId)
    if vehicleFinance.balance == 0 then
        MySQL.query('DELETE FROM vehicle_financing WHERE vehicleId = ?', {
            vehicleId
        })
    else
        MySQL.update('UPDATE vehicle_financing AS vf INNER JOIN player_vehicles AS pv ON vf.vehicleId = pv.id SET vf.balance = ?, vf.paymentamount = ?, vf.paymentsleft = ?, vf.financetime = ? WHERE pv.id = ?', {
            vehicleFinance.balance,
            vehicleFinance.payment,
            vehicleFinance.paymentsLeft,
            vehicleFinance.timer,
            vehicleId
        })
    end
end

---@param id integer
---@return VehicleFinancingEntity
local function fetchFinancedVehicleEntityById(id)
    return MySQL.single.await('SELECT * FROM vehicle_financing WHERE vehicleId = ? AND balance > 0 AND financetime < 1', {id})
end

---@param vehicleId integer
---@return boolean
local function fetchIsFinanced(vehicleId)
    return MySQL.scalar.await('SELECT 1 FROM vehicle_financing WHERE vehicleId = ? AND balance > 0', {
        vehicleId
    }) ~= nil
end

---@param citizenId string
---@return VehicleFinancingEntity
local function fetchFinancedVehicleEntitiesByCitizenId(citizenId)
    return MySQL.query.await('SELECT vehicle_financing.* FROM vehicle_financing INNER JOIN player_vehicles ON player_vehicles.citizenid = ? WHERE vehicle_financing.vehicleId = player_vehicles.id AND vehicle_financing.balance > 0 AND vehicle_financing.financetime > 1', {citizenId})
end

return {
    insertVehicleEntityWithFinance = insertVehicleEntityWithFinance,
    updateVehicleEntityFinanceTime = updateVehicleEntityFinanceTime,
    updateVehicleFinance = updateVehicleFinance,
    fetchFinancedVehicleEntityById = fetchFinancedVehicleEntityById,
    fetchIsFinanced = fetchIsFinanced,
    fetchFinancedVehicleEntitiesByCitizenId = fetchFinancedVehicleEntitiesByCitizenId,
}