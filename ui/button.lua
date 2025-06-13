-- ui/button.lua
local Button = {}
Button.__index = Button

function Button:new(text, x, y, width, height)
    local btn = setmetatable({}, Button)
    btn.text = text
    btn.x = x
    btn.y = y
    btn.width = width
    btn.height = height
    btn.hovered = false
    return btn
end

function Button:isHovered(mx, my)
    return mx >= self.x and mx <= self.x + self.width and
           my >= self.y and my <= self.y + self.height
end

function Button:update()
    local mx, my = love.mouse.getPosition()
    self.hovered = self:isHovered(mx, my)
end

function Button:draw()
    -- Background
    love.graphics.setColor(self.hovered and {0.3, 0.3, 0.3} or {0.2, 0.2, 0.2})
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)

    -- Border
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 10, 10)

    -- Text
    local font = love.graphics.getFont()
    local textY = self.y + (self.height - font:getHeight()) / 2
    love.graphics.printf(self.text, self.x, textY, self.width, "center")
end

return Button
