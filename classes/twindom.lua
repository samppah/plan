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
    self.bi = {boundary1:getMyIndex(), boundary2:getMyIndex()}

    self.so = {boundary1.parent, boundary2.parent}
    self.si = {boundary1.parent:getMyIndex(), boundary2.parent:getMyIndex()}


    if (not self.so[1]) or (not self.so[2]) then
        con:add("creating twindom without parent space")
    end

    self.center = boundary1:center()

    table.insert(twindoms, self)

end

function Twindom:update()
    self.center = self.bo[1]:center()
    self.bi = {self.bo[1]:getMyIndex(), self.bo[2]:getMyIndex()}
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
            --do it
            self.bo[1] = new
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
            --do it
            self.bo[2] = new
        end
    end
    self:update()
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
    if s1.isSelected or s2.isSelected then
        if getBlinkStat() then
            alpha = 255
            love.graphics.setColor(255,0,0)
            drawTwinLines = true
        end
    else
        alpha = 128
        drawTwinLines = true
    end

    if drawTwinLines then
        --[[
        local sin = math.sin
        local cos = math.cos

        local offsetx = 5
        local offsety1 = 15
        local offsety2 = 5
        local ang2 = b1:angle()-math.pi*2 --angle of share line
        local p = b1:pointAtLen(b1:len()/2-offsetx)
        local spx = p[1] + offsetx * sin(ang2)
        local spy = p[2] + offsety1 * cos(ang2)
        local epx = p[1] - offsetx * sin(ang2)
        local epy = p[2] - offsety2 * cos(ang2)
        love.graphics.line(spx,spy,epx,epy)

        local p = b1:pointAtLen(b1:len()/2+offsetx)
        local spx = p[1] + offsetx * sin(ang2)
        local spy = p[2] + offsety2 * cos(ang2)
        local epx = p[1] - offsetx * sin(ang2)
        local epy = p[2] - offsety1 * cos(ang2)
        love.graphics.line(spx,spy,epx,epy)
        --]]
        love.graphics.setColor(255,0,0,alpha)
        love.graphics.circle("fill", b1:center()[1], b1:center()[2], 10)
        love.graphics.setColor(0,255,0,alpha)
        love.graphics.circle("fill", b2:center()[1], b2:center()[2], 5)
    end

end
