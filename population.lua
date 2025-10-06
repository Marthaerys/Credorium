-- population version 5.0 - with skill levels (FIXED)
local Population = {}
local Food = require("industry/food")


-- Budgeting
Population.totalAvailBudget = 1200


-- Skill level distribution for new workers (when turning 18)
Population.skillDistribution = {
    low = 0.40,
    medium = 0.40,
    high = 0.20
}

-- Income class distribution per skill level
Population.incomeDistribution = {
    low = {low = 0.74, medium = 0.21, high = 0.05},
    medium = {low = 0.31, medium = 0.60, high = 0.10},
    high = {low = 0.05, medium = 0.36, high = 0.60}
}

-- Income upgrade thresholds per skill level
local upgradeThresholds = {
    low = {
        { age = 23, income = "low" },
        { age = 54, income = "medium" },
        { age = 63, income = "high" }
    },
    medium = {
        { age = 23, income = "low" },
        { age = 36, income = "medium" },
        { age = 61, income = "high" }
    },
    high = {
        { age = 23, income = "low" },
        { age = 25, income = "medium" },
        { age = 40, income = "high" }
    }
}

--unemploymeny
local unemploymentRate = 0.05
Population.unemploymentRate = unemploymentRate

-- Initial population counts
Population.total = 100000
Population.children = math.floor(Population.total * 0.30)
Population.adult = math.floor(Population.total * 0.45)
Population.retired = math.floor(Population.total * 0.25)
Population.adult_employed = 0
Population.adult_unemployed = 0

-- Birth and death rates
Population.birthrate = 0.07
local weeksPerYear = 52

-- Aim for ~1% annual population growth
Population.deathRateMultiplier = 10


-- Calculate weekly birth rate
Population.childrenGrowthPerWeek = (Population.birthrate * Population.adult) / weeksPerYear

-- Accumulator for fractional births
Population.childrenAcc = 0

-- Age ranges
local childEndAge = 17         -- 0–17
local studentStartAge = 18     -- 18–22
local studentEndAge = 22
local adultStartAge = 23     -- 23–64
local adultEndAge = 64
local retiredStartAge = 65     -- 65–99
local deathAge = 99

-- Initialize ageGroups
Population.ageGroups = {}

-- Initialize children and students (0–22)
for age = 0, studentEndAge do
    Population.ageGroups[age] = 0
end

-- Initialize adult and retired (23–99) with skill levels
for age = adultStartAge, deathAge do
    Population.ageGroups[age] = {
        low = {low = 0, medium = 0, high = 0},
        medium = {low = 0, medium = 0, high = 0},
        high = {low = 0, medium = 0, high = 0}
    }
end

-- Distribute students (18–22)
local studentCount = 0
for age = 18, 22 do
    studentCount = studentCount + Population.ageGroups[age]
end

-- Set portions
local childrenPortion = Population.children / (childEndAge + 1)
local studentPortion = studentCount / (studentEndAge - studentStartAge + 1)
local adultPortion = Population.adult / (adultEndAge - adultStartAge + 1)
local retiredPortion = Population.retired / (deathAge - retiredStartAge + 1)

-- Distribute children (0–17)
for age = 0, childEndAge do
    Population.ageGroups[age] = childrenPortion
end

-- Distribute adult adults (23–64) with income distribution
for age = adultStartAge, retiredStartAge - 1 do
    for skill, skillRatio in pairs(Population.skillDistribution) do
        local skillPop = adultPortion * skillRatio
        local incDist = Population.incomeDistribution[skill]
        
        Population.ageGroups[age][skill].low = skillPop * incDist.low
        Population.ageGroups[age][skill].medium = skillPop * incDist.medium
        Population.ageGroups[age][skill].high = skillPop * incDist.high
    end
end

-- Distribute retirees (65–99) with income distribution
for age = retiredStartAge, deathAge do
    for skill, skillRatio in pairs(Population.skillDistribution) do
        local skillPop = retiredPortion * skillRatio
        local incDist = Population.incomeDistribution[skill]
        
        Population.ageGroups[age][skill].low = skillPop * incDist.low
        Population.ageGroups[age][skill].medium = skillPop * incDist.medium
        Population.ageGroups[age][skill].high = skillPop * incDist.high
    end
end

