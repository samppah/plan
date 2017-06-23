math.randomseed(os.time())

Object = require "libraries/classic"

objectTree = {} --a table to hold all objects (for mouse GUI interaction)
function getObjectTree()
    --this can be called by subs to get main objectTree reference
    return objectTree
end
twindoms = {} --a table to hold all boundary twinhoodds
function getTwindoms()
    return twindoms
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
showTwindoms = true
globalGrid = 30 --for guide setting
EPS = 0.001
globalDecimals = 3 --for all results round STRINGS to this number of decimals

currentScreen = "start" --/plan


minDoorWidth = 90

desiredRooms = {
    "OH",
    "MH",
    "WC",
    "ET",
    "K"
}

function normBIndex(btl, bi)
    --normalize a boundary index
    --btl = boundary table length
    --bi = boundary index, possibly out of bounds
    --needed across the project
    
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


require "classes/Space"
require "classes/cursor"
require "classes/guideline"
--require "classes/Boundary"





spaceCases = {}
--basic "box"
table.insert(spaceCases,
        { 100,100,
        500,100,
        400,400,
        100,400
            }
        )

--basic "triangle"
table.insert(spaceCases,
        { 100,100,
        500,100,
        400,400,
            }
        )


--concave
table.insert(spaceCases,
        { 100,100,
        500,100,
        500,150,
        200,150,
        200,280,
        500,280,
        400,400,
        100,400
            }
        )


local prepPlanDone = false

local g1 = nil
local s1 = nil

local cursor = nil
function getCursor()
    return cursor
end

