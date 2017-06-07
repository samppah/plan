Cursor = Object:extend()

function Cursor:new()
    self.x = love.mouse.getX()
    self.y = love.mouse.getY()
end

function Cursor:update(objects)
    --objects should contain all to test hovering, clicking etc against
    objects = objects or getObjectTree()

    self.x = love.mouse.getX()
    self.y = love.mouse.getY()

    --test hovering
    for i, s in pairs(objects) do
        --loop over spaces
        for i, b in pairs(s) do
            --loop over boundaries in a space
            --basic x/y prechecks
            --...
            --draw a triangle from cursor to endpoints,
            --calculate area. If smaller than tolerance,
            --set boundary as "hovered on"
        end
    end
end

function Cursor:draw()
    love.graphics.setColor(255, 255, 255)
    love.graphics.print(""..self.x.."/"..self.y, self.x, self.y) 
end
