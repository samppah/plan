Boundary = Object:extend()

require "classes/point"
local stringFuncs = require "strings"
local pmath = require "pmath"

local con = getCon() --get ref to main console

function Boundary:new(point1, point2, parentSpace)
--function Boundary:new(x1,y1,x2,y2)
--[[
    self.x1 = x1 or 0
    self.y1 = y1 or 0
    self.x2 = x2 or 0
    self.y2 = y2 or 0
    --]]
    self.p1 = point1
    self.p2 = point2
    self.type = "wall" --further types ex. border?
    self.features = {} --have a table for doors, windows, etc.
    self.showInfo = false --show metrics
    self.showPoints = true --show points
    self.showDir = false --show boundary direction
    self.isSelected = false
    self.guideMode = "off" --/"inverse"/"both"/"off"
    self.guides = {}
    self.guides.normal, --from boundary point 1 (last one(s?) over)
    self.guides.inverse, --from boundary point 2 (last one(s?) over)
    self.guides.nback, --from boundary point 1, backwards (always over)
    self.guides.iback = self:calcGuides() --from bp2, backwards (always over)

    self.guides.sortedForSplit = self:sortGuidesForSplit()

    self.parent = parentSpace

    --shared boundary info
    --boundary can be either: shared or outer
    self.isOuter = true --default
    self.isShared = false --default

    self.twin = {}
    self.twin.bo = self
    self.twin.bi = nil -- my index (boundary index in my parent space)
    self.twin.sbo = nil --shared boundary object
    self.twin.sbi = nil --shared boundary index
    self.twin.sso = nil --shared space object
    self.twin.ssi = nil --shared space index
end


function Boundary:setShared(boundary)
    --sets "boundary" as a shared ("twin") boundary
    --as to self

    --set my data
    self.isShared = true
    self.isOuter = false

    self.twin.bo = self
    self.twin.bi = self:getMyIndex()
    self.twin.sbo = boundary
    self.twin.sbi = boundary:getMyIndex()
    self.twin.sso = boundary.parent
    self.twin.ssi = boundary.parent:getMyIndex()

    --set twin data
    boundary.isShared = true
    boundary.isOuter = false

    boundary.twin.bo = boundary
    boundary.twin.bi = self.twin.sbi
    boundary.twin.sbo = self
    boundary.twin.sbo = self.twin.bi
    boundary.twin.sso = self.parent
    boundary.twin.ssi = self.parent:getMyIndex()
end

function Boundary:getData(mode)
    --returns a table for passable boundary data
    --mode: "keys" / "data"
    --
    --keys returns an indexed list of the
    --keys in "boundary" object which are gettable/settable
    --with "getData"/"setData"
    --
    --data returns a table with those keys,
    --and the values linked to those keys
    --
    --if mode is omitted, returns keys,data both
    
    local passableKeys = {}
    local data = {}
    table.insert(passableKeys, "type")
    table.insert(passableKeys, "features")
    --table.insert(passableKeys, "showInfo")
    --table.insert(passableKeys, "showPoints")
    --table.insert(passableKeys, "showDir")
    --table.insert(passableKeys, "isSelected")
    --table.insert(passableKeys, "guideMode")
    --table.insert(passableKeys, "guides")
    table.insert(passableKeys, "isOuter")
    table.insert(passableKeys, "isShared")
    table.insert(passableKeys, "twin")
    for i, v in pairs(passableKeys) do
        data[v] = self[v]
    end
    if mode then
        if mode == "keys" then
            return passableKeys
        elseif mode == "data" then
            return data
        end
    else
        return passableKeys, data
    end

end

function Boundary:setData(boundary)
    --passes information to another boundary

    local myKeys, myData = self:getData()
    for i, v in pairs(myKeys) do
        boundary[v] = self[v]
    end
end


function Boundary:getMyIndex()
    for i, b in ipairs(self.parent.boundaries) do
        if b == self then
            return i
        end
    end
end