function prepPlan(sc)
    --create cursor
    cursor = Cursor()

    --start a random case
    local scbpgon
    if sc == "0" then
        -- a random case
        sc = math.ceil(math.random(#spaceCases))
    end
    scbpgon = spaceCases[sc]

    s1 = Space( desiredRooms[1], scbpgon)
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
    g1.isVisible = false--true
    g1.drawInfo = true




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


    prepPlanDone = true

end

local function clearPlan()

    --nullify table of spaces
    objectTree = {}
    --nullify table of twindoms
    --twindoms = {}
    
    local safety = 1000
    while #twindoms > 0 and safety > 0 do
        safety = safety - 1
        t = twindoms[1]
        t:separate()
    end

    s1 = nil
    g1 = nil
    prepPlanDone = false

    --love.load()
end



local updateStart = function(dt)
    --start screen update function
end

local drawStart = function()
    love.graphics.setColor(255,255,255,255)
    love.graphics.print("1:BOX\n2:TRIANGLE\n3:CONCAVE",0,0)
    con:draw()
end


local gps = 0 --guide position "multiplier" for auto-moving guide point
local rotcallback = function ()
    --this is used to rotate the guide line
    --this is called by update. the mapped
    --ui functions relink this function to
    --ones that spin the line
end
local updatePlan = function(dt)
    --plan screen update function
    cursor:update()

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

local drawPlan = function()
    --draws plan screen
    for i, v in pairs(objectTree) do
        v:draw()
    end
    con:draw()
    cursor:draw()
    g1:draw()

    if showTwindoms then
        for i, t in pairs(twindoms) do
            t:draw()
        end
    end
end




local function goToPlanScreen(sc)
    --sc = space case
    clearKeyMappings()
    mapKeysPlan()

    --update screen pointers
    currentScreen = "plan"
    drawScreen = drawPlan
    updateScreen = updatePlan

    prepPlan(sc) --setup a basic space (and additional startup gizmos)
end

local function goToStartScreen()
    clearKeyMappings()
    mapKeysStart()

    currentScreen = "start"
    drawScreen = drawStart
    updateScreen = updateStart

    clearPlan()
end

function love.load()
    love.keyboard.setKeyRepeat = true

    --see if start screen is overridden for some reason
    if drawScreen == drawPlan and updateScreen == updatePlan then
        prepPlan()
    end

    goToStartScreen()

end

drawScreen = drawPlan --override
function love.draw()
    drawScreen()
end






updateScreen = updatePlan
function love.update(dt)
    updateScreen(dt)
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
        --con:add("space debug on")
    else
        --con:add("space debug off")
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
    --con:add("Selection mode: SPACE")

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
    --con:add("Selection mode: BOUNDARY")
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
    --con:add("SelectNextSpace")
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
    --con:add("SelectPreviousSpace")
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
    --con:add("SelectNextBoundary")
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
    --con:add("SelectPreviousBoundary")
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



--[[
keyEvents.splitBoundary = function()
    local selectedSpace = getSelectedSpace()
    for i, v in ipairs(selectedSpace.boundaries) do
        if v.isSelected then
            selectedSpace:splitBoundary(v)
            break
        end
    end
end
--]]

keyEvents.splitSpace = function()
    local selectedSpace = getSelectedSpace()
    selectedSpace:split()
end
keyEvents.split = function()
    if selectionMode == "boundary" then
        keyEvents.splitSpace()
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

keyEvents.toggleShowTwindoms = function()
    showTwindoms = not showTwindoms
end

keyEvents.unselectAllBoundaries = function()
    for i, s in pairs(objectTree) do
        for i, b in pairs(s.boundaries) do
            b.isSelected = false
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


keyEvents.showTwindomInfo = function()
    con:add("number of twindoms: #"..#twindoms)
    local ns = 0
    for i, t in pairs(twindoms)do
        if t:isSelected() then
            ns = ns + 1
        end  
    end
    con:add("number of selected: #"..ns)
    for i, t in pairs(twindoms)do
        for ii, tt in pairs(twindoms)do
            if t == tt then
                --
            else
                if math.abs(t.center[1]-tt.center[1])<EPS and math.abs(t.center[2]-tt.center[2])<EPS then
                    con:add("twindom overlap (1/2)")
                end
            end
        end
    end
end

keyEvents.updateTwindoms = function()
    for i, t in pairs(twindoms)do
        t:update()
    end
end

keyEvents.restart = function()
    goToStartScreen()
end

keyEvents.joinSpaces = function()
    local twindom = nil
    for i, t in pairs(twindoms) do
        if t.isHovered then
            twindom = t
            break
        end
    end
    if not twindom then
        con:add("no twindom hovered. cannot join spaces")
        return
    end
    local s1 = twindom.so[1]
    local s2 = twindom.so[2]
    --check if space is selected
    local reselect = false
    if s1.isSelected then
        --it's all right
    elseif s2.isSelected then
        --we need to select s1 after joining
        reselect = true 
    end
    s1:join(s2)
    if reselect then
        s1.isSelected = true
    end
end

keyEvents.startWithBox = function()
    --start
    goToPlanScreen(1)
end
keyEvents.startWithTriangle = function()
    --start
    goToPlanScreen(2)
end
keyEvents.startWithConcave = function()
    --start
    goToPlanScreen(3)
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

function clearKeyMappings()
    keys = {}
    keys.mappingInfo = {}
    keys.pressed = false --for handling key repeat
end

function mapKeysPlan()
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
    addKeyMapping(",", keyEvents.showMappings, "showMappings")
    addKeyMapping("t", keyEvents.toggleShowTwindoms, "toggleShowTwindoms")
    addKeyMapping("u", keyEvents.unselectAllBoundaries, "unselectAllBoundaries")
    addKeyMapping("y", keyEvents.showTwindomInfo, "showTwindomInfo")
    addKeyMapping("w", keyEvents.updateTwindoms, "updateTwindoms")
    addKeyMapping("q", keyEvents.restart, "restart")
    addKeyMapping("escape", keyEvents.restart, "restart")
    addKeyMapping("o", keyEvents.joinSpaces, "joinSpaces")
end

function mapKeysStart()
    addKeyMapping("1", keyEvents.startWithBox, "startWithBox")
    addKeyMapping("2", keyEvents.startWithTriangle, "startWithTriangle")
    addKeyMapping("3", keyEvents.startWithConcave, "startWithConcave")
    addKeyMapping("q", keyEvents.quit, "quit")
    addKeyMapping("escape", keyEvents.quit, "quit")
    addKeyMapping(",", keyEvents.showMappings, "showMappings")
end

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
    local description = "-"
    for i,m in ipairs(keys.mappingInfo) do
        if m.key == key then
            description = m.description
            break
        end
    end
    print("key:"..key.." scancode:"..scancode.." / "..description)
end

function love.keyreleased(key)
    keys.pressed = false
end
