-- main.lua
local Button = require("ui/button")
local Game = require("game")

local buttons = {}
local startButton = nil
local font
local screenX = 1600
local screenY = 1200

gamestate = "menu"


local inputFields = {
    country = { text = "", active = false, y = 200 },
    currency = { text = "", active = false, y = 300 },
}

function love.load()
    love.window.setTitle("Credorium")
    love.window.setMode(screenX, screenY)

    font = love.graphics.newFont("assets/font/Source_Serif_4/static/SourceSerif4-Light.ttf", 36)
    love.graphics.setFont(font)

    local centerX = screenX/2
    local startY = screenY/3
    local buttonWidth = 400
    local buttonHeight = 100
    local spacing = 20

    table.insert(buttons, Button:new("Continue", centerX - buttonWidth / 2, startY, buttonWidth, buttonHeight))
    table.insert(buttons, Button:new("New Game", centerX - buttonWidth / 2, startY + (buttonHeight + spacing), buttonWidth, buttonHeight))
    table.insert(buttons, Button:new("Quit", centerX - buttonWidth / 2, startY + 2 * (buttonHeight + spacing), buttonWidth, buttonHeight))
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
        love.graphics.printf("Credorium", 0, 200, 1600, "center")
        for _, btn in ipairs(buttons) do
            btn:draw()
        end
    elseif gamestate == "country_select" then
        love.graphics.printf("Choose Your Nation", 0, 100, 1600, "center")

        love.graphics.print("Country Name:", 300, inputFields.country.y)
        drawInputField(inputFields.country, 600, inputFields.country.y, 400)

        love.graphics.print("Currency Name:", 300, inputFields.currency.y)
        drawInputField(inputFields.currency, 600, inputFields.currency.y, 400)

        local currency = inputFields.currency.text ~= "" and inputFields.currency.text or "BUCKS"
        love.graphics.print("Starting capital: 1,000,000 " .. currency, 300, 450)

        -- Draw start button
        if startButton then
            if startButton.enabled then
                love.graphics.setColor(1, 1, 1)
            else
                love.graphics.setColor(0.5, 0.5, 0.5)
            end
            startButton:draw()
            love.graphics.setColor(1, 1, 1)
        end
    elseif gamestate == "game" then
        Game.draw()
    end
end

function love.mousepressed(x, y, button)
    if gamestate == "menu" then
        for _, btn in ipairs(buttons) do
            if btn.hovered then
                if btn.text == "New Game" then
                    gamestate = "country_select"
                    startButton = Button:new("Start Game", screenX/2 - 200, 600, 400, 100)
                elseif btn.text == "Continue" then
                    Game.loadFromSave()
                    gamestate = "game"
                elseif btn.text == "Quit" then
                    love.event.quit()
                end
            end
        end
    elseif gamestate == "game" then
        if Game.menuButton and isInside(x, y, Game.menuButton.x, Game.menuButton.y, Game.menuButton.width, Game.menuButton.height) then
            gamestate = "menu"
        end
    elseif gamestate == "country_select" then
        inputFields.country.active = isInside(x, y, 600, inputFields.country.y, 400, 50)
        inputFields.currency.active = isInside(x, y, 600, inputFields.currency.y, 400, 50)

        if startButton and startButton.enabled and isInside(x, y, startButton.x, startButton.y, startButton.width, startButton.height) then
            Game.load(inputFields.country.text, inputFields.currency.text)
            gamestate = "game"
        end
    end
end


function love.textinput(t)
    for key, field in pairs(inputFields) do
        if field.active then
            local maxLen = 20
            if key == "currency" then
                maxLen = 5
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
