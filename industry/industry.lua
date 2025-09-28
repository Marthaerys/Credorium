local Industry = {}

Industry.subcategory = "food"
Industry.foodButton = nil
Industry.clothingButton = nil
Industry.luxuryButton = nil

local Food = require("industry/food")
local Clothing = require("industry/clothing")
local Luxury = require("industry/luxury")

function Industry.updateByWeeks(weeks)
    if Industry.subcategory == "food" then
        Food.updateByWeeks(weeks)
    elseif Industry.subcategory == "clothing" then
        Clothing.updateByWeeks(weeks)
    elseif Industry.subcategory == "luxury" then
        Luxury.updateByWeeks(weeks)
    end
end

function Industry.loadButtons(panelX, panelY, panelWidth, panelHeight)
    local Button = require("ui/button")
    local buttonY = panelY + panelHeight - 100

    Industry.foodButton = Button:new("Food", panelX + 50, buttonY, 250, 80)
    Industry.clothingButton = Button:new("Clothing", panelX + 350, buttonY, 250, 80)
    Industry.luxuryButton = Button:new("Luxury", panelX + 650, buttonY, 250, 80)
end

function Industry.draw(x, y, width)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Industry Overview", x, y + 20, width, "center")

    -- Draw subcategory buttons
    if Industry.foodButton then Industry.foodButton:draw() end
    if Industry.clothingButton then Industry.clothingButton:draw() end
    if Industry.luxuryButton then Industry.luxuryButton:draw() end

    -- Show data based on subcategory
    local info = ""
    if Industry.subcategory == "food" then
        info = Food.getInfo()
    elseif Industry.subcategory == "clothing" then
        info = Clothing.getInfo()
    elseif Industry.subcategory == "luxury" then
        info = Luxury.getInfo()
    end

    love.graphics.printf(info, x + 50, y + 130, width - 100, "left")
end

return Industry
