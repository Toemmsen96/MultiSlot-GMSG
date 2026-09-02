local M = {}

local template = nil
local templateVersion = -1
local templateNames = nil

local function fs()       return tommot_lib_fs end
local function gen()      return tommot_lib_generator end
local function logger()   return tommot_lib_logger end
local function vehicles() return tommot_gmsg_vehicles end

local function GMSGMessage(msg, title, t, dur) local l = logger(); if l then l.GMSGMessage(msg, title, t, dur) end end
local function convertName(name)               local g = gen(); return g and g.convertName(name) or name end

local function writeFileAtomic(path, data, compact)
    return fs().writeFileAtomic(path, data, compact)
end

local function makeAndSaveNewTemplate(vehicleDir, slotName, helperTemplate, templateName)
    local fsMod = fs()
    local vehMod = vehicles()
    if not fsMod or not vehMod then
        log('E', 'makeAndSaveNewTemplate', "required modules are not available")
        return
    end
    local templateCopy = deepcopy(helperTemplate)
    if templateCopy == nil then log('W', 'makeAndSaveNewTemplate', "templateCopy is nil") return end
    local convName = convertName(templateName)
    local mainPart = {}
    templateCopy.slotType = slotName
    mainPart[vehicleDir .. "_" .. convName] = templateCopy
    local savePath = vehMod.getModSlotJbeamPath(vehicleDir, convName)
    local saveDir = savePath:match("^(.*)/[^/]+$")
    if saveDir then FS:directoryCreate(saveDir, true) end
    if not fsMod.writeFileAtomic(savePath, mainPart, true) then
        log('E', 'makeAndSaveNewTemplate', "Failed to save template to: " .. savePath)
    end
end

local function makeAndSaveCustomTemplate(vehicleDir, slotName, helperTemplate, templateName, outputPath)
    if outputPath == nil then log('E', 'makeAndSaveCustomTemplate', "outputPath is nil") return end
    local fsMod = fs()
    local convName = convertName(templateName)
    local templateCopy = deepcopy(helperTemplate)
    if templateCopy == nil then
        log('W', 'makeAndSaveCustomTemplate', "templateCopy is nil")
        GMSGMessage("Error: templateCopy is nil", "Error", "error", 5000)
        return
    end
    local mainPart = {}
    templateCopy.slotType = slotName
    mainPart[vehicleDir .. "_" .. convName] = templateCopy
    local savePath = "mods/" .. outputPath .. "/vehicles/" .. vehicleDir .. "/" .. vehicleDir .. "_" .. convName .. ".jbeam"
    FS:directoryCreate("mods/" .. outputPath .. "/vehicles/" .. vehicleDir .. "/", true)
    if not fsMod or not fsMod.writeFileAtomic(savePath, mainPart, true) then
        log('E', 'makeAndSaveCustomTemplate', "Failed to save custom template to: " .. savePath)
    end
end

local function findTemplateVersion(modslotJbeam)
    if type(modslotJbeam) ~= 'table' then return nil end
    for _, mod in pairs(modslotJbeam) do
        if mod.version ~= nil then return mod.version end
    end
    return nil
end

local function loadTemplate(templateName)
    if templateName == nil then
        log('E', 'loadTemplate', "templateName is nil")
        GMSGMessage("Error: templateName is nil", "Error", "error", 5000)
        return nil
    end
    local fsMod = fs()
    if not fsMod then
        log('E', 'loadTemplate', "tommot_lib_fs is not available")
        return nil
    end
    template = fsMod.readJsonFile("/modslotgenerator/" .. templateName .. ".json")
    if template ~= nil then
        templateVersion = template.version or 1.0
        template.version = templateVersion
        return template
    end
    log('E', 'loadTemplate', "Failed to load template: " .. templateName)
    GMSGMessage("Failed to load template: " .. templateName, "Error", "error", 5000)
    return nil
end

local function loadTemplateNames()
    templateNames = {}
    local files = FS:findFiles("/modslotgenerator", "*.json", -1, true, false)
    for _, file in ipairs(files) do
        local name = string.match(file, "/modslotgenerator/(.*)%.json")
        if name then table.insert(templateNames, name) end
    end
    if #templateNames == 0 then return nil end
    return templateNames
end

local function getTemplateNames()
    templateNames = loadTemplateNames()
    if templateNames == nil then
        GMSGMessage("No templates found!", "Warning", "warning", 5000)
        log('E', 'getTemplateNames', "No templates found")
        return false
    end
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
