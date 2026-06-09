--[[
Injects a MultiSlot slot into each vehicle's main jbeam part at load time,
so it appears as a top-level slot in the vehicle configurator.

Hooks jbeam/io.getPart and jbeam/io.getAvailableParts:
- getPart: appends the slot entry to slots2 so slotSystem resolves it
- getAvailableParts: adds the slot to slotInfoUi so the configurator labels it correctly
]]

local M = {}

local jbeamIO = nil
local originalGetPart = nil
local originalGetAvailableParts = nil

local function getModelFromIoCtx(ioCtx)
    if not ioCtx or not ioCtx.preloadedDirs then return nil end
    for _, dir in ipairs(ioCtx.preloadedDirs) do
        local model = dir:match("/vehicles/([^/]+)/")
        if model then return model end
    end
    return nil
end

local function hasMultimod(model)
    local path = "/vehicles/" .. model .. "/modslot/" .. model .. "_multimod.jbeam"
    return FS:fileExists(path)
end

-- Hook 1: inject slot entry into the decoded part so slotSystem sees it
local function hookedGetPart(ioCtx, partName)
    local part, filename = originalGetPart(ioCtx, partName)
    if not part or part.slotType ~= "main" then return part, filename end

    local model = getModelFromIoCtx(ioCtx) or partName
    if not hasMultimod(model) then return part, filename end

    local slotName = model .. "_multislot"
    local modSlotType = model .. "_mod"
    local multimodPartName = model .. "_multimod"

    if not part.slots2 then part.slots2 = {} end
    for _, row in ipairs(part.slots2) do
        if type(row) == "table" and row.name == slotName then
            return part, filename
        end
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

-- Hook 2: inject slotInfoUi entry so the configurator shows "MultiSlot" as the label
local function hookedGetAvailableParts(ioCtx)
    local res = originalGetAvailableParts(ioCtx)
    if not res then return res end

    local model = getModelFromIoCtx(ioCtx)
    if not model or not hasMultimod(model) then return res end

    local mainPartDesc = res[model]
    if not mainPartDesc then return res end

    local slotName = model .. "_multislot"
    local modSlotType = model .. "_mod"

    if not mainPartDesc.slotInfoUi then mainPartDesc.slotInfoUi = {} end
    if not mainPartDesc.slotInfoUi[slotName] then
        mainPartDesc.slotInfoUi[slotName] = {
            name        = slotName,
            allowTypes  = {modSlotType},
            denyTypes   = {},
            description = "MultiSlot",
        }
    end

    return res
end

local function onExtensionLoaded()
    setExtensionUnloadMode(M, "manual")

    jbeamIO = require('jbeam/io')
    if not jbeamIO or not jbeamIO.getPart then
        log('E', 'multiSlotInjector', "jbeam/io not found — cannot hook")
        return
    end

    originalGetPart = jbeamIO.getPart
    jbeamIO.getPart = hookedGetPart

    originalGetAvailableParts = jbeamIO.getAvailableParts
    jbeamIO.getAvailableParts = hookedGetAvailableParts

    log('D', 'multiSlotInjector', "Hooked jbeam/io.getPart and getAvailableParts")
end

local function onExtensionUnloaded()
    if jbeamIO then
        if originalGetPart then
            jbeamIO.getPart = originalGetPart
            originalGetPart = nil
        end
        if originalGetAvailableParts then
            jbeamIO.getAvailableParts = originalGetAvailableParts
            originalGetAvailableParts = nil
        end
        log('D', 'multiSlotInjector', "Unhooked jbeam/io")
    end
end

M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

return M
