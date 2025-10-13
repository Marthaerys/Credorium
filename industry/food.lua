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
        Food.inventory = Food.inventory + (Food.producedDaily - Food.soldToday)
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
        if Food.funds.investments > 100 then
            Food.productionLevel = Food.productionLevel + 1
        end


    end
end



function Food.draw(x, y, width, currency)
    local lineHeight = 80
    love.graphics.setColor(1, 1, 1)
    local symbol = currency and (" $" .. currency) or ""
    local lines = {
    
        string.format("Employees: %d", Food.employees),
        string.format("Employee salary/Week: %s%s", util.formatMoney(Food.employeeSalary), symbol),
        string.format("Food production/day: %d", Food.producedDaily),
        string.format("Food demand/day: %d", Food.demandDaily or 0),
        string.format("Inventory: %d", Food.inventory),
        string.format("Sale price/pc: %s%s", util.formatMoney(Food.salePrice), symbol),
        string.format("Weekly revenue: %s%s", util.formatMoney(Food.lastWeekRevenue or 0), symbol),
        string.format("Weekly cost: %s%s", util.formatMoney(Food.costs.total or 0), symbol),
        string.format("Weekly profit: %s%s", util.formatMoney(Food.weeklyProfit or 0), symbol),
        string.format("Investments: %s%s", util.formatMoney(Food.funds.investments or 0), symbol),
        string.format("Assets: %s%s", util.formatMoney(Food.assets or 0), symbol),
        --string.format("Loans: %d", Food.loans),
        --string.format("Reserves: %d", Food.reserves),
    }

    for i, line in ipairs(lines) do
        love.graphics.print(line, x, y + (i - 1) * lineHeight)
    end
end

function Food.drawGraph(x, y, width, height)
    if #Food.weeklySales < 2 then return end

    -- Bepaal schaal
    local maxRevenue = 0
    for _, val in ipairs(Food.weeklySales) do
        if val > maxRevenue then
            maxRevenue = val
        end
    end
    if maxRevenue == 0 then maxRevenue = 1 end  -- voorkom deling door 0

    -- Tekenen van assen
    love.graphics.setColor(1, 1, 1)
    love.graphics.line(x, y + height, x + width, y + height) -- X-as
    love.graphics.line(x, y, x, y + height) -- Y-as

    -- Teken de lijn
    love.graphics.setColor(0, 1, 0)
    local step = width / math.max(1, (#Food.weeklySales - 1))

    for i = 1, #Food.weeklySales - 1 do
        local x1 = x + (i - 1) * step
        local y1 = y + height - (Food.weeklySales[i] / maxRevenue) * height
        local x2 = x + i * step
        local y2 = y + height - (Food.weeklySales[i + 1] / maxRevenue) * height
        love.graphics.line(x1, y1, x2, y2)
    end
end


return Food
