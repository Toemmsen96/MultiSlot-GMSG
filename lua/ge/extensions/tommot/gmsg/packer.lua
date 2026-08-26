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
        -- initDB() is itself a background job (core_jobsystem.wrap) that mounts the new
        -- files, populates the mod DB, THEN broadcasts onFileChanged/onFileChangedEnd to
        -- clear jbeam's caches - in that order. isModInDB() only tells us the DB step is
        -- done, not the cache-invalidation broadcast that comes after it, so polling on
        -- isModInDB and reloading immediately raced the still-stale jbeam cache (this is
        -- why a manual Ctrl+R - which happens well after initDB settles - "fixed" it).
        --
        -- onModManagerReady looked like the right "initDB finished" signal but isn't: the
        -- engine only ever fires it once per game session (the first time the mod manager
        -- becomes ready), guarded by `if ready ~= true`. Every later initDB() call - i.e.
        -- every regeneration after the first - skips that broadcast entirely, so nothing
        -- ever picked this up after the initial load. onModManagerStateChanged is fired
        -- unconditionally on every initDB() completion (core_modmanager.stateChanged, called
        -- right after the onFileChanged broadcast), so use that instead.
        isWaitingForVehReload = true
    end
end

local function onModManagerStateChanged()
    if not isWaitingForVehReload then return end
    if not (core_vehicle_manager and be) then return end
    isWaitingForVehReload = false
    -- initDB() already broadcast onFileChanged/onFileChangedEnd for the new files by the
    -- time this fires, so jbeam's caches should already be clear - this is just a defensive
    -- extra invalidation in case any consumer missed that broadcast.
    modman().invalidateJbeamCache()
    local veh = be:getPlayerVehicle(0)
    if veh then
        core_vehicle_manager.reloadVehicle(0)
        logger().GMSGMessage("Reloaded vehicle after generation", "Info", "info", 2000)
    else
        logger().debugMessage("No player vehicle spawned, skipping auto-reload", "Debug: onModManagerStateChanged")
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

M.onFinishGen              = onFinishGen
M.onModManagerStateChanged = onModManagerStateChanged
M.queueCustomPack          = queueCustomPack
M.pollPack                 = pollPack
M.deleteTempFiles          = deleteTempFiles
M.incrementPending         = incrementPending
M.resetPending             = resetPending

return M
