local Food = {}

-- === Input variables (base state) ===
Food.employees = 10000
Food.employeeSalary = 1000       -- per week, per werknemer
Food.unitsProduced = 100000

Food.variableCostPerUnit = 1
Food.desiredDemand = 0
Food.needFactor = 0.95
Food.salePrice = 105    
Food.budgetReq = Food.desiredDemand * Food.salePrice
Food.availBudget = 1200

Food.inventory = 100

Food.loans = 100000              -- totaal geleend bedrag
Food.interestRate = 0.0018       -- 0.18% per week

Food.assets = 1000000            -- totale waarde activa
Food.assetWriteOffRate = 0.001   -- 0.10% per week
Food.reserves = 100000

-- === Outputs (calculated each week) ===
Food.costs = {
    employee = 0,
    material = 0,
    interest = 0,
    total = 0,
}

Food.income = {
    sales = 0,-- Bereken food demand
}

Food.profit = 0

-- === Profit distribution percentages ===
Food.profitDistribution = {
    investments = 0.40,
    shareholders = 0.20,
    loanRepayment = 0.15,
    reserves = 0.10,
    wageIncrease = 0.15,
}

Food.distribution = { -- actual amounts calculated later
    investments = 0,
    shareholders = 0,
    loanRepayment = 0,
    reserves = 0,
    wageIncrease = 0,
}

-- Plotting
Food.weeklySales = {}

-- === Functions ===

function Food.updateByWeeks(weeksPassed)
    for week = 1, weeksPassed do
        -- general updates 
        Food.budgetReq = Food.desiredDemand * Food.salePrice
        Food.availBudget = Food.budgetReq

        -- Kosten
        Food.costs.employee = Food.employees * Food.employeeSalary * weeksPassed
        Food.costs.material = Food.unitsProduced * Food.variableCostPerUnit * weeksPassed
        Food.costs.interest = Food.loans * Food.interestRate * weeksPassed
        Food.costs.total = Food.costs.employee + Food.costs.material + Food.costs.interest

        -- Inkomsten (per week, niet geschaald)
        Food.sales = Population.foodDemand
        Food.weeklyRevenue = Food.sales * Food.salePrice

        for i = 1, weeksPassed do
            table.insert(Food.weeklySales, Food.weeklyRevenue)

            -- Houd de tabel beperkt tot de laatste 52 weken
            if #Food.weeklySales > 52 then
                table.remove(Food.weeklySales, 1)
            end
        end

        -- Winst (geschaald met weeksPassed)
        Food.profit = (Food.weeklyRevenue - Food.costs.total) * weeksPassed

        -- Afschrijving (exponentieel i.p.v. lineair)
        Food.assets = Food.assets * ((1 - Food.assetWriteOffRate) ^ weeksPassed)

        -- Winstverdeling (geen extra * weeksPassed!)
        Food.distribution.investments = Food.profit * Food.profitDistribution.investments
        Food.distribution.shareholders = Food.profit * Food.profitDistribution.shareholders
        Food.distribution.loanRepayment = Food.profit * Food.profitDistribution.loanRepayment
        Food.distribution.reserves = Food.profit * Food.profitDistribution.reserves
        Food.distribution.wageIncrease = Food.profit * Food.profitDistribution.wageIncrease

            -- Winstverdeling
            if Food.profit > 0 then
                Food.distribution.investments = Food.profit * Food.profitDistribution.investments
                Food.distribution.shareholders = Food.profit * Food.profitDistribution.shareholders
                Food.distribution.loanRepayment = Food.profit * Food.profitDistribution.loanRepayment
                Food.distribution.reserves = Food.profit * Food.profitDistribution.reserves
                Food.distribution.wageIncrease = Food.profit * Food.profitDistribution.wageIncrease
            end
        end
end

function Food.draw(x, y, width)
    local lineHeight = 80
    local lines = {
        string.format("Employees: %d", Food.employees),
        string.format("Salary/employee: %.2f", Food.employeeSalary),
        string.format("Units produced: %d", Food.unitsProduced),
        string.format("Inventory: %d", Food.inventory),
        string.format("Sale price/unit: %.2f", Food.salePrice),
        string.format("Weekly revenue: %d", Food.weeklyRevenue or 0),
        string.format("Total costs: %.2f", Food.costs.total or 0),
        string.format("Profit: %.2f", Food.profit or 0),
        string.format("Loans: %.2f", Food.loans),
        string.format("Assets: %.2f", Food.assets),
        string.format("Reserves: %.2f", Food.reserves),
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
