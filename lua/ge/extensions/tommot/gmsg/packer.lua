local M = {}

local isWaitingForAutoPack = false
local isWaitingForPackAll  = false
local pendingFinishCount   = 0
local customOutputPath     = nil
local customOutputName     = nil

local function cfg()    return tommot_gmsg_settings.cfg end
local function logger() return tommot_lib_logger end

local function onFinishGen()
    pendingFinishCount = pendingFinishCount - 1
    if pendingFinishCount > 0 then return end
    local genPath = cfg().GENERATED_PATH:lower() .. "/"
    if FS:isMounted(genPath) then
        FS:unmount(genPath)
        log('D', 'onFinishGen', "Unmounted " .. genPath .. " for remount")
    end
    core_modmanager.initDB()
    if cfg().AUTOPACK then
        isWaitingForPackAll = true
        logger().logToConsole('W', 'onFinishGen', "Queued for Autopack")
    end
end

local function queueCustomPack(outputPath)
    customOutputPath = outputPath
    customOutputName = tommot_lib_fs.getModNameFromPath(outputPath)
    log('D', 'queueCustomPack', "Queued " .. customOutputName .. " for Autopack with path:\n" .. customOutputPath)
    core_modmanager.initDB()
    isWaitingForAutoPack = true
end

-- Call each frame from onGuiUpdate to drive async pack operations.
local function pollPack()
    if isWaitingForAutoPack and customOutputPath ~= nil then
        for _, mod in pairs(core_modmanager.getMods() or {}) do
            if mod and mod.modname and mod.modname:lower() == customOutputName then
                logger().logToConsole('D', 'Autopack', "Packing mod: /mods" .. customOutputPath:lower())
                core_modmanager.packMod("/mods" .. customOutputPath:lower())
                isWaitingForAutoPack = false
                break
            end
        end
    end
    if isWaitingForPackAll then
        if core_modmanager.modIsUnpacked("generatedmodslot") then
            logger().logToConsole('D', 'Autopack', "Packing generatedModSlot")
            isWaitingForPackAll = false
            core_modmanager.packMod(cfg().GENERATED_PATH:lower())
        end
    end
end

local function deleteTempFiles()
    local path = cfg().GENERATED_PATH
    log('W', 'deleteTempFiles', "Deleting all files in " .. path)
    logger().GMSGMessage("Deleting temp files", "Info", "info", 2000)
    local function deleteFrom(p)
        for _, file in ipairs(FS:findFiles(p, "*", -1, true, false)) do FS:removeFile(file) end
    end
    deleteFrom(path)
    deleteFrom(path:lower())
    core_modmanager.deleteMod("generatedmodslot")
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
