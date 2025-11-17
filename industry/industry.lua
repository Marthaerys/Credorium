local Industry = {}
local util = require("util")
local colors = util.colors
local Food = require("industry/food")
local Clothing = require("industry/clothing")
local Luxury = require("industry/luxury")

Industry.subcategory = "food"
Industry.foodButton = nil
Industry.clothingButton = nil
Industry.luxuryButton = nil



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
    local height = 600 -- of dynamic

    love.graphics.setColor(util.colors.text)
    love.graphics.printf("Industry Overview", x, y + 20, width, "center")

    -- buttons
    if Industry.foodButton then Industry.foodButton:draw() end
    if Industry.clothingButton then Industry.clothingButton:draw() end
    if Industry.luxuryButton then Industry.luxuryButton:draw() end

    -- active subsector
    if Industry.subcategory == "food" then
        Food.draw(x + 50, y + 130, width - 100, currency)
        Food.drawGraph(1500, 800, 400, 400)
    end
end


return Industry