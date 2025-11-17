local Food = {}
local util = require("util")
local Population = require("population")



-- === Input variables (base state) ===
Food.employees = 1000
Food.employeeSalary = 700       -- per week, per werknemer
Food.producedDaily = 1200   -- daily
Food.variableCostPerUnit = 1


Food.demandDaily = Population.foodDemand
Food.salePrice = 105    
Food.inventory = 5000

Food.loans = 100000              -- totaal geleend bedrag
Food.interestRate = 0.0018       -- 0.18% per week

Food.assets = 100000            -- totale waarde activa
Food.assetWriteOffRate = 0.001   -- 0.10% per week
Food.reserves = 10000

Food.weeklySold = 0
Food.weeklyRevenue = 0
Food.weeklySales = {} -- als je die tabel ook gebruikt

--investements
Food.productionLevel = 1
Food.investmentCost = 1000

Food.costs = {
    employee = 0,
    material = 0,
    interest = 0,
    total = 0,
}

Food.income = {
    sales = 0,-- Bereken food demand
}

Food.weeklyProfit = 0

-- === Profit distribution percentages ===
Food.profitDistribution = {
    investments = 0.40,
    shareholders = 0.20,
    loanRepayment = 0.15,
    reserves = 0.10,
    wageIncrease = 0.15,
}

Food.funds = {
    investments = 0,
    shareholders = 0,
    loanRepayment = 0,
    reserves = 0,
    wageIncrease = 0,
}


-- Plotting
Food.weeklySales = {}

-- Daily updates for prices, inventory, demand
function Food.updateDaily(daysPassed)
    for i = 1, daysPassed do
        Food.demandDaily = Population.foodDemand / 7
        Food.soldToday = math.min(Food.demandDaily, Food.producedDaily + Food.inventory)
        Food.inventory = math.max(0, math.floor(Food.inventory))
        Food.inventoryRatio = Food.inventory/Food.producedDaily -- ratio of invetory to production

        -- Prijs aanpassen
        if Food.producedDaily > 0 then
            local imbalance = (Food.demandDaily - Food.producedDaily) / Food.producedDaily
            Food.salePrice = Food.salePrice * (1 + 0.1 * imbalance)
        end

        -- ✅ Tel de omzet en verkoop op in weektotaal
        Food.weeklySold = Food.weeklySold + Food.soldToday
        Food.weeklyRevenue = Food.weeklyRevenue + (Food.soldToday * Food.salePrice)
    end
end


function Food.updateByWeeks(weeksPassed)
    for week = 1, weeksPassed do
        -- Kosten
        Food.costs.employee = Food.employees * Food.employeeSalary
        Food.costs.material = Food.weeklySold * Food.variableCostPerUnit
        Food.costs.interest = Food.loans * Food.interestRate
        Food.costs.total = Food.costs.employee + Food.costs.material + Food.costs.interest

        -- Winst
        Food.weeklyProfit = Food.weeklyRevenue - Food.costs.total

        -- Winstverdeling
        if Food.weeklyProfit > 0 then
            Food.weeklyDistribution = {}
            for k, v in pairs(Food.profitDistribution) do
                local amount = Food.weeklyProfit * v
                Food.weeklyDistribution[k] = amount
                Food.funds[k] = (Food.funds[k] or 0) + amount
            end
        else
            Food.weeklyDistribution = {}
            for k in pairs(Food.profitDistribution) do
                Food.weeklyDistribution[k] = 0
            end
        end

        -- ✅ Sla de revenue van deze week op
        Food.lastWeekRevenue = Food.weeklyRevenue

        -- Eventueel: hou een jaaroverzicht bij
        table.insert(Food.weeklySales, Food.weeklyRevenue)
        if #Food.weeklySales > 52 then
            table.remove(Food.weeklySales, 1)
        end

        -- Reset weekcijfers
        Food.weeklySold = 0
        Food.weeklyRevenue = 0

        -- assets updating
        Food.assetWriteOff = Food.assets*Food.assetWriteOffRate
        Food.assets = Food.assets + Food.funds.reserves - Food.assetWriteOff -- increase by reserves and by investments made minus write off

        -- investemetns
        if Food.funds.investments > 10000*Food.productionLevel then
            Food.funds.investments = Food.funds.investments - 10000*Food.productionLevel
            Food.productionLevel = Food.productionLevel + 1
            Food.producedDaily = Food.producedDaily*1.10 -- increase production capacity 10% everytime
        end


    end
end



