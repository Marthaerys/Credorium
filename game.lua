-- game.lua
local Game = {}

Game.capital = 1000000
Game.currency = "BUCKS"
Game.country = ""
Game.menuButton = nil
local screenX, screenY = 1600, 1200

--UI
Game.uiState = "main"
Game.industryButton = nil
Game.closeButton = nil

--Clock
Game.timeCounter = 0
Game.day = 1
Game.week = 1
Game.year = 1


function Game.load(countryName, currencyName)
    Game.country = countryName
    Game.currency = currencyName
    Game.capital = 1000000

    local Button = require("ui/button")
    Game.menuButton = Button:new("Menu", 20, screenY - 120, 200, 80)

    Game.industryButton = Button:new("Industry", 240, screenY - 120, 200, 80)
    Game.closeButton = Button:new("Close", screenX/2 - 100, screenY/2 + 100, 200, 80)

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
    if Game.uiState == "main" then
        if Game.menuButton then
            local mx, my = love.mouse.getPosition()
            Game.menuButton:update(mx, my)
        end
        if Game.industryButton then
            local mx, my = love.mouse.getPosition()
            Game.industryButton:update(mx, my)
        end
    elseif Game.uiState == "industry" then
        if Game.closeButton then
            local mx, my = love.mouse.getPosition()
            Game.closeButton:update(mx, my)
        end
    end

    -- Time simulation
    Game.timeCounter = Game.timeCounter + dt

    if Game.timeCounter >= 1 then
        Game.timeCounter = Game.timeCounter - 1 -- remove 1 second
        Game.day = Game.day + 1

        if Game.day > 7 then
            Game.day = 1
            Game.week = Game.week + 1

            -- Here you could call: Company:updateWeek() if you want automatic simulation per week
        end

        if Game.week > 52 then
            Game.week = 1
            Game.year = Game.year + 1
        end
    end
end

function Game.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(formatMoney(Game.capital) .. " " .. Game.currency, 20, 20)

    if Game.uiState == "main" then
        if Game.menuButton then Game.menuButton:draw() end
        if Game.industryButton then Game.industryButton:draw() end
    elseif Game.uiState == "industry" then
        -- Draw popup background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
        love.graphics.rectangle("fill", screenX/2 - 300, screenY/2 - 200, 600, 400, 12, 12)

        -- Draw industry info (example text for now)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Industry Overview", screenX/2 - 300, screenY/2 - 180, 600, "center")
        love.graphics.printf("Manufacturing output: 1,500 units\nEmployment: 25%\nExports: 300 units", 
                            screenX/2 - 250, screenY/2 - 120, 500, "left")

        -- Draw Close button
        if Game.closeButton then Game.closeButton:draw() end
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(" Day:  " .. Game.day .. "  Week:  " .. Game.week .. "  Year:  " .. Game.year, 0, 20, 1600 - 40, "right")

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


Company = {
    employees = 100,
    salary_per_employee = 100,
    units_produced = 5000,
    sale_price_per_unit = 5,
    material_cost_per_unit = 1,
    loan_balance = 1000000,
    loan_interest_rate_per_week = 0.0018, -- 0.18% as decimal
    assets_value = 6000000,
    reserves_balance = 100000,

    fixed_costs = 0, -- e.g. rent, utilities
    asset_depreciation_rate_per_week = 0.001, -- 0.1%

    -- Behavior targets
    investment_allocation = 0.4,
    shareholder_dividend_allocation = 0.2,
    loan_repayment_allocation = 0.2,
    reserves_allocation = 0.1,
    wage_increase_allocation = 0.1,

    -- Internal states
    net_profit = 0,
    revenue = 0,
    total_costs = 0,
}

function Company:updateWeek()
    self:calculateRevenue()
    self:calculateCosts()
    self:calculateNetProfit()
    self:distributeProfit()
    self:adjustStrategy()
end


return Game
