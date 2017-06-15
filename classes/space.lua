Space = Object:extend()

Space.debug = true

local stringFuncs = require "strings"
local pmath = require "pmath"
local con = getCon() --get ref to main console
local twindoms = getTwindoms()

require "classes/Boundary"
require "classes/twindom"


function normBIndex(btl, bi)
    --normalize a boundary index
    --btl = boundary table length
    --bi = boundary index, possibly out of bounds
    --
    if bi < 1 then
        while bi < 1 do
            bi = btl + bi
        end
    elseif bi > btl then
        while bi > btl do
            bi = -btl + bi
        end
    end
    return bi
end

function bIter(table, start, end_)
    --an iterator function to loop over
    --boundaries tables ends to beginnings
    --
    --end_ is not normalized (=possibly out of bounds)
    --
    local i = 0
    local len = #table
    if end_ <= start then
        --a loopover case
        end_ = end_ + len
    end
    local lenE = end_ - start

    local safety = 1000

    return function()
        i = i + 1
        safety = safety - 1
        
        if safety < 0 then
            con:add("botched loop")
            return nil
        end

        if i > lenE then
            --the number of boundaries have been looped over
            return nil
        end

        return normBIndex(len, start + i - 1), table[normBIndex(len, start + i - 1)]

    end
end


function Space:new(name, bpgon, boundaries)
    --create new "master" space (non-child)
    --bpgon = the boundary polygon, a table of coordpoints
    --bpgon[1] = x1
    --bpgon[2] = y1
    --bpgon[3] = x2
    --bpgon[4] = y2
    --...
    --pgon cannot be closed
    --
    --boundaries are optional. if they are provided,
    --the createBoundaries call is passed over
    
    self.name = name or "noname"
    self.parent = nil
    self.bpgon = bpgon --boundary polygon, open
    self.boundaries = {} --a table to hold outer boundary objects
    self.spaces = {} --a table to hold child spaces
    self.showInfo = true
    self.showPoints = true
    self.isSelected = false
    self.debug = false

    --insert space into main object tree for GUI functions
    table.insert(getObjectTree(), self)

    if not boundaries then
        self:createBoundaries()
    else
        --:new is called from :split.
        --we need to assign the parent space property to
        --boundaries created in :split, that were created
        --before the parent space was in existence
        self.boundaries = boundaries
        for i, v in pairs(boundaries) do
            v.parent = self
        end
    end

end

function Space:update(bpgon, boundaries)
    self.bpgon = bpgon
    self.boundaries = boundaries
end


function Space:createBoundaries()
    --creates new boundaries for the space with self.bpgon
    if self.bpgon then
        --if not nil, create boundaries
        self.boundaries = {}
        for i = 1, #self.bpgon, 2 do 
            local x1 = self.bpgon[i]
            local y1 = self.bpgon[i+1]
            local x2 = nil
            local y2 = nil
            if i < #self.bpgon-1 then
                x2 = self.bpgon[i+2]
                y2 = self.bpgon[i+3]
            else
                --close polygon
                x2 = self.bpgon[1]
                y2 = self.bpgon[2]
            end
            newPoint1 = Point(x1,y1)
            newPoint2 = Point(x2,y2)
            newBoundary = Boundary(newPoint1,newPoint2, self)
            newBoundary.showInfo = false
            table.insert(self.boundaries,newBoundary)
        end
    else
        con:add("can't create space boundaries. self.bpgon is nil.")
    end
end

function Space:draw()

    --draw boundaries of self
    for i, v in ipairs(self.boundaries) do
        v:draw(i)
    end

    if self.isSelected then


        --draw selection indicator
        local alpha
        if selectionMode == "space" then
            alpha = 128
        else
            alpha = 32
        end
        love.graphics.setColor(255, 255, 0, alpha)
        love.graphics.polygon("fill", unpack(self.bpgon))
    end

    --draw info
    if self.showInfo then
        love.graphics.setColor(255, 255, 255)
        local text = "#"..self:getMyIndex().."/"..self.name.."\nA:"..self:area()
        text = stringFuncs.formatText(text)
        love.graphics.print(text, unpack(self:center()))
    end

    --draw polygon points
    if self.showPoints and self.isSelected then
        for i = 1, #self.bpgon, 2 do
            px = self.bpgon[i]
            py = self.bpgon[i+1]
            newPoint = Point(px, py, {0,0,255,255})
            newPoint:draw()
        end
    end
    --draw children
    for i, v in pairs(self.spaces) do
        v:draw()
    end
end

