local M = {}
M.dependencies = {"ui_imgui"}
M.showUI = false

local imgui     = ui_imgui
local ffi       = require("ffi")
local libUI     = nil  -- tommot_lib_ui, resolved on load

-- UI state
local outputPath                    = "/unpacked/gmsg_out/"
local autopackCheckboxValue         = imgui.BoolPtr(false)
local autopackAllCheckboxValue      = imgui.BoolPtr(false)
local generateSeparateCheckboxValue = imgui.BoolPtr(false)
local generateMultiSlotCheckboxValue= imgui.BoolPtr(true)
local generateAdditionalCheckboxValue= imgui.BoolPtr(true)
local detailedDebugCheckboxValue    = imgui.BoolPtr(true)
local useCoroutinesCheckboxValue    = imgui.BoolPtr(true)
local includeMStemplate             = imgui.BoolPtr(true)
local addDependencyDownloader       = imgui.BoolPtr(true)
local advancedModeCheckbox          = imgui.BoolPtr(false)
local concurrencyDelay              = imgui.FloatPtr(2/3)
local logLevelOptions               = {"No Logs", "Info & Warnings", "All Logs"}
local logLevelSelected              = imgui.IntPtr(2)
local loadedExtensions              = {}
local selectedExtension             = ""
local templates                     = nil
local selectedTemplate              = nil

local function toggleUI() M.showUI = not M.showUI end

-- Sync imgui pointers from the shared settings config.
local function syncFromSettings()
    local c = tommot_gmsg_settings.cfg
    generateSeparateCheckboxValue[0]  = c.SEPARATE_MODS
    generateMultiSlotCheckboxValue[0] = c.MULTISLOT_MODS
    generateAdditionalCheckboxValue[0]= c.ADDITIONAL_TO_MULTISLOT
    detailedDebugCheckboxValue[0]     = c.DET_DEBUG
    useCoroutinesCheckboxValue[0]     = c.USE_COROUTINES
    autopackAllCheckboxValue[0]       = c.AUTOPACK
    logLevelSelected[0]               = c.LOGLEVEL
end

local function getTemplate()
    if not extensions.isExtensionLoaded("tommot_gmsg_templates") then
        extensions.load("tommot_gmsg_templates")
    end
    local result = tommot_gmsg_templates.loadTemplateNames()
    if result and #result > 0 then return result end
    return nil
end

-- ── Tab: Generate Standalone ─────────────────────────────────────────────────
local function renderTabStandalone()
    if selectedTemplate == nil or (templates == nil or #templates == 0) then
        imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "No Templates found!")
        imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "Please download or create at least one MultiSlot / GMSG Plugin")
        imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "and ensure the template is in the modslotgenerator folder")
    else
        if imgui.BeginCombo("Select Template", selectedTemplate) then
            for _, template in ipairs(templates) do
                if imgui.Selectable1(template, template == selectedTemplate) then selectedTemplate = template end
            end
            imgui.EndCombo()
        end
        if imgui.IsItemHovered() then imgui.SetTooltip("Select the Template to generate. Saved in /modslotgenerator/\"Name\".json") end
    end

    imgui.Text("Enter Output Path: (Relative to the mods-Folder)")
    local outputPathBuffer = ffi.new("char[256]", outputPath)
    imgui.InputText("##outputPath", outputPathBuffer, 256, imgui.InputTextFlags_EnterReturnsTrue)
    outputPath = ffi.string(outputPathBuffer)
    if imgui.IsItemHovered() then imgui.SetTooltip("Where the generated Mod will be saved (Default: /unpacked/gmsg_out/)") end

    libUI.checkboxRow("Autopack generated Mod", autopackCheckboxValue,
        "Automatically packs the generated Mod into a .zip file")

    libUI.checkboxRow("Include MultiSlot-Template", includeMStemplate,
        "Includes the MultiSlot-Template for compatibility with MultiSlot-Mods (Recommended)")

    if not includeMStemplate[0] then
        imgui.BeginDisabled()
        addDependencyDownloader[0] = false
        imgui.Checkbox("##addDependencyDownloader", addDependencyDownloader)
        imgui.EndDisabled()
    else
        imgui.Checkbox("##addDependencyDownloader", addDependencyDownloader)
    end
    local ddTooltip = includeMStemplate[0]
        and "Adds the Dependency-Downloader which auto-downloads the required MultiSlot-Mod"
        or  "Enable 'Include MultiSlot-Template' to use this option"
    if imgui.IsItemHovered() then imgui.SetTooltip(ddTooltip) end
    imgui.SameLine()
    if imgui.Selectable1("Add Dependency-Downloader", addDependencyDownloader[0]) then
        if includeMStemplate[0] then addDependencyDownloader[0] = not addDependencyDownloader[0] end
    end
    if imgui.IsItemHovered() then imgui.SetTooltip(ddTooltip) end

    if imgui.Button("Generate selected Mod") then
        tommot_modslotGenerator.generateSpecificMod(selectedTemplate, selectedTemplate, ffi.string(outputPathBuffer),
            autopackCheckboxValue[0], addDependencyDownloader[0], includeMStemplate[0])
    end
    if imgui.IsItemHovered() then imgui.SetTooltip("Generates the selected mod with the specified settings") end
