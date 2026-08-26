local M = {}

local isWaitingForAutoPack   = false
local isWaitingForPackAll    = false
local isWaitingForVehReload  = false
local pendingFinishCount     = 0
local customOutputPath       = nil
local customOutputName       = nil

local function cfg()    return tommot_gmsg_settings.cfg end
local function logger() return tommot_lib_logger end
local function modman() return tommot_lib_modman end
local function log(level, func, msg) logger().logToConsole(level, func, msg) end

local function onFinishGen()
    pendingFinishCount = pendingFinishCount - 1
    if pendingFinishCount > 0 then return end
    modman().initDBSafe(cfg().GENERATED_PATH:lower() .. "/")
    if cfg().AUTOPACK then
        isWaitingForPackAll = true
        logger().logToConsole('W', 'onFinishGen', "Queued for Autopack")
    end
    if cfg().QUEUE_VEHICLE_RELOADING then
        -- initDB() is itself a background job (core_jobsystem.wrap), so the VFS remount
        -- it triggers isn't done yet here - reloading the vehicle immediately would just
        -- reload against the still-stale mount. Wait until the mod is visible in the DB.
        isWaitingForVehReload = true
    end
end

local function queueCustomPack(outputPath)
    customOutputPath = outputPath
    customOutputName = tommot_lib_fs.getModNameFromPath(outputPath)
    log('D', 'queueCustomPack', "Queued " .. customOutputName .. " for Autopack with path:\n" .. customOutputPath)
    modman().initDBSafe("mods/" .. outputPath)
    isWaitingForAutoPack = true
end

-- Call each frame from onGuiUpdate to drive async pack operations.
local function pollPack()
    if isWaitingForAutoPack and customOutputPath ~= nil then
        if modman().isModInDB(customOutputName) then
            logger().logToConsole('D', 'Autopack', "Packing mod: /mods" .. customOutputPath:lower())
            logger().debugMessage("Autopacking: /mods" .. customOutputPath:lower(), "Debug: Autopack")
            modman().packMod("/mods" .. customOutputPath:lower())
            isWaitingForAutoPack = false
        end
    end
    if isWaitingForPackAll then
        if modman().isModUnpacked("generatedmodslot") then
            logger().logToConsole('D', 'Autopack', "Packing generatedModSlot")
            logger().debugMessage("Autopacking: generatedModSlot", "Debug: Autopack")
            isWaitingForPackAll = false
            modman().packMod(cfg().GENERATED_PATH:lower())
        end
    end
    if isWaitingForVehReload then
        if modman().isModInDB("generatedmodslot") and core_vehicle_manager then
            isWaitingForVehReload = false
            modman().invalidateJbeamCache()
            core_vehicle_manager.reloadVehicle(0)
            logger().GMSGMessage("Reloaded vehicle after generation", "Info", "info", 2000)
        end
    end
end

local function deleteTempFiles()
    local path = cfg().GENERATED_PATH
    log('W', 'deleteTempFiles', "Deleting all files in " .. path)
    logger().GMSGMessage("Deleting temp files", "Info", "info", 2000)
    modman().deleteGeneratedMod(path, "generatedmodslot")
    log('W', 'deleteTempFiles', "Done")
    logger().GMSGMessage("Done deleting temp files", "Info", "info", 2000)
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
