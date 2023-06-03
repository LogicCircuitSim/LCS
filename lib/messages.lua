local lume = require "lume"
local messages = {}
messages.version = "0.1.1"
messages.list = {}
messages.defaulttimeout = 3000
messages.x, messages.y = 0, 0

messages.update = function(dt)
    if lume.count(messages.list) == 0 then return end
    lume.each(messages.list, function(msg)
        msg.timeout = msg.timeout - (dt * 1000.0)
    end)
    messages.list = lume.reject(messages.list, function(msg)
        return msg.timeout <= 0
    end)
end

messages.draw = function(debug)
    if lume.count(messages.list) == 0 then return end
    local y = messages.y
    lume.each(messages.list, function(msg)
        love.graphics.draw(msg.text, 0, y)
        if debug then love.graphics.print(msg.timeout, msg.text:getWidth()+10, y) end
        y = y + msg.text:getHeight()
    end)
end

messages.addMessage = function(msg, wraplimit, align)
    local text = love.graphics.newText(love.graphics.getFont(), msg)
    if wraplimit then
        text:setf(msg, wraplimit, align or love.graphics.AlignMode.left)
    end
    local message = {}
    message.text = text
    message.timeout = messages.defaulttimeout
    
    lume.push(messages.list, message)
end

messages.add = messages.addMessage
return messages