end

-- ── Tab: Generate Manually ────────────────────────────────────────────────────
local function renderTabManual()
    local function loadMultislot()
        if not extensions.isExtensionLoaded("tommot_gmsg_multislot") then
            extensions.load("tommot_gmsg_multislot")
            setExtensionUnloadMode("tommot_gmsg_multislot", "manual")
        end
    end

    if imgui.Button("Generate MultiSlot-Mods") then
        loadMultislot()
        tommot_gmsg_multislot.generateMultiSlotMod()
    end
    if imgui.IsItemHovered() then imgui.SetTooltip("Generates all Templates as MultiSlot-Mods (Lag-Spike)") end

    if imgui.Button("Generate MultiSlot-Mods concurrently") then
        loadMultislot()
        core_jobsystem.create(tommot_gmsg_multislot.generateMultiSlotJob, concurrencyDelay[0])
    end
    if imgui.IsItemHovered() then imgui.SetTooltip("Generates all Templates as MultiSlot-Mods, less lag") end

    if imgui.Button("Generate SingleSlot-Mods") then
        tommot_modslotGenerator.generateSeparateMods()
    end
    if imgui.IsItemHovered() then imgui.SetTooltip("Generates all Templates as Additional Modification Mods (Lag-Spike)") end

    if imgui.Button("Generate SingleSlot-Mods concurrently") then
        core_jobsystem.create(tommot_modslotGenerator.generateSeparateJob, tonumber(concurrencyDelay[0]))
    end
    if imgui.IsItemHovered() then imgui.SetTooltip("Generates all Templates as Additional Modification Mods, less lag") end

    if imgui.Button("Generate MultiSlot-Mods from Additional Mods") then
        if not extensions.isExtensionLoaded("tommot_gmsg_additionalslots") then
            extensions.load("tommot_gmsg_additionalslots")
        end
        tommot_gmsg_additionalslots.additionalToMultiSlot()
    end
    if imgui.IsItemHovered() then imgui.SetTooltip("Generates MultiSlot-Mods from existing Additional Mods") end

    if imgui.Button("Generate MultiSlot-Mods from Additional Mods concurrently") then
        if not extensions.isExtensionLoaded("tommot_gmsg_additionalslots") then
            extensions.load("tommot_gmsg_additionalslots")
        end
        core_jobsystem.create(tommot_gmsg_additionalslots.additionalToMultiSlotJob, tonumber(concurrencyDelay[0]))
    end
    if imgui.IsItemHovered() then imgui.SetTooltip("Generates MultiSlot-Mods from existing Additional Mods, less lag") end
end

-- ── Tab: Settings ─────────────────────────────────────────────────────────────
local function renderTabSettings()
    libUI.checkboxRow("Generate Separate Mods", generateSeparateCheckboxValue,
        "Generates all Templates as normal Additional Modification Mods")
    libUI.checkboxRow("Generate MultiSlot Mods", generateMultiSlotCheckboxValue,
        "Generates all Templates as MultiSlot-Mods")
    libUI.checkboxRow("Generate Additional as MultiSlot-Mods", generateAdditionalCheckboxValue,
        "Combines Template-Mods and Additional-Mods into MultiSlot-Mods")
    libUI.checkboxRow("Detailed Debug", detailedDebugCheckboxValue,
        "Logs more detailed information (may impact performance)")
    libUI.checkboxRow("Generate Mods concurrently (less of a lag spike)", useCoroutinesCheckboxValue,
        "Generates Mods concurrently to reduce the lag spike")
    libUI.checkboxRow("Autopack all generated Mods", autopackAllCheckboxValue,
        "(WIP, buggy!) Automatically packs all generated Mods into .zip files")

    imgui.Text("Log Level:")
    if imgui.BeginCombo("##logLevelCombo", logLevelOptions[logLevelSelected[0] + 1]) then
        for i, level in ipairs(logLevelOptions) do
            if imgui.Selectable1(level, (i - 1) == logLevelSelected[0]) then
                logLevelSelected[0] = i - 1
                if tommot_lib_logger then tommot_lib_logger.setLogLevel(i - 1) end
            end
        end
        imgui.EndCombo()
    end
    if imgui.IsItemHovered() then imgui.SetTooltip("Sets the log level (0 = no logs, 1 = info/warnings, 2 = all logs)") end

    if imgui.Button("Save Settings") then
        tommot_gmsg_settings.setModSettings(jsonEncode({
            SeparateMods          = generateSeparateCheckboxValue[0],
            MultiSlotMods         = generateMultiSlotCheckboxValue[0],
            AdditionalToMultiSlot = generateAdditionalCheckboxValue[0],
            DetailedDebug         = detailedDebugCheckboxValue[0],
            UseCoroutines         = useCoroutinesCheckboxValue[0],
            AutoApplySettings     = false,
            Autopack              = autopackAllCheckboxValue[0],
            LogLevel              = logLevelSelected[0],
        }))
    end
end

