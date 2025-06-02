-- main.lua
local Button = require("ui/button")

local buttons = {}
local font
local screenX = 1600
local screenY = 1200

function love.load()
    love.window.setTitle("Your Game Title")
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
    local mx, my = love.mouse.getPosition()
    for _, btn in ipairs(buttons) do
        btn:update(mx, my)
    end
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1) -- Dark background
    love.graphics.setColor(1, 1, 1)

    -- Calculate top button Y-position
    local topButtonY = buttons[1].y
    local titlePadding = 100
    local titleY = topButtonY - titlePadding

    -- Draw title centered horizontally
    love.graphics.printf("Credorium", 0, titleY, screenX, "center")

    -- Draw buttons
    for _, btn in ipairs(buttons) do
        btn:draw()
    end
end


function love.mousepressed(x, y, button)
    if button == 1 then
        for _, btn in ipairs(buttons) do
            if btn.hovered then
                print("Clicked:", btn.text)
            end
        end
    end
end
