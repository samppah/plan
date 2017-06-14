local pmath = {}

function pmath.sign(n)
    return n>0 and 1
        or n<0 and -1
        or 0
end
math.sign = math.sign or pmath.sign


function pmath.round(n, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(n * mult + 0.5) / mult
end
math.round = math.round or pmath.round

function pmath:dist(x1,y1,x2,y2)
    return ((x2-x1)^2+(y2-y1)^2)^0.5
end

function pmath:checkIntersect(l1p1, l1p2, l2p1, l2p2)
        --from:https://love2d.org/wiki/General_math
	local function checkDir(pt1, pt2, pt3)
            return math.sign(((pt2.x-pt1.x)*(pt3.y-pt1.y)) - ((pt3.x-pt1.x)*(pt2.y-pt1.y)))
        end
	return (checkDir(l1p1,l1p2,l2p1) ~= checkDir(l1p1,l1p2,l2p2))
            and (checkDir(l2p1,l2p2,l1p1) ~= checkDir(l2p1,l2p2,l1p2))
end

function pmath:lineCenter(x1,y1, x2,y2)
    --return a line segment centerpoint, table format {x,y}
    return {x1+((x2-x1)/2),y1+((y2-y1)/2)}
end

function pmath:pointAtLen(len, x1,y1,x2,y2)
    local totLen = pmath:dist(x1,y1,x2,y2)
    local ratio = len/totLen
    return {x1+((x2-x1)*ratio), y1+((y2-y1)*ratio)}
end

function pmath:findIntersect(l1p1x,l1p1y, l1p2x,l1p2y, l2p1x,l2p1y, l2p2x,l2p2y, seg1, seg2, selfObject)
    -- applied from: https://love2d.org/forums/viewtopic.php?f=4&t=12175&p=73352&hilit=line+intersection#p73352
    -- Checks if two lines intersect (or line segments if seg is true)
    -- Lines are given as four numbers (two coordinates)

    --check if intersection is with self. if so, return false
    local tempPoint1 = Point(l2p1x,l2p1y)
    local tempPoint2 = Point(l2p2x,l2p2y)
    local tempBoundary = Boundary(tempPoint1, tempPoint2)
    if selfObject:overlaps(tempBoundary) then
        return false, "false hit with line casting the guide ray"
    end
    local tolerance = EPS -- added tolerance
    local a1,b1,a2,b2 = l1p2y-l1p1y, l1p1x-l1p2x, l2p2y-l2p1y, l2p1x-l2p2x
    local c1,c2 = a1*l1p1x+b1*l1p1y, a2*l2p1x+b2*l2p1y
    local det = a1*b2 - a2*b1
    if det==0 then return false, "The lines are parallel." end
    local x,y = (b2*c1-b1*c2)/det, (a1*c2-a2*c1)/det
    if seg1 or seg2 then
        local min,max = math.min, math.max
        if seg1 and not (min(l1p1x,l1p2x) <= x + tolerance and x <= max(l1p1x,l1p2x) + tolerance and min(l1p1y,l1p2y) <= y + tolerance 
                and y <= (max(l1p1y,l1p2y)) + tolerance) or
           seg2 and not (min(l2p1x,l2p2x) <= x + tolerance and x <= max(l2p1x,l2p2x) + tolerance and min(l2p1y,l2p2y) <= y + tolerance 
                and y <= (max(l2p1y,l2p2y)) + tolerance) then
            return false, "The lines don't intersect."
        end
    end
    return x,y
end

return pmath
