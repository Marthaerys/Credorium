local Industry = {}

Industry.subcategory = "food"  -- Default
Industry.foodButton = nil
Industry.clothingButton = nil
Industry.luxuryButton = nil

function Industry.loadButtons(panelX, panelY, panelWidth, panelHeight)
    local Button = require("ui/button")

    -- Position near bottom left of popup
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
        info = string.format(
            " Food Sector\nManufacturing output: %d units\nEmployment: %.0f%%\nExports: %d units",
            Industry.manufacturingOutput or 0,
            (Industry.employmentRate or 0) * 100,
            Industry.exports or 0
        )
    elseif Industry.subcategory == "clothing" then
        info = string.format(
            " Clothing Sector\nFactories: 20\nEmployment: %.0f%%\nExports: %d garments",
            (Industry.employmentRate or 0) * 100,
            (Industry.exports or 0) + 100
        )
    elseif Industry.subcategory == "luxury" then
        info = " Luxury Sector\n"  -- geen format nodig als het leeg is
    end


    love.graphics.printf(info, x + 50, y + 130, width - 100, "left")
end

function Industry.updateByWeeks(weeks)
    -- Simulate dynamic changes here
end

return Industry
