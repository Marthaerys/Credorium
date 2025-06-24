-- Supply&demand version 1.0
local supply_demand = {}


--Food distribution 0.05/child + 0.1/adult + 0.08 elderly
function updateFoodDemand()
    local children = Population.children or 0
    local adults = Population.adults or 0
    local elderly = Population.elderly or 0

    FoodDemand = 0.05 * children + 0.1 * adults + 0.08 * elderly
end

function love.update(dt)
    updateFoodDemand()
    -- Other update logic
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Consumer demands", x, currentY, width, "center")
    currentY = currentY +lh
    -- Column headers at same positions as v4.0
    love.graphics.printf("Item",  x + 100,  currentY, 300, "left")
    love.graphics.printf("/Day",  x + 500,  currentY, 300, "left")
    currentY = currentY +lh

    -- Compute demand before drawing
    local children = Population.children or 0
    local adults   = Population.working or 0
    local elderly  = Population.retired or 0
    local FoodDemand = 0.05 * children + 0.1 * adults + 0.08 * elderly
    -- Draw static row
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Food", x + 100, currentY, 400, "left")
    love.graphics.printf(string.format("%.1f", FoodDemand), x + 500, currentY, 400, "left")
    currentY = currentY + lh
end
    
