--[ Author: TommoT / Toemmsen
-- Entry point for the GMSG / MultiSlot Generator mod.
-- Loads all sub-modules, orchestrates generation, and re-exports the public API
-- for backwards compatibility with mods that depend on tommot_modslotGenerator.

local M = {}

-- Sub-module references (populated in loadSubModules)
local settings_mod
local template_mod
local vehicles_mod
local packer_mod
local multislot_mod
local addtomulti_mod

local function cfg() return tommot_gmsg_settings.cfg end

-- ── Sub-module loader ─────────────────────────────────────────────────────────

local function loadExt(name)
    if not extensions.isExtensionLoaded(name) then
        extensions.load(name)
        setExtensionUnloadMode(name, "manual")
    end
end

local function loadSubModules()
    loadExt("tommot_lib_logger")
    loadExt("tommot_lib_fs")
    loadExt("tommot_lib_generator")
    loadExt("tommot_gmsg_settings")
    loadExt("tommot_gmsg_vehicles")
    loadExt("tommot_gmsg_templates")
    loadExt("tommot_gmsg_packer")

    settings_mod = tommot_gmsg_settings
    template_mod = tommot_gmsg_templates
    vehicles_mod = tommot_gmsg_vehicles
    packer_mod   = tommot_gmsg_packer
end

-- ── Core generation (stays here — orchestrates templates + vehicles) ───────────

local function generate(vehicleDir, templateName, tmpl)
    local convName = tommot_lib_generator.convertName(templateName)
    local existingData    = vehicles_mod.loadExistingModSlotData(vehicleDir, convName)
    local existingVersion = template_mod.findTemplateVersion(existingData)
    local vehicleModSlot  = vehicles_mod.getModSlot(vehicleDir)
    if vehicleModSlot == nil then return end
    if tmpl == nil then
        tmpl = template_mod.loadTemplate(templateName)
        if tmpl == nil then return end
    end
    if existingData ~= nil and existingVersion == tmpl.version then return end
    template_mod.makeAndSaveNewTemplate(vehicleDir, vehicleModSlot, tmpl, convName)
end

local function generateAll(templateName, tmpl)
    tmpl = tmpl or template_mod.loadTemplate(templateName)
    if tmpl == nil then return end
    for _, veh in pairs(vehicles_mod.getAllVehicles()) do
        generate(veh, templateName, tmpl)
    end
end

local function generateAllSpecific(templateName, outputPath)
    local convName = tommot_lib_generator.convertName(templateName)
    for _, veh in pairs(vehicles_mod.getAllVehicles()) do
        local vehicleModSlot = vehicles_mod.getModSlot(veh)
        if vehicleModSlot then
            local tmpl = template_mod.loadTemplate(templateName)
            if tmpl then template_mod.makeAndSaveCustomTemplate(veh, vehicleModSlot, tmpl, convName, outputPath) end
        end
    end
    tommot_lib_logger.GMSGMessage("Done generating mods for: " .. templateName, "Info", "info", 2000)
end

local function generateSeparateJob(job)
    local timer = cfg().TIMER_GENERATION and hptimer() or nil
    tommot_lib_logger.GMSGMessage("Generating separate mods", "Info", "info", 2000)
    local templateNames = template_mod.loadTemplateNames()
    if templateNames then
        for _, name in pairs(templateNames) do
            local tmpl = template_mod.loadTemplate(name)
            if tmpl then
                for _, veh in pairs(vehicles_mod.getAllVehicles()) do
                    generate(veh, name, tmpl)
                    job.yield()
                end
            end
        end
    end
    if timer then tommot_lib_logger.GMSGMessage("Done separate mods (timer: " .. timer:stop() .. ")", "Info", "info", 2000) end
    tommot_lib_logger.GMSGMessage("Done generating separate mods", "Info", "info", 2000)
    packer_mod.onFinishGen()
end

local function generateSeparateMods()
    tommot_lib_logger.GMSGMessage("Generating separate mods", "Info", "info", 2000)
    local templateNames = template_mod.loadTemplateNames()
    if templateNames == nil then return end
    for _, name in pairs(templateNames) do
        local tmpl = template_mod.loadTemplate(name)
        if tmpl then generateAll(name, tmpl) end
    end
    tommot_lib_logger.GMSGMessage("Done generating separate mods", "Info", "info", 2000)
    packer_mod.onFinishGen()
end

local function generateSpecificMod(templatePath, templateName, outputPath, autoPack, addDependencyDownloader, includeMStemplate)
    local fs = tommot_lib_fs
    if fs.isEmptyOrWhitespace(templatePath) or fs.isEmptyOrWhitespace(templateName) or fs.isEmptyOrWhitespace(outputPath) then
        tommot_lib_logger.GMSGMessage("Error: invalid arguments to generateSpecificMod", "Error", "error", 5000)
        return
    end
    autoPack = autoPack ~= nil and autoPack or cfg().AUTOPACK
    addDependencyDownloader = addDependencyDownloader or false
    includeMStemplate       = includeMStemplate or false

    local template = fs.readJsonFile(templatePath) or template_mod.loadTemplate(templateName)
    if template == nil then
        tommot_lib_logger.GMSGMessage("Failed to load template: " .. templateName, "Error", "error", 5000)
        return
    end

    tommot_lib_logger.GMSGMessage("Generating mod: " .. templateName, "Info", "info", 2000)
    generateAllSpecific(templateName, outputPath)

    if addDependencyDownloader then
        local depPath = "/modslotgeneratorexampletemplates/depdownloader"
        tommot_lib_generator.copyFileTree(depPath, "mods/" .. outputPath)
    end

    if includeMStemplate then
        local dest = "/mods" .. outputPath .. (fs.ends_with(outputPath, "/") and "" or "/") .. "modslotgenerator/" .. templateName .. ".json"
        fs.writeJsonFile(dest, deepcopy(template), true)
    end

    if autoPack then
        tommot_lib_logger.GMSGMessage("Autopacking...", "Info", "info", 2000)
        packer_mod.queueCustomPack(outputPath)
    end
end

-- ── Lifecycle ──────────────────────────────────────────────────────────────────

local function onExtensionLoaded()
    setExtensionUnloadMode(M, "manual")
    loadSubModules()

    if extensions.isExtensionLoaded("tommot_gmsg_ui") then
        tommot_lib_logger.logToConsole('W', 'onExtensionLoaded', "Already loaded, returning.")
        return
    end

    log('D', 'onExtensionLoaded', "GMSG ModSlot Generator Loaded")
    settings_mod.loadSettings()
    tommot_lib_logger.GMSGMessage("MultiSlot Generator Loaded, starting generation.", "Info", "info", 3000)

    if template_mod.getTemplateNames() then
        packer_mod.resetPending()
        local c = cfg()
        if c.SEPARATE_MODS then
            packer_mod.incrementPending()
            if c.USE_COROUTINES then core_jobsystem.create(generateSeparateJob, c.CONCURRENCY_DELAY) else generateSeparateMods() end
        end
        if c.MULTISLOT_MODS then
            loadExt("tommot_gmsg_multislot")
            multislot_mod = tommot_gmsg_multislot
            packer_mod.incrementPending()
            if c.USE_COROUTINES then core_jobsystem.create(multislot_mod.generateMultiSlotJob, c.CONCURRENCY_DELAY) else multislot_mod.generateMultiSlotMod() end
        end
        if c.ADDITIONAL_TO_MULTISLOT then
            loadExt("tommot_gmsg_additionalslots")
            addtomulti_mod = tommot_gmsg_additionalslots
            packer_mod.incrementPending()
            if c.USE_COROUTINES then core_jobsystem.create(addtomulti_mod.additionalToMultiSlotJob, c.CONCURRENCY_DELAY) else addtomulti_mod.additionalToMultiSlot() end
        end
        if not c.SEPARATE_MODS and not c.MULTISLOT_MODS and not c.ADDITIONAL_TO_MULTISLOT then
            tommot_lib_logger.GMSGMessage("No generation method selected", "Warning", "warning", 5000)
        end
        tommot_lib_logger.GMSGMessage("Done generating all mods", "Info", "info", 4000)
    end

    loadExt("tommot_gmsg_ui")
    loadExt("tommot_multiSlotInjector")
end

local function onExtensionUnloaded()
    log('D', 'onExtensionUnloaded', "GMSG ModSlot Generator Unloaded")
end

local function onGuiUpdate()
    if packer_mod then packer_mod.pollPack() end
end

local function onModDeactivated(mod)
    if mod == nil then log('E', 'onModDeactivated', "mod is nil") return end
    local validMods = {["generatedmodslot"] = true, ["generalmodslotgenerator"] = true, ["tommot_gmsg"] = true}
    if not validMods[mod.modname] then return end
    tommot_lib_logger.GMSGMessage("Unloading mod: " .. mod.modname, "Info", "info", 2000)
    if packer_mod and not cfg().CACHE_GENERATED_MODS then
        packer_mod.deleteTempFiles()
        return
    end
    for _, name in ipairs({"tommot_gmsg_ui","tommot_gmsg_additionalslots","tommot_gmsg_multislot",
                            "tommot_gmsg_templates","tommot_gmsg_vehicles","tommot_gmsg_settings",
                            "tommot_gmsg_packer","tommot_lib_logger","tommot_lib_fs","tommot_lib_generator",
                            "tommot_modslotGenerator"}) do
        extensions.unload(name)
    end
end

local function onExit()
    log('D', 'onExit', "Exiting")
    if packer_mod and not cfg().CACHE_GENERATED_MODS then packer_mod.deleteTempFiles() end
    for _, name in ipairs({"tommot_gmsg_ui","tommot_gmsg_additionalslots","tommot_gmsg_multislot",
                            "tommot_gmsg_templates","tommot_gmsg_vehicles","tommot_gmsg_settings",
                            "tommot_gmsg_packer","tommot_lib_logger","tommot_lib_fs","tommot_lib_generator",
                            "tommot_modslotGenerator"}) do
        extensions.unload(name)
    end
end

-- ── Public API ────────────────────────────────────────────────────────────────

M.onInit             = function() setExtensionUnloadMode(M, "manual") end
M.onExtensionLoaded  = onExtensionLoaded
M.onExtensionUnloaded= onExtensionUnloaded
M.onModDeactivated   = onModDeactivated
M.onModActivated     = onExtensionLoaded
M.onExit             = onExit
M.onGuiUpdate        = onGuiUpdate

-- Generation
M.generateSeparateMods = generateSeparateMods
M.generateSeparateJob  = generateSeparateJob
M.generateSpecificMod  = generateSpecificMod

-- Settings (backwards compat — delegates to tommot_gmsg_settings)
M.loadSettings       = function()    if settings_mod then settings_mod.loadSettings() end end
M.saveSettings       = function()    if settings_mod then settings_mod.saveSettings() end end
M.setModSettings     = function(j)   if settings_mod then settings_mod.setModSettings(j) end end
M.sendSettingsToUI   = function()    if settings_mod then settings_mod.sendSettingsToUI() end end
M.setConcurrencyDelay= function(d)   if settings_mod then settings_mod.setConcurrencyDelay(d) end end

-- Utilities (backwards compat — delegates to lib modules)
M.deleteTempFiles    = function()    if packer_mod then packer_mod.deleteTempFiles() end end
M.logToConsole       = function(...) if tommot_lib_logger then tommot_lib_logger.logToConsole(...) end end
M.GMSGMessage        = function(...) if tommot_lib_logger then tommot_lib_logger.GMSGMessage(...) end end
M.convertName        = function(n)   if tommot_lib_generator then return tommot_lib_generator.convertName(n) end end
M.readJsonFile       = function(...) if tommot_lib_fs then return tommot_lib_fs.readJsonFile(...) end end
M.writeJsonFile      = function(...) if tommot_lib_fs then return tommot_lib_fs.writeJsonFile(...) end end
M.getModNameFromPath = function(...) if tommot_lib_fs then return tommot_lib_fs.getModNameFromPath(...) end end
M.isEmptyOrWhitespace= function(...) if tommot_lib_fs then return tommot_lib_fs.isEmptyOrWhitespace(...) end end
M.getAllVehicles      = function()    if vehicles_mod then return vehicles_mod.getAllVehicles() end end
M.onFinishGen        = function()    if packer_mod then packer_mod.onFinishGen() end end
M.getModSlotJbeamPath= function(...) if vehicles_mod then return vehicles_mod.getModSlotJbeamPath(...) end end
M.getModSlot         = function(...) if vehicles_mod then return vehicles_mod.getModSlot(...) end end
M.getSlotTypes       = function(...) if vehicles_mod then return vehicles_mod.getSlotTypes(...) end end

-- Constant exposed for mods that read it directly
M.GENERATED_PATH = "/mods/unpacked/generatedModSlot"

return M
