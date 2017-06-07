Console = Object:extend()

local stringFuncs = require "strings"

local rowHeight = 15
local defaultWidth = 300
local defaultHeight = 300
local defaultLines = defaultHeight / rowHeight
local forgetMs = 3000
local fadeOutPerc = 0.75
local streamToTerminal = true

function Console:new(name, x, y, w, h, log, lines)
    self.name = name or "unnamed"
    self.x = x or 0
    self.y = y or 600-rowHeight
    self.w = w or defaultWidth
    self.h = h or defaultHeight
    self.log = log or {}
    self.lines = lines or defaultLines
    self.isVisible = true
end

function Console:draw()
    if self.isVisible == false then
        return
    end
    local y = self.y
    for i, v in ipairs(self.log) do
        local fade = 1-(i/self.lines*fadeOutPerc)
        love.graphics.setColor(255, 255, 255, 255*fade)
        love.graphics.print(v, self.x, y-((i-1)*rowHeight)) 
    end
end

function Console:update()

end

function Console:add(text, streamToT)
    if streamToT == nil then
        streamToT = streamToTerminal
    end
    ftext = stringFuncs.formatText(text)
    table.insert(self.log, 1, ftext)
    if #self.log > self.lines then
        table.remove(self.log, #self.log)
    end
    if streamToT then
        print(text)
    end
end

function Console:hide()
    self.isVisible = false 
end

function Console:show()
    self.isVisible = true
end
