local M = {}

local templateNames = {}

local function fs()     return tommot_lib_fs end
local function veh()    return tommot_gmsg_vehicles end
local function tpl()    return tommot_gmsg_templates end
local function packer() return tommot_gmsg_packer end
local function cfg()    return tommot_gmsg_settings.cfg end
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

local function getLicensePlateAdditionalMods()
    local result = {}
    local files = FS:findFiles("/vehicles/common", "*.jbeam", -1, true, false)
    for _, file in ipairs(files) do
        local jbeam = fs().readJsonFile(file)
        if jbeam then
            for partKey, part in pairs(jbeam) do
                local hasLPSlot = false
                if part.slotType then
                    if type(part.slotType) == "string" and part.slotType == "licenseplate_design_2_1" then
                        hasLPSlot = true
                    elseif type(part.slotType) == "table" then
                        for _, st in ipairs(part.slotType) do
                            if st == "licenseplate_design_2_1" then hasLPSlot = true break end
                        end
                    end
                end
                if hasLPSlot then
                    if part.information and part.information.name then
                        local n = part.information.name:lower()
                        if n:find("plate") and n:find("design") then goto continue end
                    end
                    local additionalPartKey = fs().ends_with(partKey, "_additional_lp")
                        and partKey:lower()
                        or  partKey:lower() .. "_additional_lp"
                    local outputPath = cfg().GENERATED_PATH:lower() .. "/vehicles/common/modslot/" .. additionalPartKey .. ".jbeam"
                    if FS:fileExists(outputPath) and fs().readJsonFile(outputPath) ~= nil then
                        table.insert(result, {partKey = additionalPartKey, file = file, name = part.information and part.information.name or partKey})
                        goto continue
                    end
                    local modifiedJbeam = deepcopy(jbeam)
                    if not modifiedJbeam then log('E', 'getLicensePlateAdditionalMods', "deepcopy failed: " .. partKey) goto continue end
                    modifiedJbeam[additionalPartKey] = deepcopy(part)
                    modifiedJbeam[additionalPartKey].slotType = additionalPartKey
                    modifiedJbeam[partKey] = nil
                    FS:directoryCreate(cfg().GENERATED_PATH:lower() .. "/vehicles/common/modslot/", true)
                    if not fs().writeFileAtomic(outputPath, modifiedJbeam, true) then
                        log('E', 'getLicensePlateAdditionalMods', "Failed to write: " .. outputPath)
                        goto continue
                    end
                    if fs().readJsonFile(outputPath) == nil then
                        log('E', 'getLicensePlateAdditionalMods', "Validation failed: " .. outputPath)
                        goto continue
                    end
                    table.insert(result, {partKey = additionalPartKey, file = file, name = part.information and part.information.name or partKey})
                end
                ::continue::
            end
        end
    end
    return result
end

local function getAdditionalMods(vehicleDir)
    local result = {}
    local vehicleModSlot = veh().getModSlot(vehicleDir)
    if not vehicleModSlot then return result end
    local files = FS:findFiles("/vehicles/" .. vehicleDir, "*.jbeam", -1, true, false)
    for _, file in ipairs(files) do
        local jbeamData = fs().readJsonFile(file)
        if jbeamData then
            for partKey, part in pairs(jbeamData) do
                if part.slotType == vehicleModSlot
                   and not fs().ends_with(partKey, "_multimod")
                   and not fs().ends_with(vehicleModSlot, "_additional") then
                    local outputPath = cfg().GENERATED_PATH:lower() .. "/vehicles/" .. vehicleDir .. "/modslot/" .. partKey .. "_multislot.jbeam"
                    if FS:fileExists(outputPath) and fs().readJsonFile(outputPath) ~= nil then
                        table.insert(result, {partKey = partKey, file = file, name = part.information and part.information.name or partKey})
                        break
                    end
                    local modifiedJbeam = deepcopy(jbeamData)
                    if not modifiedJbeam then log('E', 'getAdditionalMods', "deepcopy failed: " .. partKey) break end
                    local additionalPartKey = partKey .. "_additional"
                    modifiedJbeam[additionalPartKey] = deepcopy(part)
                    modifiedJbeam[additionalPartKey].slotType = additionalPartKey
                    modifiedJbeam[partKey] = nil
                    FS:directoryCreate(cfg().GENERATED_PATH:lower() .. "/vehicles/" .. vehicleDir .. "/modslot/", true)
                    if not fs().writeFileAtomic(outputPath, modifiedJbeam, true) then log('E', 'getAdditionalMods', "Failed to write: " .. outputPath) break end
                    if fs().readJsonFile(outputPath) == nil then log('E', 'getAdditionalMods', "Validation failed: " .. outputPath) break end
                    table.insert(result, {partKey = partKey, file = file, name = part.information and part.information.name or partKey})
                    break
                end
            end
        end
    end
    return result
end

local function generateMultiWithAdditional(vehicleDir, addMods, lpMods)
    local multiModTemplate = fs().readJsonFile("/lua/ge/extensions/tommot/mSGTemplate.json")
    if multiModTemplate == nil then log('E', 'generateMultiWAdditional', "Failed to load multiModTemplate") return end
    local vehicleModSlot = veh().getModSlot(vehicleDir)
    if vehicleModSlot == nil then return end
    multiModTemplate.slotType = vehicleModSlot
    local addedEntries = {}
    for _, templateName in pairs(templateNames) do
        local convName = templateName:lower():gsub(" ", "_")
        local entryKey = convName .. "_mod"
        if not addedEntries[entryKey] then
            table.insert(multiModTemplate.slots, {entryKey, "", templateName})
            addedEntries[entryKey] = true
        end
    end
    for _, mod in pairs(addMods) do
        local entryKey = mod.partKey .. "_additional"
        if not addedEntries[entryKey] then
            table.insert(multiModTemplate.slots, {entryKey, "", mod.name})
            addedEntries[entryKey] = true
        end
    end
    for _, mod in pairs(lpMods) do
        local entryKey = mod.partKey
        if not addedEntries[entryKey] then
            table.insert(multiModTemplate.slots, {entryKey, "", mod.name})
            addedEntries[entryKey] = true
        end
    end
    multiModTemplate.slots = dedupeSlotRows(multiModTemplate.slots)
    tpl().makeAndSaveNewTemplate(vehicleDir, vehicleModSlot, multiModTemplate, "multimod")
end

local function additionalToMultiSlotJob(job)
    GMSGMessage("Generating combined MultiSlot", "Info", "info", 2000)
    templateNames = tpl().loadTemplateNames() or {}
    local lpMods = getLicensePlateAdditionalMods()
    for _, vehicle in pairs(veh().getAllVehicles()) do
        generateMultiWithAdditional(vehicle, getAdditionalMods(vehicle), lpMods)
        job.yield()
    end
    GMSGMessage("Finished generating combined MultiSlot", "Info", "info", 2000)
    packer().onFinishGen()
end

local function additionalToMultiSlot()
    GMSGMessage("Generating combined MultiSlot", "Info", "info", 2000)
    templateNames = tpl().loadTemplateNames() or {}
    local lpMods = getLicensePlateAdditionalMods()
    for _, vehicle in pairs(veh().getAllVehicles()) do
        generateMultiWithAdditional(vehicle, getAdditionalMods(vehicle), lpMods)
    end
    GMSGMessage("Finished generating combined MultiSlot", "Info", "info", 2000)
    packer().onFinishGen()
end

M.additionalToMultiSlotJob = additionalToMultiSlotJob
M.additionalToMultiSlot    = additionalToMultiSlot

return M
