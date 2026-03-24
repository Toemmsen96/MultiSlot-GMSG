--[ Author: TommoT / Toemmsen
-- Description: This script is used to generate modslot jbeams for all vehicles in the game.
-- It uses a template files that are placed in /modslotgenerator/ to generate the Additional Modification mods and makes them selectable at once.
-- Don't inlcude this mod in your mod, add it as a requirement in you Modpage, as it prevents duplicate code.

local M = {}
local DET_DEBUG = true
local gmsg = tommot_modslotGenerator
local templateNames = {}
local additionalMods = {}

-- helpers
local function isEmptyOrWhitespace(str)
    return str == nil or str:match("^%s*$") ~= nil
end

local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

local function readJsonFile(path)
    if isEmptyOrWhitespace(path) then
        log('E', 'readJsonFile', "path is empty")
        return nil
    end
    return jsonReadFile(path)
end

local function writeJsonFile(path, data, compact)
    return jsonWriteFile(path, data, compact)
end

local function writeFileAtomic(finalPath, data, compact)
    local tempPath = finalPath .. ".tmp"
    
    -- Write to temp file first as validation
    local writeSuccess = writeJsonFile(tempPath, data, compact)
    if not writeSuccess then
        log('E', 'writeFileAtomic', "Failed to write temp file: " .. tempPath)
        return false
    end
    
    -- Validate temp file
    local validateData = readJsonFile(tempPath)
    if validateData == nil then
        log('E', 'writeFileAtomic', "Validation failed for temp file: " .. tempPath)
        FS:removeFile(tempPath)
        return false
    end
    
    -- Write directly to final path (overwrite safely)
    local finalWriteSuccess = writeJsonFile(finalPath, data, compact)
    if not finalWriteSuccess then
        log('E', 'writeFileAtomic', "Failed to write final file: " .. finalPath)
        FS:removeFile(tempPath)
        return false
    end
    
    -- Validate final file
    local validateFinal = readJsonFile(finalPath)
    if validateFinal == nil then
        log('E', 'writeFileAtomic', "Validation failed for final file: " .. finalPath)
        FS:removeFile(tempPath)
        return false
    end
    
    -- Clean up temp file
    FS:removeFile(tempPath)
    
    if DET_DEBUG then log('D', 'writeFileAtomic', "Successfully wrote and validated: " .. finalPath) end
    return true
end

local function getModNameFromPath(path) -- stolen from modmanager.lua lol, credits to BeamNG
    local modname = string.lower(path)
    modname = modname:gsub('dir:/', '') --should have been killed by now
    modname = modname:gsub('/mods/', '')
    modname = modname:gsub('repo/', '')
    modname = modname:gsub('unpacked/', '')
    modname = modname:gsub('/', '')
    modname = modname:gsub('.zip$', '')
    --log('I', 'getModNameFromPath', "getModNameFromPath path = "..path .."    name = "..dumps(modname) )
    return modname
end
-- end helpers

-- TODO: ADJUST BELOW THIS LINE --
local function findMainPart(vehicleJbeam) 
    if type(vehicleJbeam) ~= 'table' then return nil end
    
    for partKey, part in pairs(vehicleJbeam) do
        -- is it valid?
        if part.slotType == "main" then
            return partKey
        end
    end
    return nil
end

local function loadMainSlot(vehicleDir)
    --first check if a file exists named vehicleDir.jbeam
    local vehJbeamPath = "/vehicles/" .. vehicleDir .. "/" .. vehicleDir .. ".jbeam"
    local vehicleJbeam = nil
    
    if FS:fileExists(vehJbeamPath) then
        -- load it!
        vehicleJbeam = readJsonFile(vehJbeamPath)
        
        -- is it valid?
        local mainPartKey = findMainPart(vehicleJbeam)
        if mainPartKey ~= nil then
            return vehicleJbeam[mainPartKey]
        end
    end
    
    --if it wasn't valid, look through all files in this vehicle dir
    local files = FS:findFiles("/vehicles/" .. vehicleDir, "*.jbeam", -1, true, false)
    for _, file in ipairs(files) do
        -- load it!
        vehicleJbeam = readJsonFile(file)
        
        -- is it valid?
        local mainPartKey = findMainPart(vehicleJbeam)
        if mainPartKey ~= nil then
            return vehicleJbeam[mainPartKey]
        end
    end
    if DET_DEBUG then log('W', 'loadMainSlot', "No main slot found for " .. vehicleDir) end
    --if all else fails, return nil
    return nil
end

local function getSlotTypes(slotTable)
    local slotTypes = {}
    for i, slot in pairs(slotTable) do
        if i > 1 then
            local slotType = slot[1]
            table.insert(slotTypes, slotType)
        end
    end
    return slotTypes
end

local function dedupeSlotRows(slotTable)
    if type(slotTable) ~= 'table' then
        return slotTable
    end

    local deduped = {}
    local seen = {}

    for i, row in ipairs(slotTable) do
        -- Keep header rows untouched.
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

local function getModSlot(vehicleDir)
    local mainSlotData = loadMainSlot(vehicleDir)
    if mainSlotData ~= nil and mainSlotData.slots ~= nil and type(mainSlotData.slots) == 'table' then
        for _,slotType in pairs(getSlotTypes(mainSlotData.slots)) do
            if ends_with(slotType, "_mod") then
                return slotType
            end
        end
    end

    --if that didn't work, try for slots2, which is used in some vehicles, and a newer format
    if mainSlotData ~= nil and mainSlotData.slots2 ~= nil and type(mainSlotData.slots2) == 'table' then
        for _,slotType in pairs(getSlotTypes(mainSlotData.slots2)) do
            if ends_with(slotType, "_mod") then
                return slotType
            end
        end
    end
    return nil
end

local function getLicensePlateAdditionalMods()
    local additionalMods = {}
    local files = FS:findFiles("/vehicles/common", "*.jbeam", -1, true, false)

    for _, file in ipairs(files) do
        local jbeam = readJsonFile(file)
        if jbeam then
            for partKey, part in pairs(jbeam) do
                local hasLicensePlateSlot = false
                --if DET_DEBUG then log('D', 'getLicensePlateAdditionalMods', "Checking part: " .. partKey) end
                if part.slotType then
                    if type(part.slotType) == "string" and part.slotType == "licenseplate_design_2_1" then
                        if DET_DEBUG then log('D', 'getLicensePlateAdditionalMods', "Found license plate slot in " .. partKey) end
                        hasLicensePlateSlot = true
                    elseif type(part.slotType) == "table" then
                        for _, slotType in ipairs(part.slotType) do
                            if slotType == "licenseplate_design_2_1" then
                                if DET_DEBUG then log('D', 'getLicensePlateAdditionalMods', "Found license plate slot in " .. partKey) end
                                hasLicensePlateSlot = true
                                break
                            end
                        end
                    end
                end
                
                if hasLicensePlateSlot then
                    if part.information and part.information.name then
                        local infoName = part.information.name:lower()
                        if infoName:find("plate") and infoName:find("design") then
                            if DET_DEBUG then log('D', 'getLicensePlateAdditionalMods', "Skipping: " .. partKey .. " due to name filter") end
                            goto continue
                        end
                    end
                    
                    -- Create additional license plate part
                    if DET_DEBUG then log('D', 'getLicensePlateAdditionalMods', "Creating additional mod for: " .. partKey) end
                    local additionalPartKey
                    if not partKey:endswith("_additional_lp") then
                        if DET_DEBUG then log('D', 'getLicensePlateAdditionalMods', "Part key does not end with _additional_lp, proceeding: " .. partKey) end
                        additionalPartKey = partKey:lower() .. "_additional_lp"
                    else
                        if DET_DEBUG then log('D', 'getLicensePlateAdditionalMods', "Part key already ends with _additional_lp, skipping: " .. partKey) end
                        additionalPartKey = partKey:lower()
                    end

                    local outputPath = gmsg.GENERATED_PATH:lower().."/vehicles/common/modslot/" .. additionalPartKey .. ".jbeam"
                    if FS:fileExists(outputPath) and readJsonFile(outputPath) ~= nil then
                        table.insert(additionalMods, {
                            partKey = additionalPartKey,
                            file = file,
                            name = part.information and part.information.name or partKey
                        })
                        if DET_DEBUG then log('D', 'getLicensePlateAdditionalMods', "Using existing additional mod: " .. additionalPartKey) end
                        goto continue
                    end
                    
                    -- Create a deep copy and modify the data structure instead of manipulating strings
                    local modifiedJbeam = deepcopy(jbeam)
                    if modifiedJbeam == nil then
                        log('E', 'getLicensePlateAdditionalMods', "Failed to deepcopy jbeam for: " .. partKey)
                        goto continue
                    end
                    
                    -- Create new entry with modified key and slotType
                    modifiedJbeam[additionalPartKey] = deepcopy(part)
                    modifiedJbeam[additionalPartKey].slotType = additionalPartKey
                    modifiedJbeam[partKey] = nil  -- Remove original entry
                    
                    -- Write using proper JSON serialization with atomic operation
                    FS:directoryCreate(gmsg.GENERATED_PATH:lower().."/vehicles/common/modslot/", true)
                    
                    local writeSuccess = writeFileAtomic(outputPath, modifiedJbeam, true)
                    if not writeSuccess then
                        log('E', 'getLicensePlateAdditionalMods', "Failed to write file: " .. outputPath)
                        goto continue
                    end
                    
                    -- Validate by reading back
                    local validateJbeam = readJsonFile(outputPath)
                    if validateJbeam == nil then
                        log('E', 'getLicensePlateAdditionalMods', "Validation failed - file not readable: " .. outputPath)
                        goto continue
                    end
                    
                    table.insert(additionalMods, {
                        partKey = additionalPartKey,
                        file = file,
                        name = part.information and part.information.name or partKey
                    })
                    if DET_DEBUG then log('D', 'getLicensePlateAdditionalMods', "Created and validated additional mod: " .. additionalPartKey) end
                end
                ::continue::
            end
        end
    end
    return additionalMods
end


local function getAdditionalMods(vehicleDir)
    local additionalMods = {}
    local vehicleModSlot = getModSlot(vehicleDir)
    
    if not vehicleModSlot then
        return additionalMods
    end
    
    -- Search for any jbeam files that have a matching mod slot type
    local files = FS:findFiles("/vehicles/" .. vehicleDir, "*.jbeam", -1, true, false)
    
    for _, file in ipairs(files) do
        local jbeamData = readJsonFile(file)
        if jbeamData then
            -- Look through each part in the jbeam file
            for partKey, part in pairs(jbeamData) do
                -- Check if this part uses the vehicle's mod slot and isn't a multiMod
                -- Skip if the vehicleModSlot already ends with _additional
                if part.slotType == vehicleModSlot and 
                   not ends_with(partKey, "_multimod") and
                   not ends_with(vehicleModSlot, "_additional") then
                    
                    -- First, create a modified part key for our new additional part
                    local additionalPartKey = partKey .. "_additional"
                    local outputPath = gmsg.GENERATED_PATH:lower().."/vehicles/" .. vehicleDir .. "/modslot/" .. partKey .. "_multislot.jbeam"
                    if FS:fileExists(outputPath) and readJsonFile(outputPath) ~= nil then
                        table.insert(additionalMods, {
                            partKey = partKey,
                            file = file,
                            name = part.information and part.information.name or partKey
                        })
                        if DET_DEBUG then log('D', 'getAdditionalMods', "Using existing additional mod: " .. partKey) end
                        break
                    end
                    
                    -- Create a deep copy and modify the data structure instead of manipulating strings
                    local modifiedJbeam = deepcopy(jbeamData)
                    if modifiedJbeam == nil then
                        log('E', 'getAdditionalMods', "Failed to deepcopy jbeam for: " .. partKey)
                        break
                    end
                    
                    -- Create new entry with modified key and slotType
                    modifiedJbeam[additionalPartKey] = deepcopy(part)
                    modifiedJbeam[additionalPartKey].slotType = additionalPartKey
                    modifiedJbeam[partKey] = nil  -- Remove original entry
                    
                    -- Write using proper JSON serialization with atomic operation
                    FS:directoryCreate(gmsg.GENERATED_PATH:lower().."/vehicles/" .. vehicleDir .. "/modslot/", true)
                    
                    local writeSuccess = writeFileAtomic(outputPath, modifiedJbeam, true)
                    if not writeSuccess then
                        log('E', 'getAdditionalMods', "Failed to write file: " .. outputPath)
                        break
                    end
                    
                    -- Validate by reading back
                    local validateJbeam = readJsonFile(outputPath)
                    if validateJbeam == nil then
                        log('E', 'getAdditionalMods', "Validation failed - file not readable: " .. outputPath)
                        break
                    end
                    
                    -- Add to our additional mods list
                    table.insert(additionalMods, {
                        partKey = partKey,
                        file = file,
                        name = part.information and part.information.name or partKey
                    })
                    
                    if DET_DEBUG then log('D', 'getAdditionalMods', "Created and validated additional mod: " .. partKey) end
                    break
                end
            end
        end
    end
    
    return additionalMods
end

local function generateMultiWithAdditional(vehicleDir, additionalMods, licensePlateAdditionalMods)
    -- Generate the multi-mod template as before
    local multiModTemplate = readJsonFile("/lua/ge/extensions/tommot/mSGTemplate.json")
    if multiModTemplate == nil then
        log('E', 'generateMultiWAdditional', "Failed to load multiModTemplate")
        return
    end
    local vehicleModSlot = getModSlot(vehicleDir)
    if vehicleModSlot == nil then
        if DET_DEBUG then log('D', 'generateMulti', vehicleDir .. " has no mod slot") end
        return
    end
    multiModTemplate.slotType = vehicleModSlot
    
    -- Keep track of added entries to prevent duplicates
    local addedEntries = {}
    
    for _,templateName in pairs(templateNames) do
        local convName = templateName:lower():gsub(" ", "_")
        if multiModTemplate ~= nil and multiModTemplate.slots ~= nil and type(multiModTemplate.slots) == 'table' then
            local entryKey = convName .. "_mod"
            if not addedEntries[entryKey] then
                table.insert(multiModTemplate.slots, {entryKey, "", templateName})
                addedEntries[entryKey] = true
            end
        end
    end

    -- add additional mods
    for _, additionalMod in pairs(additionalMods) do
        if additionalMod ~= nil then
            local entryKey = additionalMod.partKey.."_additional"
            if not addedEntries[entryKey] then
                table.insert(multiModTemplate.slots, {entryKey, "", additionalMod.name})
                addedEntries[entryKey] = true
            end
        end
    end

    -- add license plate additional mods
    for _, additionalMod in pairs(licensePlateAdditionalMods) do
        if additionalMod ~= nil then
            local entryKey = additionalMod.partKey
            if not addedEntries[entryKey] then
                table.insert(multiModTemplate.slots, {entryKey, "", additionalMod.name})
                addedEntries[entryKey] = true
            end
        end
    end

    -- Final safety net: remove duplicate slot keys in the finished table.
    multiModTemplate.slots = dedupeSlotRows(multiModTemplate.slots)

    -- Save the multi-mod template
    local savePath = gmsg.GENERATED_PATH:lower().."/vehicles/" .. vehicleDir .. "/modslot/" .. vehicleDir .. "_multimod.jbeam"
    tommot_templates.makeAndSaveNewTemplate(vehicleDir, vehicleModSlot, multiModTemplate, "multimod")
end

local function additionalToMultiSlotJob(job)
    gmsg.GMSGMessage("Generating combined MultiSlot", "Info", "info", 2000)
    local vehicles = gmsg.getAllVehicles()
    templateNames = tommot_templates.loadTemplateNames()
    local licensePlateAdditionalMods = getLicensePlateAdditionalMods()
    for _,vehicle in pairs(vehicles) do
        additionalMods = getAdditionalMods(vehicle)
        generateMultiWithAdditional(vehicle, additionalMods, licensePlateAdditionalMods)
        job.yield()
    end
    gmsg.GMSGMessage("Finished generating combined MultiSlot", "Info", "info", 2000)
    gmsg.onFinishGen()
end

local function additionalToMultiSlot()
    gmsg.GMSGMessage("Generating combined MultiSlot", "Info", "info", 2000)
    local vehicles = gmsg.getAllVehicles()
    templateNames = tommot_templates.loadTemplateNames()
    local licensePlateAdditionalMods = getLicensePlateAdditionalMods()
    for _,vehicle in pairs(vehicles) do
        additionalMods = getAdditionalMods(vehicle)
        generateMultiWithAdditional(vehicle, additionalMods, licensePlateAdditionalMods)
    end
    gmsg.GMSGMessage("Finished generating combined MultiSlot", "Info", "info", 2000)
    gmsg.onFinishGen()
end



M.additionalToMultiSlotJob = additionalToMultiSlotJob
M.additionalToMultiSlot = additionalToMultiSlot
return M