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
Population.deathRateMultiplier = 0.1

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
        -- Calculate births based on CURRENT working population:
        local childIncrease = (Population.birthrate * Population.working) / weeksPerYear
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
        Population.totals = {
            children = 0,
            working = 0,
            retired = 0
        }

        for age = 0, 99 do
            local count = Population.ageGroups[age]
            if age <= 17 then
                Population.totals.children = Population.totals.children + count
            elseif age <= 64 then
                Population.totals.working = Population.totals.working + count
            else
                Population.totals.retired = Population.totals.retired + count
            end
        end
        
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
        
        -- Yearly projections (weekly × 52)
        children_year = Population.changes.children * 52,
        working_year = Population.changes.working * 52,
        retired_year = Population.changes.retired * 52,
        total_year = totalChange * 52,
        total_year_percent = ((totalChange * 52) / Population.previousTotal) * 100,
        
        births_week = Population.changes.births,
        deaths_week = Population.changes.deaths
    }
end

-- Enhanced draw function with change rates
function Population.draw(x, y, width, height)
    local lh = 80 -- Line height
    local currentY = y + 40

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Population Overview", x, currentY, width, "center")
    currentY = currentY + lh * 1.2

    -- Column headers at 100, 400, 700, 1000
    love.graphics.printf("Group",  x + 100,  currentY, 300, "left")
    love.graphics.printf("Value",  x + 500,  currentY, 300, "left")
    love.graphics.printf("/week",  x + 900,  currentY, 300, "left")
    love.graphics.printf("/year",  x + 1300, currentY, 300, "left")
    currentY = currentY + lh

    -- Get changes
    local c = Population.getChanges()

    -- Helper to draw a row of data
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

    -- Draw each row
    drawRow("Total",    Population.total,   c.total_week,   c.total_week_percent,   c.total_year,   c.total_year_percent)
    drawRow("Children", Population.children, c.children_week, 100 * c.children_week / math.max(Population.children, 1),
                                             c.children_year, 100 * c.children_year / math.max(Population.children, 1))
    drawRow("Working",  Population.working,  c.working_week, 100 * c.working_week / math.max(Population.working, 1),
                                             c.working_year, 100 * c.working_year / math.max(Population.working, 1))
    drawRow("Retired",  Population.retired,  c.retired_week, 100 * c.retired_week / math.max(Population.retired, 1),
                                             c.retired_year, 100 * c.retired_year / math.max(Population.retired, 1))
end



return Population