-- ── Tab: Utils ────────────────────────────────────────────────────────────────
local function renderTabUtils()
    if imgui.Button("Get Templates") then
        templates = getTemplate()
        tommot_gmsg_templates.getTemplateNames()
        if (selectedTemplate == nil or selectedTemplate == "") and templates and #templates > 0 then
            selectedTemplate = templates[1]
        end
    end
    if imgui.IsItemHovered() then imgui.SetTooltip("Reloads the Templates from the mods-Folder") end

    if imgui.Button("Reload ModDB") then core_modmanager.initDB() end
    if imgui.IsItemHovered() then imgui.SetTooltip("Reloads the ModDB") end

    libUI.checkboxRow("Advanced Mode", advancedModeCheckbox, "Enable advanced features (use with caution)")

    if advancedModeCheckbox[0] then
        if imgui.Button("Reload GELUA") then
            Lua:requestReload()
            ui_message('engine.lua.reloaded', 2, 'lua', 'refresh')
        end
        if imgui.IsItemHovered() then imgui.SetTooltip("Reloads all Lua extensions (warning: will lag the game)") end

        if imgui.Button("Reload gmsgUI") then
            toggleUI()
            core_jobsystem.create(function()
                extensions.unload("tommot_gmsg_ui")
                extensions.load("tommot_gmsg_ui")
            end, 1/60)
        end

        if imgui.Button("Reload GMSG / MultiSlot") then
            toggleUI()
            core_jobsystem.create(function()
                extensions.unload("tommot_modslotGenerator")
                extensions.load("tommot_modslotGenerator")
            end, 1/60)
        end

        loadedExtensions = extensions.getLoadedExtensionsNames()
        if loadedExtensions then
            if imgui.BeginCombo("##loadedExtensions", selectedExtension == "" and "Select an extension" or selectedExtension) then
                for _, extName in ipairs(loadedExtensions) do
                    if imgui.Selectable1(extName, extName == selectedExtension) then
                        selectedExtension = extName
                    end
                end
                imgui.EndCombo()
            end
            if imgui.IsItemHovered() then imgui.SetTooltip("Select an extension to reload it") end
            imgui.SameLine()
            if imgui.Button("Reload Selected Extension") and selectedExtension ~= "" then
                core_jobsystem.create(function()
                    extensions.unload(selectedExtension)
                    extensions.load(selectedExtension)
                end, 1/60)
            end
            if imgui.IsItemHovered() then imgui.SetTooltip("Reloads the selected extension") end
        end

        if imgui.Button("Load Dependency Installer UI") then
            extensions.load("tommot_dependnginstaller")
        end
        if imgui.IsItemHovered() then imgui.SetTooltip("Loads the Dependency Installer UI (gmsgDownloader must be installed)") end

        if imgui.SliderFloat("##concurrencyDelay", concurrencyDelay, 1/1000, 1) then
            tommot_modslotGenerator.setConcurrencyDelay(concurrencyDelay[0])
        end
        imgui.SameLine()
        imgui.Text("Concurrency Delay")
        if imgui.IsItemHovered() then imgui.SetTooltip("Sets the delay for concurrent generation (default: 2/3 seconds)") end
    end
end

-- ── Main render ───────────────────────────────────────────────────────────────
local function render()
    imgui.SetNextWindowSizeConstraints(imgui.ImVec2(256, 256), imgui.ImVec2(1024, 1024))
    imgui.Begin("GMSG UI", nil, imgui.WindowFlags_NoTitleBar + imgui.WindowFlags_MenuBar + imgui.WindowFlags_NoDocking)
    imgui.BeginMenuBar()
    libUI.renderWindowHeader("GMSG UI", toggleUI)
    imgui.EndMenuBar()

    if imgui.BeginTabBar("Tabs") then
        if imgui.BeginTabItem("Generate Standalone") then renderTabStandalone() imgui.EndTabItem() end
        if imgui.BeginTabItem("Generate Manually")   then renderTabManual()     imgui.EndTabItem() end
        if imgui.BeginTabItem("Settings")            then renderTabSettings()   imgui.EndTabItem() end
        if imgui.BeginTabItem("Utils")               then renderTabUtils()      imgui.EndTabItem() end
        imgui.EndTabBar()
    end
    imgui.End()
end

local function onUpdate()
    if not M.showUI then return end
    local ok, err = pcall(render)
    if not ok and err then print("Error in gmsg/ui render: " .. err) end
end

local function onExtensionLoaded()
    if not extensions.isExtensionLoaded("tommot_lib_ui") then
        extensions.load("tommot_lib_ui")
        setExtensionUnloadMode("tommot_lib_ui", "manual")
    end
    libUI = tommot_lib_ui

    templates = getTemplate()
    if templates and #templates > 0 and (selectedTemplate == nil or selectedTemplate == "") then
        selectedTemplate = templates[1]
    end
    syncFromSettings()
end

local function onExtensionUnloaded()
    if M.showUI then toggleUI() end
end

M.onUpdate            = onUpdate
M.toggleUI            = toggleUI
M.onExtensionLoaded   = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

return M
