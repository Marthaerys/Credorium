local Population = require("population")

local Economy = {}

-- Wages (set as fixed for now, can make dynamic later)
Economy.employeeWageLow = 2
Economy.employeeWageMedium = 3
Economy.employeeWageHigh = 4

-- Starting wealth per class
Economy.lowClassWealth = 1000
Economy.mediumClassWealth = 1000
Economy.highClassWealth = 1000

function Economy.update(dt)
    -- Get current income multipliers from Population
    local incomeLow = Population.adultIncome.low or 0
    local incomeMedium = Population.adultIncome.medium or 0
    local incomeHigh = Population.adultIncome.high or 0

    -- Add wages to wealth (adjust for dt if you want time-based logic)
    Economy.lowClassWealth = Economy.lowClassWealth + Economy.employeeWageLow * incomeLow * dt
    Economy.mediumClassWealth = Economy.mediumClassWealth + Economy.employeeWageMedium * incomeMedium * dt
    Economy.highClassWealth = Economy.highClassWealth + Economy.employeeWageHigh * incomeHigh * dt
end

function Economy.draw(x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Wealth of Low Class: " .. math.floor(Economy.lowClassWealth), x, y)
    love.graphics.print("Wealth of Middle Class: " .. math.floor(Economy.mediumClassWealth), x, y + 30)
    love.graphics.print("Wealth of High Class: " .. math.floor(Economy.highClassWealth), x, y + 60)
end

return Economy
