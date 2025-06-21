-- population version 2.0
local Population = {}

-- Initial population counts
Population.total = 100000
Population.children = math.floor(Population.total * 0.23)
Population.working = math.floor(Population.total * 0.60)
Population.retired = math.floor(Population.total * 0.17)

-- Birth and death rates
Population.birthrate = 0.1
local weeksPerYear = 52

-- Death rate multiplier - adjust this to control overall death rates
-- Lower values = less deaths, higher population growth
-- Aim for ~1% annual population growth, so try values like 0.3-0.8
Population.deathRateMultiplier = 0.08

-- Calculate weekly birth rate
Population.childrenGrowthPerWeek = (Population.birthrate * Population.working) / weeksPerYear

-- Accumulator for fractional births
Population.childrenAcc = 0

-- Age groups 0-99 (changed from 0-100 to 0-99)
Population.ageGroups = {}
for i = 0, 99 do
    Population.ageGroups[i] = 0
end

-- Initialize age groups roughly matching children/working/retired split
-- Children 0-17, working 18-64, retired 65-99
local childrenPortion = Population.children / 18
local workingPortion = Population.working / (64 - 18 + 1)
local retiredPortion = Population.retired / (99 - 65 + 1)

for age = 0, 17 do
    Population.ageGroups[age] = childrenPortion
end
for age = 18, 64 do
    Population.ageGroups[age] = workingPortion
end
for age = 65, 99 do
    Population.ageGroups[age] = retiredPortion
end

-- Track population changes for display
Population.changes = {
    children = 0,      -- net change per week
    working = 0,       -- net change per week
    retired = 0,       -- net change per week
    births = 0,        -- births per week
    deaths = 0         -- deaths per week
}

-- Store previous total for growth rate calculation
Population.previousTotal = Population.total

-- Helper: recalculate aggregate categories from age groups
function Population.recalculateTotals()
    local children, working, retired = 0, 0, 0
    for age = 0, 17 do children = children + Population.ageGroups[age] end
    for age = 18, 64 do working = working + Population.ageGroups[age] end
    for age = 65, 99 do retired = retired + Population.ageGroups[age] end

    Population.children = math.floor(children)
    Population.working = math.floor(working)
    Population.retired = math.floor(retired)
    Population.total = Population.children + Population.working + Population.retired
end

-- Main update function - now processes weekly with fractional aging and linear death distribution
function Population.updateByWeeks(weeksPassed)
    if weeksPassed <= 0 then return end
    
    -- Store previous totals for change calculation
    Population.previousTotal = Population.total
    local prevChildren = Population.children
    local prevWorking = Population.working
    local prevRetired = Population.retired
    
    -- Process each week individually for more accurate simulation
    for week = 1, weeksPassed do
        -- 1. Add new births
        local childIncrease = Population.childrenGrowthPerWeek
        Population.childrenAcc = Population.childrenAcc + childIncrease
        local childrenIncreaseInt = math.floor(Population.childrenAcc)
        Population.childrenAcc = Population.childrenAcc - childrenIncreaseInt
        Population.ageGroups[0] = Population.ageGroups[0] + childrenIncreaseInt
        
        -- 2. Apply deaths with linear age-based probability
        local totalDeaths = 0
        for age = 0, 99 do
            -- Linear death rate: age 1 = 1% annually, age 80 = 80% annually, etc.
            -- Multiply by deathRateMultiplier to control overall death rates
            local annualDeathRate = math.max(0.01, age / 100) * Population.deathRateMultiplier
            local weeklyDeathRate = annualDeathRate / weeksPerYear
            
            local deaths = Population.ageGroups[age] * weeklyDeathRate
            deaths = math.min(deaths, Population.ageGroups[age]) -- can't die more than exist
            
            Population.ageGroups[age] = Population.ageGroups[age] - deaths
            totalDeaths = totalDeaths + deaths
        end
        
        -- 3. Age everyone by 1/52 of a year (weekly aging)
        -- Move 1/52 of each age group to the next age group
        local agingFraction = 1 / weeksPerYear
        local newAgeGroups = {}
        
        -- Initialize new age groups
        for i = 0, 99 do
            newAgeGroups[i] = 0
        end
        
        -- Age people gradually
        for age = 0, 99 do
            local currentPop = Population.ageGroups[age]
            local agingOut = currentPop * agingFraction
            local stayingPut = currentPop - agingOut
            
            -- People staying in current age
            newAgeGroups[age] = newAgeGroups[age] + stayingPut
            
            -- People aging to next group (if not at max age)
            if age < 99 then
                newAgeGroups[age + 1] = newAgeGroups[age + 1] + agingOut
            end
            -- People at age 99 who age out simply disappear (natural death from old age)
        end
        
        Population.ageGroups = newAgeGroups
        
        -- Track births and deaths for this week
        Population.changes.births = childrenIncreaseInt
        Population.changes.deaths = totalDeaths
    end
    
    -- Recalculate totals after all weeks processed
    Population.recalculateTotals()
    
    -- Calculate net changes by category (total change over all weeks)
    Population.changes.children = Population.children - prevChildren
    Population.changes.working = Population.working - prevWorking
    Population.changes.retired = Population.retired - prevRetired
