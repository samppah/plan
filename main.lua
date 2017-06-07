--math.randomseed(os.time())

Object = require "libraries/classic"

objectTree = {} --a table to hold all objects (for mouse GUI interaction)
function getObjectTree()
    --this can be called by subs to get main objectTree reference
    return objectTree
end

local blinkTimer = 0
local blinkSec = 0.5
local blinkStat = true
function getBlinkStat()
    return blinkStat
end


require "classes/console"
con = Console("main")

function getCon()
    --a function for classes to use the main console
    return con
end
selectionMode = "space" --/"boundary"

globalGrid = 30
EPS = 0.001


globalDecimals = 3 --for all results round STRINGS to this number of decimals


desiredRooms = {
    "OH",
    "MH",
    "WC",
    "ET",
    "K"
}

require "classes/Space"
require "classes/cursor"
require "classes/guideline"
--require "classes/Boundary"












function love.load()

    love.keyboard.setKeyRepeat = true

    s1 = Space( desiredRooms[1], {
                100,100,
                500,100,
                400,400,
                100,400
            })
            --[[
    s2 = Space( "living", {
                300,50,
                550,50,
                550,200,
                300,300
            })
            --]]

    s1.isSelected = true --select space for modifications

    --[[
    s2 = s1:addChild ( "child",
 {       100,100,
        300,100,
        300,200,
        200,200
    })
    --]]

    --draw a guide
    g1 = Guide(400,200, -2*math.pi) --true: drawInfo
    g1.isVisible = true
    g1.drawInfo = true

    cursor = Cursor()


    --[[
    --PRE SPLIT
    --split the master space into desiredRooms nr of spaces
    local safety = 1000
    local roomNr = 2
    local otn = #objectTree
    while #objectTree < #desiredRooms and safety > 0 do
        safety = safety - 1
        local function selectSpaceToSplit()
            --random placeholder
            return math.ceil(math.random(#objectTree))
        end

        local si = selectSpaceToSplit()
        objectTree[si]:split(desiredRooms[roomNr])
        if otn < #objectTree then
            --split was succesful
            otn = #objectTree
            roomNr = roomNr + 1
        end
    end
    con:add("PreSplitting done, after "..1000-safety.."tries")
    --]]


    --[[
    --try passing data
    for i,b in ipairs(s1.boundaries) do
        if i == 2 then
            --nothing
        else
            s1.boundaries[2]:setData(s1.boundaries[i])
        end
    end
    --]]
end












function love.draw()
    for i, v in pairs(objectTree) do
        v:draw()
    end
    con:draw()
    --cursor:draw()
    g1:draw()

end









local gps = 0 --guide position "multiplier" for auto-moving guide point
local rotcallback = function ()
    --this is used to rotate the guide line
    --this is called by update. the mapped
    --ui functions relink this function to
    --ones that spin the line
end


function love.update(dt)

    --cursor:update(objectTree)

    --Auto move guideline point in circular motion
    --[[
    --move guideline
    gps = gps + (math.pi/80)

    if gps > 2*math.pi then gps = 0 end
    g1.point.x = g1.point.x + 4*(math.cos(gps))
    g1.point.y = g1.point.y + 1.5*(math.sin(gps))
    --]]

    --call guideline rotating function
    rotcallback()

    --manage blinking element timer
    blinkTimer = blinkTimer + 1 * dt
    if blinkTimer >= blinkSec then
        blinkTimer = 0
        blinkStat = not blinkStat
    end
end






--KEYBOARD HANDLING, USER INTERFACE
--define keyboard controlled ui functions

--helpers
local function getSelectedSpace()
    for i, v in ipairs(objectTree) do
        if v.isSelected then
            return v
        end
    end
    return nil
end


--keyEvents
keyEvents = {}
keyEvents.dummy = function()
    con:add("dummy")
end
keyEvents.spaceDebugToggle = function()

    local s = getSelectedSpace()
    s.debug = not(s.debug)

    if s.debug then
        con:add("space debug on")
    else
        con:add("space debug off")
    end

end

keyEvents.spaceInfoToggle = function()
    local s = getSelectedSpace()
    s.showInfo = not(s.showInfo)
    --set boundary infos off/on
    for i, b in pairs(s.boundaries) do
        b.showInfo = s.showInfo
        b.showDir = not b.showDir
    end
end
keyEvents.boundaryInfoToggle = function()
    local s = getSelectedSpace()
    --set boundary infos off/on
    for i, b in pairs(s.boundaries) do
        if b.isSelected then
            b.showInfo = not b.showInfo
            b.showDir = not b.showDir
        end
    end
end

keyEvents.mainConsoleToggle = function()
    con.isVisible = not con.isVisible
end
keyEvents.showSpaceInfo = function()
    --show info for selected spaces
    for i,v in pairs(objectTree) do
        if v.isSelected then
            con:add("Space: #"..i.." '"..v.name.."'")

            con:add("Area: "..v:area())

            --[[
            local angles = v:getBoundaryAngles()
            local string = ""
            for i, s in ipairs(angles) do
                string = string .. s
                if i < #angles then
                    string = string .. ", "
                end
            end
            con:add("Angles: "..string)
            --]]

            --shared boundaries
            --TODO
        end
    end
    --toggle ui info
    keyEvents.spaceInfoToggle()
end
keyEvents.showBoundaryInfo = function()
    --show info for selected spaces
    local selectedSpace = getSelectedSpace()
    for i,v in pairs(selectedSpace.boundaries) do
        if v.isSelected then
            con:add("Boundary: #"..i.." '"..v.type.."'")

            con:add("len: "..v:len())

            con:add("angle: "..v:angle())

            for _, g in ipairs(v.guides.sortedForSplit) do
                con:add("#".._.." "..g.atLen)
            end

        end
    end
    --toggle ui info
    keyEvents.boundaryInfoToggle()
end
keyEvents.showInfo = function()
    if selectionMode == "space" then
        keyEvents.showSpaceInfo()
    else
        keyEvents.showBoundaryInfo()
    end
end


keyEvents.setSpaceSelectionMode = function()
    if selectionMode == "space" then
        return
    end
    selectionMode = "space"
    con:add("Selection mode: SPACE")

    --[[
    --deselect all boundaries
    for _, s in pairs(objectTree) do
        for __, b in pairs(s.boundaries) do
            b.isSelected = false
        end
    end
    --]]
end
keyEvents.setBoundarySelectionMode = function()
    if selectionMode == "boundary" then
        return
    end
    selectionMode = "boundary"
    con:add("Selection mode: BOUNDARY")
    --if no boundary is selected, select first boundary of space
    local s = getSelectedSpace()
    local hasSelected = false
    for i, v in ipairs(s.boundaries) do
        if v.isSelected then
            hasSelected = true
            break
        end
    end
    if not hasSelected then
        getSelectedSpace().boundaries[1].isSelected = true
    end
end


keyEvents.selectNextSpace = function()
    for i, v in ipairs(objectTree) do
        if v.isSelected then
            v.isSelected = false
            if i < #objectTree then
                objectTree[i+1].isSelected = true
            else
                objectTree[1].isSelected = true
            end
            break
        end
    end
    con:add("SelectNextSpace")
end
keyEvents.selectPreviousSpace = function()
    for i, v in ipairs(objectTree) do
        if v.isSelected then
            v.isSelected = false
            if i > 1 then
                objectTree[i-1].isSelected = true
            else
                objectTree[#objectTree].isSelected = true
            end
            break
        end
    end
    con:add("SelectPreviousSpace")
end


keyEvents.selectNextBoundary = function()
    if not(selectionMode == "boundary") then
        return
    end
    local selectedSpace = getSelectedSpace()
    for i, v in ipairs(selectedSpace.boundaries) do
        if v.isSelected then
            v.isSelected = false
            if i < #selectedSpace.boundaries then
                selectedSpace.boundaries[i+1].isSelected = true
            else
                selectedSpace.boundaries[1].isSelected = true
            end
            break
        end
    end
    con:add("SelectNextBoundary")
end
keyEvents.selectPreviousBoundary = function()
    local selectedSpace = getSelectedSpace()
    for i, v in ipairs(selectedSpace.boundaries) do
        if v.isSelected then
            v.isSelected = false
            if i > 1 then
                selectedSpace.boundaries[i-1].isSelected = true
            else
                selectedSpace.boundaries[#selectedSpace.boundaries].isSelected = true
            end
            break
        end
    end
    con:add("SelectPreviousBoundary")
end
keyEvents.selectNext = function()
    if selectionMode == "boundary" then
        keyEvents.selectNextBoundary()
    else
        keyEvents.selectNextSpace()
    end
end
keyEvents.selectPrevious = function()
    if selectionMode == "boundary" then
        keyEvents.selectPreviousBoundary()
    else
        keyEvents.selectPreviousSpace()
    end
end



keyEvents.splitBoundary = function()
    local selectedSpace = getSelectedSpace()
    for i, v in ipairs(selectedSpace.boundaries) do
        if v.isSelected then
            selectedSpace:splitBoundary(i)
            break
        end
    end
end
keyEvents.splitSpace = function()
    local selectedSpace = getSelectedSpace()
    selectedSpace:split()
end
keyEvents.split = function()
    if selectionMode == "boundary" then
        keyEvents.splitBoundary()
    else
        keyEvents.splitSpace()
    end
end


--moving the guideline
glspeedr = 0.01
glspeed = 10
glrot = "off"
keyEvents.rotateGuideCCWToggle = function()
    if glrot == "ccw" then 
        glrot = "off"
        rotcallback = function ()
            --dummy
        end
    else
        glrot = "ccw"
        rotcallback = function () 
            g1.angle = g1.angle + glspeedr
            if g1.angle > 2*math.pi then g1.angle = -2*math.pi end
        end
    end
end
keyEvents.rotateGuideCWToggle = function()
    --rotate guideline
    if glrot == "cw" then 
        glrot = "off"
        rotcallback = function ()
            --dummy
        end
    else
        glrot = "cw"
        rotcallback = function () 
            g1.angle = g1.angle - glspeedr
            if g1.angle < -2*math.pi then g1.angle = 2*math.pi end
        end
    end
end
keyEvents.moveGuideUp = function()
    g1.point.y = g1.point.y - glspeed
end
keyEvents.moveGuideDown = function()
    g1.point.y = g1.point.y + glspeed
end
keyEvents.moveGuideLeft = function()
    g1.point.x = g1.point.x - glspeed
end
keyEvents.moveGuideRight = function()
    g1.point.x = g1.point.x + glspeed
end



keyEvents.toggleBoundaryGuideMode = function()
    if not selectionMode == "boundary" then
        return
    end
    --show info for selected spaces
    local selectedSpace = getSelectedSpace()
    for i,v in pairs(selectedSpace.boundaries) do
        local mode = v.guideMode
        if v.isSelected then
            if mode == "normal" then
                mode = "inverse"
            elseif mode == "inverse" then
                mode = "both"
            elseif mode == "both" then
                mode = "off"
            else
                mode = "normal"
            end
            con:add("Boundary: #"..i.." guideMode:"..mode)
            v.guideMode = mode
        end
    end
end




keyEvents.quit = function()
    love.event.quit()
end

keyEvents.showMappings = function()
    for i, m in ipairs(keys.mappingInfo) do
        con:add(m.key..": "..m.description)
    end
end




--map keys to ui functions
keys = {}

keys.pressed = false --for handling key repeat
keys.mappingInfo = {}

function addKeyMapping(key, uiFunction, description)
    keys[key] = uiFunction
    table.insert(keys.mappingInfo, {})
    keys.mappingInfo[#keys.mappingInfo].key = key
    keys.mappingInfo[#keys.mappingInfo].description = description
end

--[[
keys.d = keyEvents.spaceDebugToggle 
keys.e = keyEvents.dummy
keys.space = keyEvents.mainConsoleToggle
keys.i = keyEvents.showInfo
keys.down = keyEvents.setBoundarySelectionMode
keys.up = keyEvents.setSpaceSelectionMode
keys.right = keyEvents.selectNext
keys.left = keyEvents.selectPrevious
keys.s = keyEvents.split
keys.h = keyEvents.moveGuideLeft
keys.l = keyEvents.moveGuideRight
keys.j = keyEvents.moveGuideDown
keys.k = keyEvents.moveGuideUp
keys.n = keyEvents.rotateGuideCCWToggle
keys.m = keyEvents.rotateGuideCWToggle
keys.g = keyEvents.toggleBoundaryGuideMode
keys.escape = keyEvents.quit
keys.q = keyEvents.quit
--]]
addKeyMapping("d", keyEvents.spaceDebugToggle, "spaceDebugToggle")
addKeyMapping("e", keyEvents.dummy, "dummy")
addKeyMapping("space", keyEvents.mainConsoleToggle, "mainConsoleToggle")
addKeyMapping("i", keyEvents.showInfo, "showInfo")
addKeyMapping("down", keyEvents.setBoundarySelectionMode, "setBoundarySelectionMode")
addKeyMapping("up", keyEvents.setSpaceSelectionMode, "setSpaceSelectionMode")
addKeyMapping("right", keyEvents.selectNext, "selectNext")
addKeyMapping("left", keyEvents.selectPrevious, "selectPrevious")
addKeyMapping("s", keyEvents.split, "split")
addKeyMapping("h", keyEvents.moveGuideLeft, "moveGuideLeft")
addKeyMapping("l", keyEvents.moveGuideRight, "moveGuideRight")
addKeyMapping("j", keyEvents.moveGuideDown, "moveGuideDown")
addKeyMapping("k", keyEvents.moveGuideUp, "moveGuideUp")
addKeyMapping("n", keyEvents.rotateGuideCCWToggle, "rotateGuideCCWToggle")
addKeyMapping("m", keyEvents.rotateGuideCWToggle, "rotateGuideCWToggle")
addKeyMapping("g", keyEvents.toggleBoundaryGuideMode, "toggleBoundaryGuideMode")
addKeyMapping("q", keyEvents.quit, "quit")
addKeyMapping("escape", keyEvents.quit, "quit")
addKeyMapping(",", keyEvents.showMappings, "showMappings")

local repeatingKeys = {
    "h","l","j","k"
}
function love.keypressed(key, scancode, isRepeat)

    --remap troublemakers
    if key == " " then key = "space" end
  
    --test for repeat and if key is mapped
    --if (not keys.pressed) and keys[key] then
    if keys[key] then
        --call mapped ui function
        keys[key]()
    end

    --TODO NOT WORKING
    --find out if key is supposed to repeat
    local isRepeating = false
    for _,v in pairs(repeatingKeys) do
        if key == v then 
            isRepeating = true
            break
        end
    end

    --set pressed as per previous inquiry
    if isRepeating then
        keys.pressed = false
    else
        keys.pressed = true
    end

    --print char (terminal only)
    print("key:"..key.." scancode:"..scancode)
end

function love.keyreleased(key)
    keys.pressed = false
end
