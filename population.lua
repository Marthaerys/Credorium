-- population version 5.0 - with skill levels
local Population = {}

-- Skill level distribution for new workers (when turning 18)
Population.skillDistribution = {
    low = 0.40,
    medium = 0.40,
    high = 0.20
}

-- Initial population counts
Population.total = 100000
Population.children = math.floor(Population.total * 0.23)
Population.working = math.floor(Population.total * 0.60)
Population.retired = math.floor(Population.total * 0.17)

-- Birth and death rates
Population.birthrate = 0.035
local weeksPerYear = 52

-- Aim for ~1% annual population growth
Population.deathRateMultiplier = 100

-- Calculate weekly birth rate
Population.childrenGrowthPerWeek = (Population.birthrate * Population.working) / weeksPerYear

-- Accumulator for fractional births
Population.childrenAcc = 0

-- For ages 0-17: no skill levels (just a number)
-- For ages 18-99: each age has {low, medium, high} skill breakdown
Population.ageGroups = {}

-- Initialize children (ages 0-17) - no skill levels yet
for age = 0, 17 do
    Population.ageGroups[age] = 0
end

-- Initialize working and retired (ages 18-99) with skill levels
-- All initially assigned as low skill as per requirements
for age = 18, 99 do
    Population.ageGroups[age] = {
        low = 0,
        medium = 0,
        high = 0
    }
end

-- Set initial distribution
local childrenPortion = Population.children / 18
local workingPortion = Population.working / (64 - 18 + 1)
local retiredPortion = Population.retired / (99 - 65 + 1)

-- Children (0-17) - simple numbers
for age = 0, 17 do
    Population.ageGroups[age] = childrenPortion
end

-- Working age (18–64) - follow skill distribution
for age = 18, 64 do
    Population.ageGroups[age].low = workingPortion * Population.skillDistribution.low
    Population.ageGroups[age].medium = workingPortion * Population.skillDistribution.medium
    Population.ageGroups[age].high = workingPortion * Population.skillDistribution.high
end

-- Retired (65–99) - follow skill distribution
for age = 65, 99 do
    Population.ageGroups[age].low = retiredPortion * Population.skillDistribution.low
    Population.ageGroups[age].medium = retiredPortion * Population.skillDistribution.medium
    Population.ageGroups[age].high = retiredPortion * Population.skillDistribution.high
end


-- Track population changes for display
Population.changes = {
    children = 0,
    working = 0,
    retired = 0,
    -- Skill level changes
    working_low = 0,
    working_medium = 0,
    working_high = 0,
    retired_low = 0,
    retired_medium = 0,
    retired_high = 0,
}

-- Store previous totals
Population.previousTotal = Population.total

-- Helper: get total population in an age group (18-99)
local function getAgeGroupTotal(ageGroup)
    if type(ageGroup) == "number" then
        return ageGroup -- Children ages 0-17
    else
        return ageGroup.low + ageGroup.medium + ageGroup.high
    end
end

-- Helper: get skill breakdown for working population
function Population.getWorkingSkills()
    local skills = {low = 0, medium = 0, high = 0}
    for age = 18, 64 do
        skills.low = skills.low + Population.ageGroups[age].low
        skills.medium = skills.medium + Population.ageGroups[age].medium
        skills.high = skills.high + Population.ageGroups[age].high
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
    for age = 65, 99 do
        skills.low = skills.low + Population.ageGroups[age].low
        skills.medium = skills.medium + Population.ageGroups[age].medium
        skills.high = skills.high + Population.ageGroups[age].high
    end
    return {
        low = math.floor(skills.low),
        medium = math.floor(skills.medium),
        high = math.floor(skills.high)
    }
end

