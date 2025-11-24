local Game = {}
local util = require("util")
Population = require("population")
Industry = require("industry/industry")
Economy = require("economy")

Game.capital = 1000000
Game.currency = "BUCKS"
Game.country = ""
Game.menuButton = nil

screenX, screenY = love.graphics.getDimensions()

-- UI
Game.uiState = "main"
Game.industryButton = nil
Game.closeButton = nil

-- Clock
Game.timeCounter = 0
Game.day = 1
Game.week = 1
Game.year = 1
Game.previousWeek = 0 


function Game.load(countryName, currencyName)
    Game.country = countryName
    Game.currency = currencyName
    Game.capital = 1000000

    local Button = require("ui/button")

    local screenX, screenY = love.graphics.getDimensions()

    Game.menuButton = Button:new("Menu", 20, screenY - 100, 200, 80)
    Game.industryButton = Button:new("Industry", 240, screenY - 100, 200, 80)
    Game.populationButton = Button:new("Population", 460, screenY - 100, 300, 80)
    Game.economyButton = Button:new("Economy", 800, screenY - 100, 200, 80)
    Game.closeButton = Button:new("Close", screenX / 2 - 100, screenY / 2 + 100, 200, 80)
end

function Game.loadFromSave()
    if love.filesystem.getInfo("savegame.txt") then
        local data = love.filesystem.read("savegame.txt")
        local country, currency, capital = data:match("([^;]+);([^;]+);([^;]+)")
        Game.country = country
        Game.currency = currency
        Game.capital = tonumber(capital)

        local Button = require("ui/button")
        local screenX, screenY = love.graphics.getDimensions()

        Game.menuButton = Button:new("Menu", 20, screenY - 100, 200, 80)
        Game.industryButton = Button:new("Industry", 240, screenY - 100, 200, 80)
        Game.populationButton = Button:new("Population", 460, screenY - 100, 300, 80)
        Game.economyButton = Button:new("Economy", 800, screenY - 100, 200, 80)
        Game.closeButton = Button:new("Close", screenX / 2 - 100, screenY / 2 + 100, 200, 80)

        Game.uiState = "main"  -- Optional but good to reset this explicitly
    end
end


function Game.save()
    local data = Game.country .. ";" .. Game.currency .. ";" .. tostring(Game.capital)
    love.filesystem.write("savegame.txt", data)
end


function Game.update(dt)
    local mx, my = love.mouse.getPosition()
    Industry.updateByWeeks(dt)

    -- ✅ Always update bottom buttons
    if Game.menuButton then Game.menuButton:update(mx, my) end
    if Game.industryButton then Game.industryButton:update(mx, my) end
    if Game.populationButton then Game.populationButton:update(mx, my) end
    if Game.economyButton then Game.economyButton:update(mx, my) end

    -- ✅ Only update the close button when a panel is open
    if Game.uiState ~= "main" and Game.closeButton then
        Game.closeButton:update(mx, my)
    end
    

    -- Time simulation
    Game.timeCounter = Game.timeCounter + dt
    if Game.timeCounter >= 1 then
        Game.timeCounter = Game.timeCounter - 1
        Game.day = Game.day + 1
        
        Industry.updateDaily(1)

        if Game.day >= 7 then
            Game.day = 1
            Game.week = Game.week + 1

            if Game.week > 52 then
                Game.week = 1
                Game.year = Game.year + 1
            end
        end
    end

    -- Update population if a week has passed
    local currentWeek = Game.week or 0
    local previousWeek = Game.previousWeek or 0

    local weeksPassed
    if currentWeek >= previousWeek then
        weeksPassed = currentWeek - previousWeek
    else
        weeksPassed = (52 - previousWeek) + currentWeek
    end

    if weeksPassed > 0 then
        Population.updateByWeeks(weeksPassed)
        Industry.updateByWeeks(weeksPassed)
        Economy.update(weeksPassed)
        Game.previousWeek = currentWeek
    end
end


function Game.draw()
    local screenX, screenY = love.graphics.getDimensions()

    ---------------------------------------------------------
    -- 1. Achtergrond tekenen met util
    ---------------------------------------------------------
    util.drawBackground()

    ---------------------------------------------------------
    -- 2. Capital rechtsboven
    ---------------------------------------------------------
    love.graphics.setColor(util.colors.text)
    love.graphics.print(
        formatMoney(Game.capital) .. " " .. Game.currency,
        20, 20
    )

    ---------------------------------------------------------
    -- 3. Altijd de bottom buttons tekenen
    ---------------------------------------------------------
    if Game.menuButton then Game.menuButton:draw() end
    if Game.industryButton then Game.industryButton:draw() end
    if Game.populationButton then Game.populationButton:draw() end
    if Game.economyButton then Game.economyButton:draw() end

    ---------------------------------------------------------
    -- 4. UI overlay (industry / population / economy)
    ---------------------------------------------------------
    if Game.uiState ~= "main" then
        local width  = screenX * 0.90
        local height = screenY * 0.85
        local x = (screenX - width) / 2
        local y = (screenY - height) / 2

        -- ✨ Gebruik util.drawWindow!
        util.drawWindow(x, y, width, height)

        -- Tekstkleur instellen
        love.graphics.setColor(util.colors.text)

        -- ✨ Teken de juiste UI module
        if Game.uiState == "industry" then
            Industry.loadButtons(x, y, width, height)
            Industry.draw(x, y, width, Game.currency)

        elseif Game.uiState == "population" then
            Population.draw(x, y, width, Game.currency)

        elseif Game.uiState == "economy" then
            love.graphics.printf("Economic Overview",
                x, y + 20, width, "center"
            )
            Economy.draw(x + 50, y + 80, Game.currency)
        end

        -----------------------------------------------------
        -- Close button (positie vernieuwen)
        -----------------------------------------------------
        if Game.closeButton then
            Game.closeButton.x = x + (width / 2) - (Game.closeButton.width / 2)
            Game.closeButton.y = y + height - Game.closeButton.height - 40
            Game.closeButton:draw()
        end
    end

    ---------------------------------------------------------
    -- 5. Datum rechtsboven
    ---------------------------------------------------------
    love.graphics.setColor(util.colors.text)
    love.graphics.printf(
        "Day: " .. Game.day .. "   Week: " .. Game.week .. "   Year: " .. Game.year,
        0, 20, screenX - 20, "right"
    )
end



-- Helper function
function formatMoney(amount)
    local formatted = string.format("%.0f", amount)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end



return Game
