Twindom = Object:extend()

local twindoms = getTwindoms()


function Twindom:new(boundary1, boundary2)
    --[[
    self.bo1 = boundary1
    self.bi1 = boundary1:getMyIndex()

    self.bo2 = boundary2
    self.bi2 = boundary2:getMyIndex()

    self.so1 = boundary1.parent
    self.si1 = boundary1.parent:getMyIndex()

    self.so2 = boundary2.parent
    self.si2 = boundary2.parent:getMyIndex()
    --]]
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
    else
        self.isWonky = false
    end

    --update geometry info
    self.center = self.bo[1]:center()
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

        --maybe a way to test if new boundary is a part of
        --one of the spaces, specifically of the same, where
        --the old is contained in
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
                con:add("can't replace old in twindom. new doesn't overlap b2")
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
                con:add("can't replace old in twindom. new doesn't overlap b1")
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

function Twindom:draw()

    --draw twin linesymbols
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
        local text = "twin1 = S#"..self.si[1].."B#"..self.bi[1]
        text = text .. "\ntwin2 = S#"..self.si[2].."B#"..self.bi[2]
        love.graphics.setColor(255,255,255,255)
        love.graphics.print(text, 0,0)--self.center[1], self.center[2])
    end

end
