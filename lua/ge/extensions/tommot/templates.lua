-- Backwards-compatibility stub. External mods loading tommot_templates still work;
-- all calls are forwarded transparently to tommot_gmsg_templates.
local M = {}

local function onExtensionLoaded()
    if not extensions.isExtensionLoaded("tommot_gmsg_templates") then
        extensions.load("tommot_gmsg_templates")
        setExtensionUnloadMode("tommot_gmsg_templates", "manual")
    end
end

setmetatable(M, {
    __index = function(_, k)
        return tommot_gmsg_templates and tommot_gmsg_templates[k]
    end
})

M.onExtensionLoaded = onExtensionLoaded
return M
