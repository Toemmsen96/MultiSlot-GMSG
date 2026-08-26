local M = {}

-- Defaults, also used to restore settings via resetToDefaults().
local DEFAULTS = {
    SEPARATE_MODS          = false,
    MULTISLOT_MODS         = true,
    ADDITIONAL_TO_MULTISLOT = true,
    DET_DEBUG              = false,
    LOGLEVEL               = 2,
    USE_COROUTINES         = true,
    AUTO_APPLY_SETTINGS    = false,
    AUTOPACK               = false,
    GENERATED_PATH         = "/mods/unpacked/generatedModSlot",
    CONCURRENCY_DELAY      = 1/100,
    TIMER_GENERATION       = true,
    CACHE_GENERATED_MODS   = true,
    QUEUE_VEHICLE_RELOADING = true,
}

-- Shared config table - other modules hold a reference so changes are visible immediately.
local cfg = deepcopy(DEFAULTS)

local SETTINGS_PATH         = "/settings/GMSG_Settings.json"
local DEFAULT_SETTINGS_PATH = "/lua/ge/extensions/tommot/GMSG_Settings.json"

local function readJsonFile(path)  return tommot_lib_fs.readJsonFile(path) end
local function writeJsonFile(p, d, c) return tommot_lib_fs.writeJsonFile(p, d, c) end
local function notify(msg, title, t, dur) tommot_lib_logger.GMSGMessage(msg, title, t, dur) end
local function log(level, func, msg)      tommot_lib_logger.logToConsole(level, func, msg) end

-- Pushes LOGLEVEL and DET_DEBUG to the logger module so it actually governs
-- console verbosity and debug popups (not just the values held in cfg).
local function syncLoggerState()
    if not tommot_lib_logger then return end
    tommot_lib_logger.setLogLevel(cfg.LOGLEVEL)
    tommot_lib_logger.setDetailedDebug(cfg.DET_DEBUG)
end

local function sendSettingsToUI()
    guihooks.trigger('setModSettings', {
        SeparateMods      = cfg.SEPARATE_MODS,
        DetailedDebug     = cfg.DET_DEBUG,
        UseCoroutines     = cfg.USE_COROUTINES,
        AutoApplySettings = cfg.AUTO_APPLY_SETTINGS,
        Autopack          = cfg.AUTOPACK,
        CacheGeneratedMods = cfg.CACHE_GENERATED_MODS,
        QueueVehicleReloading = cfg.QUEUE_VEHICLE_RELOADING,
    })
end

local function loadSettings()
    local settings = readJsonFile(SETTINGS_PATH)
    if settings == nil then
        log('W', 'loadSettings', "No saved settings found, trying defaults")
        settings = readJsonFile(DEFAULT_SETTINGS_PATH)
    end
    if settings ~= nil then
        local map = {
            SeparateMods          = "SEPARATE_MODS",
            MultiSlotMods         = "MULTISLOT_MODS",
            AdditionalToMultiSlot = "ADDITIONAL_TO_MULTISLOT",
            DetailedDebug         = "DET_DEBUG",
            UseCoroutines         = "USE_COROUTINES",
            AutoApplySettings     = "AUTO_APPLY_SETTINGS",
            Autopack              = "AUTOPACK",
            LogLevel              = "LOGLEVEL",
            CacheGeneratedMods    = "CACHE_GENERATED_MODS",
            QueueVehicleReloading = "QUEUE_VEHICLE_RELOADING",
        }
        for jsonKey, cfgKey in pairs(map) do
            if settings[jsonKey] ~= nil then cfg[cfgKey] = settings[jsonKey] end
        end
        syncLoggerState()
        notify("Settings loaded", "Info", "info", 2000)
        sendSettingsToUI()
    else
        notify("Failed to load settings, using defaults", "Warning", "warning", 2000)
    end
end

local function saveSettings()
    writeJsonFile(SETTINGS_PATH, {
        SeparateMods          = cfg.SEPARATE_MODS,
        MultiSlotMods         = cfg.MULTISLOT_MODS,
        AdditionalToMultiSlot = cfg.ADDITIONAL_TO_MULTISLOT,
        DetailedDebug         = cfg.DET_DEBUG,
        UseCoroutines         = cfg.USE_COROUTINES,
        AutoApplySettings     = cfg.AUTO_APPLY_SETTINGS,
        Autopack              = cfg.AUTOPACK,
        LogLevel              = cfg.LOGLEVEL,
        CacheGeneratedMods    = cfg.CACHE_GENERATED_MODS,
        QueueVehicleReloading = cfg.QUEUE_VEHICLE_RELOADING,
    }, true)
    notify("Settings saved", "Info", "info", 2000)
    sendSettingsToUI()
end

local function setModSettings(jsonData)
    local data = json.decode(jsonData)
    local map = {
        SeparateMods          = "SEPARATE_MODS",
        DetailedDebug         = "DET_DEBUG",
        UseCoroutines         = "USE_COROUTINES",
        AutoApplySettings     = "AUTO_APPLY_SETTINGS",
        Autopack              = "AUTOPACK",
        MultiSlotMods         = "MULTISLOT_MODS",
        AdditionalToMultiSlot = "ADDITIONAL_TO_MULTISLOT",
        LogLevel              = "LOGLEVEL",
        CacheGeneratedMods    = "CACHE_GENERATED_MODS",
        QueueVehicleReloading = "QUEUE_VEHICLE_RELOADING",
    }
    for jsonKey, cfgKey in pairs(map) do
        if data[jsonKey] ~= nil then cfg[cfgKey] = data[jsonKey] end
    end
    syncLoggerState()
    saveSettings()
end

local function setConcurrencyDelay(delay)
    if delay == nil then log('E', 'setConcurrencyDelay', "delay is nil") return end
    cfg.CONCURRENCY_DELAY = delay
end

local function resetToDefaults()
    for k, v in pairs(DEFAULTS) do cfg[k] = v end
    syncLoggerState()
    saveSettings()
    notify("Settings reset to defaults", "Info", "info", 2000)
end

M.cfg = cfg
M.loadSettings = loadSettings
M.saveSettings = saveSettings
M.setModSettings = setModSettings
M.sendSettingsToUI = sendSettingsToUI
M.setConcurrencyDelay = setConcurrencyDelay
M.resetToDefaults = resetToDefaults

return M
