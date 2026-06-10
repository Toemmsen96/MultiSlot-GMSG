local M = {}

local function convertName(name)
    return name:lower():gsub(" ", "_")
end

-- Recursively copies all files from srcBase into destBase, preserving relative paths.
local function copyFileTree(srcBase, destBase)
    local files = FS:findFiles(srcBase, "*", -1, true, false)
    for _, file in ipairs(files) do
        local relativePath = file:sub(#srcBase + 2)
        local targetPath = destBase .. "/" .. relativePath
        local src = io.open(file, "r")
        if src then
            local content = src:read("*all")
            src:close()
            local dir = targetPath:match("(.*[/\\])")
            if dir then FS:directoryCreate(dir, true) end
            local dst = io.open(targetPath, "w")
            if dst then
                dst:write(content)
                dst:close()
            else
                log('E', 'copyFileTree', "Failed to write to " .. targetPath)
            end
        else
            log('E', 'copyFileTree', "Failed to read from " .. file)
        end
    end
end

-- Generic generation engine.
--
-- Iterates targets × sources (or just targets if sources is absent), calling
-- opts.process for each pair that opts.skip does not reject.
--
-- opts = {
--   targets  : function() -> table          required  outer collection
--   sources  : function() -> table          optional  inner collection; omit for single-level iteration
--   skip     : function(target, source)     optional  return true to skip this pair
--   process  : function(target, source)     required  does the actual work; source is nil if no sources given
--   onDone   : function()                   optional  called once after all pairs are processed
-- }
-- job : optional coroutine job — when provided, job.yield() is called after each process() call
--
-- Example (two-level, with version skip):
--   M.generate({
--     targets = tommot_gmsg_vehicles.getAllVehicles,
--     sources = tommot_gmsg_templates.loadTemplateNames,
--     skip    = function(vehicle, templateName) return isUpToDate(vehicle, templateName) end,
--     process = function(vehicle, templateName) generateFile(vehicle, templateName) end,
--     onDone  = packer.onFinishGen,
--   }, job)
--
-- Example (single-level, no skip):
--   M.generate({
--     targets = tommot_gmsg_vehicles.getAllVehicles,
--     process = function(vehicle) doSomething(vehicle) end,
--   })
local function generate(opts, job)
    assert(type(opts.process) == 'function', "generator.generate: opts.process is required")

    local targets = opts.targets and opts.targets() or {}
    local sources = opts.sources and opts.sources()

    if sources then
        for _, source in pairs(sources) do
            for _, target in pairs(targets) do
                if not opts.skip or not opts.skip(target, source) then
                    opts.process(target, source)
                end
                if job then job.yield() end
            end
        end
    else
        for _, target in pairs(targets) do
            if not opts.skip or not opts.skip(target, nil) then
                opts.process(target, nil)
            end
            if job then job.yield() end
        end
    end

    if opts.onDone then opts.onDone() end
end

M.convertName = convertName
M.copyFileTree = copyFileTree
M.generate     = generate

return M