function Food.draw(x, y, width, currency)
    local lineHeight = 70
    local currencySymbol = currency and (" $" .. currency) or ""

    -- panel dimensions
    local rows = 9
    local padding = 100
    local panelX = x - 20
    local panelY = y - 20
    local panelW = width + 10
    local panelH = rows * lineHeight + padding * 2


    -- prepare rows as {label, value, symbol}
    local rowsData = {
        {"Employees", tostring(Food.employees), ""},
        {"Salary/Week", util.formatMoney(Food.employeeSalary), currency and currencySymbol or ""},
        {"Production/day", tostring(Food.producedDaily), "Lvl " .. tostring(Food.productionLevel)},
        {"Demand/day", util.formatMoney(Food.demandDaily or 0), currency and currencySymbol or ""},
        {"Sale price", util.formatMoney(Food.salePrice), currency and currencySymbol or ""},
        {"Weekly revenue", util.formatMoney(Food.lastWeekRevenue or 0), currency and currencySymbol or ""},
        {"Weekly profit", util.formatMoney(Food.weeklyProfit or 0), currency and currencySymbol or ""},
        {"Investments", util.formatMoney(Food.funds.investments or 0), currency and currencySymbol or ""},
        {"Assets", util.formatMoney(Food.assets or 0), currency and currencySymbol or ""},
    }

    -- text color
    love.graphics.setColor(
        util.colors.text[1],
        util.colors.text[2],
        util.colors.text[3],
        util.colors.text[4] or 1
    )

    -- column positions (simple 3-column layout)
    local col1X = x
    local col2X = x + math.floor(width * 0.2)
    local col3X = x + math.floor(width * 0.28)
    local textY = panelY + padding

    -- draw rows
    for i, pair in ipairs(rowsData) do
        local label, value, sym = pair[1], pair[2], pair[3]
        love.graphics.print(label .. ":", col1X, textY + (i - 1) * lineHeight)
        love.graphics.print(value, col2X, textY + (i - 1) * lineHeight)
        love.graphics.print(sym, col3X, textY + (i - 1) * lineHeight)
    end
end

function Food.drawGraph(x, y, width, height)
    if #Food.weeklySales < 2 then return end

    -- Max schaal
    local maxRevenue = 0
    for _, val in ipairs(Food.weeklySales) do
        if val > maxRevenue then
            maxRevenue = val
        end
    end
    if maxRevenue == 0 then maxRevenue = 1 end

    -- Aslijnen in zacht wit
    love.graphics.setColor(0.9, 0.95, 0.95)
    love.graphics.line(x, y + height, x + width, y + height)
    love.graphics.line(x, y, x, y + height)

    -- Groene lijn iets zachter maken
    love.graphics.setColor(0.2, 0.9, 0.5)
    local step = width / math.max(1, (#Food.weeklySales - 1))

    for i = 1, #Food.weeklySales - 1 do
        local x1 = x + (i - 1) * step
        local y1 = y + height - (Food.weeklySales[i] / maxRevenue) * height
        local x2 = x + i * step
        local y2 = y + height - (Food.weeklySales[i + 1] / maxRevenue) * height
        love.graphics.line(x1, y1, x2, y2)
    end

    -- Eventueel zachte schaduw onder de lijn
    love.graphics.setColor(0.2, 0.9, 0.5, 0.2)
    for i = 1, #Food.weeklySales - 1 do
        local x1 = x + (i - 1) * step
        local y1 = y + height - (Food.weeklySales[i] / maxRevenue) * height
        local x2 = x + i * step
        local y2 = y + height - (Food.weeklySales[i + 1] / maxRevenue) * height
        love.graphics.line(x1, y1 + 2, x2, y2 + 2)
    end
end


function Food.drawGraph(x, y, width, height)
    if #Food.weeklySales < 2 then return end

    -- Max schaal
    local maxRevenue = 0
    for _, val in ipairs(Food.weeklySales) do
        if val > maxRevenue then
            maxRevenue = val
        end
    end
    if maxRevenue == 0 then maxRevenue = 1 end

    -- Aslijnen in zacht wit
    love.graphics.setColor(0.9, 0.95, 0.95)
    love.graphics.line(x, y + height, x + width, y + height)
    love.graphics.line(x, y, x, y + height)

    -- Groene lijn iets zachter maken
    love.graphics.setColor(0.2, 0.9, 0.5)
    local step = width / math.max(1, (#Food.weeklySales - 1))

    for i = 1, #Food.weeklySales - 1 do
        local x1 = x + (i - 1) * step
        local y1 = y + height - (Food.weeklySales[i] / maxRevenue) * height
        local x2 = x + i * step
        local y2 = y + height - (Food.weeklySales[i + 1] / maxRevenue) * height
        love.graphics.line(x1, y1, x2, y2)
    end

    -- Eventueel zachte schaduw onder de lijn
    love.graphics.setColor(0.2, 0.9, 0.5, 0.2)
    for i = 1, #Food.weeklySales - 1 do
        local x1 = x + (i - 1) * step
        local y1 = y + height - (Food.weeklySales[i] / maxRevenue) * height
        local x2 = x + i * step
        local y2 = y + height - (Food.weeklySales[i + 1] / maxRevenue) * height
        love.graphics.line(x1, y1 + 2, x2, y2 + 2)
    end
end


return Food
