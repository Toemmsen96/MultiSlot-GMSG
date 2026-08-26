-- Utilities for interacting with BeamNG's mod manager and VFS safely.

local M = {}

local function logger() return tommot_lib_logger end
local function log(level, func, msg)
    if logger() then logger().logToConsole(level, func, msg) else _G.log(level, func, msg) end
end

-- Unmounts a directory if mounted, then calls initDB so the VFS rescans it.
-- Without the unmount, files written to an already-mounted directory are invisible
-- until the next full restart.
local function initDBSafe(dirPath)
    if not dirPath then
        log('E', 'initDBSafe', "dirPath is nil")
        return
    end
    if FS:isMounted(dirPath) then
        FS:unmount(dirPath)
        log('D', 'initDBSafe', "Unmounted " .. dirPath .. " for VFS rescan")
        if logger() then logger().debugMessage("Unmounted " .. dirPath .. " for VFS rescan", "Debug: initDBSafe") end
    end
    core_modmanager.initDB()
end

-- Returns true if a mod with the given name (case-insensitive) is registered in the mod DB.
local function isModInDB(name)
    if not name then return false end
    name = name:lower()
    for _, mod in pairs(core_modmanager.getMods() or {}) do
        if mod and mod.modname and mod.modname:lower() == name then return true end
    end
    return false
end

-- Returns true if a mod with the given name exists and is currently unpacked (not zipped).
local function isModUnpacked(name)
    if not name then return false end
    return core_modmanager.modIsUnpacked(name:lower())
end

-- Packs the mod at the given path. Logs an error if the mod is not found in the DB first.
local function packMod(modPath)
    if not modPath then log('E', 'packMod', "modPath is nil") return end
    local name = modPath:match("([^/]+)/?$") or modPath
    if not isModInDB(name) then
        log('W', 'packMod', "Mod not in DB yet, pack may fail: " .. name)
    end
    if logger() then logger().debugMessage("Packing mod: " .. modPath, "Debug: packMod") end
    core_modmanager.packMod(modPath:lower())
end

-- Experimental function to invalidate the jbeam cache by triggering a file change event.
local function invalidateJbeamCache()
    extensions.hook('onFileChanged', "/vehicles/_gmsg_cache_invalidate.jbeam", "added")
    extensions.hook('onFileChangedEnd')
end

-- Deletes a directory tree and removes its packed zip from the mod DB.
-- modName is the name used by the mod manager (e.g. "generatedmodslot").
--
-- FS:findFiles(..., true, false) only ever returns files, never subdirectories, and
-- FS:removeFile() can't remove a directory - so a findFiles+removeFile loop silently
-- leaves every subfolder (and anything only reachable through one) behind. FS:remove()
-- is recursive and deletes both files and directories in one call (this is also how
-- BeamNG's own modmanager.safeDeleteFolder() does it), so use that instead.
--
-- After deleting, broadcast onFileChanged so jbeam drops its cached parts for the
-- removed files, then reload the spawned vehicle (if any) so it picks up the change
-- immediately instead of needing a manual Ctrl+R.
local function deleteGeneratedMod(dirPath, modName)
    if not dirPath then log('E', 'deleteGeneratedMod', "dirPath is nil") return end
    if FS:directoryExists(dirPath) and FS:remove(dirPath) ~= 0 then
        log('E', 'deleteGeneratedMod', "Failed to remove: " .. dirPath)
    end
    local dirPathLower = dirPath:lower()
    if dirPathLower ~= dirPath and FS:directoryExists(dirPathLower) and FS:remove(dirPathLower) ~= 0 then
        log('E', 'deleteGeneratedMod', "Failed to remove: " .. dirPathLower)
    end
    if modName then core_modmanager.deleteMod(modName:lower()) end

    -- jbeam only recognizes real .jbeam paths via onFileChanged (extension check), so a
    -- single marker call is enough to flush the caches for whatever was just removed.
    extensions.hook('onFileChanged', dirPath .. "/_gmsg_cache_invalidate.jbeam", "deleted")
    extensions.hook('onFileChangedEnd')

    if core_vehicle_manager and be then
        local veh = be:getPlayerVehicle(0)
        if veh then core_vehicle_manager.reloadVehicle(0) end
    end
end

M.initDBSafe        = initDBSafe
M.invalidateJbeamCache = invalidateJbeamCache
M.isModInDB         = isModInDB
M.isModUnpacked     = isModUnpacked
M.packMod           = packMod
M.deleteGeneratedMod= deleteGeneratedMod

return M
