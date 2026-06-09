--[[
Injects a MultiSlot slot into each vehicle's main jbeam part at load time,
so it appears as a top-level slot in the vehicle configurator.

Wraps jbeam/io.getPart: when it returns a "main" slotType part and a
matching <model>_multimod.jbeam exists in the VFS, a new slot entry is
appended to the part's slots2 table before slotSystem processes it.
]]

local M = {}

local jbeamIO = nil
local originalGetPart = nil

local function getModelFromPartName(ioCtx, partName)
    if not ioCtx or not ioCtx.preloadedDirs then return nil end
    for _, dir in ipairs(ioCtx.preloadedDirs) do
        local model = dir:match("/vehicles/([^/]+)/")
        if model then return model end
    end
    -- fallback: partName is usually the model name for the main part
    return partName
end

local function hookedGetPart(ioCtx, partName)
    local part, filename = originalGetPart(ioCtx, partName)
    if not part then return part, filename end

    -- Only modify the main part
    if part.slotType ~= "main" then return part, filename end

    local model = getModelFromPartName(ioCtx, partName)
    if not model then return part, filename end

    local multimodPartName = model .. "_multimod"
    local multimodPath = "/vehicles/" .. model .. "/modslot/" .. multimodPartName .. ".jbeam"
    if not FS:fileExists(multimodPath) then return part, filename end

    -- Inject the MultiSlot slot into slots2
    -- allowTypes uses the existing <model>_mod type so <model>_multimod (slotType=<model>_mod) fits it
    local modSlotType = model .. "_mod"
    local slotName = model .. "_multislot"

    -- Check if already injected (idempotent across multiple getPart calls for the same part)
    if part.slots2 then
        for _, row in ipairs(part.slots2) do
            if type(row) == "table" and row.name == slotName then
                return part, filename
            end
        end
    else
        part.slots2 = {}
    end

    table.insert(part.slots2, {
        name        = slotName,
        allowTypes  = {modSlotType},
        denyTypes   = {},
        default     = multimodPartName,
        description = "MultiSlot",
    })

    return part, filename
end

local function onExtensionLoaded()
    setExtensionUnloadMode(M, "manual")

    jbeamIO = require('jbeam/io')
    if not jbeamIO or not jbeamIO.getPart then
        log('E', 'multiSlotInjector', "jbeam/io.getPart not found — cannot hook")
        return
    end

    originalGetPart = jbeamIO.getPart
    jbeamIO.getPart = hookedGetPart
    log('D', 'multiSlotInjector', "Hooked jbeam/io.getPart")
end

local function onExtensionUnloaded()
    if originalGetPart and jbeamIO then
        jbeamIO.getPart = originalGetPart
        originalGetPart = nil
        log('D', 'multiSlotInjector', "Unhooked jbeam/io.getPart")
    end
end

M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

return M
