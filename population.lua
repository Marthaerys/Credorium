local Population = {}

-- Initial population counts
Population.total = 100000
Population.children = math.floor(Population.total * 0.23)
Population.working = math.floor(Population.total * 0.60)
Population.retired = math.floor(Population.total * 0.17)

-- Birth and death rates
Population.birthrate = 0.033
Population.deathrate = 0.059
local weeksPerYear = 52

-- Calculate weekly growth/death rates (used in old calculation)
Population.childrenGrowthPerWeek = (Population.birthrate * Population.working) / weeksPerYear
Population.elderlyDeathPerWeek = (Population.deathrate * Population.retired) / weeksPerYear

Population.childrenAcc = 0
Population.retiredAcc = 0

-- Age groups 0-100, each element = count of people age i
Population.ageGroups = {}
for i = 0, 100 do
    Population.ageGroups[i] = 0
end

-- Initialize age groups roughly matching children/working/retired split
-- For simplicity: children 0-17, working 18-64, retired 65-100
local childrenPortion = Population.children / 18
local workingPortion = Population.working / (64 - 18 + 1)
local retiredPortion = Population.retired / (100 - 65 + 1)

for age = 0, 17 do
    Population.ageGroups[age] = childrenPortion
end
for age = 18, 64 do
    Population.ageGroups[age] = workingPortion
end
for age = 65, 100 do
    Population.ageGroups[age] = retiredPortion
end

-- Helper: recalc aggregate categories from age groups
function Population.recalculateTotals()
    local children, working, retired = 0, 0, 0
    for age = 0, 17 do children = children + Population.ageGroups[age] end
    for age = 18, 64 do working = working + Population.ageGroups[age] end
    for age = 65, 100 do retired = retired + Population.ageGroups[age] end

    Population.children = math.floor(children)
    Population.working = math.floor(working)
    Population.retired = math.floor(retired)
    Population.total = Population.children + Population.working + Population.retired
end

-- The old update logic from your working code integrated into this function
function Population.updateByWeeks(weeksPassed)
    if weeksPassed <= 0 then return end

    -- Add new children (births)
    local childIncrease = Population.childrenGrowthPerWeek * weeksPassed
    Population.childrenAcc = Population.childrenAcc + childIncrease
    local childrenIncreaseInt = math.floor(Population.childrenAcc)
    Population.childrenAcc = Population.childrenAcc - childrenIncreaseInt
    -- Add newborns to age 0 group
    Population.ageGroups[0] = Population.ageGroups[0] + childrenIncreaseInt

    -- Deaths mostly in older groups (simple linear death probability increasing with age)
    local totalDeaths = 0
    local deathRatePerAge = {}
    for age = 0, 100 do
        deathRatePerAge[age] = (age / 100) * Population.deathrate / weeksPerYear
    end

    for age = 100, 0, -1 do
        local deaths = Population.ageGroups[age] * deathRatePerAge[age] * weeksPassed
        if deaths > Population.ageGroups[age] then deaths = Population.ageGroups[age] end
        Population.ageGroups[age] = Population.ageGroups[age] - deaths
        totalDeaths = totalDeaths + deaths
    end

    -- Age everyone by the number of weeks (in years, 1 year = 52 weeks)
    local yearsPassed = weeksPassed / weeksPerYear
    -- For simplicity, age groups shift only when a full year passes
    local wholeYears = math.floor(yearsPassed)
    if wholeYears > 0 then
        for _ = 1, wholeYears do
            -- Shift ages up by 1 year
            for age = 100, 1, -1 do
                Population.ageGroups[age] = Population.ageGroups[age - 1]
            end
            Population.ageGroups[0] = 0 -- newborns added separately above
        end
    end

    Population.recalculateTotals()
end

-- Optional: simple draw function for debugging
function Population.draw(x, y, width, height)
    local lh = 60  -- line height (spacing between lines)
    local currentY = y + 40 -- start a bit below the panel top

    love.graphics.printf("Population Overview", x, currentY, width, "center")
    currentY = currentY + lh * 2

    love.graphics.printf(string.format("Total population: %d", Population.total), x + 40, currentY, width - 80, "left")
    currentY = currentY + lh

    love.graphics.printf(string.format("Children (0-17): %d", Population.children), x + 40, currentY, width - 80, "left")
    currentY = currentY + lh

    love.graphics.printf(string.format("Working (18-64): %d", Population.working), x + 40, currentY, width - 80, "left")
    currentY = currentY + lh

    love.graphics.printf(string.format("Retired (65+): %d", Population.retired), x + 40, currentY, width - 80, "left")
end


return Population
