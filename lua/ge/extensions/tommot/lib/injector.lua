-- Generic function hook/unhook utility.
-- hook() wraps a function on a table and returns an unhook closure.
-- unhookAll() restores every hook registered in this session.

local M = {}

local function logger() return tommot_lib_logger end
local function log(level, func, msg)
    if logger() then logger().logToConsole(level, func, msg) else _G.log(level, func, msg) end
end

local _hooks = {}

local function hook(tbl, funcName, hookFn)
    local original = tbl[funcName]
    if not original then
        log('E', 'injector.hook', "Function not found: " .. tostring(funcName))
        return function() end
    end
    tbl[funcName] = function(...) return hookFn(original, ...) end
    table.insert(_hooks, {tbl = tbl, funcName = funcName, original = original})
    if logger() then logger().debugMessage("Hooked function: " .. tostring(funcName), "Debug: injector") end
    return function()
        tbl[funcName] = original
    end
end

local function unhookAll()
    for _, h in ipairs(_hooks) do
        h.tbl[h.funcName] = h.original
    end
    _hooks = {}
end

M.hook = hook
M.unhookAll = unhookAll

return M
