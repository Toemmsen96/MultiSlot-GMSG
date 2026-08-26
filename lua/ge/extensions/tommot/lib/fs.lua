local M = {}

local function isEmptyOrWhitespace(str)
    return str == nil or str:match("^%s*$") ~= nil
end

local function ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

local function readJsonFile(path)
    if isEmptyOrWhitespace(path) then
        log('E', 'readJsonFile', "path is empty")
        return nil
    end
    return jsonReadFile(path)
end

local function writeJsonFile(path, data, compact)
    return jsonWriteFile(path, data, compact)
end

local function readJsonFileSafe(path)
    if isEmptyOrWhitespace(path) then
        log('E', 'readJsonFileSafe', "path is empty")
        return nil
    end
    if not FS:fileExists(path) then
        log('E', 'readJsonFileSafe', "File does not exist: " .. path)
        return nil
    end
    local content = readFile(path)
    if not content then
        log('E', 'readJsonFileSafe', "Failed to read file: " .. path)
        return nil
    end
    local ok, data = pcall(json.decode, content)
    if not ok then
        log('E', 'readJsonFileSafe', "JSON decode error in " .. path .. ": " .. tostring(data))
        return nil
    end
    if type(data) ~= 'table' then
        log('E', 'readJsonFileSafe', "Decoded JSON is not a table in: " .. path)
        return nil
    end
    return data
end

local function writeFileAtomic(finalPath, data, compact)
    local tempPath = finalPath .. ".tmp"
    if not writeJsonFile(tempPath, data, compact) then
        log('E', 'writeFileAtomic', "Failed to write temp file: " .. tempPath)
        return false
    end
    if readJsonFile(tempPath) == nil then
        log('E', 'writeFileAtomic', "Validation failed for temp file: " .. tempPath)
        FS:removeFile(tempPath)
        return false
    end
    if not writeJsonFile(finalPath, data, compact) then
        log('E', 'writeFileAtomic', "Failed to write final file: " .. finalPath)
        FS:removeFile(tempPath)
        return false
    end
    if readJsonFile(finalPath) == nil then
        log('E', 'writeFileAtomic', "Validation failed for final file: " .. finalPath)
        FS:removeFile(tempPath)
        return false
    end
    FS:removeFile(tempPath)
    return true
end

local function validateSlots(part, sourceFile)
    if not part then return false end
    if not part.slots and not part.slots2 then return true end
    local slots = part.slots or part.slots2
    if type(slots) ~= 'table' then
        log('E', 'validateSlots', "slots is not a table in " .. sourceFile .. ", partName: " .. tostring(part.partName))
        return false
    end
    if #slots == 0 then return true end
    if part.slots and type(slots[1]) == 'table' and slots[1][1] ~= "type" then
        log('W', 'validateSlots', "slots missing header in " .. sourceFile .. ", adding default header")
        table.insert(slots, 1, {"type", "default", "description"})
    end
    return true
end

local function validatePart(part, sourceFile)
    if not part or type(part) ~= 'table' then
        log('E', 'validatePart', "Part is not a valid table in: " .. sourceFile)
        return false
    end
    if not part.partName then log('W', 'validatePart', "Part missing partName in: " .. sourceFile) end
    if not part.slotType then log('W', 'validatePart', "Part missing slotType in: " .. sourceFile .. ", partName: " .. tostring(part.partName)) end
    validateSlots(part, sourceFile)
    return true
end

local function getModNameFromPath(path)
    local modname = string.lower(path)
    modname = modname:gsub('dir:/', '')
    modname = modname:gsub('/mods/', '')
    modname = modname:gsub('repo/', '')
    modname = modname:gsub('unpacked/', '')
    modname = modname:gsub('/', '')
    modname = modname:gsub('.zip$', '')
    return modname
end

M.isEmptyOrWhitespace = isEmptyOrWhitespace
M.ends_with = ends_with
M.readJsonFile = readJsonFile
M.writeJsonFile = writeJsonFile
M.readJsonFileSafe = readJsonFileSafe
M.writeFileAtomic = writeFileAtomic
M.validateSlots = validateSlots
M.validatePart = validatePart
M.getModNameFromPath = getModNameFromPath

return M
