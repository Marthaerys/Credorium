local Food = {}
local util = require("util")
local Population = require("population")

-- === Input variables (base state) ===
Food.employees = 1000
Food.employeeSalary = 700       -- per week, per werknemer
Food.efficiencyPerEmployee = 1    -- units produced per day, per employee
Food.producedDaily = 1100   -- daily
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
Food.investConstant = 5000

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
    -- ensure sensible defaults
    Food.productionLevel = Food.productionLevel or 1
    Food.baseCapacityPerLevel = Food.baseCapacityPerLevel or 1200
    Food.maxProducedDaily = Food.maxProducedDaily or (Food.baseCapacityPerLevel * Food.productionLevel)

    for i = 1, daysPassed do
        -- safe demand (Population.foodDemand may be nil)
        local weeklyDemand = (Population.foodDemand or 0)
        Food.demandDaily = weeklyDemand / 7

        -- actual production limited by capacity and workforce
        Food.producedDaily = math.ceil(math.min(Food.maxProducedDaily or math.huge, (Food.employees or 0) * (Food.efficiencyPerEmployee or 1)))

        -- compute how many can be sold today (capacity + inventory vs demand)
        local potentialSold = math.min(Food.demandDaily, Food.producedDaily + (Food.inventory or 0))
        Food.soldToday = math.floor(potentialSold)

        -- update inventory and keep integer >= 0
        Food.inventory = math.max(0, math.floor((Food.inventory or 0) + Food.producedDaily - Food.soldToday))

        -- inventory ratio (avoid division by zero)
        Food.inventoryRatio = Food.producedDaily > 0 and (Food.inventory / Food.producedDaily) or 0

        -- adjust price based on imbalance
        if Food.producedDaily > 0 then
            local imbalance = (Food.demandDaily - Food.producedDaily) / Food.producedDaily
            Food.salePrice = (Food.salePrice or 0) * (1 + 0.1 * imbalance)
        end

        -- accumulate weekly totals
        Food.weeklySold = (Food.weeklySold or 0) + Food.soldToday
        Food.weeklyRevenue = (Food.weeklyRevenue or 0) + (Food.soldToday * (Food.salePrice or 0))
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

        ---------------------------------------------------------
        -- 📉 NEGATIVE FEEDBACK LOOP: werknemers verminderen
        ---------------------------------------------------------

        local profitMargin = Food.weeklyProfit / (Food.costs.total + 1)

        -- werknemers worden NIET aangepast bij kleine fluctuaties
        local lossThreshold = -0.05  -- -5% marge

        if profitMargin < lossThreshold then
            -- percentage ontslag (hoe groter verlies → hoe meer ontslag)
            local cutRate = math.min(0.05, -profitMargin * 0.5) 
            -- vb: -10% marge → 5% ontslag cap

            local oldEmployees = Food.employees

            Food.employees = math.floor(Food.employees * (1 - cutRate))

            -- ondergrens
            if Food.employees < 100 then
                Food.employees = 100
            end

            print("⚠ Employees reduced from " .. oldEmployees .. " to " .. Food.employees)
        end

        ---------------------------------------------------------
        -- 📈 POSITIVE FEEDBACK: groeien bij hoge marges
        ---------------------------------------------------------

        local growthThreshold = 0.15 -- +15% marge

        if profitMargin > growthThreshold then
            -- neem max 4% per week aan, bounded
            local hireRate = math.min(0.04, profitMargin * 0.3)

            local old = Food.employees
            Food.employees = math.floor(Food.employees * (1 + hireRate))

            -- cap op basis van max capacity
            if Food.employees * Food.efficiencyPerEmployee > Food.maxProducedDaily then
                Food.employees = math.floor(Food.maxProducedDaily / Food.efficiencyPerEmployee)
            end

            print("📈 Employees increased from " .. old .. " to " .. Food.employees)
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
        
        if Food.funds.investments > Food.investConstant* Food.productionLevel then
            Food.funds.investments = Food.funds.investments - Food.investConstant*Food.productionLevel
            Food.productionLevel = Food.productionLevel + 1
            Food.maxProducedDaily = Food.maxProducedDaily*1.05 -- increase production capacity 5% everytime
            Food.efficiencyPerEmployee = Food.efficiencyPerEmployee*1.05 -- increase efficiency 5% everytime
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
        -- Production will be drawn as current/max in column 2; column 3 will show level
        {"Production/day", "", "Lvl " .. tostring(Food.productionLevel)},
        {"Demand/day", util.formatMoney(Food.demandDaily or 0), currency and currencySymbol or ""},
        {"Sale price", util.formatMoney(Food.salePrice), currency and currencySymbol or ""},
        {"Weekly revenue", util.formatMoney(Food.lastWeekRevenue or 0), currency and currencySymbol or ""},
        {"Weekly profit", util.formatMoney(Food.weeklyProfit or 0), currency and currencySymbol or ""},
        {"Investments", util.formatMoney(Food.funds.investments or 0), currency and currencySymbol or ""},
        {"Assets", util.formatMoney(Food.assets or 0), currency and currencySymbol or ""},
    }

    -- text color
    local tx = util.colors.text
    love.graphics.setColor(tx[1], tx[2], tx[3], tx[4] or 1)

    -- column positions (simple 3-column layout)
    local col1X = x
    local col2X = x + math.floor(width * 0.2)
    local col3X = x + math.floor(width * 0.45)
    local textY = panelY + padding

    -- draw rows
    for i, pair in ipairs(rowsData) do
        local label, value, sym = pair[1], pair[2], pair[3]
        local yPos = textY + (i - 1) * lineHeight

        love.graphics.print(label .. ":", col1X, yPos)

        if label == "Production/day" then
            -- compute safe integers for current and max production
            local current = math.floor(Food.producedDaily or 0)
            local maxp = math.floor(Food.maxProducedDaily or ((Food.baseCapacityPerLevel or 0) * (Food.productionLevel or 1)))
            love.graphics.print(tostring(current) .. " / " .. tostring(maxp), col2X, yPos)

            -- green level in third column
            love.graphics.setColor(0.2, 0.9, 0.5, 1)
            love.graphics.print("Lvl " .. tostring(Food.productionLevel or 0), col3X, yPos)
            -- restore base text color
            love.graphics.setColor(tx[1], tx[2], tx[3], tx[4] or 1)
        else
            love.graphics.print(value, col2X, yPos)
            love.graphics.print(sym, col3X, yPos)
        end
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
