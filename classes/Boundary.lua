Boundary = Object:extend()

require "classes/point"
local stringFuncs = require "strings"
local pmath = require "pmath"

local con = getCon() --get ref to main console
local twindoms = getTwindoms() --get ref to twindoms

function Boundary:new(point1, point2, parentSpace)
--function Boundary:new(x1,y1,x2,y2)
    self.p1 = point1
    self.p2 = point2
    self.type = "wall" --further types ex. border?
    self.features = {} --have a table for doors, windows, etc.
    self.showInfo = false --show metrics
    self.showPoints = false --show points
    self.showDir = false --show boundary direction
    self.isSelected = false
    self.guideMode = "off" --/"inverse"/"both"/"off"
    self.showTwin = true
    self.isVirtual = true --for composite space virtual boundaries
    self.guides = {}
    self.guides.normal, --from boundary point 1 (last one(s?) over)
    self.guides.inverse, --from boundary point 2 (last one(s?) over)
    self.guides.nback, --from boundary point 1, backwards (always over)
    self.guides.iback = self:calcGuides() --from bp2, backwards (always over)
    self.hasTwin = false --only for info display

    self.guides.sortedForSplit = self:sortGuidesForSplit()

    self.parent = parentSpace

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
    table.insert(passableKeys, "parent")
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


function Boundary:getMyIndex(debug)
    for i, b in ipairs(self.parent.boundaries) do
        if b == nil then
            con:add("nil in self.parent.boundaries! at index #"..i)
        end
        if b == self then
            return i
        end
    end
    --if not returned, my parent info is
    --malformed
    local isInOT
    for i, s in pairs(getObjectTree()) do
        if self.parent == s then
            isInOT = true
            con:add("queried boundary:getMyIndex() for a space in objectTree")
            break
        end
    end
    if not isInOT then
        con:add("queried boundary:getMyIndex() for a space NOT in objectTree")
    end
    con:add("returned a nil from boundary:getmyindex() /.."..(debug or ""))
end


function Boundary:draw()
    local sin = math.sin
    local cos = math.cos
    local pi = math.pi

    --draw line
    if self.parent.isSelected then
        alpha = 255
    else
        alpha = 64
    end
    if self.isVirtual then
        alpha = alpha /2
    end
    if self.isSelected then
        love.graphics.setColor(255, 0, 255, alpha)
    else
        love.graphics.setColor(255, 255, 255, alpha)
    end
    if self.isVirtual then
        --draw dashed line
        local l = self:len()
        local dashl = 10
        local gapl = 15
        local safety = 1000
        local x1 = self.p1.x
        local y1 = self.p1.y
        local ang = self:angle()
        while safety > 0 and l > dashl+gapl do
            safety = safety - 1
            local x2 = x1 + dashl * sin(ang+pi/2)
            local y2 = y1 + dashl * cos(ang+pi/2)
            love.graphics.line(x1,y1,x2,y2)
            x1 = x1 + (dashl+gapl) * sin(ang+pi/2)
            y1 = y1 + (dashl+gapl) * cos(ang+pi/2)
            l = l - (dashl+gapl)
        end
        --draw last dash
        local x2 = 0
        local y2 = 0
        if l < dashl  then
            x2 = self.p2.x
            y2 = self.p2.y
        else
            x2 = x1 + dashl * sin(ang+pi/2)
            y2 = y1 + dashl * cos(ang+pi/2)
        end
        love.graphics.line(x1,y1,x2,y2)
    else
        love.graphics.line(self.p1.x,self.p1.y,self.p2.x,self.p2.y)
    end




    if self.showInfo then
        --draw info
        --local infotxt = "#" .. index .. " " .. self:len() .. " " .. self:angle()
        local index = self:getMyIndex()
        
        local function hastwin()
            local has = false
            for i, t in pairs(getTwindoms()) do
                if t:contains(self) then
                    has = true
                    break
                end
            end
            return has
        end
        self.hasTwin = hastwin()
        local infotxt = "#" .. (index or "nil") .. " " .. self:angle() .. "\n" .. "hasTwin = " .. (self.hasTwin and "true" or "false")
        
        local lenratio = .8
        love.graphics.print(stringFuncs.formatText(infotxt),unpack(self:pointAtLen(self:len()*lenratio)))
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
    return pmath.lineCenter(self.p1.x, self.p1.y, self.p2.x, self.p2.y)