-- Helper: recalculate aggregate categories from age groups
function Population.recalculateTotals()
    local children, working, retired = 0, 0, 0
    
    -- Children (0-17)
    for age = 0, 17 do 
        children = children + Population.ageGroups[age] 
    end
    
    -- Working (18-64)
    for age = 18, 64 do 
        working = working + getAgeGroupTotal(Population.ageGroups[age])
    end
    
    -- Retired (65-99)
    for age = 65, 99 do 
        retired = retired + getAgeGroupTotal(Population.ageGroups[age])
    end

    Population.children = math.floor(children)
    Population.working = math.floor(working)
    Population.retired = math.floor(retired)
    Population.total = Population.children + Population.working + Population.retired
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
    local prevWorking = Population.working
    local prevRetired = Population.retired
    local prevWorkingSkills = Population.getWorkingSkills()
    local prevRetiredSkills = Population.getRetiredSkills()
    
    -- Process each week individually
    for week = 1, weeksPassed do
        -- 1. Add new births
        local childIncrease = (Population.birthrate * Population.working) / weeksPerYear
        Population.childrenAcc = Population.childrenAcc + childIncrease
        local childrenIncreaseInt = math.floor(Population.childrenAcc)
        Population.childrenAcc = Population.childrenAcc - childrenIncreaseInt
        Population.ageGroups[0] = Population.ageGroups[0] + childrenIncreaseInt
        
        -- 2. Apply deaths (ages 30-99)
        for age = 30, 99 do
            local annualDeathRate = Population.deathRateMultiplier * 1e-5 * 2^((age - 30) / 10)
            local weeklyDeathRate = annualDeathRate / weeksPerYear
            
            if age <= 17 then
                -- Children (shouldn't happen since we start at age 30)
                local deaths = Population.ageGroups[age] * weeklyDeathRate
                deaths = math.min(deaths, Population.ageGroups[age])
                Population.ageGroups[age] = Population.ageGroups[age] - deaths
            else
                -- Adults with skill levels
                local currentGroup = Population.ageGroups[age]
                local totalPop = getAgeGroupTotal(currentGroup)
                
                if totalPop > 0 then
                    local deaths = totalPop * weeklyDeathRate
                    deaths = math.min(deaths, totalPop)
                    
                    -- Distribute deaths proportionally across skill levels
                    local deathsLow = (currentGroup.low / totalPop) * deaths
                    local deathsMedium = (currentGroup.medium / totalPop) * deaths
                    local deathsHigh = (currentGroup.high / totalPop) * deaths
                    
                    currentGroup.low = math.max(0, currentGroup.low - deathsLow)
                    currentGroup.medium = math.max(0, currentGroup.medium - deathsMedium)
                    currentGroup.high = math.max(0, currentGroup.high - deathsHigh)
                end
            end
        end
        
        -- 3. Age everyone by 1/52 of a year
        local agingFraction = 1 / weeksPerYear
        local newAgeGroups = {}
        
        -- Initialize new age groups
        for age = 0, 17 do
            newAgeGroups[age] = 0
        end
        for age = 18, 99 do
            newAgeGroups[age] = {low = 0, medium = 0, high = 0}
        end
        
        -- Age children (0-17)
        for age = 0, 17 do
            local currentPop = Population.ageGroups[age]
            local agingOut = currentPop * agingFraction
            local stayingPut = currentPop - agingOut
            
            newAgeGroups[age] = newAgeGroups[age] + stayingPut
            
            if age < 17 then
                -- Age to next child age
                newAgeGroups[age + 1] = newAgeGroups[age + 1] + agingOut
            elseif age == 17 then
                -- Age to 18 - assign skill levels!
                local newWorkers = math.floor(agingOut)
                if newWorkers > 0 then
                    local skillAssignment = assignSkillLevels(newWorkers)
                    newAgeGroups[18].low = newAgeGroups[18].low + skillAssignment.low
                    newAgeGroups[18].medium = newAgeGroups[18].medium + skillAssignment.medium
                    newAgeGroups[18].high = newAgeGroups[18].high + skillAssignment.high
                end
            end
        end
        
        -- Age adults (18-99)
        for age = 18, 99 do
            local currentGroup = Population.ageGroups[age]
            
            for skill, pop in pairs(currentGroup) do
                local agingOut = pop * agingFraction
                local stayingPut = pop - agingOut
                
                newAgeGroups[age][skill] = newAgeGroups[age][skill] + stayingPut
                
                if age < 99 then
                    newAgeGroups[age + 1][skill] = newAgeGroups[age + 1][skill] + agingOut
                end
            end
        end
        
        -- Update age groups
        Population.ageGroups = newAgeGroups
    end
    
    -- Recalculate totals
    Population.recalculateTotals()
    
    -- Calculate changes
    Population.changes.children = Population.children - prevChildren
    Population.changes.working = Population.working - prevWorking
    Population.changes.retired = Population.retired - prevRetired
    
    local currentWorkingSkills = Population.getWorkingSkills()
    local currentRetiredSkills = Population.getRetiredSkills()
    
    Population.changes.working_low = currentWorkingSkills.low - prevWorkingSkills.low
    Population.changes.working_medium = currentWorkingSkills.medium - prevWorkingSkills.medium
    Population.changes.working_high = currentWorkingSkills.high - prevWorkingSkills.high
    
    Population.changes.retired_low = currentRetiredSkills.low - prevRetiredSkills.low
    Population.changes.retired_medium = currentRetiredSkills.medium - prevRetiredSkills.medium
    Population.changes.retired_high = currentRetiredSkills.high - prevRetiredSkills.high
end

-- Get weekly and yearly change rates for display
function Population.getChanges()
    local totalChange = Population.total - Population.previousTotal
    return {
        -- Weekly changes
        children_week = Population.changes.children,
        working_week = Population.changes.working,
        retired_week = Population.changes.retired,
        total_week = totalChange,
        total_week_percent = (totalChange / Population.previousTotal) * 100,
        
        -- Yearly projections
        children_year = Population.changes.children * 52,
        working_year = Population.changes.working * 52,
        retired_year = Population.changes.retired * 52,
        total_year = totalChange * 52,
        total_year_percent = ((totalChange * 52) / Population.previousTotal) * 100,
        
        -- Skill level changes
        working_low_week = Population.changes.working_low,
        working_medium_week = Population.changes.working_medium,
        working_high_week = Population.changes.working_high,
        retired_low_week = Population.changes.retired_low,
        retired_medium_week = Population.changes.retired_medium,
        retired_high_week = Population.changes.retired_high,
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
    drawRow("Working",  Population.working,  c.working_week, 100 * c.working_week / math.max(Population.working, 1),
                                             c.working_year, 100 * c.working_year / math.max(Population.working, 1))
    drawRow("Retired",  Population.retired,  c.retired_week, 100 * c.retired_week / math.max(Population.retired, 1),
                                             c.retired_year, 100 * c.retired_year / math.max(Population.retired, 1))
    
    -- Add working skill breakdown
    currentY = currentY + lh * 0.5 -- Half line spacing
    
    local workingSkills = Population.getWorkingSkills()
    
    drawRow("├ Low Skill",  workingSkills.low,    c.working_low_week,    100 * c.working_low_week / math.max(workingSkills.low, 1),
                                                  c.working_low_week * 52, 100 * c.working_low_week * 52 / math.max(workingSkills.low, 1))
    drawRow("├ Med Skill",  workingSkills.medium, c.working_medium_week, 100 * c.working_medium_week / math.max(workingSkills.medium, 1),
                                                  c.working_medium_week * 52, 100 * c.working_medium_week * 52 / math.max(workingSkills.medium, 1))
    drawRow("└ High Skill", workingSkills.high,   c.working_high_week,   100 * c.working_high_week / math.max(workingSkills.high, 1),
                                                  c.working_high_week * 52, 100 * c.working_high_week * 52 / math.max(workingSkills.high, 1))
end

return Population