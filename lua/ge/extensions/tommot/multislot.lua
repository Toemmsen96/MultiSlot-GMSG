--[[
This file is part of the "MultiSlot / ModSlot generator" mod for BeamNG.drive by TommoT / Toemmsen
To get the latest version of this mod, please visit:
https://github.com/Toemmsen96/generalModSlotGenerator/
]]


local M = {}

local TIMER_GENERATION = true

local function makeAndSaveNewTemplate(...) return tommot_templates.makeAndSaveNewTemplate(...) end
local function getModSlot(...) return tommot_modslotGenerator.getModSlot(...) end
local function getModSlotJbeamPath(...) return tommot_modslotGenerator.getModSlotJbeamPath(...) end
local function getSlotTypes(...) return tommot_modslotGenerator.getSlotTypes(...) end
local function getAllVehicles(...) return tommot_modslotGenerator.getAllVehicles(...) end
local function readJsonFile(...) return tommot_modslotGenerator.readJsonFile(...) end
local function writeJsonFile(...) return tommot_modslotGenerator.writeJsonFile(...) end
local function loadTemplateNames(...) return tommot_templates.loadTemplateNames(...) end
local function loadTemplate(...) return tommot_templates.loadTemplate(...) end
local function convertName(...) return tommot_modslotGenerator.convertName(...) end
local function getGeneratedPath() return tommot_modslotGenerator.GENERATED_PATH end
local function onFinishGen(...) return tommot_modslotGenerator.onFinishGen(...) end

local function GMSGMessage(msg, title, icon, duration)
    tommot_modslotGenerator.GMSGMessage(msg, title, icon, duration)
end

local function dedupeSlotRows(slotTable)
    if type(slotTable) ~= 'table' then
        return slotTable
    end

    local deduped = {}
    local seen = {}

    for i, row in ipairs(slotTable) do
        -- Preserve the two header rows from mSGTemplate.json.
        if i <= 2 then
            table.insert(deduped, row)
        elseif type(row) == 'table' then
            local key = row[1]
            if key == nil or not seen[key] then
                table.insert(deduped, row)
                if key ~= nil then
                    seen[key] = true
                end
            end
        else
            table.insert(deduped, row)
        end
    end

    return deduped
end

local function saveMultiTemplate(template, templateName)
    local convName = convertName(templateName)
    local newTemplate = deepcopy(template)
    makeAndSaveNewTemplate("common", convName .. "_mod", newTemplate, templateName)
end

--generation stuff for multi templates
local function generateMulti(vehicleDir)
    local multiModTemplate = readJsonFile("/lua/ge/extensions/tommot/mSGTemplate.json")
    if multiModTemplate == nil then
        log('E', 'generateMulti', "Failed to load multiModTemplate")
        return
    end
    local vehicleModSlot = getModSlot(vehicleDir)
    if vehicleModSlot == nil then
        if DET_DEBUG then logToConsole('D', 'generateMulti', vehicleDir .. " has no mod slot") end
        return
    end
    multiModTemplate.slotType = vehicleModSlot
    local templateNames = loadTemplateNames()
    local addedEntries = {}
    for _,templateName in pairs(templateNames) do
        local convName = convertName(templateName)
        if multiModTemplate ~= nil and multiModTemplate.slots ~= nil and type(multiModTemplate.slots) == 'table' then
            local entryKey = convName .. "_mod"
            if not addedEntries[entryKey] then
                table.insert(multiModTemplate.slots, {entryKey, "", templateName})
                addedEntries[entryKey] = true
            end
        end
    end
    multiModTemplate.slots = dedupeSlotRows(multiModTemplate.slots)
    makeAndSaveNewTemplate(vehicleDir, vehicleModSlot, multiModTemplate, "multimod")
end

local function generateMultiSlotJob(job)
    local timer = nil
    local time = nil
    if TIMER_GENERATION then 
        log('D', 'generateSeparateJob', "Generating MultiSlot mods with timer: " .. os.time())
        timer = hptimer()
    end
    GMSGMessage("Generating multi mods", "Info", "info", 2000)
    local templateNames = loadTemplateNames()
    for _,name in pairs(templateNames) do
        local template = loadTemplate(name)
        if template ~= nil then
            saveMultiTemplate(template, name)
            job.yield()
        end
    end
    for _,veh in pairs(getAllVehicles()) do
        generateMulti(veh)
        job.yield()
    end
    if TIMER_GENERATION then 
        time = timer:stop()
        log('D', 'generateSeparateJob', "Done generating MultiSlot mods with timer: " .. time)
        GMSGMessage("Done generating MultiSlot mods with timer: " .. time, "Info", "info", 2000)
    end
    GMSGMessage("Done generating all mods", "Info", "info", 2000)
    onFinishGen()
end

local function generateMultiSlotMod()
    local templateNames = loadTemplateNames()
    for _,name in pairs(templateNames) do
        local template = loadTemplate(name)
        if template ~= nil then
            saveMultiTemplate(template, name)
        end
    end
	for _,veh in pairs(getAllVehicles()) do
		generateMulti(veh)
    end
    onFinishGen()
end





M.generateMultiSlotJob = generateMultiSlotJob
M.generateMultiSlotMod = generateMultiSlotMod
M.saveMultiTemplate = saveMultiTemplate

return M