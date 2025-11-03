-- util.lua
local util = {}

function util.formatMoney(amount)
    local formatted = string.format("%.0f", amount)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

function util.drawBackground()
    love.graphics.clear(0.4, 0.8, 0.85)  
end

colors = {
    background = {0.4, 0.8, 0.85},
    window = {0.92, 0.96, 0.97},
    border = {0.2, 0.5, 0.55},
    text = {0.1, 0.1, 0.1},
    button = {0.3, 0.7, 0.75},
    buttonHover = {0.35, 0.75, 0.8},
    buttonDisabled = {0.7, 0.85, 0.87},
    accent = {0.95, 0.7, 0.2},
}


return util
