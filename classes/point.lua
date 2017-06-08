Point = Object:extend()

Point.points = {}
local displayRadius = 10

function Point:new(x,y, color)
    self.color = color or {255,0,0,128}
    self.x = x
    self.y = y
    table.insert(Point.points, self)
end

function Point:draw()
    love.graphics.setColor(unpack(self.color))
    love.graphics.circle("line", self.x, self.y, displayRadius)
end

function Point:overlaps(point)
    if math.abs(self.x - point.x) < EPS and math.abs(self.y - point.y) < EPS then
        return true
    else
        return false
    end
end
