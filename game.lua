-- game.lua
local Game = {}

Game.capital = 1000000
Game.currency = "BUCKS"
Game.country = ""
Game.menuButton = nil
local screenX, screenY = 1600, 1200

function Game.load(countryName, currencyName)
    Game.country = countryName
    Game.currency = currencyName
    Game.capital = 1000000

    local Button = require("ui/button")
    Game.menuButton = Button:new("Menu", 20, screenY - 120, 200, 80)
end

function Game.loadFromSave()
    if love.filesystem.getInfo("savegame.txt") then
        local data = love.filesystem.read("savegame.txt")
        local country, currency, capital = data:match("([^;]+);([^;]+);([^;]+)")
        Game.country = country
        Game.currency = currency
        Game.capital = tonumber(capital)

        -- Create Menu button
        local Button = require("ui/button")
        Game.menuButton = Button:new("Menu", 20, screenY - 120, 200, 80)
    end
end

function Game.save()
    local data = Game.country .. ";" .. Game.currency .. ";" .. tostring(Game.capital)
    love.filesystem.write("savegame.txt", data)
end

function Game.update(dt)
    -- Placeholder for future game logic
end

function Game.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Capital: " .. formatMoney(Game.capital) .. " " .. Game.currency, 20, 20)

    if Game.menuButton then
        Game.menuButton:draw()
    end
end

-- Helper function for thousands separator
function formatMoney(amount)
    local formatted = string.format("%.0f", amount) -- no decimals
    -- Insert commas
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end


return Game
