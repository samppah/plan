Space = Object:extend()

Space.debug = true

local stringFuncs = require "strings"
local pmath = require "pmath"

local con = getCon() --get ref to main console

require "classes/Boundary"


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
    self.isSelected = false
    self.debug = false

    self.sharedBoundaries = {} --table to hold shared boundaries
    self.outerBoundaries = {} --table to hold outer boundaries


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
        --recreate shared boundaries table
        for i, v in pairs(boundaries) do
            if v.isShared then
                table.insert(self.sharedBoundaries, v.sharedRef)
            end
        end
    end

    --set default shared and outer
    for i, b in pairs(self.boundaries) do
        self:setOuter(i)
    end
end

function Space:update(bpgon, boundaries)
    self.bpgon = bpgon
    self.boundaries = boundaries
end

function Space:shareBoundary(bi, ssi, sbi)
    --bi = index of boundary to share in this space
    --ssi = index of parent space of shared boundary
    --sbi = index of boundary of the adjacent space to share

    bo = self.boundaries[bi]
    sbo = getObjectTree()[ssi].boundaries[sbi]

    bo:setShared(sbo)

    table.insert(self.sharedBoundaries, self.boundaries[bi].sharedRef)
    con:add("Shared my boundary #"..bi.." with space #"..ssi.."'s boundary #"..sbi)
    
end


function Space:setOuter(bi)
    --set outer
    local outerRef = {}
    table.insert(self.outerBoundaries, bi)
    con:add("Set my boundary #"..bi.." outer.")
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
    --draw self
    for i, v in ipairs(self.boundaries) do
        v:draw(i)
    end

    --draw selection indicator
    if self.isSelected then
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