function Boundary:draw()
        local sin = math.sin
        local cos = math.cos
    if self.isSelected then
        love.graphics.setColor(255, 0, 255)
    else
        love.graphics.setColor(255, 255, 255)
    end
    love.graphics.line(self.p1.x,self.p1.y,self.p2.x,self.p2.y)

    if self.showInfo then
        --draw info
        --local infotxt = "#" .. index .. " " .. self:len() .. " " .. self:angle()
        local index = self:getMyIndex()
        local infotxt = "#" .. index .. " " .. self:angle() .. "\n" .. "isShared = " .. (self.isShared and "true" or "false")
        
        love.graphics.print(stringFuncs.formatText(infotxt),unpack(self:center()))
    end

    --draw share lines
    --make share lines blink RED when space is selected,
    --show faded red otherwise
    local drawShareLines = false
    if self.isShared then
        if self.parent.isSelected then
            if getBlinkStat() then
                love.graphics.setColor(255,0,0)
                drawShareLines = true
            end
        else
            love.graphics.setColor(255,0,0,128)
            drawShareLines = true
        end
    end
    if drawShareLines then
        local offset = 10
        local ang2 = self:angle()-math.pi*2 --angle of share line
        local p = self:pointAtLen(self:len()/2-offset)
        local spx = p[1] + offset * sin(ang2)
        local spy = p[2] + offset * cos(ang2)
        local epx = p[1] - offset * sin(ang2)
        local epy = p[2] - offset * cos(ang2)
        love.graphics.line(spx,spy,epx,epy)

        local p = self:pointAtLen(self:len()/2+offset)
        local spx = p[1] + offset * sin(ang2)
        local spy = p[2] + offset * cos(ang2)
        local epx = p[1] - offset * sin(ang2)
        local epy = p[2] - offset * cos(ang2)
        love.graphics.line(spx,spy,epx,epy)
    end

    if self.showPoints then
        self.p1:draw()
        self.p2:draw()
    end
    if self.guideMode ~= "off" then
        self:drawGuides()
    end

    if self.showDir then
        love.graphics.setColor(255,255,255,128)


        --draw arrow body
        local offset = 15
        local ang2 = self:angle()-math.pi*2 --angle of line offset
        local spx = self.p1.x + offset * sin(ang2)
        local spy = self.p1.y + offset * cos(ang2)
        local epx = self.p2.x + offset * sin(ang2)
        local epy = self.p2.y + offset * cos(ang2)
        love.graphics.line(spx,spy,epx,epy)

        --draw arrow tip
        local tiplen = 10
        local ang2 = self:angle() + math.pi * 1.75 --angle of arrow tip
        local tipspx = epx
        local tipspy = epy
        local tipepx = epx + tiplen * sin(ang2)
        local tipepy = epy + tiplen * cos(ang2)
        love.graphics.line(tipspx, tipspy, tipepx, tipepy)

        local ang2 = self:angle() - math.pi * 0.75 --angle of arrow tip
        local tipspx = epx
        local tipspy = epy
        local tipepx = epx + tiplen * sin(ang2)
        local tipepy = epy + tiplen * cos(ang2)
        love.graphics.line(tipspx, tipspy, tipepx, tipepy)

        
    end
end

function Boundary:len()
    --return boundary length
    xp12 = (self.p1.x-self.p2.x)*(self.p1.x-self.p2.x)
    yp12 = (self.p1.y-self.p2.y)*(self.p1.y-self.p2.y)
    hyp = math.sqrt(xp12+yp12) 
    return hyp
end

function Boundary:center()
    --return Boundary centerpoint, table format {x,y}
    return pmath:lineCenter(self.p1.x, self.p1.y, self.p2.x, self.p2.y)
end

function Boundary:pointAtLen(len)
    return pmath:pointAtLen(len, self.p1.x, self.p1.y, self.p2.x, self.p2.y)
end

function Boundary:angle()
    --return the absolute angle (direction) of a boundary in radians
    --return math.atan(self.p2.x-self.p1.x,self.p1.y-self.p2.y)
    local y1 = self.p1.y
    local y2 = self.p2.y
    local x1 = self.p1.x
    local x2 = self.p2.x
    local angle = math.atan2(y1-y2, x2-x1)
    --normalize to positive radians
    if angle<0 then
        angle = angle + 2*math.pi
    end
    return angle
end

