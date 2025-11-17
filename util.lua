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

-- ensure unpack works across Lua versions
local _unpack = table.unpack or unpack

util.colors = {
    background = {0.737, 0.416, 0.235},  
    window     = {0.776, 0.596, 0.455}, -- wood colour
    border     = {0.10, 0.14, 0.16},
    text       = {0.92, 0.96, 0.97}, -- zacht wit
    button      = {0.35, 0.70, 0.75},
    buttonHover = {0.42, 0.76, 0.80},
    buttonDisabled = {0.65, 0.80, 0.85},
    accent      = {0.95, 0.70, 0.20}
}


function util.drawWindow(x, y, w, h)
    -- shadow
    love.graphics.setColor(0, 0, 0, 0.15)
    love.graphics.rectangle("fill", x + 4, y + 4, w, h, 12, 12)

    -- window background
    love.graphics.setColor(util.colors.window)
    love.graphics.rectangle("fill", x, y, w, h, 12, 12)

    -- border
    love.graphics.setColor(util.colors.border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 12, 12)
end


function util.drawBackground()
    love.graphics.clear(_unpack(util.colors.background))
end

return util