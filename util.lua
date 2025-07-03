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

return util
