local Industry = {}
local util = require("util")

Industry.subcategory = "food"
Industry.foodButton = nil
Industry.clothingButton = nil
Industry.luxuryButton = nil

local Food = require("industry/food")
local Clothing = require("industry/clothing")
local Luxury = require("industry/luxury")

function Industry.updateDaily(daysPassed)
    Food.updateDaily(daysPassed)
end

function Industry.updateByWeeks(weeksPassed)
    Food.updateByWeeks(weeksPassed)
    Clothing.updateByWeeks()
    Luxury.updateByWeeks()
end

function Industry.loadButtons(panelX, panelY, panelWidth, panelHeight)
    local Button = require("ui/button")
    local buttonY = panelY + panelHeight - 100

    Industry.foodButton = Button:new("Food", panelX + 50, buttonY, 250, 80)
    Industry.clothingButton = Button:new("Clothing", panelX + 350, buttonY, 250, 80)
    Industry.luxuryButton = Button:new("Luxury", panelX + 650, buttonY, 250, 80)
end

function Industry.draw(x, y, width, currency)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Industry Overview", x, y + 20, width, "center")

    -- Draw subcategory buttons
    if Industry.foodButton then Industry.foodButton:draw() end
    if Industry.clothingButton then Industry.clothingButton:draw() end
    if Industry.luxuryButton then Industry.luxuryButton:draw() end

    -- Delegate drawing to the active sub-sector
    if Industry.subcategory == "food" then
        Food.draw(x + 50, y + 130, width - 100, currency)
        Food.drawGraph(1500, 800, 400, 400)
    elseif Industry.subcategory == "clothing" then
        Clothing.draw(x + 50, y + 130, width - 100, currency)
    elseif Industry.subcategory == "luxury" then
        Luxury.draw(x + 50, y + 130, width - 100, currency)
    end
end

return Industry