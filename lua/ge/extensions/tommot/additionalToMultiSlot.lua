-- Backwards-compatibility stub. External mods loading tommot_additionalToMultiSlot still work;
-- all calls are forwarded transparently to tommot_gmsg_additionalslots.
local M = {}

local function onExtensionLoaded()
    if not extensions.isExtensionLoaded("tommot_gmsg_additionalslots") then
        extensions.load("tommot_gmsg_additionalslots")
        setExtensionUnloadMode("tommot_gmsg_additionalslots", "manual")
    end
end

setmetatable(M, {
    __index = function(_, k)
        return tommot_gmsg_additionalslots and tommot_gmsg_additionalslots[k]
    end
})

M.onExtensionLoaded = onExtensionLoaded
return M
