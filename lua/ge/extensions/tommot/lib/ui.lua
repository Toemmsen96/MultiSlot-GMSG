local M = {}

local imgui = ui_imgui

-- Renders a bold title bar with an X button. Call inside BeginMenuBar/EndMenuBar.
local function renderWindowHeader(title, toggleFn)
    local style = imgui.GetStyle()
    imgui.SetCursorPosY(-style.ItemSpacing.y + imgui.GetScrollY())
    imgui.PushFont3("cairo_bold")
    imgui.Text(title)
    imgui.SetCursorPosX(imgui.GetWindowWidth() - imgui.CalcTextSize("X").x - style.FramePadding.x * 2 - style.WindowPadding.x)
    if imgui.Button("X") then toggleFn() end
    imgui.SetCursorPosX(0)
    imgui.PopFont()
    imgui.Separator()
end

-- Renders a checkbox + clickable label row with an optional tooltip on both widgets.
local function checkboxRow(label, boolPtr, tooltip)
    local id = "##cb_" .. label:gsub("%W", "_")
    imgui.Checkbox(id, boolPtr)
    if tooltip and imgui.IsItemHovered() then imgui.SetTooltip(tooltip) end
    imgui.SameLine()
    if imgui.Selectable1(label, boolPtr[0]) then boolPtr[0] = not boolPtr[0] end
    if tooltip and imgui.IsItemHovered() then imgui.SetTooltip(tooltip) end
end

M.renderWindowHeader = renderWindowHeader
M.checkboxRow = checkboxRow

return M