function Space:addChild(name, bpgon)
    spaceObject = Space(name, bpgon) 
    spaceObject.parent = self
    table.insert(self.spaces, spaceObject)
    return spaceObject
end

function Space:chooseSplitBoundary()
    --returns a candidate for splitting (index, object)
    --or the selected boundary
    for i, b in ipairs(self.boundaries) do
        if b.isSelected then
            return i, b
        end
    end

    local function rateByPrevalence()
        --collect the angles and rate by prevalence
        local angles = self:getBoundaryAngles() --normalized to positive radians
        local ratedAngles = {}
        for i, a in pairs(angles) do
            --check if angle is listed
            local isListedAt = 0
            for ii, ra in ipairs(ratedAngles) do
                if ra.angle and ra.angle == a then
                    --angle is listed
                    isListedAt = ii
                    break
                end
            end
            if isListedAt > 0 then
                --ar.rating = ar.rating + 1
                --don't rate this. parallel lines get too much
                --rating value. just collect angles.
            else
                --a new angle
                ar = {}
                ar.angle = a
                ar.rating = 1
                table.insert(ratedAngles, ar) 
            end
        end

        return ratedAngles
    end

    local function rateBy90Deg(ratedAngles)
        --rate up angles that are parallel OR 90deg away from any
        --other angles
        for i, a in ipairs(ratedAngles) do

            local function is90DegFrom(a1, a2)
                if a1 == a2 then
                    --parallel
                    return true
                end
                --create comparison table
                local amin = math.min(a1,a2)
                local amax = math.max(a1,a2)
                local at = {}
                for i = 1, 3 do
                    at[i] = (at[i-1] or amin) + math.pi/2
                end
                --check for a match
                local tolerance = EPS
                local is90 = false
                for i = 1,3 do
                    if math.abs(at[i]-amax) < tolerance then
                        return true
                    end
                end
                return false
            end

            --check against all others
            for ii, aa in ipairs(ratedAngles) do
                if ii == i then
                    --don't compare against yourself
                else
                    if is90DegFrom(a.angle, aa.angle) then
                        a.rating = a.rating + 1
                    end
                end
            end
        end

        return ratedAngles

    end

    --rate angles of boundaries
    local ratedAngles = rateByPrevalence()
    ratedAngles = rateBy90Deg(ratedAngles)

    --get highest results in a table
    local highestRatedAngles = {}
    --get highest score
    local highScore = 0
    for i, a in pairs(ratedAngles) do
        if a.rating > highScore then
            highScore = a.rating
        end
    end
    --collect angles with highScore
    for i, a in pairs(ratedAngles) do
        if a.rating == highScore then
            table.insert(highestRatedAngles, a.angle)
        end
    end

    --randomly select one
    local selIndex = math.ceil(math.random(#highestRatedAngles))
    local selAngle = highestRatedAngles[selIndex]

    --find boundary with this angle and splittable and set sb
    --sb = selected boundary (index)
    local sb = 0
    local sbo = nil
    for i, b in pairs(self.boundaries) do
        if b:angle() == selAngle then
            --is splittable?
            if #b.guides.normal > 0 then
                sb = i
                sbo = b
                break
            end
        end
    end

    return sb, sbo
end

function Space:chooseSplitGuide(sbo)
    --returns a guide (index) and the guide object
    --select a guide along sb to split along
    local sgtl = #sbo.guides.sortedForSplit
    print("sgtl: "..sgtl)
    local sg = math.ceil(sgtl/2) --the middle one
    print("sg: "..sg)

    local sgo = sbo.guides.sortedForSplit[sg] --the selected guide object

    return sg, sgo
end


function Space:findGuideHitpoint(sgo, sbo)
    --returns boundary index and object of the boundary
    --which gets hit by the guide object
    --and the coordinates of the hit
    --
    --calculate guide hitpoint with a boundary
    --it is always pointing inwards. which is nice.
    --
    --sbo = the boundary from which the guide ray is cast
    --avoid intersection with this!

    local hb = 0 --"hitBoundary", the index of boundary receiving a guideline hit in split
    local hbo = nil -- hitBoundary object
    local hpx = 0 --the hit point
    local hpy = 0

    for i,b in ipairs(self.boundaries) do
        if i == sbo:getMyIndex() then
            --no test for selected boundary ("self")
        else
            --con:add("testing boundary #"..i)
            repeat --faux do loop to use breaks to escape this block
                --if hit, set hb = i
                
                --guide line coordinates (IN SCREEN! TODO)
                local glx1 = sgo.bPoint1.x
                local gly1 = sgo.bPoint1.y
                local glx2 = sgo.bPoint2.x
                local gly2 = sgo.bPoint2.y

                --test line coordinates
                local tlx1 = b.p1.x
                local tly1 = b.p1.y
                local tlx2 = b.p2.x
                local tly2 = b.p2.y

                
                --find point of intersect (hpx, hpy)
                hpx, hpy = pmath:findIntersect(
                    glx1,gly1,glx2,gly2,
                    tlx1,tly1,tlx2,tly2,
                    true, true,
                    sbo
                    )
                
                if hpx == false then
                    --no crossing
                    hb = 0
                else
                    hb = i
                    hbo = self.boundaries[hb]
                end

            until true --end of faux do loop

            if hb > 0 then
                --guide hits boundary #hb at hpx, hpy

                --print("predicting hit on boundary #"..hb)
                --leave for loop.
                --the boundaries are in clockwise order so
                --the right one should be the FIRST one that is
                --intersected.
                break
            end
        end
    end
    return hb, hbo, hpx, hpy
end



function Space:splitBoundary(boundary, atLen)
    --splits a boundary object
    --if atLen is a number, splits b at Len atLen
    --along boundary
    --if atLen is a table {x,y}, splits b at x,y

    if not boundary then
        con:add("malformed splitBoundary call")
        return
    end
    if not boundary.parent == self then
        con:add("malformed splitBoundary call")
        return
    end

    if type(atLen) == "table" then
        --split at x,y
    elseif type(atLen) == "number" then
        --split at length along boundary
    else
        con:add("malformed splitBoundary call")
        return
    end

    local bi = boundary:getMyIndex()
    local newB, nx, ny
    if type(atLen) == "number" then
        newB, nx, ny = boundary:split(atLen)
    elseif type(atLen) == "table" then
        newB, nx, ny = boundary:splitAtXy(atLen)
    end
    local btl = #self.boundaries
    --table.insert(self.boundaries, normBIndex(btl, bi+1), newB)
    table.insert(self.boundaries, bi+1, newB)

    --[[
    --TODO: this fucks up
    --manage space.bpgon
    table.insert(self.bpgon, normBIndex(btl, bi)*2+1, nx)
    table.insert(self.bpgon, normBIndex(btl, bi)*2+1, ny) --the same index, we push and slide
    --]]
    --
    return newB
end



function Space:split(name)
    --splits a space into two
    --name is the name of the new space
    
    --select a boundary to split
    --sb selected boundary (index), sbo = the boundary object
    local sb, sbo = self:chooseSplitBoundary()

    if sb == 0 then
        --no boundaries suitable for splitting
        con:add("no boundaries suitable for splitting: can't split space")
        return
    end


    --select a guide to split along
    local sg, sgo = self:chooseSplitGuide(sbo)

    if sg == 0 then
        --no guides to split along!
        con:add("no guides to split along: can't split space")
        return
    end

    --con:add("selected guide #"..sg.." for split")
    --con:add("guide x:"..sgo.point.x.." guide y:"..sgo.point.y)


    --calculate guide hitpoint with a boundary
    local hb, hbo, hpx, hpy = self:findGuideHitpoint(sgo, sbo)

    --con:add("found hitpoint for split at boundary #"..hb)
    --con:add("hitpoint x:"..hpx.." hitpoint y:"..hpy)

    local hitPoint = Point(hpx,hpy)
    if hitPoint:overlaps(sgo.point) then
        --this is weird
        con:add("hitpoint overlaps split point. won't split")
        return
    end
    if hbo == sbo then
        --this is weird
        con:add("hbo == sbo. won't split.")
        return
    end


    --split neighbouring boundaries along split points

    --manage twindoms
    local nsnSb = nil --new to-split neighbour on selected boundary side
    local nsnHb = nil --hit boundary side
    for i, t in pairs(twindoms) do

        local exclude = true
        if t:contains(sbo) then 

            --get the neighbouring space side boundary
            nsnSb = t:getTwinWithParent(self, exclude) 
            --t:separate()

        elseif t:contains(hbo) then

            --get the neighbouring space side boundary
            nsnHb = t:getTwinWithParent(self, exclude) 

        end
    end

    local newBSb = nil --new boundary on selected boundary side
    local newBHb = nil --hit boundary side
    if nsnSb then
        newBSb = nsnSb.parent:splitBoundary(nsnSb, sbo:len()-sgo.atLen) 
    end
    if nsnHb then
        newBHb = nsnHb.parent:splitBoundary(nsnHb, {hpx,hpy}) --hbo:len()-sgo.atLen) 
    end




    --CREATE BOUNDARIES FOR SPACES

    local btl = #self.boundaries --boundary table length

    --create new self bpgon
    local s1Bpgon = {} 
    local s1PointsS = {}
    local s1PointsE = {}
    local s1Boundaries = {} --we create new boundaries as we go


    --first boundary starts at sgo (guide point)
    table.insert(s1Bpgon, sgo.point.x)
    table.insert(s1Bpgon, sgo.point.y)
    s1PointsS[1] = Point(sgo.point.x, sgo.point.y)

    --next point is the hpx, hpy
    table.insert(s1Bpgon, hpx)
    table.insert(s1Bpgon, hpy)
    s1PointsE[1] = Point(hpx, hpy)

    --create first boundary between those
    local s1b1 = Boundary(s1PointsS[1],s1PointsE[1], self)
    --this is new so no inherited data
    --put in boundary reconstruction table
    table.insert(s1Boundaries, s1b1)
    

    --from there, do endpoints of boundaries until at sbo
    local ptI = 1
    local tailBoundaries = {}
    local _i = 0
    for i, b in bIter(self.boundaries, hb, sb) do
        _i = _i + 1
        table.insert(s1Bpgon, b.p2.x)
        table.insert(s1Bpgon, b.p2.y)

        ptI = ptI + 1 --start from pointset 2
        s1PointsS[ptI] = Point(s1PointsE[ptI-1].x, s1PointsE[ptI-1].y)
        s1PointsE[ptI] = Point(b.p2.x, b.p2.y)
        
        --create nth boundary between prev and this
        tailBoundaries[_i] = Boundary(s1PointsS[ptI], s1PointsE[ptI], self)
        --this inherits original boundary data
        b:setData(tailBoundaries[_i])
        --put boundary in reconstruction table
        table.insert(s1Boundaries, tailBoundaries[_i])

        --manage twindoms
        for _, t in pairs(twindoms) do
            if t:contains(b) then
                t:replace(b, tailBoundaries[_i])
            end
        end
    end

    --and create last, closing boundary
    local beforelastpoint = Point(s1PointsE[ptI].x, s1PointsE[ptI].y)
    local lastpoint = Point(s1PointsS[1].x, s1PointsS[1].y)
    local s1b3 = Boundary(beforelastpoint,lastpoint,self)
    --this inherits the data of sb
    sbo:setData(s1b3)
    --put boundary in reconstruction table
    table.insert(s1Boundaries, s1b3)







    --create new space bpgon
    local s2Bpgon = {}
    local s2PointsS = {}
    local s2PointsE = {}
    local s2Boundaries = {}


    --first boundary startpoint is the hpx, hpy
    table.insert(s2Bpgon, hpx)
    table.insert(s2Bpgon, hpy)
    s2PointsS[1] = Point(hpx,hpy)


    --second point is the guide point
    table.insert(s2Bpgon, sgo.point.x)
    table.insert(s2Bpgon, sgo.point.y)
    s2PointsE[1] = Point(sgo.point.x, sgo.point.y)


    local s2b1 = Boundary(s2PointsS[1],s2PointsE[1], nil)
    --notice we're setting the parent as nil because the space is not yet created!
    --remember to set these after said move. (update->this is done in space:new)
    --all new boundary, no inherited data

    --put in boundary construction table 
    table.insert(s2Boundaries,s2b1)


    --from there, do endpoints of boundaries until at hbo
    --until hb
    local ptI = 1
    local tailBoundaries2 = {}
    local _i = 0
    for i, b in bIter(self.boundaries, sb, hb) do
        _i = _i + 1
        table.insert(s2Bpgon, b.p2.x)
        table.insert(s2Bpgon, b.p2.y)

        ptI = ptI + 1 --start from pointset 2
        s2PointsS[ptI] = Point(s2PointsE[ptI-1].x, s2PointsE[ptI-1].y)
        s2PointsE[ptI] = Point(b.p2.x, b.p2.y)

        --create nth boundary between prev and this
        tailBoundaries2[_i] = Boundary(s2PointsS[ptI],s2PointsE[ptI],nil)
        --this inherits original boundary data
        b:setData(tailBoundaries2[_i])
        --put in boundary reconstruction table
        table.insert(s2Boundaries, tailBoundaries2[_i])

        --manage twindoms
        for _, t in pairs(twindoms) do
            if t:contains(b) then
                t:replace(b, tailBoundaries2[_i])
            end
        end

    end
    local beforelastpoint = Point(s2PointsE[ptI].x, s2PointsE[ptI].y)
    local lastpoint = Point(s2PointsS[1].x, s2PointsS[1].y)

    --and create last, closing boundary
    local s2b3 = Boundary(beforelastpoint, lastpoint,nil)
    --this inherits the data of hb
    hbo:setData(s2b3)
    --put in boundary reconstruction table
    table.insert(s2Boundaries, s2b3)
    




    --bpgons and new boundaries are baked
    --
    --separate old twindoms of sbo, hbo
    for i, t in pairs(twindoms) do
        if t:contains(sbo) or t:contains(hbo) then
            con:add("separating hbo/sbo:")
            con:add("S#"..t.si[1].."/B#"..t.bi[1].."++S#"..t.si[2].."B#"..t.bi[2])
            t:separate()
        end
    end

    --update old boundaries
    self:update(s1Bpgon, s1Boundaries)

    --create new space. this also sets correct boundary parents.
    local s2 = Space(name, s2Bpgon, s2Boundaries)



    --create new twindoms
    local newTwindomShared = Twindom(s1Boundaries[1], s2Boundaries[1])

    if newBSb then
        --local newTwindomSboO = Twindom(nsnSb, tailBoundaries2[1])
        local newTwindomSboN = Twindom(newBSb, s1b3)
    end
    if newBHb then
        --local newTwindomHboO = Twindom(nsnHb, tailBoundaries[1])
        local newTwindomHboN = Twindom(newBHb, s2b3)
    end

    --update twindoms
    for i, t in pairs(twindoms) do
        local dbt = "t:update, s#"..(t.si[1] or "nil").."b#"..(t.bi[1] or "nil")
        dbt = dbt.."++s#"..(t.si[2] or "nil").."b#"..(t.bi[2] or "nil")
        t:update(dbt)
    end

        
    con:add("Space was split")

end

function Space:getMyIndex()
    for i, s in ipairs(getObjectTree()) do
        if s == self then
            return i
        end
    end
end


function Space:area()
    --return the area for the space object
    local debug = self.debug
    triangles = love.math.triangulate(self.bpgon)
    area = 0
    for i, v in ipairs(triangles) do
        thisarea = 0
        --calculate side lengths
        x1 = v[1]
        y1 = v[2]
        x2 = v[3]
        y2 = v[4]
        x3 = v[5]
        y3 = v[6]
        xp12 = (x1-x2)*(x1-x2)
        xp23 = (x2-x3)*(x2-x3)
        xp31 = (x3-x1)*(x3-x1)
        yp12 = (y1-y2)*(y1-y2)
        yp23 = (y2-y3)*(y2-y3)
        yp31 = (y3-y1)*(y3-y1)
        side1 = math.sqrt(xp12+yp12) 
        side2 = math.sqrt(xp23+yp23) 
        side3 = math.sqrt(xp31+yp31) 
        p = (side1 + side2 + side3) / 2
        thisarea = math.sqrt(p*(p-side1)*(p-side2)*(p-side3))
        area = area + thisarea
        if debug then
            --draw calc triangles
            love.graphics.setColor(255, 255, 255)
            love.graphics.polygon("line", x1, y1, x2, y2, x3, y3)
        end
    end
    return area
end

function Space:center()
    --get the centerpoint of space for info
    --
    --given vertex points of polygon, draw lines from
    --every vertex to the vertex that is numVertices/2 away
    --from that point. Calculate midpoints of each line.
    --Get average of those points.
    --
    --gets distortion from vertex distribution
    --TODO:replace with a better algorithm
    --
    local verts = {}
    for i = 1, #self.bpgon, 2 do
        table.insert(verts, {})
        local vi = math.ceil(i/2)
        verts[vi].x = self.bpgon[i]
        verts[vi].y = self.bpgon[i+1]
    end
    local midPoints = {}
    for i = 1, #verts/2 do
        oi = i + math.ceil(#verts/2)
        midPoints[i] = pmath:lineCenter(verts[i].x,verts[i].y,verts[oi].x,verts[oi].y)
    end
    local mpx = 0
    local mpy = 0
    for i, ml in pairs(midPoints) do
       mpx = mpx + ml[1] 
       mpy = mpy + ml[2]
    end
    mpx = mpx / #midPoints
    mpy = mpy / #midPoints
    return {mpx,mpy}
end


function Space:getBoundaryAngles()
    local angles = {}
    for i, v in pairs(self.boundaries) do
        table.insert(angles, v:angle())
    end
    return angles
end
