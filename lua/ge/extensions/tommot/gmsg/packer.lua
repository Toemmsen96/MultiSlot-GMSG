local M = {}

local isWaitingForAutoPack = false
local isWaitingForPackAll  = false
local pendingFinishCount   = 0
local customOutputPath     = nil
local customOutputName     = nil

local function cfg()    return tommot_gmsg_settings.cfg end
local function logger() return tommot_lib_logger end
local function modman() return tommot_lib_modman end
local function fs()     return tommot_lib_fs end

local function onFinishGen()
    pendingFinishCount = pendingFinishCount - 1
    if pendingFinishCount > 0 then return end
    local cfgMod = tommot_gmsg_settings
    local modmanMod = modman()
    local logMod = logger()
    if not cfgMod or not cfgMod.cfg or not modmanMod then
        log('E', 'onFinishGen', "required modules are not available")
        return
    end
    modmanMod.initDBSafe(cfgMod.cfg.GENERATED_PATH:lower() .. "/")
    if cfgMod.cfg.AUTOPACK and logMod then
        isWaitingForPackAll = true
        logMod.logToConsole('W', 'onFinishGen', "Queued for Autopack")
    end
end

local function queueCustomPack(outputPath)
    local fsMod = fs()
    local modmanMod = modman()
    if not fsMod or not modmanMod then
        log('E', 'queueCustomPack', "required modules are not available")
        return
    end
    customOutputPath = outputPath
    customOutputName = fsMod.getModNameFromPath(outputPath)
    log('D', 'queueCustomPack', "Queued " .. customOutputName .. " for Autopack with path:\n" .. customOutputPath)
    modmanMod.initDBSafe("mods/" .. outputPath)
    isWaitingForAutoPack = true
end

-- Call each frame from onGuiUpdate to drive async pack operations.
local function pollPack()
    local cfgMod = tommot_gmsg_settings
    local modmanMod = modman()
    local logMod = logger()
    if not cfgMod or not cfgMod.cfg or not modmanMod then return end
    if isWaitingForAutoPack and customOutputPath ~= nil then
        if modmanMod.isModInDB(customOutputName) then
            if logMod then logMod.logToConsole('D', 'Autopack', "Packing mod: /mods" .. customOutputPath:lower()) end
            modmanMod.packMod("/mods" .. customOutputPath:lower())
            isWaitingForAutoPack = false
        end
    end
    if isWaitingForPackAll then
        if modmanMod.isModUnpacked("generatedmodslot") then
            if logMod then logMod.logToConsole('D', 'Autopack', "Packing generatedModSlot") end
            isWaitingForPackAll = false
            modmanMod.packMod(cfgMod.cfg.GENERATED_PATH:lower())
        end
    end
end

local function deleteTempFiles()
    local cfgMod = tommot_gmsg_settings
    local modmanMod = modman()
    local logMod = logger()
    if not cfgMod or not cfgMod.cfg or not modmanMod then
        log('E', 'deleteTempFiles', "required modules are not available")
        return
    end
    local path = cfgMod.cfg.GENERATED_PATH
    log('W', 'deleteTempFiles', "Deleting all files in " .. path)
    if logMod then logMod.GMSGMessage("Deleting temp files", "Info", "info", 2000) end
    modmanMod.deleteGeneratedMod(path, "generatedmodslot")
    log('W', 'deleteTempFiles', "Done")
    if logMod then logMod.GMSGMessage("Done deleting temp files", "Info", "info", 2000) end
end

local function incrementPending() pendingFinishCount = pendingFinishCount + 1 end
local function resetPending()     pendingFinishCount = 0 end

M.onFinishGen       = onFinishGen
M.queueCustomPack   = queueCustomPack
M.pollPack          = pollPack
M.deleteTempFiles   = deleteTempFiles
M.incrementPending  = incrementPending
M.resetPending      = resetPending

return M
