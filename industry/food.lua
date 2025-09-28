local Food = {}

-- === Input variables (base state) ===
Food.employees = 10000
Food.employeeSalary = 1000       -- per week, per werknemer
Food.unitsProduced = 100000
Food.salePrice = 105             -- per unit
Food.variableCostPerUnit = 1

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
    sales = 0,
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

function Food.updateByWeeks(weeks)
    for i = 1, weeks do
        -- Kosten
        Food.costs.employee = Food.employees * Food.employeeSalary
        Food.costs.material = Food.unitsProduced * Food.variableCostPerUnit
        Food.costs.interest = Food.loans * Food.interestRate
        Food.costs.total = Food.costs.employee + Food.costs.material + Food.costs.interest

        -- Inkomsten
        Food.income.sales = Food.unitsProduced * Food.salePrice

        -- Winst
        Food.profit = Food.income.sales - Food.costs.total

        -- Asset depreciation (write-off)
        Food.assets = Food.assets * (1 - Food.assetWriteOffRate)

        -- Winstverdeling
        if Food.profit > 0 then
            Food.distribution.investments = Food.profit * Food.profitDistribution.investments
            Food.distribution.shareholders = Food.profit * Food.profitDistribution.shareholders
            Food.distribution.loanRepayment = Food.profit * Food.profitDistribution.loanRepayment
            Food.distribution.reserves = Food.profit * Food.profitDistribution.reserves
            Food.distribution.wageIncrease = Food.profit * Food.profitDistribution.wageIncrease

            -- Effecten van winstverdeling
            Food.loans = Food.loans - Food.distribution.loanRepayment
            Food.reserves = Food.reserves + Food.distribution.reserves
            Food.employeeSalary = Food.employeeSalary + (Food.distribution.wageIncrease / Food.employees)
        end
    end
end

function Food.getInfo()
    return string.format(
        " Food Sector\n" ..
        "Employees: %d\n" ..
        "Salary/employee: €%.2f\n" ..
        "Units produced: %d\n" ..
        "Sale price/unit: €%.2f\n" ..
        "Total sales: €%.2f\n" ..
        "Total costs: €%.2f\n" ..
        "Profit: €%.2f\n" ..
        "Loans: €%.2f\n" ..
        "Assets: €%.2f\n" ..
        "Reserves: €%.2f",
        Food.employees,
        Food.employeeSalary,
        Food.unitsProduced,
        Food.salePrice,
        Food.income.sales,
        Food.costs.total,
        Food.profit,
        Food.loans,
        Food.assets,
        Food.reserves
    )
end

return Food