function Space:split(name)
    
    --select a boundary to split

    --collect the angles and rate by prevalence
    local angles = self:getBoundaryAngles() --normalized to positive radians
    local anglesRating = {}
    for i, a in pairs(angles) do
        --check if angle is listed
        local isListedAt = 0
        for ii, ra in ipairs(anglesRating) do
            if ra.angle and ra.angle == a then
                --angle is listed
                isListedAt = ii
                break
            end
        end
        if isListedAt > 0 then
            ar.rating = ar.rating + 1
        else
            --a new angle
            ar = {}
            ar.angle = a
            ar.rating = 1
            table.insert(anglesRating, ar) 
        end
    end

    --rate up angles that are parallel OR 90deg away from any
    --other angles
    for i, a in ipairs(anglesRating) do

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
            local tolerance = 0.0000000001
            local is90 = false
            for i = 1,3 do
                if math.abs(at[i]-amax) < tolerance then
                    return true
                end
            end
            return false
        end

        --check against all others
        for ii, aa in ipairs(anglesRating) do
            if ii == i then
                --don't compare against yourself
            else
                if is90DegFrom(a.angle, aa.angle) then
                    a.rating = a.rating + 1
                end
            end
        end
    end

    --[[
    --debug dump
    print("Selecting boundary to split")
    for i, v in ipairs(anglesRating) do
        print("angle #"..i..": "..v.angle.." / score: "..v.rating)
    end
    --]]

    --get highest results in a separate table
    local highestRatedAngles = {}
    --get highest score
    local highScore = 0
    for i, a in pairs(anglesRating) do
        if a.rating > highScore then
            highScore = a.rating
        end
    end
    --collect angles with highScore
    for i, a in pairs(anglesRating) do
        if a.rating == highScore then
            table.insert(highestRatedAngles, a.angle)
        end
    end

    --randomly select one
    local selIndex = math.ceil(math.random(#highestRatedAngles))
    local selAngle = highestRatedAngles[selIndex]

    --find boundary with this angle and splittable and set sb
    local sb = 1
    for i, b in pairs(self.boundaries) do
        if b:angle() == selAngle then
            --is splittable?
            if #b.guides.normal > 0 then
                sb = i
                break
            end
        end
    end
    --set oldSb to use with sharing setting
    oldSb = sb

    --debug
    --print("selected boundary #"..sb..", index:"..selIndex.."/"..#highestRatedAngles)


    for i, v in ipairs(self.boundaries) do
        if v.isSelected then
            sb = i
            break
        end
    end
    sbo = self.boundaries[sb] --the selected boundary object


    --select a guide along sb to split along
    local sgtl = #sbo.guides.sortedForSplit
    print("sgtl: "..sgtl)
    local sg = math.ceil(sgtl/2) --the middle one
    print("sg: "..sg)

    if sg == 0 then
        --no guides to split along!
        con:add("can't split space")
        return
    end

    local hb = 0 --"hitBoundary", the index of boundary receiving a guideline hit in split
    local hbo = nil -- hitBoundary object
    local hpx = 0 --the hit point
    local hpy = 0

    con:add("Space:split("..(name or "")..")")

    sgo = sbo.guides.sortedForSplit[sg] --the selected guide object
    sgo.isSelected = true
    --print("sgo: "..sgo)
    --calculate guide hitpoint with a boundary
    --it is always pointing inwards. which is nice.

    for i,b in ipairs(self.boundaries) do
        if i == sb then
            --no test for selected boundary ("self")
        else
            con:add("testing boundary #"..i)
            repeat --faux do loop to use breaks to escape this block
                --
                --SUPER TESTING
                --
                --if hit, set hb = i
                --
                
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


                local doCross = pmath:checkIntersect(
                    {x = glx1, y = gly1},
                    {x = glx2, y = gly2},
                    {x = tlx1, y = tly1},
                    {x = tlx2, y = tly2})


                if not doCross then
                    break --exit faux do loop
                end

                --they cross! yeah baby!
                hb = i
                hbo = self.boundaries[hb]
                
                --find point of intersect (hpx, hpy)
                hpx, hpy = pmath:findIntersect(
                    glx1,gly1,glx2,gly2,
                    tlx1,tly1,tlx2,tly2,
                    true, true
                    )
                print("x = glx1:"..glx1..", y = gly1:"..gly1)
                print("x = glx2:"..glx2..", y = gly2:"..gly2)
                print("x = tlx1:"..tlx1..", y = tly1:"..tly1)
                print("x = tlx2:"..tlx2..", y = tly2:"..tly2)



            until true --end of faux do loop
            

            if hb > 0 then
                --guide hits boundary #hb at hpx, hpy

                print("predicting hit on boundary #"..hb)
                --leave for loop.
                --the boundaries are in clockwise order so
                --the right one should be the FIRST one that is
                --intersected.
                break
            end
        end
    end

    if hb == 0 then
        print("No hb found!"..hb)
        con:add("Could not find hb")
        return
    end
    if hpx == false then
        --a hit predicted but no hit point registered
        --some tolerance issues with pmath:findIntersect did this
        con:add("weird shit happenin, boss:"..hpy)
        return
    end

    --CREATE BOUNDARIES FOR SPACES
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
        --end_ is not normalized
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



    --TODO:managing shared boundaries is a pain in the ass
    --maybe there's something more intuitive than the
    --"SharedBoundaries" -table (which should be updated ALL the time)

    --I can't split boundaries, because the table is not reliable

    --[[
    --split neighbouring boundaries, if shared
    local newSplitNeighbourSb = nil
    local newSplitNeighbourHb = nil
    for i, sharedRef in pairs(self.sharedBoundaries) do
        local bi = sharedRef.bi
        local bo = sharedRef.bo
        local sbi = sharedRef.sbi
        local sbo = sharedRef.sbo
        local ssi = sharedRef.ssi
        local sso = sharedRef.sso

        local atLen = sgo.atLen
        local atInvLen = hbo:len()-sgo.atLen

        if bi == sb or bi == hb then
            local newB = nil
            if bi == sb then
                --split boundary
                newB = sbo:split(atLen)
                newSplitNeighbourSb = newB
            elseif sharedRef.bi == hb then
                --split
                newB = sharedRef.sbo:split(atInvLen)
                newSplitNeighbourHb = newB
            end
            --push boundary in right spot at sso.boundaries
            local ssobtl = #sso.boundaries
            table.insert(sso.boundaries, normBIndex(ssobtl, sbi), newB)
            --manage sso.bpgon
            table.insert(sso.bpgon, (sbi)*2, newB.p1.y)
            table.insert(sso.bpgon, (sbi)*2, newB.p1.x) --the same index, we push and slide
        else
            --don't split!
        end
    end
    --]]





    local btl = #self.boundaries --boundary table length

    --create new self bpgon
    local s1Bpgon = {} 
    local s1Points = {}
    local s1Boundaries = {} --we create new boundaries as we go


    --first boundary starts at sgo (guide point)
    table.insert(s1Bpgon, sgo.point.x)
    table.insert(s1Bpgon, sgo.point.y)
    s1Points[1] = Point(sgo.point.x, sgo.point.y)

    --next point is the hpx, hpy
    table.insert(s1Bpgon, hpx)
    table.insert(s1Bpgon, hpy)
    s1Points[2] = Point(hpx, hpy)

    --create first boundary between those
    local s1b1 = Boundary(s1Points[1],s1Points[2], self)
    --this is new so no inherited data
    --put in boundary reconstruction table
    table.insert(s1Boundaries, s1b1)
    

    --from there, do endpoints of boundaries until at sbo
    local ptI = 2
    local tailBoundaries = {}
    for i, b in bIter(self.boundaries, hb, sb) do
        table.insert(s1Bpgon, b.p2.x)
        table.insert(s1Bpgon, b.p2.y)

        ptI = ptI + 1 --start from point 3
        s1Points[ptI] = Point(b.p2.x, b.p2.y)
        
        --create nth boundary between prev and this
        tailBoundaries[i] = Boundary(s1Points[ptI-1], s1Points[ptI], self)
        --this inherits original boundary data
        b:setData(tailBoundaries[i])
        --put boundary in reconstruction table
        table.insert(s1Boundaries, tailBoundaries[i])
    end

    --and create last, closing boundary
    local s1b3 = Boundary(s1Points[ptI],s1Points[1],self)
    --this inherits the data of sb
    sbo:setData(s1b3)
    --put boundary in reconstruction table
    table.insert(s1Boundaries, s1b3)







    --create new space bpgon
    local s2Bpgon = {}
    local s2Points = {}
    local s2Boundaries = {}


    --first boundary startpoint is the hpx, hpy
    table.insert(s2Bpgon, hpx)
    table.insert(s2Bpgon, hpy)
    s2Points[1] = Point(hpx,hpy)


    --second point is the guide point
    table.insert(s2Bpgon, sgo.point.x)
    table.insert(s2Bpgon, sgo.point.y)
    s2Points[2] = Point(sgo.point.x, sgo.point.y)


    local s2b1 = Boundary(s2Points[1],s2Points[2], nil) --notice we're setting the parent as nil because the space is not yet created! remember to set these after said move. (this is done in space:new)
    --all new boundary, no inherited data

    --put in boundary construction table 
    table.insert(s2Boundaries,s2b1)


    --from there, do endpoints of boundaries until at hbo
    --until hb
    local ptI = 2
    local tailBoundaries2 = {}
    for i, b in bIter(self.boundaries, sb, hb) do
        table.insert(s2Bpgon, b.p2.x)
        table.insert(s2Bpgon, b.p2.y)

        ptI = ptI + 1 --start from point 3
        s2Points[ptI] = Point(b.p2.x, b.p2.y)

        --create nth boundary between prev and this
        tailBoundaries2[i] = Boundary(s2Points[ptI-1],s2Points[ptI],nil)
        --this inherits original boundary data
        b:setData(tailBoundaries2[i])
        --put in boundary reconstruction table
        table.insert(s2Boundaries, tailBoundaries2[i])

    end

    --and create last, closing boundary
    local s2b3 = Boundary(s2Points[ptI],s2Points[1],nil)
    --this inherits the data of hb
    hbo:setData(s2b3)
    --put in boundary reconstruction table
    table.insert(s2Boundaries, s2b3)
    




    --bpgons are done
    --
    --update old boundaries
    self:update(s1Bpgon, s1Boundaries)

    --create new space
    local s2 = Space(name, s2Bpgon, s2Boundaries)

    --new boundary is shared with self, new space
    local setSBI1=1
    local setSBI2=1
    local ssi = #getObjectTree() --the new space index, latest one created
    self:shareBoundary(setSBI1, ssi, setSBI2) 


    --[[
    --set sharing information for new split neighbours
    if newSplitNeighbourSb then
        --it's the same sharing info
    end

    if newSplitNeighbourHb then
        local n = newSplitNeighbourHb
        s2:shareBoundary(2, n.parent:getMyIndex(), n:getMyIndex())
    end
    --]]



    --[[
    --debug space boundary data
    for i,b in ipairs(self.boundaries) do
        print("boundary #"..i)
        print("  isOuter: "..(b.isOuter and "true" or "-"))
        print("  isShared: "..(b.isShared and "true" or "-"))
        print("  sharedRef.bi: "..(b.sharedRef.bi or "-"))
        print("  sharedRef.ssi: "..(b.sharedRef.ssi or "-"))
        print("  sharedRef.sbi: "..(b.sharedRef.sbi or "-"))
    end
    --]]
        
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

function Space:splitBoundary(index)
    --splits a boundary object
    local newBoundary = self.boundaries[index]:split()
    table.insert(self.boundaries, index+1, newBoundary)
end

function Space:getBoundaryAngles()
    local angles = {}
    for i, v in pairs(self.boundaries) do
        table.insert(angles, v:angle())
    end
    --[[
    angles[1]=10
    angles[2]=20
    --]]
    return angles
end
