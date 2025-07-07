local Button = require("ui/button")
local Game = require("game")


local buttons = {}
local startButton = nil
local font
local screenX, screenY

gamestate = "menu"

local inputFields = {
    country = { text = "", active = false, y = 0 },
    currency = { text = "", active = false, y = 0 },
}

function love.load()
    love.window.setTitle("Credorium")
    love.window.setMode(0, 0, { fullscreen = true })

    screenX, screenY = love.graphics.getDimensions()

    font = love.graphics.newFont("assets/font/Source_Serif_4/static/SourceSerif4-Light.ttf", math.floor(screenY * 0.04))
    love.graphics.setFont(font)

    local centerX = screenX / 2
    local startY = screenY / 3
    local buttonWidth = screenX * 0.25
    local buttonHeight = screenY * 0.1
    local spacing = screenY * 0.02

    table.insert(buttons, Button:new("Continue", centerX - buttonWidth / 2, startY, buttonWidth, buttonHeight))
    table.insert(buttons, Button:new("New Game", centerX - buttonWidth / 2, startY + (buttonHeight + spacing), buttonWidth, buttonHeight))
    table.insert(buttons, Button:new("Quit", centerX - buttonWidth / 2, startY + 2 * (buttonHeight + spacing), buttonWidth, buttonHeight))

    -- Adjust input field Y positions dynamically
    inputFields.country.y = screenY * 0.3
    inputFields.currency.y = screenY * 0.4
end

function love.resize(w, h)
    screenX, screenY = w, h
end

function love.update(dt)
    if gamestate == "menu" then
        local mx, my = love.mouse.getPosition()
        for _, btn in ipairs(buttons) do
            btn:update(mx, my)
        end
    elseif gamestate == "country_select" then
        if startButton then
            local allFilled = inputFields.country.text ~= "" and inputFields.currency.text ~= ""
            startButton.enabled = allFilled

            local mx, my = love.mouse.getPosition()
            startButton:update(mx, my)
        end
    elseif gamestate == "game" then
        Game.update(dt)
    end
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)
    love.graphics.setColor(1, 1, 1)

    if gamestate == "menu" then
        love.graphics.printf("Credorium", 0, screenY * 0.1, screenX, "center")
        for _, btn in ipairs(buttons) do
            btn:draw()
        end
    elseif gamestate == "country_select" then
        love.graphics.printf("Choose Your Nation", 0, screenY * 0.08, screenX, "center")

        love.graphics.print("Country Name:", screenX * 0.2, inputFields.country.y)
        drawInputField(inputFields.country, screenX * 0.375, inputFields.country.y, screenX * 0.25)

        love.graphics.print("Currency Name:", screenX * 0.2, inputFields.currency.y)
        drawInputField(inputFields.currency, screenX * 0.375, inputFields.currency.y, screenX * 0.25)

        local currency = inputFields.currency.text ~= "" and inputFields.currency.text or "BUCKS"
        love.graphics.print("Starting capital: 1,000,000 " .. currency, screenX * 0.2, screenY * 0.55)

        if startButton then
            love.graphics.setColor(startButton.enabled and 1 or 0.5, startButton.enabled and 1 or 0.5, startButton.enabled and 1 or 0.5)
            startButton:draw()
            love.graphics.setColor(1, 1, 1)
        end
    elseif gamestate == "game" then
        Game.draw()
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        if gamestate == "menu" then
            for _, btn in ipairs(buttons) do
                if btn:isHovered(x, y) then
                    if btn.text == "New Game" then
                        gamestate = "country_select"
                        local buttonWidth = screenX * 0.25
                        local buttonHeight = screenY * 0.1
                        startButton = Button:new("Start Game", screenX / 2 - buttonWidth / 2, screenY * 0.7, buttonWidth, buttonHeight)
                    elseif btn.text == "Continue" then
                        Game.loadFromSave()
                        gamestate = "game"
                    elseif btn.text == "Quit" then
                        love.event.quit()
                    end
                end
            end

        elseif gamestate == "game" then
        -- Always-clickable game buttons
        if Game.menuButton and Game.menuButton:isHovered(x, y) then
            Game.save()
            gamestate = "menu"
        elseif Game.industryButton and Game.industryButton:isHovered(x, y) then
            Game.uiState = "industry"
            Industry.subcategory = "food" -- Reset to default when opening
        elseif Game.populationButton and Game.populationButton:isHovered(x, y) then
            Game.uiState = "population"
        elseif Game.economyButton and Game.economyButton:isHovered(x, y) then
            Game.uiState = "economy"
        end

        -- Subcategory clicks
        if Game.uiState == "industry" then
            if Industry.foodButton and Industry.foodButton:isHovered(x, y) then
                Industry.subcategory = "food"
            elseif Industry.clothingButton and Industry.clothingButton:isHovered(x, y) then
                Industry.subcategory = "clothing"
            end
        end

    -- Close popup
    if Game.uiState ~= "main" and Game.closeButton and Game.closeButton:isHovered(x, y) then
        Game.uiState = "main"
    end


        elseif gamestate == "country_select" then
            local fieldW = screenX * 0.25
            inputFields.country.active = isInside(x, y, screenX * 0.375, inputFields.country.y, fieldW, 50)
            inputFields.currency.active = isInside(x, y, screenX * 0.375, inputFields.currency.y, fieldW, 50)

            if startButton and startButton.enabled and startButton:isHovered(x, y) then
                Game.load(inputFields.country.text, inputFields.currency.text)
                gamestate = "game"
            end
        end
    end
end



function love.textinput(t)
    for key, field in pairs(inputFields) do
        if field.active then
            local maxLen = (key == "currency") and 5 or 20
            if key == "currency" then
                t = t:upper()
            end
            if #field.text < maxLen then
                field.text = field.text .. t
            end
        end
    end
end

function love.keypressed(key)
    if key == "backspace" then
        for _, field in pairs(inputFields) do
            if field.active then
                field.text = field.text:sub(1, -2)
            end
        end
    end
end

-- Helpers
function drawInputField(field, x, y, width)
    love.graphics.setColor(field.active and {0.8, 0.8, 0.8} or {0.5, 0.5, 0.5})
    love.graphics.rectangle("fill", x, y, width, 50, 8, 8)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(field.text, x + 10, y + 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, width, 50, 8, 8)
end

function isInside(px, py, x, y, w, h)
    return px > x and px < x + w and py > y and py < y + h
end
