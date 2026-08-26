local M = {}

local function fs()  return tommot_lib_fs end
local function cfg() return tommot_gmsg_settings.cfg end

local function findMainPart(vehicleJbeam)
    if type(vehicleJbeam) ~= 'table' then return nil end
    for partKey, part in pairs(vehicleJbeam) do
        if part.slotType == "main" then return partKey end
    end
    return nil
end

local function loadMainSlot(vehicleDir)
    local vehJbeamPath = "/vehicles/" .. vehicleDir .. "/" .. vehicleDir .. ".jbeam"
    if FS:fileExists(vehJbeamPath) then
        local vehicleJbeam = fs().readJsonFile(vehJbeamPath)
        local mainPartKey = findMainPart(vehicleJbeam)
        if mainPartKey then return vehicleJbeam[mainPartKey] end
    end
    local files = FS:findFiles("/vehicles/" .. vehicleDir, "*.jbeam", -1, true, false)
    for _, file in ipairs(files) do
        local vehicleJbeam = fs().readJsonFile(file)
        local mainPartKey = findMainPart(vehicleJbeam)
        if mainPartKey then return vehicleJbeam[mainPartKey] end
    end
    if cfg().DET_DEBUG then log('W', 'loadMainSlot', "No main slot found for " .. vehicleDir) end
    return nil
end

local function getSlotTypes(slotTable)
    local slotTypes = {}
    for i, slot in pairs(slotTable) do
        if i > 1 then table.insert(slotTypes, slot[1]) end
    end
    return slotTypes
end

local function getModSlot(vehicleDir)
    local mainSlotData = loadMainSlot(vehicleDir)
    if mainSlotData == nil then return nil end
    for _, slotKey in ipairs({"slots", "slots2"}) do
        local slots = mainSlotData[slotKey]
        if slots and type(slots) == 'table' then
            for _, slotType in pairs(getSlotTypes(slots)) do
                if fs().ends_with(slotType, "_mod") then return slotType end
            end
        end
    end
    return nil
end

local function getAllVehicles()
    local vehicles = {}
    for _, v in ipairs(FS:findFiles('/vehicles', '*', 0, false, true)) do
        if v ~= '/vehicles/common' then
            table.insert(vehicles, string.match(v, '/vehicles/(.*)'))
        end
    end
    return vehicles
end

local function getModSlotJbeamPath(vehicleDir, templateName)
    return cfg().GENERATED_PATH:lower() .. "/vehicles/" .. vehicleDir .. "/modslot/" .. vehicleDir .. "_" .. templateName .. ".jbeam"
end

local function loadExistingModSlotData(vehicleDir, templateName)
    return fs().readJsonFile(getModSlotJbeamPath(vehicleDir, templateName))
end

M.getAllVehicles = getAllVehicles
M.getModSlot = getModSlot
M.getSlotTypes = getSlotTypes
M.getModSlotJbeamPath = getModSlotJbeamPath
M.loadExistingModSlotData = loadExistingModSlotData

return M
