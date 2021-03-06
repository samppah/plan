Twindom = Object:extend()

local twindoms = getTwindoms()


function Twindom:new(boundary1, boundary2)

    self.bo = {boundary1, boundary2}
    self.bi = {boundary1:getMyIndex("Twindom:new, b1"), boundary2:getMyIndex("Twindom:new, b2")}

    self.so = {boundary1.parent, boundary2.parent}
    self.si = {boundary1.parent:getMyIndex(), boundary2.parent:getMyIndex()}

    self.isWonky = false --debug

    self.isHovered = false

    if (not self.so[1]) or (not self.so[2]) then
        con:add("creating twindom without parent space")
    end

    self.center = boundary1:center()

    self.len = self.bo[1]:len()

    self.canFitDoor = self.len >= minDoorWidth


    table.insert(twindoms, self)

end

function Twindom:update(debug)
    local dbt
    if not debug then
        dbt = ""
    else
        dbt = debug.." -> "
    end

    --test if separated
    if not (self.bo[1]:overlaps(self.bo[2])) then
        con:add("update:separating outdated twindom:")
        con:add("S#"..self.si[1].."/B#"..self.bi[1].."++S#"..self.si[2].."B#"..self.bi[2])
        self.isWonky = true
        --self:separate()
    end

    --update geometry info
    self.center = self.bo[1]:center()
    self.len = self.bo[1]:len()

    self.canFitDoor = self.len >= minDoorWidth

    --update index info
    self.bi = {self.bo[1]:getMyIndex(dbt.."Twindom:update, b1"), self.bo[2]:getMyIndex(dbt.."Twindom:update, b2")}
    self.so = {self.bo[1].parent, self.bo[2].parent}
    self.si = {self.so[1]:getMyIndex(), self.so[2]:getMyIndex()}
end


function Twindom:replace(old, new)

    local oldRef = 0
    if self.bo[1] == old then
        oldRef = 1
    elseif self.bo[2] == old then
        oldRef = 2
    end

    if oldRef == 0 then
        con:add("can't replace old in twindom. old is not contained")
        return

    elseif oldRef == 1 then
        if new.parent ~= old.parent then
            con:add("can't replace old in twindom. new has a different parent")
            return
        elseif new.parent ~= self.so[1] then
            con:add("can't replace old in twindom. new has a different parent")
            return
        else
            if self.bo[2]:overlaps(new) then 
                --do it
                self.bo[1] = new
                self.so[1] = new.parent
            else
                local nx1 = new.p1.x
                local ny1 = new.p1.y
                local nx2 = new.p2.x
                local ny2 = new.p2.y
                local ox1 = self.bo[2].p1.x
                local oy1 = self.bo[2].p1.y
                local ox2 = self.bo[2].p2.x
                local oy2 = self.bo[2].p2.y
                con:add("can't replace old in twindom. new doesn't overlap b2")
                con:add("nx1="..nx1.."/ox1="..ox1.."/nx2="..nx2.."/ox2="..ox2)
                con:add("ny1="..ny1.."/oy1="..oy1.."/ny2="..ny2.."/oy2="..oy2)
            end
        end
    else
        --oldRef == 2
        if new.parent ~= old.parent then
            con:add("can't replace old in twindom. new has a different parent")
            return
        elseif new.parent ~= self.so[2] then
            con:add("can't replace old in twindom. new has a different parent")
            return
        else
            if self.bo[1]:overlaps(new) then 
                --do it
                self.bo[2] = new
                self.so[2] = new.parent
            else
                local nx1 = new.p1.x
                local ny1 = new.p1.y
                local nx2 = new.p2.x
                local ny2 = new.p2.y
                local ox1 = self.bo[1].p1.x
                local oy1 = self.bo[1].p1.y
                local ox2 = self.bo[1].p2.x
                local oy2 = self.bo[1].p2.y
                con:add("can't replace old in twindom. new doesn't overlap b2")
                con:add("nx1="..nx1.."/ox1="..ox1.."/nx2="..nx2.."/ox2="..ox2)
                con:add("ny1="..ny1.."/oy1="..oy1.."/ny2="..ny2.."/oy2="..oy2)

            end
        end
    end

    --self:update()
end