-- Track population changes for display
Population.changes = {
    children = 0,
    adult = 0,
    retired = 0,
    -- Skill level changes
    adult_low = 0,
    adult_medium = 0,
    adult_high = 0,
    retired_low = 0,
    retired_medium = 0,
    retired_high = 0,
    --Add income level changes
    income_low = 0,
    income_medium = 0,
    income_high = 0,
    --unemployment
    adult_employed = 0,
    adult_unemployed = 0,
}

-- Store previous totals
Population.previousTotal = Population.total


--Helper: income function
function Population.getWorkingIncome()
    local income = {low = 0, medium = 0, high = 0}
    for age = adultStartAge, adultEndAge do
        for skill, incomeGroup in pairs(Population.ageGroups[age]) do
            for incomeLevel, count in pairs(incomeGroup) do
                -- Only count the employed portion
                income[incomeLevel] = income[incomeLevel] + count * (1 - Population.unemploymentRate)
            end
        end
    end
    return {
        low = math.floor(income.low),
        medium = math.floor(income.medium),
        high = math.floor(income.high)
    }
end


--Helper: assign income from skill
local function assignIncomeFromSkill(skillLevel, count)
    local assigned = {low = 0, medium = 0, high = 0}
    local dist = Population.incomeDistribution[skillLevel]

    local remaining = count
    while remaining > 0 do
        local r = math.random()
        if r < dist.low then
            assigned.low = assigned.low + 1
        elseif r < dist.low + dist.medium then
            assigned.medium = assigned.medium + 1
        else
            assigned.high = assigned.high + 1
        end
        remaining = remaining - 1
    end

    return assigned
end

-- Helper: get total population in an age group (0–99)
local function getAgeGroupTotal(group)
    if type(group) == "number" then
        return group -- For simple child/student counts
    elseif type(group) == "table" then
        local total = 0
        for _, v in pairs(group) do
            total = total + getAgeGroupTotal(v)
        end
        return total
    else
        return 0
    end
end

-- Helper: get skill breakdown for adult population
function Population.getWorkingSkills()
    local skills = {low = 0, medium = 0, high = 0}
    for age = adultStartAge, retiredStartAge - 1 do
        for skill, incomeGroup in pairs(Population.ageGroups[age]) do
            for income, count in pairs(incomeGroup) do
                skills[skill] = skills[skill] + count
            end
        end
    end
    return {
        low = math.floor(skills.low),
        medium = math.floor(skills.medium),
        high = math.floor(skills.high)
    }
end

-- Helper: get skill breakdown for retired population
function Population.getRetiredSkills()
    local skills = {low = 0, medium = 0, high = 0}
    for age = retiredStartAge, deathAge do
        for skill, incomeGroup in pairs(Population.ageGroups[age]) do
            for income, count in pairs(incomeGroup) do
                skills[skill] = skills[skill] + count
            end
        end
    end
    return {
        low = math.floor(skills.low),
        medium = math.floor(skills.medium),
        high = math.floor(skills.high)
    }
end

-- Helper: recalculate aggregate categories from age groups
function Population.recalculateTotals()
    local children, students, adult, retired = 0, 0, 0, 0

    -- Children (0–17)
    for age = 0, childEndAge do
        children = children + Population.ageGroups[age]
    end

    -- Students (18–22)
    for age = studentStartAge, studentEndAge do
        students = students + Population.ageGroups[age]
    end

    -- Working (23–64)
    for age = adultStartAge, retiredStartAge - 1 do
        adult = adult + getAgeGroupTotal(Population.ageGroups[age])
    end

    -- Retired (65–99)
    for age = retiredStartAge, deathAge do
        retired = retired + getAgeGroupTotal(Population.ageGroups[age])
    end

    Population.children = math.floor(children)
    Population.adult = math.floor(adult)
    Population.retired = math.floor(retired)
    Population.total = Population.children + Population.adult + Population.retired
    -- Split adult into employed and unemployed
    local adultSkills = Population.getWorkingSkills()
    local totalAdults = adultSkills.low + adultSkills.medium + adultSkills.high

    Population.adult_employed = math.floor((1 - Population.unemploymentRate) * totalAdults)
    Population.adult_unemployed = totalAdults - Population.adult_employed

end