end

-- Get daily change rates for display (divide weekly changes by 7)
function Population.getDailyChanges()
    return {
        children = Population.changes.children / 7,
        working = Population.changes.working / 7,
        retired = Population.changes.retired / 7,
        births = Population.changes.births / 7,
        deaths = Population.changes.deaths / 7,
        totalChange = (Population.total - Population.previousTotal) / 7,
        totalChangePercent = ((Population.total - Population.previousTotal) / Population.previousTotal) * 100 / 7 -- daily percent change
    }
end

-- Enhanced draw function with change rates
function Population.draw(x, y, width, height)
    local lh = 80  -- line height
    local currentY = y + 40

    love.graphics.printf("Population Overview", x, currentY, width, "center")
    currentY = currentY + lh * 1.2

    -- Get daily changes for display
    local dailyChanges = Population.getDailyChanges()
    
    -- Helper function to set color based on change value
    local function setChangeColor(change)
        if change > 0 then
            love.graphics.setColor(0, 0.8, 0) -- Green for growth
        elseif change < 0 then
            love.graphics.setColor(0.8, 0, 0) -- Red for decline
        else
            love.graphics.setColor(0.6, 0.6, 0.6) -- Gray for no change
        end
    end
    
    -- Helper function to format change text
    local function formatChange(change, isPercent)
        if isPercent then
            if change > 0 then
                return string.format(" (+%.3f%%)", change)
            elseif change < 0 then
                return string.format(" (%.3f%%)", change)
            else
                return " (0%)"
            end
        else
            if change > 0 then
                return string.format(" (+%.1f)", change)
            elseif change < 0 then
                return string.format(" (%.1f)", change)
            else
                return " (0)"
            end
        end
    end

    -- Current population with total change
    love.graphics.setColor(1, 1, 1) -- White for main text
    love.graphics.printf(string.format("Total: %d", Population.total), x + 20, currentY, width - 40, "left")
    
    -- Add total change info in smaller text
    setChangeColor(dailyChanges.totalChange)
    love.graphics.printf(formatChange(dailyChanges.totalChange, false) .. "/day " .. formatChange(dailyChanges.totalChangePercent, true) .. "/day", x + 400, currentY + 5, width - 180, "left")
    currentY = currentY + lh

    -- Children with daily change
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(string.format("Children: %d", Population.children), x + 20, currentY, width - 40, "left")
    setChangeColor(dailyChanges.children)
    love.graphics.printf(formatChange(dailyChanges.children, false) .. "/day", x + 800, currentY + 5, width - 240, "left")
    currentY = currentY + lh

    -- Working with daily change
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(string.format("Working: %d", Population.working), x + 20, currentY, width - 40, "left")
    setChangeColor(dailyChanges.working)
    love.graphics.printf(formatChange(dailyChanges.working, false) .. "/day", x + 800, currentY + 5, width - 240, "left")
    currentY = currentY + lh

    -- Retired with daily change
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(string.format("Retired: %d", Population.retired), x + 20, currentY, width - 40, "left")
    setChangeColor(dailyChanges.retired)
    love.graphics.printf(formatChange(dailyChanges.retired, false) .. "/day", x + 800, currentY + 5, width - 240, "left")
    currentY = currentY + lh * 1.2

    -- Birth and death rates
    love.graphics.setColor(0, 0.8, 0) -- Green for births
    love.graphics.printf(string.format("Births: %.1f/day", dailyChanges.births), x + 20, currentY, width - 40, "left")
    currentY = currentY + lh * 0.8
    love.graphics.setColor(0.8, 0, 0) -- Red for deaths
    love.graphics.printf(string.format("Deaths: %.1f/day", dailyChanges.deaths), x + 20, currentY, width - 40, "left")
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

return Population