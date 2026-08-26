local M = {}

local function tpl()    return tommot_gmsg_templates end
local function veh()    return tommot_gmsg_vehicles end
local function packer() return tommot_gmsg_packer end
local function gen()    return tommot_lib_generator end
local function logger() return tommot_lib_logger end

local function GMSGMessage(msg, title, t, dur) logger().GMSGMessage(msg, title, t, dur) end

local function dedupeSlotRows(slotTable)
    if type(slotTable) ~= 'table' then return slotTable end
    local deduped = {}
    local seen = {}
    for i, row in ipairs(slotTable) do
        if i <= 2 then
            table.insert(deduped, row)
        elseif type(row) == 'table' then
            local key = row[1]
            if key == nil or not seen[key] then
                table.insert(deduped, row)
                if key ~= nil then seen[key] = true end
            end
        else
            table.insert(deduped, row)
        end
    end
    return deduped
end

local function saveMultiTemplate(template, templateName)
    local convName = gen().convertName(templateName)
    tpl().makeAndSaveNewTemplate("common", convName .. "_mod", deepcopy(template), templateName)
end

local function generateMulti(vehicleDir)
    local multiModTemplate = tommot_lib_fs.readJsonFile("/lua/ge/extensions/tommot/mSGTemplate.json")
    if multiModTemplate == nil then
        log('E', 'generateMulti', "Failed to load multiModTemplate")
        return
    end
    local vehicleModSlot = veh().getModSlot(vehicleDir)
    if vehicleModSlot == nil then return end
    multiModTemplate.slotType = vehicleModSlot
    local templateNames = tpl().loadTemplateNames() or {}
    local addedEntries = {}
    for _, templateName in pairs(templateNames) do
        local convName = gen().convertName(templateName)
        local entryKey = convName .. "_mod"
        if not addedEntries[entryKey] then
            table.insert(multiModTemplate.slots, {entryKey, "", templateName})
            addedEntries[entryKey] = true
        end
    end
    multiModTemplate.slots = dedupeSlotRows(multiModTemplate.slots)
    tpl().makeAndSaveNewTemplate(vehicleDir, vehicleModSlot, multiModTemplate, "multimod")
end

local function generateMultiSlotJob(job)
    local timer = tommot_gmsg_settings.cfg.TIMER_GENERATION and hptimer() or nil
    GMSGMessage("Generating multi mods", "Info", "info", 2000)
    local templateNames = tpl().loadTemplateNames() or {}
    for _, name in pairs(templateNames) do
        local template = tpl().loadTemplate(name)
        if template ~= nil then
            saveMultiTemplate(template, name)
            job.yield()
        end
    end
    for _, v in pairs(veh().getAllVehicles()) do
        generateMulti(v)
        job.yield()
    end
    if timer then GMSGMessage("Done generating MultiSlot mods: " .. timer:stop(), "Info", "info", 2000) end
    GMSGMessage("Done generating all mods", "Info", "info", 2000)
    packer().onFinishGen()
end

local function generateMultiSlotMod()
    local templateNames = tpl().loadTemplateNames() or {}
    for _, name in pairs(templateNames) do
        local template = tpl().loadTemplate(name)
        if template then saveMultiTemplate(template, name) end
    end
    for _, v in pairs(veh().getAllVehicles()) do
        generateMulti(v)
    end
    packer().onFinishGen()
end

M.generateMultiSlotJob = generateMultiSlotJob
M.generateMultiSlotMod = generateMultiSlotMod
M.saveMultiTemplate    = saveMultiTemplate

return M