-- Helper: assign skill levels to new 18-year-olds
local function assignSkillLevels(newWorkers)
    local assigned = {low = 0, medium = 0, high = 0}
    local remaining = newWorkers
    
    -- Use random assignment based on distribution
    while remaining > 0 do
        local rand = math.random()
        if rand < Population.skillDistribution.low then
            assigned.low = assigned.low + 1
        elseif rand < Population.skillDistribution.low + Population.skillDistribution.medium then
            assigned.medium = assigned.medium + 1
        else
            assigned.high = assigned.high + 1
        end
        remaining = remaining - 1
    end
    
    return assigned
end

-- Main update function
function Population.updateByWeeks(weeksPassed)
    if weeksPassed <= 0 then return end
    
    -- Store previous totals for change calculation
    Population.previousTotal = Population.total
    local prevChildren = Population.children
    local prevWorking = Population.adult
    local prevRetired = Population.retired
    local prevWorkingSkills = Population.getWorkingSkills()
    local prevWorkingIncome = Population.getWorkingIncome()
    local prevAdultTotal = prevWorkingSkills.low + prevWorkingSkills.medium + prevWorkingSkills.high
    local prevEmployed = math.floor((1 - Population.unemploymentRate) * prevAdultTotal)
    local prevUnemployed = prevAdultTotal - prevEmployed
    
    -- Process each week individually
    for week = 1, weeksPassed do
        -- 1. Add new births
        local childIncrease = (Population.birthrate * Population.adult) / weeksPerYear
        Population.childrenAcc = Population.childrenAcc + childIncrease
        local childrenIncreaseInt = math.floor(Population.childrenAcc)
        Population.childrenAcc = Population.childrenAcc - childrenIncreaseInt
        Population.ageGroups[0] = Population.ageGroups[0] + childrenIncreaseInt
        
        -- 2. Apply deaths (ages 30-99) - FIXED VERSION
        for age = 30, 99 do
            local currentGroup = Population.ageGroups[age]

            -- Only process if this is a structured age group (23+)
            if type(currentGroup) == "table" and currentGroup.low and currentGroup.medium and currentGroup.high then
                -- Compute death rate per age
                local annualDeathRate = Population.deathRateMultiplier * 1e-5 * 2^((age - 30) / 10)
                local weeklyDeathRate = annualDeathRate / weeksPerYear

                -- Calculate total population in this age group
                local totalPop = 0
                for skill, incomeGroup in pairs(currentGroup) do
                    for income, count in pairs(incomeGroup) do
                        totalPop = totalPop + count
                    end
                end

                if totalPop > 0 then
                    local totalDeaths = totalPop * weeklyDeathRate
                    totalDeaths = math.min(totalDeaths, totalPop)

                    -- Apply deaths proportionally across all skill/income combinations
                    for skill, incomeGroup in pairs(currentGroup) do
                        for income, count in pairs(incomeGroup) do
                            if count > 0 then
                                local share = (count / totalPop) * totalDeaths
                                incomeGroup[income] = math.max(0, count - share)
                            end
                        end
                    end
                end
            end
        end

        -- 3. Age everyone by 1/52 of a year
        local agingFraction = 1 / weeksPerYear
        local newAgeGroups = {}
        
        -- Initialize new age groups
        for age = 0, studentEndAge do
            newAgeGroups[age] = 0
        end
        for age = adultStartAge, deathAge do
            newAgeGroups[age] = {
                low = {low = 0, medium = 0, high = 0},
                medium = {low = 0, medium = 0, high = 0},
                high = {low = 0, medium = 0, high = 0}
            }
        end
        
        -- Age children and students (0-22)
        for age = 0, studentEndAge do
            local currentPop = Population.ageGroups[age]
            local agingOut = currentPop * agingFraction
            local stayingPut = currentPop - agingOut

            newAgeGroups[age] = newAgeGroups[age] + stayingPut

            if age < studentEndAge then
                newAgeGroups[age + 1] = newAgeGroups[age + 1] + agingOut
            elseif age == studentEndAge then
                -- At 23: assign skill levels and income classes
                local newWorkers = math.floor(agingOut)
                if newWorkers > 0 then
                    local skillAssignment = assignSkillLevels(newWorkers)

                    for skill, count in pairs(skillAssignment) do
                        local incomeAssignment = assignIncomeFromSkill(skill, count)
                        for income, subcount in pairs(incomeAssignment) do
                            newAgeGroups[23][skill][income] = newAgeGroups[23][skill][income] + subcount
                        end
                    end
                end
            end
        end
        
        -- Age adults (23–99)
        for age = adultStartAge, deathAge do
            local currentGroup = Population.ageGroups[age]
            
            for skill, incomeGroup in pairs(currentGroup) do
                for income, count in pairs(incomeGroup) do
                    local agingOut = count * agingFraction
                    local stayingPut = count - agingOut
                    
                    newAgeGroups[age][skill][income] = newAgeGroups[age][skill][income] + stayingPut
                    
                    if age < 99 then
                        newAgeGroups[age + 1][skill][income] = newAgeGroups[age + 1][skill][income] + agingOut
                    end
                end
            end
        end
        
        -- Update age groups
        Population.ageGroups = newAgeGroups
    end
    
    -- 4. Apply income upgrades based on skill and age
    for age = adultStartAge, adultEndAge do
        for skill, incomeGroup in pairs(Population.ageGroups[age]) do
            for _, rule in ipairs(upgradeThresholds[skill]) do
                if age >= rule.age then
                    -- Upgrade everyone below target income to that income
                    for income, count in pairs(incomeGroup) do
                        local upgradeRanks = { low = 1, medium = 2, high = 3 }
                        if upgradeRanks[income] < upgradeRanks[rule.income] then
                            incomeGroup[rule.income] = incomeGroup[rule.income] + count
                            incomeGroup[income] = 0
                        end
                    end
                end
            end
        end
    end

    -- SUPPLY AND DEMAND
    Population.totalAvailBudget = Food.availBudget --Add more later
    Population.foodDemand = (Population.children * 8) + (Population.adult * 1) + (Population.retired * 0.7)

    -- Recalculate totals
    Population.recalculateTotals()
    
    -- Calculate changes
    Population.changes.children = Population.children - prevChildren
    Population.changes.adult = Population.adult - prevWorking
    Population.changes.retired = Population.retired - prevRetired
    
    local currentWorkingSkills = Population.getWorkingSkills()
    local currentRetiredSkills = Population.getRetiredSkills()
    local currentWorkingIncome = Population.getWorkingIncome()
    
    Population.changes.adult_low = currentWorkingSkills.low - prevWorkingSkills.low
    Population.changes.adult_medium = currentWorkingSkills.medium - prevWorkingSkills.medium
    Population.changes.adult_high = currentWorkingSkills.high - prevWorkingSkills.high

    Population.changes.income_low = currentWorkingIncome.low - prevWorkingIncome.low
    Population.changes.income_medium = currentWorkingIncome.medium - prevWorkingIncome.medium
    Population.changes.income_high = currentWorkingIncome.high - prevWorkingIncome.high

    Population.changes.adult_employed = Population.adult_employed - prevEmployed
    Population.changes.adult_unemployed = Population.adult_unemployed - prevUnemployed 
