-- Utilities for interacting with BeamNG's mod manager and VFS safely.

local M = {}

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
    core_modmanager.packMod(modPath:lower())
end

-- Deletes all files under a directory and removes its packed zip from the mod DB.
-- modName is the name used by the mod manager (e.g. "generatedmodslot").
local function deleteGeneratedMod(dirPath, modName)
    if not dirPath then log('E', 'deleteGeneratedMod', "dirPath is nil") return end
    local files = FS:findFiles(dirPath, "*", -1, true, false)
    for _, file in ipairs(files) do FS:removeFile(file) end
    local filesLower = FS:findFiles(dirPath:lower(), "*", -1, true, false)
    for _, file in ipairs(filesLower) do FS:removeFile(file) end
    if modName then core_modmanager.deleteMod(modName:lower()) end
end

M.initDBSafe        = initDBSafe
M.isModInDB         = isModInDB
M.isModUnpacked     = isModUnpacked
M.packMod           = packMod
M.deleteGeneratedMod= deleteGeneratedMod

return M