function Boundary:split(len)
    --splits boundary in two 
    --if no len is specified, the split is
    --in the exact middle (no guides)
    --returns the new Boundary object and split point in {1=x, 2=y} format

    local newPoint1
    local newPoint2
    if not len then
        local center = self:center()
        local xm = center[1]
        local ym = center[2]
        local xe = self.p2.x
        local ye = self.p2.y
        --this boundary will be x1,y1 -> xm,ym
        --new boundary will be xm,ym -> xe,ye
        self.p2.x = xm
        self.p2.y = ym
        newPoint1 = Point(xm, ym)
        newPoint2 = Point(xe, ye)
    else
        local pal = self:pointAtLen(len)
        local xal = pal[1]
        local yal = pal[2]
        local xe = self.p2.x
        local ye = self.p2.y
        --this boundary will be x1,y1 -> xal,yal 
        --new boundary will be xal,yal -> xe,ye
        self.p2.x = xal
        self.p2.y = yal
        newPoint1 = Point(xal, yal)
        newPoint2 = Point(xe, ye)
    end
    local newBoundary = Boundary(newPoint1, newPoint2, self.parent)
    --pass data to new boundary
    self:setData(newBoundary)
    return newBoundary, {newPoint1.x, newPoint1.y}
end

function Boundary:overlaps(boundary)
    if self.p1.x == boundary.p1.x and self.p1.y == boundary.p1.y then
        return true
    elseif
        self.p2.x == boundary.p1.x and self.p2.y == boundary.p2.y then
        return true
    else
        return false
    end
end

function Boundary:calcGuides()
    --calculates guide points for the boundary
    --normal and inverse points are calculated
    --nback and iback are "1 guide step outside"
    --(for future, when outer boundary would
    --be also adjustable)
    local len = self:len()
    local ang = self:angle()
    local ggrid = globalGrid
    local tlab = ggrid--traversed length along boundary
    local gang = ang - (math.pi/2) --guide angle
    local gx, gy
    
    local normal = {}
    local inverse = {}

    local safety = 1000
    if len - ggrid > EPS then
        repeat
            safety = safety - 1
            --draw normal guide(s)
            gx = tlab * math.cos(ang) + self.p1.x
            gy = self.p1.y - (tlab * math.sin(ang))
            local newGuide = Guide(gx,gy,gang)
            newGuide.atLen = tlab
            table.insert(normal, newGuide)
            --draw inverse guide(s)
            gx = self.p2.x - (tlab * math.cos(ang))
            gy = self.p2.y + (tlab * math.sin(ang))
            local newGuide = Guide(gx,gy,gang)
            newGuide.atLen = len - tlab
            table.insert(inverse, newGuide)
            --increment tlab
            tlab = tlab + ggrid
        until len-tlab <= EPS or (safety < 0)
    end

    local nback = {}
    local iback = {}
    gx = -ggrid * math.cos(ang) + self.p1.x
    gy = self.p1.y - (-ggrid * math.sin(ang))
    local newGuide = Guide(gx,gy,gang)
    newGuide.atLen = -ggrid
    table.insert(nback, newGuide)
    gx = self.p2.x - (-ggrid * math.cos(ang))
    gy = self.p2.y + (-ggrid * math.sin(ang))
    local newGuide = Guide(gx,gy,gang)
    newGuide.atLen = -ggrid
    table.insert(iback, newGuide)


    return normal, inverse, nback, iback
end
    
function Boundary:sortGuidesForSplit()
    --orders guides in "normal", "inverse" in a table for splitting a boundary
    local sorted = {}
    local tlen = #self.guides.normal

    if tlen == 0 then
        --no guides for border
        return sorted
    end
    --check which comes first
    local nfirst = self.guides.normal[1].atLen < self.guides.inverse[tlen].atLen
    for i = 1, tlen do
        local ii = #self.guides.normal
        local g = self.guides.normal[i]
        local gi = self.guides.inverse[tlen+1-i]
        if nfirst then
            table.insert(sorted, g)
            table.insert(sorted, gi)
        else
            table.insert(sorted, gi)
            table.insert(sorted, g)
        end
    end
    return sorted
end

function Boundary:drawGuides()
    --draws perpendicular guides along the boundary
    if self.guideMode == "normal" or self.guideMode == "both" then
        for i, v in ipairs(self.guides.normal) do
            v:draw()
        end
        for i, v in ipairs(self.guides.nback) do
            v:draw()
        end

    end
    if self.guideMode == "inverse" or self.guideMode == "both" then
        for i, v in ipairs(self.guides.inverse) do
            v:draw()
        end
        for i, v in ipairs(self.guides.iback) do
            v:draw()
        end
    end
end