end


-- Get weekly and yearly change rates for display
function Population.getChanges()
    local totalChange = Population.total - Population.previousTotal
    return {
        -- Weekly changes
        children_week = Population.changes.children,
        adult_week = Population.changes.adult,
        retired_week = Population.changes.retired,
        total_week = totalChange,
        total_week_percent = (totalChange / Population.previousTotal) * 100,
        
        -- Yearly projections
        children_year = Population.changes.children * 52,
        adult_year = Population.changes.adult * 52,
        retired_year = Population.changes.retired * 52,
        total_year = totalChange * 52,
        total_year_percent = ((totalChange * 52) / Population.previousTotal) * 100,
        
        -- Skill level changes
        adult_low_week = Population.changes.adult_low,
        adult_medium_week = Population.changes.adult_medium,
        adult_high_week = Population.changes.adult_high,
        retired_low_week = Population.changes.retired_low,
        retired_medium_week = Population.changes.retired_medium,
        retired_high_week = Population.changes.retired_high,

        --Income changes
        income_low_week = Population.changes.income_low,
        income_medium_week = Population.changes.income_medium,
        income_high_week = Population.changes.income_high,
    }
end

-- Enhanced draw function with skill level breakdown
function Population.draw(x, y, width, height)
    local lh = 80 -- Line height
    local currentY = y + 40

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Population Overview", x, currentY, width, "center")
    currentY = currentY + lh * 1.2

    -- Column headers at same positions as v4.0
    love.graphics.printf("Group",  x + 100,  currentY, 300, "left")
    love.graphics.printf("Value",  x + 500,  currentY, 300, "left")
    love.graphics.printf("/week",  x + 900,  currentY, 300, "left")
    love.graphics.printf("/year",  x + 1300, currentY, 300, "left")
    currentY = currentY + lh

    -- Get changes
    local c = Population.getChanges()

    -- Helper to draw a row of data (same as v4.0)
    local function drawRow(label, base, deltaW, percentW, deltaY, percentY)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(label, x + 100, currentY, 400, "left")
        love.graphics.printf(base,  x + 500, currentY, 400, "left")

        local function fmt(n, p)
            local sign = n > 0 and "+" or ""
            return string.format("%s%d (%.1f%%)", sign, n, p)
        end

        -- Weekly change
        love.graphics.setColor(deltaW > 0 and {0, 0.8, 0} or deltaW < 0 and {0.8, 0, 0} or {0.6, 0.6, 0.6})
        love.graphics.printf(fmt(deltaW, percentW), x + 900, currentY, 400, "left")

        -- Yearly change
        love.graphics.setColor(deltaY > 0 and {0, 0.8, 0} or deltaY < 0 and {0.8, 0, 0} or {0.6, 0.6, 0.6})
        love.graphics.printf(fmt(deltaY, percentY), x + 1300, currentY, 400, "left")

        currentY = currentY + lh
    end

    -- Draw main population rows (same as v4.0)
    drawRow("Total",    Population.total,   c.total_week,   c.total_week_percent,   c.total_year,   c.total_year_percent)
    drawRow("Children", Population.children, c.children_week, 100 * c.children_week / math.max(Population.children, 1),
                                             c.children_year, 100 * c.children_year / math.max(Population.children, 1))
    drawRow("Adults",  Population.adult,  c.adult_week, 100 * c.adult_week / math.max(Population.adult, 1),
                                             c.adult_year, 100 * c.adult_year / math.max(Population.adult, 1))
    drawRow("Retired",  Population.retired,  c.retired_week, 100 * c.retired_week / math.max(Population.retired, 1),
                                             c.retired_year, 100 * c.retired_year / math.max(Population.retired, 1))
    
    -- Add adult skill breakdown
    currentY = currentY + lh * 0.5 -- Half line spacing
    
    local adultSkills = Population.getWorkingSkills()
    
    drawRow("Low Skill",  adultSkills.low,    c.adult_low_week,    100 * c.adult_low_week / math.max(adultSkills.low, 1),
                                                  c.adult_low_week * 52, 100 * c.adult_low_week * 52 / math.max(adultSkills.low, 1))
    drawRow("Med Skill",  adultSkills.medium, c.adult_medium_week, 100 * c.adult_medium_week / math.max(adultSkills.medium, 1),
                                                  c.adult_medium_week * 52, 100 * c.adult_medium_week * 52 / math.max(adultSkills.medium, 1))
    drawRow("High Skill", adultSkills.high,   c.adult_high_week,   100 * c.adult_high_week / math.max(adultSkills.high, 1),
                                                  c.adult_high_week * 52, 100 * c.adult_high_week * 52 / math.max(adultSkills.high, 1))

    -- Add income breakdown
    currentY = currentY + lh * 0.5 -- Half line spacing

    local adultIncome = Population.getWorkingIncome()

    drawRow("Low Income",  adultIncome.low,    c.income_low_week,    100 * c.income_low_week / math.max(adultIncome.low, 1),
                                                c.income_low_week * 52, 100 * c.income_low_week * 52 / math.max(adultIncome.low, 1))
    drawRow("Med Income",  adultIncome.medium, c.income_medium_week, 100 * c.income_medium_week / math.max(adultIncome.medium, 1),
                                                c.income_medium_week * 52, 100 * c.income_medium_week * 52 / math.max(adultIncome.medium, 1))
    drawRow("High Income", adultIncome.high,   c.income_high_week,   100 * c.income_high_week / math.max(adultIncome.high, 1),
                                                c.income_high_week * 52, 100 * c.income_high_week * 52 / math.max(adultIncome.high, 1))
    drawRow("Unemployed", Population.adult_unemployed or 0, c.adult_unemployed or 0, 0, (c.adult_unemployed or 0) * 52, 0)
end

return Population