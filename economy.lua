local Population = require("population")
local util = require("util")

local Economy = {}

-- Wages per week?
Economy.employeeWageLow = 0.02
Economy.employeeWageMedium = 0.03
Economy.employeeWageHigh = 0.04

-- Starting wealth per class
Economy.lowClassWealth = 10000
Economy.mediumClassWealth = 10000
Economy.highClassWealth = 10000


function Economy.update(weeksPassed)
    -- ✅ Get the current income table
    local adultIncome = Population.getWorkingIncome()

    -- ✅ Access correct fields inside returned table
    local incomeLow = adultIncome.low or 0
    local incomeMedium = adultIncome.medium or 0
    local incomeHigh = adultIncome.high or 0

    -- Apply weekly income to wealth
    Economy.lowClassWealth = Economy.lowClassWealth + Economy.employeeWageLow * incomeLow * weeksPassed
    Economy.mediumClassWealth = Economy.mediumClassWealth + Economy.employeeWageMedium * incomeMedium * weeksPassed
    Economy.highClassWealth = Economy.highClassWealth + Economy.employeeWageHigh * incomeHigh * weeksPassed
end


function Economy.draw(x, y, currency)
    love.graphics.setColor(1, 1, 1)

    local symbol = " $" .. currency  -- e.g., " $BUCKS"

    love.graphics.print("Wealth of Low Class: " .. util.formatMoney(Economy.lowClassWealth) .. symbol, x, y)
    love.graphics.print("Wealth of Middle Class: " .. util.formatMoney(Economy.mediumClassWealth) .. symbol, x, y + 100)
    love.graphics.print("Wealth of High Class: " .. util.formatMoney(Economy.highClassWealth) .. symbol, x, y + 200)
end


return Economy