end

function Boundary:isAdjacent(btl, b)
    local i = self:getMyIndex()
    local bi = b:getMyIndex()

    if b.parent ~= self.parent then
        return false
    end

    if i == 1 or bi == 1 then
        --test for last boundary
        if i == 1 then
            if bi == btl then
                return true, "back"
            elseif bi == 2 then
                return true, "fwd"
            else
                return false
            end
        else
            --bi = 1
            if i == btl then
                return "fwd"
            elseif i == 2 then
                return true, "back"
            else
                return false
            end
        end
    else
        --test normally
        if i - bi == 1 then
            return true, "fwd"
        elseif i - bi == -1 then
            return true, "back"
        else
            return false
        end
    end

end

function Boundary:hasSameAngle(boundary)
    return math.abs(self:angle() - boundary:angle()) < EPS
end
function Boundary:join(boundary)
    --deletes boundary, sets self's
    --endpoint as boundary's
    

    --check if parallel and on the same line
    if true then --placeholder
        --all good
    else
        con:add("cannot join boundaries. not adjacent.")
        return
    end


    local bi = self:getMyIndex()
    local jbi = boundary:getMyIndex()
    local btl = #self.parent.boundaries


    local isAB, method = self:isAdjacent(btl, boundary)
    if isAB then
        if method == "back" then
            --self p2 is good,
            --self p1 shall be boundary.p1
            self.p2.x = boundary.p2.x
            self.p2.y = boundary.p2.y
        else
            --method = "fwd"
            --self p1 is good,
            --self p2 shall be boundary.p2
            self.p1.x = boundary.p1.x
            self.p1.y = boundary.p1.y
        end
        --find and delete boundary from parentSpace.boundaries
        local remI = 0
        for i, b in ipairs(self.parent.boundaries) do
            if b == boundary then
                remI = i 
                break
            end
        end
        if remI == 0 then
            con:add("remI = 0. this is weird.")
            return
        end
        table.remove(self.parent.boundaries, remI)
    else
        con:add("cannot join boundaries. not adjacent.")
        return
    end
    --fix bpgon
    --use boundaries to reconstruct it

end

function Boundary:pointAtLen(len)
    return pmath.pointAtLen(len, self.p1.x, self.p1.y, self.p2.x, self.p2.y)
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
        local xm = pal[1]
        local ym = pal[2]
        local xe = self.p2.x
        local ye = self.p2.y
        --this boundary will be x1,y1 -> xal,yal 
        --new boundary will be xal,yal -> xe,ye
        self.p2.x = xm
        self.p2.y = ym
        newPoint1 = Point(xm, ym)
        newPoint2 = Point(xe, ye)
    end
    local newBoundary = Boundary(newPoint1, newPoint2, self.parent)
    --simply pass data to new boundary
    self:setData(newBoundary)
    return newBoundary, {newPoint1.x, newPoint1.y}
end


function Boundary:splitAtXy(coords)
    --splits boundary in two at x,y
    --returns the new Boundary object and split point in {1=x, 2=y} format

    local x = coords[1]
    local y = coords[2]

    local newPoint1
    local newPoint2

    local xm = x
    local ym = y
    local xe = self.p2.x
    local ye = self.p2.y

    self.p2.x = xm
    self.p2.y = ym

    newPoint1 = Point(xm, ym)
    newPoint2 = Point(xe, ye)

    local newBoundary = Boundary(newPoint1, newPoint2, self.parent)
    --simply pass data to new boundary
    self:setData(newBoundary)

    return newBoundary, x, y
end



function Boundary:overlaps(boundary)
    if math.abs(self.p1.x - boundary.p1.x) < EPS and math.abs(self.p1.y - boundary.p1.y) < EPS then
        return true
    elseif
        math.abs(self.p2.x - boundary.p1.x) < EPS and math.abs(self.p2.y - boundary.p1.y) < EPS then
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
