-- Pause-menu tab (full action panel - mirrors every control in gmsg/ui.lua's 4 imgui tabs).
-- Called directly by the ui-vue MultiSlot mod (extensions.tommot_gmsg_pauseui.*).
local M = {}

local cardBase = "/ui/ui-vue/mods/MultiSlot/cards/"
local tabId = "multislot_gmsg"
local railButtons = {
    { id = "multislot_gmsg_manual",     label = "Generate Manually",   icon = "sync",         card = "ManualCard.vue" },
    { id = "multislot_gmsg_standalone", label = "Generate Standalone", icon = "puzzleModule", card = "StandaloneCard.vue" },
    { id = "multislot_gmsg_settings",   label = "Settings",            icon = "cogSolid",     card = "SettingsCard.vue" },
    { id = "multislot_gmsg_utils",      label = "Utils",               icon = "wrench",       card = "UtilsCard.vue" },
}

local function cfg() return tommot_gmsg_settings.cfg end

local function loadExt(name)
    if not extensions.isExtensionLoaded(name) then
        extensions.load(name)
        setExtensionUnloadMode(name, "manual")
    end
end

-- Tab / rail-button registration --

function M.register()
    local ok, err = pcall(function()
        if not ui_pause_actions and extensions and extensions.load then
            extensions.load("ui_pause_actions")
        end
        local pa = ui_pause_actions
        if not pa or not pa.registerModTab then return end
        pa.registerModTab({ id = tabId, label = "MultiSlot", icon = "puzzleModule" })
        if not pa.registerModButton then return end
        for _, b in ipairs(railButtons) do
            pa.registerModButton({
                id = b.id,
                tabId = tabId,
                label = b.label,
                icon = b.icon,
                componentName = cardBase .. b.card,
            })
        end
    end)
    if not ok then log('W', 'registerPauseUi', 'registerPauseUi failed: ' .. tostring(err)) end
end

function M.unregister()
    pcall(function()
        if ui_pause_actions and ui_pause_actions.unregisterModButton then
            for _, b in ipairs(railButtons) do
                ui_pause_actions.unregisterModButton(b.id)
            end
        end
        if ui_pause_actions and ui_pause_actions.unregisterModTab then
            ui_pause_actions.unregisterModTab(tabId)
        end
    end)
end

-- State push --

local function pushStateToUi()
    guihooks.trigger('MultiSlotState', {
        cfg = cfg(),
        templates = tommot_gmsg_templates and tommot_gmsg_templates.listTemplateNames() or {},
        loadedExtensions = extensions.getLoadedExtensionsNames() or {},
    })
end

M.requestState = function() pushStateToUi() end

-- Tab: Generate Standalone --
-- Mirrors renderTabStandalone(): one template -> one specific mod, with its own
-- output path / autopack / MultiSlot-template / dependency-downloader options.
M.generateSpecificMod = function(templateName, outputPath, autoPack, addDependencyDownloader, includeMStemplate)
    tommot_modslotGenerator.generateSpecificMod(templateName, templateName, outputPath, autoPack, addDependencyDownloader, includeMStemplate)
end

-- Tab: Generate Manually --
-- Each button mirrors one imgui button exactly (plain vs "concurrently" variant),
-- rather than following the Settings "use coroutines" toggle implicitly.
M.generateMultiSlot = function()
    loadExt("tommot_gmsg_multislot")
    tommot_gmsg_multislot.generateMultiSlotMod()
end

M.generateMultiSlotConcurrent = function()
    loadExt("tommot_gmsg_multislot")
    core_jobsystem.create(tommot_gmsg_multislot.generateMultiSlotJob, cfg().CONCURRENCY_DELAY)
end

M.generateSeparate = function()
    tommot_modslotGenerator.generateSeparateMods()
end

M.generateSeparateConcurrent = function()
    core_jobsystem.create(tommot_modslotGenerator.generateSeparateJob, cfg().CONCURRENCY_DELAY)
end

M.generateAdditionalToMultiSlot = function()
    loadExt("tommot_gmsg_additionalslots")
    tommot_gmsg_additionalslots.additionalToMultiSlot()
end

M.generateAdditionalToMultiSlotConcurrent = function()
    loadExt("tommot_gmsg_additionalslots")
    core_jobsystem.create(tommot_gmsg_additionalslots.additionalToMultiSlotJob, cfg().CONCURRENCY_DELAY)
end

-- Tab: Settings --
M.setModSettings = function(json)
    tommot_gmsg_settings.setModSettings(json)
    pushStateToUi()
end

M.resetSettingsToDefaults = function()
    tommot_gmsg_settings.resetToDefaults()
    pushStateToUi()
end

-- Tab: Utils --
M.rescanTemplates = function()
    tommot_gmsg_templates.getTemplateNames()
    pushStateToUi()
end

M.reloadModDB = function() core_modmanager.initDB() end
M.clearCache = function() tommot_gmsg_packer.deleteTempFiles() end
M.setConcurrencyDelay = function(d) tommot_gmsg_settings.setConcurrencyDelay(d) end

M.reloadGELua = function()
    Lua:requestReload()
    ui_message('engine.lua.reloaded', 2, 'lua', 'refresh')
end

M.reloadGmsgUI = function()
    core_jobsystem.create(function()
        extensions.unload("tommot_gmsg_ui")
        extensions.load("tommot_gmsg_ui")
    end, 1 / 60)
end

M.reloadGmsg = function()
    core_jobsystem.create(function()
        extensions.unload("tommot_modslotGenerator")
        extensions.load("tommot_modslotGenerator")
    end, 1 / 60)
end

M.reloadExtension = function(extName)
    if not extName or extName == "" then return end
    core_jobsystem.create(function()
        extensions.unload(extName)
        extensions.load(extName)
    end, 1 / 60)
end

M.loadDependencyInstallerUi = function()
    extensions.load("tommot_dependnginstaller")
end

return M