function Twindom:separate()
    local myIndex = 0
    for i, t in ipairs(twindoms) do
        if t == self then
            myIndex = i
            break
        end
    end
    table.remove(twindoms, myIndex)
end

function Twindom:contains(boundary)
    return self.bo[1] == boundary or self.bo[2] == boundary
end

function Twindom:containsSpace(space)
    return self.so[1] == space or self.so[2] == space
end

function Twindom:getTwinWithParent(space, exclusion)
    --exclusion, if set true, returns the boundary
    --whose parent is NOT the space
    if space == self.so[1] then
        if exclusion then
            return self.bo[2]
        else
            return self.bo[1]
        end
    else
        if exclusion then
            return self.bo[1]
        else
            return self.bo[2]
        end
    end
end

function Twindom:isSelected()
    local b1 = self.bo[1]
    local b2 = self.bo[2]
    local s1 = self.so[1]
    local s2 = self.so[2]
    return (selectionMode == "space" and (s1.isSelected or s2.isSelected)) or (selectionMode == "boundary" and (s1.isSelected and b1.isSelected) or (s2.isSelected and b2.isSelected))
end

function Twindom:isVirtual()
    local b1 = self.bo[1]
    local b2 = self.bo[2]
    return b1.isVirtual and b2.isVirtual
end

function Twindom:isAdjacent(twindom)
    --untested
    --[[
    local b1 = self.bo[1]
    local b2 = self.bo[2]
    local s1 = self.so[1]
    local s2 = self.so[2]
    local s1btl = #s1.boundaries
    local s2btl = #s2.boundaries

    local bt1 = twindom.bo[1]
    local bt2 = twindom.bo[2]
    local st1 = twindom.so[1]
    local st2 = twindom.so[2]
    local st1btl = #s1.boundaries
    local st2btl = #s2.boundaries
    
    local isAdj = false

    if b1:isAdjacent(s1btl, bt1) then
        isAdj = true
    end
    if b1:isAdjacent(s1btl, bt2) then
        isAdj = true
    end
    if b2:isAdjacent(s2btl, bt1) then
        isAdj = true
    end
    if b2:isAdjacent(s2btl, bt2) then
        isAdj = true
    end

    return isAdj
    --]]
    return false
end

function Twindom:draw()

    --draw twin symbols
    --make them blink RED when space is selected,
    --show faded red otherwise
    local drawTwinLines = false

    local b1 = self.bo[1]
    local b2 = self.bo[2]

    local s1 = self.so[1]
    local s2 = self.so[2]

    local alpha = 255

    drawTwinSymbols = true

    if self:isSelected() then
        if getBlinkStat() then
            alpha = 255
            love.graphics.setColor(255,0,0)
        else
            drawTwinSymbols = false
        end
    else
        alpha = 128
    end

    if drawTwinSymbols then
        if self.isWonky then
            love.graphics.setColor(255,0,0,alpha)
            love.graphics.circle("line", b1:center()[1], b1:center()[2], 10)
            love.graphics.setColor(0,255,0,alpha)
            love.graphics.circle("line", b2:center()[1], b2:center()[2], 5)
        else
            love.graphics.setColor(255,0,0,alpha)
            love.graphics.circle("fill", b1:center()[1], b1:center()[2], 10)
            love.graphics.setColor(0,255,0,alpha)
            love.graphics.circle("fill", b2:center()[1], b2:center()[2], 5)
        end
    end

    --draw hovering data on cursor
    if self.isHovered then
        local text = "twin1 = S#"..(self.si[1] or "nil").."B#"..(self.bi[1] or "nil")
        text = text .. "\ntwin2 = S#"..(self.si[2] or "nil").."B#"..(self.bi[2] or "nil")
        text = text .. "\ncanFitDoor = " .. (self.canFitDoor and "true" or "false")
        text = text .. "\nisWonky = " .. (self.isWonky and "true" or "false")
        love.graphics.setColor(255,255,255,255)
        love.graphics.print(text, 0,0)--self.center[1], self.center[2])
        --draw adjacent twindoms symbols
        for i, t in pairs(twindoms) do
            if t:isAdjacent(self) then
                love.graphics.setColor(255,255,255,255)
                love.graphics.circle("line", t.center[1], t.center[2], 15)
            end
        end
    end

end
