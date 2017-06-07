Guide = Object:extend()

require "classes/point"
local stringFuncs = require "strings"

function Guide:new(x, y, angle, color)
    self.angle = angle or 0
    if self.isSelected then
        self.color = {255,32,0,255}
    else
        self.color = color or {255,32,0,64}
    end
    self.drawInfo = false

    self.point = Point(x, y, self.color) --origin point through which guide is drawn
    self.isVisible = true
    self.bPoint1 = nil --screen boundary point 1 (towards/front)
    self.bPoint2 = nil --screen boundary point 2 (from/back)
    self.atLen = 0 --distance from origin along boundary

    --CALCULATE GRAPHIC REPRESENTATION
    self:update()

end

function Guide:update()
    --define canvas size
    local w = {} --as in window
    w.w, w.h = love.graphics.getDimensions()

    --find out point of contact from guide snapPoint to a screen edge
    local function getScreenEdgeCoords(ang)

        --normalize angle to positive radians
        if ang<0 then
            ang = ang + 2*math.pi
        end

        --check special
        if ang == 0 then
            return w.w, self.point.y
        elseif ang == math.pi/2 then
            return self.point.x, 0
        elseif ang == math.pi then
            return 0, self.point.y
        elseif ang == math.pi*1.5 then
            return self.point.x, w.h
        end

        local epy, epx

        --Calculate raw triangular endpoint coordinates epx,epy
        --with a triangle that's height is the height from self.point.y
        --to either the top or the bottom of the screen
        epy = ang<math.pi and
                self.point.y
            or 
                w.h - self.point.y

        epx = ang<math.pi and 
                self.point.x + (epy / math.tan(ang))
            or
                self.point.x - (epy / math.tan(ang))

        --check if endpoint x (epx) is offscreen
        if epx > w.w then
            --epx is off right of screen
            --angle = 0 -> pi/2 OR 1.5*pi -> 2pi
            if ang < math.pi/2 then
                --angle = 0 -> pi/2
                -- /|
                --o-+
                
                local smallX = w.w - self.point.x
                local smallY = epy * (smallX / (epx-self.point.x))
                epx = w.w
                epy = self.point.y - smallY
            else
                --angle = 1.5*pi -> 2pi
                --o-+
                -- \|
                local smallX = w.w - self.point.x
                local smallY = epy * (smallX / (epx-self.point.x))
                epx = w.w
                epy = self.point.y + smallY
            end
        elseif epx < 0 then
            --epx is off left of screen
            --angle = pi/2 -> pi OR pi -> 1.5*pi
            if ang < math.pi then
                --angle = pi/2 -> pi
                --|\
                --+-o
                local smallX = self.point.x
                local smallY = epy * (smallX / ((-1*epx)+smallX))
                epx = 0
                epy = self.point.y - smallY
            else
                --angle = pi -> 1.5*pi
                --+-o
                --|/
                local smallX = self.point.x
                local smallY = epy * (smallX / ((-1*epx)+smallX))
                epx = 0
                epy = self.point.y + smallY
            end
        else
            --its not offscreen
            epy = ang < math.pi and 0 or w.h
        end
        return epx, epy
    end

    --get edgepoints
    --point1 : basic angle
    local epx, epy
    epx, epy = getScreenEdgeCoords(self.angle)
    self.bPoint1 = Point(epx, epy, self.color)
    --point2 : add 180, fix overshoot
    local backAng = self.angle + math.pi
    if backAng > 2*math.pi then
        backAng = backAng - 2*math.pi
    end
    epx, epy = getScreenEdgeCoords(backAng)
    self.bPoint2 = Point(epx, epy, self.color)
end

function Guide:draw()

    if not self.isVisible then
        return
    end
    --draw graphics
    --draw selfpoint

    self:update()

    self.point:draw()
    --draw guideline
    love.graphics.setColor(unpack(self.color))
    love.graphics.line(self.bPoint1.x, self.bPoint1.y, self.bPoint2.x, self.bPoint2.y)

    --draw screen border collision point
    self.bPoint1:draw()
    --self.bPoint2:draw()

    --draw info
    if self.drawInfo then
        local infotxt = "a:"..self.angle.."\n"..self.point.x.."\n"..self.point.y
        love.graphics.print(stringFuncs.formatText(infotxt),self.point.x,self.point.y)
    end

end

