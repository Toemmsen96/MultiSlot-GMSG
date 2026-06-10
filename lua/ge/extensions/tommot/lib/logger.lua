local M = {}

local LOGLEVEL = 2

local queueHookJS
if obj then
    queueHookJS = function(...) obj:queueHookJS(...) end
elseif be then
    queueHookJS = function(...) be:queueHookJS(...) end
end

local function checkLogLevel(level)
    if (level == 'D' or level == 'debug') and LOGLEVEL < 2 then return false end
    if (level == 'I' or level == 'info') and LOGLEVEL < 1 then return false end
    if (level == 'W' or level == 'warning') and LOGLEVEL < 1 then return false end
    return true
end

local function logToConsole(level, func, message)
    if checkLogLevel(level) then
        log(level, func, message)
    end
end

local function GMSGMessage(msg, title, msgType, timeOut)
    if not queueHookJS then return end
    if not checkLogLevel(msgType) then return end
    local onTap = "function() { window.open('https://www.beamng.com/resources/general-modslot-generator-multislot.31265/') }"
    local config = jsonEncode({
        type = msgType or "warning",
        title = title or "GMSG / MultiSlot Generator",
        msg = msg or "",
        config = {
            timeOut = timeOut or 10000,
            progressBar = true,
            closeButton = true,
            positionClass = "toast-top-right",
            preventDuplicates = true,
            preventOpenDuplicates = true,
            onTap = "<REPLACETHIS>"
        }
    })
    config = config:gsub("\"<REPLACETHIS>\"", onTap)
    queueHookJS("toastrMsg", "[" .. config .. "]", 0)
end

local function setLogLevel(level)
    LOGLEVEL = level
end

M.logToConsole = logToConsole
M.GMSGMessage = GMSGMessage
M.setLogLevel = setLogLevel

return M
