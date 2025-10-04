local Food = {}

-- === Input variables (base state) ===
Food.employees = 10000
Food.employeeSalary = 1000       -- per week, per werknemer
Food.unitsProduced = 100000
Food.salePrice = 105             -- per unit
Food.variableCostPerUnit = 1
Food.sales = Population.foodDemand

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

-- === Functions ===

function Food.updateByWeeks(weeksPassed)
    for week = 1, weeksPassed do

       Food.sales = Population.foodDemand

        -- Kosten
        Food.costs.employee = Food.employees * Food.employeeSalary * weeksPassed
        Food.costs.material = Food.unitsProduced * Food.variableCostPerUnit * weeksPassed
        Food.costs.interest = Food.loans * Food.interestRate * weeksPassed
        Food.costs.total = Food.costs.employee + Food.costs.material + Food.costs.interest

        -- Inkomsten (per week, niet geschaald)
        Food.income.sales = Food.sales * Food.salePrice

        -- Winst (geschaald met weeksPassed)
        Food.profit = (Food.income.sales - Food.costs.total) * weeksPassed

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
    local lineHeight = 100
    local lines = {
        string.format("Employees: %d", Food.employees),
        string.format("Salary/employee: %.2f", Food.employeeSalary),
        string.format("Units produced: %d", Food.unitsProduced),
        string.format("Sale price/unit: %.2f", Food.salePrice),
        string.format("Total sales: %d", Food.income.sales or 0),
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



return Food
