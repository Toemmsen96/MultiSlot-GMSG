local M = {}

-- 0 = errors only, 1 = + warnings/info, 2 = + debug
local LOGLEVEL = 2
local DET_DEBUG = false

local queueHookJS
if obj then
    queueHookJS = function(...) obj:queueHookJS(...) end
elseif be then
    queueHookJS = function(...) be:queueHookJS(...) end
end

-- Console log-level codes ('D'/'I'/'W'/'E', also accepts full words).
local function checkLogLevel(level)
    if (level == 'D' or level == 'debug') then return LOGLEVEL >= 2 end
    if (level == 'I' or level == 'info') then return LOGLEVEL >= 1 end
    if (level == 'W' or level == 'warning') then return LOGLEVEL >= 1 end
    -- 'E'/'error' and anything unrecognized always gets through.
    return true
end

local function logToConsole(level, func, message)
    if checkLogLevel(level) then
        log(level, func, message)
    end
end

-- Popup/toast types (toastr-style: "info"/"warning"/"error"/"success"/"debug").
-- These are independent of LOGLEVEL - only "debug"-type popups are gated, and only
-- by the Detailed Debug setting, so users get extra visibility without touching LOGLEVEL.
local function checkPopupType(msgType)
    if msgType == 'debug' then return DET_DEBUG end
    return true
end

local function GMSGMessage(msg, title, msgType, timeOut)
    if not queueHookJS then return end
    if not checkPopupType(msgType) then return end
    local displayType = (msgType == 'debug') and 'info' or (msgType or 'warning')
    local onTap = "function() { window.open('https://www.beamng.com/resources/general-modslot-generator-multislot.31265/') }"
    local config = jsonEncode({
        type = displayType,
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

-- Convenience: always gated on Detailed Debug, always logs to console as 'D' too.
local function debugMessage(msg, title, func)
    logToConsole('D', func or 'debug', msg)
    GMSGMessage(msg, title or "Debug", "debug", 4000)
end

local function setLogLevel(level)
    LOGLEVEL = level
end

local function setDetailedDebug(enabled)
    DET_DEBUG = enabled and true or false
end

M.logToConsole = logToConsole
M.GMSGMessage = GMSGMessage
M.debugMessage = debugMessage
M.setLogLevel = setLogLevel
M.setDetailedDebug = setDetailedDebug

return M
