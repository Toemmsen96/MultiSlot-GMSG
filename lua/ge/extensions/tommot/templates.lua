--[[
This file is part of the "MultiSlot / ModSlot generator" mod for BeamNG.drive by TommoT / Toemmsen
To get the latest version of this mod, please visit:
https://github.com/Toemmsen96/generalModSlotGenerator/
]]

local M = {}

--template variables
local template = nil
local templateVersion = -1
local templateNames = nil

local readJsonFile = tommot_modslotGenerator.readJsonFile
local writeJsonFile = tommot_modslotGenerator.writeJsonFile
local convertName = tommot_modslotGenerator.convertName

local function GMSGMessage(msg, title, icon, duration)
    tommot_modslotGenerator.GMSGMessage(msg, title, icon, duration)
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


local function makeAndSaveNewTemplate(vehicleDir, slotName, helperTemplate, templateName)
    local templateCopy = deepcopy(helperTemplate)
    if templateCopy == nil then
        log('W', 'makeAndSaveNewTemplate', "templateCopy is nil")
        return
    end
    local convName = convertName(templateName)
    --make main part
    local mainPart = {}
    templateCopy.slotType = slotName
    mainPart[vehicleDir .. "_" .. convName] = templateCopy
    
    --save it with atomic operation
    local savePath = tommot_modslotGenerator.getModSlotJbeamPath(vehicleDir, convName)
    local saveDir = savePath:match("^(.*)/[^/]+$")
    if saveDir then FS:directoryCreate(saveDir, true) end
    local writeSuccess = writeFileAtomic(savePath, mainPart, true)
    if not writeSuccess then
        log('E', 'makeAndSaveNewTemplate', "Failed to save template to: " .. savePath)
        return
    end
    
    if DET_DEBUG then log('D', 'makeAndSaveNewTemplate', "Successfully saved new template: " .. templateName .. " to " .. savePath) end
end

--template version finder
local function findTemplateVersion(modslotJbeam)
    if type(modslotJbeam) ~= 'table' then return nil end
    
    for modKey, mod in pairs(modslotJbeam) do
        -- log('D', 'GELua.modslotGenerator.onExtensionLoaded', "modKey: " .. modKey)
        -- is it valid?
        if mod.version ~= nil then
            if DET_DEBUG then log('D', 'findTemplateVersion', "mod.version found: " .. mod.version) end
            return mod.version
        end
    end
    return nil
end

local function loadTemplate(templateName)
    if templateName == nil then
        log('E', 'loadTemplate', "templateName is nil")
        GMSGMessage("Error: templateName is nil", "Error", "error", 5000)
        return
    end
    template = readJsonFile("/modslotgenerator/" .. templateName .. ".json")
    if template ~= nil then
        templateVersion = template.version
        if templateVersion == nil then
            templateVersion = 1.0
            template.version = templateVersion
        end
        log('D', 'loadTemplate', "Loaded Template: " ..templateName.. " Version: " .. templateVersion)
        return template
    end
    if template == nil then
        log('E', 'loadTemplate', "Failed to load template: " .. templateName)
        GMSGMessage("Failed to load template: " .. templateName, "Error", "error", 5000)
        return nil
    end
end

local function loadTemplateNames()
    templateNames = {}
    local files = FS:findFiles("/modslotgenerator", "*.json", -1, true, false)
    for _, file in ipairs(files) do
        local name = string.match(file, "/modslotgenerator/(.*)%.json")
        if DET_DEBUG then log('D', 'loadTemplateNames', "found template: " .. name) end
        table.insert(templateNames, name)
    end
    if #templateNames == 0 then
        return nil
    end
    return templateNames
end

local function makeAndSaveCustomTemplate(vehicleDir, slotName, helperTemplate, templateName, outputPath)
    if outputPath == nil then
        log('E', 'makeAndSaveCustomTemplate', "outputPath is nil")
        return
    end
    local convName = convertName(templateName)
    log('D', 'makeAndSaveCustomTemplate', "Making and saving custom template: " .. vehicleDir .. " " .. slotName .. " " .. convName .. " " .. outputPath)
    local templateCopy = deepcopy(helperTemplate)
    if templateCopy == nil then
        log('W', 'makeAndSaveCustomTemplate', "templateCopy is nil")
        GMSGMessage("Error: templateCopy is nil", "Error", "error", 5000)
        return
    end
    
    --make main part
    local mainPart = {}
    templateCopy.slotType = slotName
    mainPart[vehicleDir .. "_" .. convName] = templateCopy
    
    --save it with atomic operation
    local savePath = "mods/" .. outputPath .. "/vehicles/".. vehicleDir.."/" ..vehicleDir.. "_" .. convName .. ".jbeam"
    FS:directoryCreate("mods/" .. outputPath .. "/vehicles/".. vehicleDir.."/", true)
    
    local writeSuccess = writeFileAtomic(savePath, mainPart, true)
    if not writeSuccess then
        log('E', 'makeAndSaveCustomTemplate', "Failed to save custom template to: " .. savePath)
        return
    end
    
    if DET_DEBUG then log('D', 'makeAndSaveCustomTemplate', "Successfully saved custom template: " .. savePath) end
end

local function getTemplateNames()
    templateNames = loadTemplateNames()
    if templateNames == nil then
        GMSGMessage("No templates found! \n Please make sure you have downloaded at least one MultiSlot / GMSG Plugin", "Warning", "warning", 5000)
        log('E', 'getTemplateNames', "No templates found")
        return false
    end
    log('D', 'getTemplateNames', "Templates found: " .. table.concat(templateNames, ", "))
    GMSGMessage("Templates found: " .. table.concat(templateNames, ", "), "Info", "info", 2000)
    return true
end

M.loadTemplate = loadTemplate
M.loadTemplateNames = loadTemplateNames
M.findTemplateVersion = findTemplateVersion
M.makeAndSaveNewTemplate = makeAndSaveNewTemplate
M.makeAndSaveCustomTemplate = makeAndSaveCustomTemplate
M.getTemplateNames = getTemplateNames

return M