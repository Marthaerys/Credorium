-- game.lua

local Game = {}

function Game.load(countryName, currencyName)
    Game.country = countryName
    Game.currency = currencyName
    Game.capital = 1000000
end

function Game.update(dt)
    -- Placeholder for future game logic
end

function Game.draw()
    love.graphics.printf("Welcome to " .. Game.country, 0, 100, 1600, "center")
    love.graphics.printf("Currency: " .. Game.currency, 0, 160, 1600, "center")
    love.graphics.printf("Capital: " .. string.format("%0.2f", Game.capital) .. " " .. Game.currency, 0, 220, 1600, "center")
end

return Game
