local Game = {}
Population = require("population")
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
    Game.closeButton = Button:new("Close", screenX / 2 - 100, screenY / 2 + 100, 200, 80)
    Game.populationButton = Button:new("Population", 460, screenY - 100, 200, 80, function()
    Game.uiState = "population"
    Game.economyButton = Button:new("Economy", 660, screenY - 100, 200, 80)
end)

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
        Game.closeButton = Button:new("Close", screenX / 2 - 100, screenY / 2 + 100, 200, 80)
        Game.populationButton = Button:new("Population", 460, screenY - 100, 200, 80, function()
        Game.uiState = "population" end)


    end
end


function Game.save()
    local data = Game.country .. ";" .. Game.currency .. ";" .. tostring(Game.capital)
    love.filesystem.write("savegame.txt", data)
end


function Game.update(dt)
    local mx, my = love.mouse.getPosition()

    -- UI updates
    if Game.uiState == "main" then
        if Game.menuButton then Game.menuButton:update(mx, my) end
        if Game.industryButton then Game.industryButton:update(mx, my) end
        if Game.populationButton then Game.populationButton:update(mx, my) end
    elseif Game.uiState == "industry" or Game.uiState == "population" then
        if Game.closeButton then Game.closeButton:update(mx, my) end
    end

    -- Time simulation
    Game.timeCounter = Game.timeCounter + dt
    if Game.timeCounter >= 1 then
        Game.timeCounter = Game.timeCounter - 1
        Game.day = Game.day + 7

        if Game.day > 7 then
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
        Game.previousWeek = currentWeek
    end
end



function Game.draw()
    local screenX, screenY = love.graphics.getDimensions()

    -- Capital display
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(formatMoney(Game.capital) .. " " .. Game.currency, 20, 20)

    if Game.uiState == "main" then
        if Game.menuButton then Game.menuButton:draw() end
        if Game.industryButton then Game.industryButton:draw() end
        if Game.populationButton then Game.populationButton:draw() end
        if Game.econmyButton then Game.economyButton:draw() end

    elseif Game.uiState == "industry" or Game.uiState == "population" or Game.uiState == "economy" then
        local width = screenX * 0.9
        local height = screenY * 0.9
        local x = (screenX - width) / 2
        local y = (screenY - height) / 2

        -- Background panel
        love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
        love.graphics.rectangle("fill", x, y, width, height, 12, 12)

        -- Title and content
        love.graphics.setColor(1, 1, 1)
        if Game.uiState == "industry" then
            love.graphics.printf("Industry Overview", x, y + 20, width, "center")
            love.graphics.printf(
                "Manufacturing output: 1,500 units\nEmployment: 25%\nExports: 300 units",
                x + 50, y + 80, width - 100, "left"
            )
        elseif Game.uiState == "population" then
            print("Type of Population:", type(Population))

            Population.draw(x, y, width)
        end

        -- Close button
        if Game.closeButton then
            Game.closeButton.x = x + (width / 2) - (Game.closeButton.width / 2)
            Game.closeButton.y = y + height - Game.closeButton.height - 40
            Game.closeButton:draw()
        end
    end


    -- Day/week/year in top right
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        " Day: " .. Game.day .. "  Week: " .. Game.week .. "  Year: " .. Game.year,
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

-- Simulated company (placeholder)
Company = {
    employees = 100,
    salary_per_employee = 100,
    units_produced = 5000,
    sale_price_per_unit = 5,
    material_cost_per_unit = 1,
    loan_balance = 1000000,
    loan_interest_rate_per_week = 0.0018,
    assets_value = 6000000,
    reserves_balance = 100000,

    fixed_costs = 0,
    asset_depreciation_rate_per_week = 0.001,

    investment_allocation = 0.4,
    shareholder_dividend_allocation = 0.2,
    loan_repayment_allocation = 0.2,
    reserves_allocation = 0.1,
    wage_increase_allocation = 0.1,

    net_profit = 0,
    revenue = 0,
    total_costs = 0,
}

needs_pyramid = {
    {
        level = 1,
        name = "Basisbehoeften",
        examples = {
            "Voedsel",
            "Water",
            "Energie (brandstof/stroom)",
            "Huur / onderdak",
            "Kleding (minimaal)",
            "Basale zorg (vaccinaties, eerste hulp)"
        }
    },
    {
        level = 2,
        name = "Veiligheid & Zekerheid",
        examples = {
            "Woningverbetering / beveiliging",
            "Zorgverzekering",
            "Spaarrekening",
            "Vaste baan / inkomen",
            "School voor kinderen (basis)",
            "Transport (fiets, OV)"
        }
    },
    {
        level = 3,
        name = "Sociale binding & status",
        examples = {
            "Feesten / bruiloften / cadeaus",
            "Relatievorming / dating / bruidsprijs",
            "Communicatiemiddelen (telefoon, internet)",
            "Kleding (modieus)",
            "Religieuze giften",
            "Sociale bijdragen (familie steunen)"
        }
    },
    {
        level = 4,
        name = "Ontwikkeling & onderwijs",
        examples = {
            "Hoger onderwijs / bijles",
            "Privé-onderwijs voor kinderen",
            "Computer / boeken",
            "Talen leren",
            "Cursussen / certificaten"
        }
    },
    {
        level = 5,
        name = "Zelfontplooiing & luxe",
        examples = {
            "Vakanties",
            "Luxe goederen (auto, sieraden)",
            "Fitness & sportclubs",
            "Entertainment (games, films, concerten)",
            "Hobby’s & creativiteit",
            "Designmeubels"
        }
    }
}


function Company:updateWeek()
    self:calculateRevenue()
    self:calculateCosts()
    self:calculateNetProfit()
    self:distributeProfit()
    self:adjustStrategy()
end

return Game
