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

function Twindom:separate()
    local myIndex = 0
    for i, t in ipairs(twindoms) do
        if t = self then
            myIndex = i
            break
        end
    end
    table.remove(twindoms, myIndex)
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

    if s1.isSelected or s2.isSelected then
        if getBlinkStat() then
            love.graphics.setColor(255,0,0)
            drawTwinLines = true
        end
    else
        love.graphics.setColor(255,0,0,128)
        drawTwinLines = true
    end

    if drawTwinLines then
        local offsetx = 5
        local offsety1 = 15
        local offsety2 = 5
        local ang2 = b1:angle()-math.pi*2 --angle of share line
        local p = b1:pointAtLen(self:len()/2-offset)
        local spx = p[1] + offsetx * sin(ang2)
        local spy = p[2] + offsety1 * cos(ang2)
        local epx = p[1] - offsetx * sin(ang2)
        local epy = p[2] - offsety2 * cos(ang2)
        love.graphics.line(spx,spy,epx,epy)

        local p = b1:pointAtLen(self:len()/2+offset)
        local spx = p[1] + offsetx * sin(ang2)
        local spy = p[2] + offsety2 * cos(ang2)
        local epx = p[1] - offsetx * sin(ang2)
        local epy = p[2] - offsety1 * cos(ang2)
        love.graphics.line(spx,spy,epx,epy)
    end

end
