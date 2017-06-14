Cursor = Object:extend()


function Cursor:new()
    self.x = love.mouse.getX()
    self.y = love.mouse.getY()
    self.text = ""..self.x.."/"..self.y
    self.hovering = {} --a table to hold hovering objects
end

function Cursor:update(objects)
    --objects should contain all to test hovering, clicking etc against
    objects = objects or getObjectTree()

    self.x = love.mouse.getX()
    self.y = love.mouse.getY()

    twindoms = getTwindoms()

    --test hovering on objects
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

    --test hovering on twindoms
    local snap = 10
    for i, t in pairs(twindoms) do
        if math.abs(self.x - t.center[1]) < snap and math.abs(self.y - t.center[2]) < snap then
            t.isHovered = true
        else
            t.isHovered = false
        end
    end
end

function Cursor:draw()
    love.graphics.setColor(255, 255, 255)
    love.graphics.print(self.text, self.x, self.y) 
end
