-- Backwards-compatibility stub. External mods loading tommot_gmsgUI still work;
-- all calls are forwarded transparently to tommot_gmsg_ui.
local M = {}

local function onExtensionLoaded()
    if not extensions.isExtensionLoaded("tommot_gmsg_ui") then
        extensions.load("tommot_gmsg_ui")
        setExtensionUnloadMode("tommot_gmsg_ui", "manual")
    end
end

setmetatable(M, {
    __index = function(_, k)
        return tommot_gmsg_ui and tommot_gmsg_ui[k]
    end
})

M.onExtensionLoaded = onExtensionLoaded
return M
