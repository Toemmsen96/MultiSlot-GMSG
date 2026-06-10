-- Backwards-compatibility stub. External mods loading tommot_multislot still work;
-- all calls are forwarded transparently to tommot_gmsg_multislot.
local M = {}

local function onExtensionLoaded()
    if not extensions.isExtensionLoaded("tommot_gmsg_multislot") then
        extensions.load("tommot_gmsg_multislot")
        setExtensionUnloadMode("tommot_gmsg_multislot", "manual")
    end
end

setmetatable(M, {
    __index = function(_, k)
        return tommot_gmsg_multislot and tommot_gmsg_multislot[k]
    end
})

M.onExtensionLoaded = onExtensionLoaded
return M
