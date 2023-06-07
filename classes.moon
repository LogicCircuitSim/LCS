-- vector_metatable = {
--     __add: (a,b) => vec2(a.x+b.x, a.y+b.y)
--     __sub: (a,b) => vec2(a.x-b.x, a.y-b.y)
--     __mul: (a,b) => vec2(a.x*b.x, a.y*b.y)
--     __div: (a,b) => vec2(a.x/b.x, a.y/b.y)
--     __mod: (a,b) => vec2(a.x%b.x, a.y%b.y)
--     __pow: (a,b) => vec2(a.x^b.x, a.y^b.y)
--     __unm: (a) => vec2(-a.x, -a.y)
--     __concat: (a,b) => vec2(a.x..b.x, a.y..b.y)
--     __len: (a) => (a.x^2 + a.y^2)^0.5
--     __eq: (a,b) => a.x == b.x and a.y == b.y
--     __lt: (a,b) => a.x < b.x and a.y < b.y
--     __le: (a,b) => a.x <= b.x and a.y <= b.y
--     __index: (a,b) => a[b]
--     __newindex: (a,b,c) => a[b] = c
--     __call: (a,b) => a(b)
--     __tostring: (a) => "vec2(#{a.x}, #{a.y})"
--     __metatable: {}
-- }

-- distance = (x1,y1,x2,y2,squared) ->
--     if squared
--         (x1-x2)^2 + (y1-y2)^2
--     else
--         math.sqrt((x1-x2)^2 + (y1-y2)^2)

lume = require "lume"
log = require "log"
log.level = "debug"

printCentered = (text, x, y, rows=1) ->
    font = love.graphics.getFont()
    love.graphics.print(text, x - (font\getWidth(text)/2), y - (font\getHeight()/(1+rows)))

export graphicSettings = {
    betterGraphics: true  
    gateUseStateColors: false
    gateStateColors: {
        ON: { 0.06, 0.65, 0.16 }
        OFF: { 0.51, 0.19, 0.29 }
    }
    gateColor: { 0.18, 0.18, 0.18 }    
    gateBorderRounding: 3
    gateBorderWidth: 1.5
    gateBorderColor: { 0.35, 0.35, 0.35 }
    gateBorderColorAlt: { 0.08, 0.08, 0.08 }
    gateUseAltBorderColor: false    
    gateDropshadowOffset: 7
    gateDropshadowColor: { 0.05, 0.05, 0.05, 0.8 }
    gateDropshadowRounding: 4    
    gatePinSize: 5.5
    gatePinColor: { 
        ON: { 0.47, 0.47, 0.47 }
        OFF: { 0.13, 0.13, 0.13 }
    }
}

class vec2
    new: (x,y) =>
        @x = x
        @y = y

class PIN
    @ID: 0
    @newID: =>
        PIN.ID += 1
        PIN.ID
    new: (parentID) =>        
        @id = @@newID()
        @parentID = parentID
        @state = false
        @pos = vec2(0,0)
        @isConnected = false


class INPUTPIN extends PIN
    new: (parentID) =>
        super parentID


class OUTPUTPIN extends PIN
    new: (parentID) =>
        super parentID


class BOARDOBJECT
    new: (x,y) =>
        log.trace'new BOARDOBJECT'
        @pos = vec2(x,y)


class GATE extends BOARDOBJECT
    @ID: 1000
    @newID: =>
        GATE.ID += 1
        GATE.ID
    @size: {width:9, height:14, scale:7, space:10}
    @getWidth: => @@size.width*@@size.scale
    @getHeight: (inputpincount=2) => @@size.space * (4+(3*(inputpincount-1))) * (@@size.scale/7)

    new: (x,y,inputpincount=2) =>
        super x,y
        log.trace'new GATE'
        @id = @@newID()
        @state = false
        @inputpincount = inputpincount
        @inputpins = {}
        table.insert @inputpins, INPUTPIN(@id) for i=1,@inputpincount
        @outputpin = OUTPUTPIN(@id)
        @getWidth = => @@size.width*@@size.scale
        @getHeight = => @@size.space * (4+(3*(@inputpincount-1))) * (@@size.scale/7)


    update: =>

    drawMe: =>

    draw: =>
        -- dropshadow
	    love.graphics.setColor(graphicSettings.gateDropshadowColor)
        height = @getHeight(@inputpincount)
        love.graphics.rectangle("fill", @pos.x + graphicSettings.gateDropshadowOffset, @pos.y + graphicSettings.gateDropshadowOffset, @getWidth(), height, graphicSettings.gateDropshadowRounding)
        -- gate background color
        if graphicSettings.gateUseStateColors
            if @state then love.graphics.setColor(graphicSettings.gateStateColors.ON)
            else love.graphics.setColor(graphicSettings.gateStateColors.OFF)
        else
            love.graphics.setColor(graphicSettings.gateColor)
        -- base rectangle
        love.graphics.rectangle("fill", @pos.x, @pos.y, @getWidth(), height, graphicSettings.betterGraphics and graphicSettings.gateBorderRounding or nil)
        -- base rectangle border
        love.graphics.setColor(graphicSettings.gateUseAltBorderColor and graphicSettings.gateBorderColorAlt or graphicSettings.gateBorderColor)
        love.graphics.setLineWidth(graphicSettings.gateBorderWidth)
        love.graphics.rectangle("line", @pos.x, @pos.y, @getWidth(), height, graphicSettings.betterGraphics and graphicSettings.gateBorderRounding or nil)
		-- input pins, circles
        for i=1,@inputpincount do
            pin = @inputpins[i]
            if pin then
                ypos = @pos.y + (@@size.space*2) + ((@@size.space*3)*(i-1))
                if pin.isConnected then love.graphics.setColor(graphicSettings.gatePinColor.ON)
                else love.graphics.setColor(graphicSettings.gatePinColor.OFF)
                love.graphics.circle("fill", @pos.x, ypos, graphicSettings.gatePinSize)
                love.graphics.setLineWidth(1)
                love.graphics.setColor(1, 1, 1)
                love.graphics.circle("line", @pos.x, ypos, graphicSettings.gatePinSize)
                pin.pos = vec2(@pos.x, ypos)
        -- output pin, circle
        if @outputpin.isConnected then love.graphics.setColor(graphicSettings.gatePinColor.ON)
        else love.graphics.setColor(graphicSettings.gatePinColor.OFF)
        love.graphics.circle("fill", @pos.x + @getWidth(), @pos.y + (height/2), graphicSettings.gatePinSize)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("line", @pos.x + @getWidth(), @pos.y + (height/2), graphicSettings.gatePinSize)
        @outputpin.pos = vec2(@pos.x + @getWidth(), @pos.y + (height/2))
        -- Gate Type dependant drawing
        @drawMe()

    resetPins: =>
        @inputpins[i].state = false for i=1,@inputpincount

    addPin: =>
        @inputpincount += 1
        table.insert @inputpins, INPUTPIN(@id)

    removePin: =>
        if @inputpincount > 2
            @inputpincount -= 1
            table.remove @inputpins, @inputpincount

    isInside: (x,y) =>
        width, height = @getWidth(), @getHeight(@inputpincount)
        x >= @pos.x and x <= @pos.x+width and y >= @pos.y and y <= @pos.y+height

    getInputPinAt: (x,y) =>
        piny = @pos.y + @@size.space * 2
        for i=1,@inputpincount
            if lume.distance(x,y,@pos.x,piny,false) < 10
                return @inputpins[i]
            piny += @@size.space * 3

    getOutputPinAt: (x,y) =>
        return @outputpin if lume.distance(x,y,@pos.x+@getWidth(),@pos.y+@getHeight(@inputpincount)/2,false) < 10

    getInputPinByID: (id) =>
        for i=1,@inputpincount
            if @inputpins[i].id == id
                return @inputpins[i]

    getOutputPinByID: (id) =>
        return @outputpin if @outputpin.id == id

    getAllPins: =>
        pins = {}
        table.insert pins, @inputpins[i] for i=1,@inputpincount
        table.insert pins, @outputpin
        pins


class PERIPHERAL extends BOARDOBJECT
    @ID: 2000
    @newID: =>
        PERIPHERAL.ID += 1
        PERIPHERAL.ID
    @size: {width:12, height:14, scale:7, space:10}
    @getWidth: => @@size.width*@@size.scale
    @getHeight: => @@size.space * 4 * (@@size.scale/7)

    new: (x,y,inputpincount=0,outputpincount=0) =>
        super x,y
        log.trace'new PERIPHERAL'
        @id = @@newID!
        @hasinputpin = inputpincount > 0
        @hasoutputpin = outputpincount > 0
        @inputpin = INPUTPIN(@id) if @hasinputpin
        @outputpin = OUTPUTPIN(@id) if @hasoutputpin
        @state = false
        @getWidth = @@size.width*@@size.scale
        @getHeight = @@size.space * 4 * (@@size.scale/7)

    update: =>
        
    drawMe: =>
        
    draw: =>
        -- dropshadow
        love.graphics.setColor(graphicSettings.gateDropshadowColor)
        height = @@getHeight!
        love.graphics.rectangle("fill", @pos.x + graphicSettings.gateDropshadowOffset, @pos.y + graphicSettings.gateDropshadowOffset, @@getWidth(), height, graphicSettings.gateDropshadowRounding)

        -- background
        if @state then love.graphics.setColor(graphicSettings.gateStateColors.ON)
        else love.graphics.setColor(graphicSettings.gateStateColors.OFF)
        love.graphics.rectangle("fill", @pos.x, @pos.y, @@getWidth(), height, graphicSettings.betterGraphics and graphicSettings.gateBorderRounding or nil)

        -- border
        love.graphics.setColor(graphicSettings.gateUseAltBorderColor and graphicSettings.gateBorderColorAlt or graphicSettings.gateBorderColor)
        love.graphics.setLineWidth(graphicSettings.gateBorderWidth)
        love.graphics.rectangle("line", @pos.x, @pos.y, @@getWidth(), height, graphicSettings.betterGraphics and graphicSettings.gateBorderRounding or nil)

        -- pins
        if @hasinputpin then
            xpos,ypos = @pos.x, @pos.y + (height/2)
            if @inputpin.isConnected then love.graphics.setColor(graphicSettings.gatePinColor.ON)
            else love.graphics.setColor(graphicSettings.gatePinColor.OFF)
            love.graphics.circle("fill", xpos, ypos, graphicSettings.gatePinSize)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(1, 1, 1)
            love.graphics.circle("line", xpos, ypos, graphicSettings.gatePinSize)
            @inputpin.pos = vec2(xpos, ypos)

        if @hasoutputpin then
            xpos,ypos = @pos.x + @@getWidth(), @pos.y + (height/2)
            if @outputpin.isConnected then love.graphics.setColor(graphicSettings.gatePinColor.ON)
            else love.graphics.setColor(graphicSettings.gatePinColor.OFF)
            love.graphics.circle("fill", xpos, ypos, graphicSettings.gatePinSize)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(1, 1, 1)
            love.graphics.circle("line", xpos, ypos, graphicSettings.gatePinSize)
            @outputpin.pos = vec2(xpos, ypos)

        @drawMe()

    resetPins: =>
        @inputpin.state = false if @hasinputpin

    set: (state) =>
        @state = state

    flip: =>
        @state = not @state

    isInside: (x,y) =>
        x >= @pos.x and x <= @pos.x + @@getWidth! and y >= @pos.y and y <= @pos.y + @@getHeight!

    getInputPinAt: (x,y) =>
        return @inputpin if lume.distance(x, y, @pos.x, @pos.y + (@@getHeight()/2)) < 10

    getOutputPinAt: (x,y) =>
        return @outputpin if lume.distance(x, y, @pos.x + @@getWidth(), @pos.y + (@@getHeight()/2)) < 10

    getInputPinByID: (id) =>
        return @inputpin if @inputpin.id == id

    getOutputPinByID: (id) =>
        return @outputpin if @outputpin.id == id

    getAllPins: =>
        return { @inputpin, @outputpin }



class AND extends GATE
    new: (x,y,inputpincount) =>
        super x,y,inputpincount
        log.trace'new AND'

    drawMe: =>
        love.graphics.setColor(1, 1, 1)
        printCentered("AND", @pos.x + (@@getWidth()/2), @pos.y + (@@getHeight(@inputpincount)/2))

    update: =>
        newstate = true
        for i=1,@inputpincount
            newstate = false if not @inputpins[i].state
        @state = newstate
        @outputpin.state = @state

class OR extends GATE
    new: (x,y,inputpincount) =>
        super x,y,inputpincount
        log.trace'new OR'

    drawMe: =>
        love.graphics.setColor(1, 1, 1)
        printCentered("OR", @pos.x + (@@getWidth()/2), @pos.y + (@@getHeight(@inputpincount)/2))

    update: =>
        newstate = false
        for i=1,@inputpincount
            newstate = true if @inputpins[i].state
        @state = newstate
        @outputpin.state = @state


class NAND extends GATE
    new: (x,y,inputpincount) =>
        super x,y,inputpincount
        log.trace'new NAND'

    drawMe: =>
        love.graphics.setColor(1, 1, 1)
        printCentered("NAND", @pos.x + (@@getWidth()/2), @pos.y + (@@getHeight(@inputpincount)/2))

    update: =>
        newstate = true
        for i=1,@inputpincount
            newstate = false if not @inputpins[i].state
        @state = not newstate
        @outputpin.state = @state


class NOR extends GATE
    new: (x,y,inputpincount) =>
        super x,y,inputpincount
        log.trace'new NOR'

    drawMe: =>
        love.graphics.setColor(1, 1, 1)
        printCentered("NOR", @pos.x + (@@getWidth()/2), @pos.y + (@@getHeight(@inputpincount)/2))

    update: =>
        newstate = false
        for i=1,@inputpincount
            newstate = true if @inputpins[i].state
        @state = not newstate
        @outputpin.state = @state


class XOR extends GATE
    new: (x,y,inputpincount) =>
        super x,y,inputpincount
        log.trace'new XOR'

    drawMe: =>
        love.graphics.setColor(1, 1, 1)
        printCentered("XOR", @pos.x + (@@getWidth()/2), @pos.y + (@@getHeight(@inputpincount)/2))

    update: =>
        newstate = false
        for i=1,@inputpincount
            newstate = not newstate if @inputpins[i].state
        @state = newstate
        @outputpin.state = @state


class XNOR extends GATE
    new: (x,y,inputpincount) =>
        super x,y,inputpincount
        log.trace'new XNOR'

    drawMe: =>
        love.graphics.setColor(1, 1, 1)
        printCentered("XNOR", @pos.x + (@@getWidth()/2), @pos.y + (@@getHeight(@inputpincount)/2))

    update: =>
        newstate = true
        for i=1,@inputpincount
            newstate = not newstate if @inputpins[i].state
        @state = newstate
        @outputpin.state = @state


class NOT extends GATE
    new: (x,y,inputpincount=1) =>
        super x,y,inputpincount
        log.trace'new NOT'

    drawMe: =>
        love.graphics.setColor(1, 1, 1)
        printCentered("NOT", @pos.x + (@@getWidth()/2), @pos.y + (@@getHeight(@inputpincount)/2))

    update: =>
        @state = not @inputpins[1].state
        @outputpin.state = @state

    removePin: =>

    addPin: =>
        


class INPUT extends PERIPHERAL
    new: (x,y) =>
        super x,y,0,1
        log.trace'new INPUT'

    update: =>
        @outputpin.state = @state

    drawMe: =>
        pad = 5
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", @pos.x+pad + (@state and @@getWidth!/2-pad or 0), @pos.y+pad, @@getWidth!/2-pad, @@getHeight!-pad*2)
    

class OUTPUT extends PERIPHERAL
    new: (x,y) =>
        super x,y,1,0
        log.trace'new OUTPUT'

    update: =>
        @state = @inputpin.state

    drawMe: =>
        love.graphics.setColor(1, 1, 1)
        printCentered("OUT #{@id-2000}", @pos.x + (@@getWidth!/2), @pos.y + (@@getHeight!/2))
            

class BUFFER extends PERIPHERAL
    new: (x,y) =>
        super x,y,1,1
        log.trace'new BUFFER'
        @ticks = 5
        @tickcount = 0
        @isBuffering = false

    update: =>
        if @isBuffering then
            if @tickcount > 0 then @tickcount -= 1
            else
                @state = @inputpin.state
                @outputpin.state = @state
                @isBuffering = false
        else
            if @inputpin.state != @state then
                @isBuffering = true
                @tickcount = @ticks

    getHeight: =>
        return @@size.space * 6

    drawMe: =>
        love.graphics.setColor(1, 1, 1)
        printCentered("BUFFER \n#{@ticks} tks", @pos.x + (@@getWidth!/2), @pos.y + (@@getHeight!/4), 2)
                
            

class CLOCK extends PERIPHERAL
    new: (x,y) =>
        super x,y,0,1
        log.trace'new CLOCK'
        @tickspeed = 1 -- ticks per second
        @ticks = 1/@tickspeed
        @lastMicroSec = love.timer.getTime!

    update: =>
        now = love.timer.getTime!
        if now - @lastMicroSec > 1/@tickspeed then
            @state = not @state
            @lastMicroSec = now

        @outputpin.state = @state
    
    getHeight: =>
        return @@size.space * 6

    drawMe: =>
        love.graphics.setColor(1, 1, 1)
        printCentered("CLOCK\n#{@tickspeed} Hz", @pos.x + (@@getWidth!/2), @pos.y + (@@getHeight!/4), 2)



loadINPUTPIN = (pin) ->
    newpin = INPUTPIN(pin.parentID)
    newpin.id = pin.id
    newpin.state = pin.state
    newpin.pos = vec2(pin.pos.x, pin.pos.y)
    newpin.isConnected = pin.isConnected
    newpin

loadOUTPUTPIN = (pin) ->
    newpin = OUTPUTPIN(pin.parentID)
    newpin.id = pin.id
    newpin.state = pin.state
    newpin.pos = vec2(pin.pos.x, pin.pos.y)
    newpin.isConnected = pin.isConnected
    newpin

loadGATE = (gatedata) ->
    newgate = GATE(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
    if gatedata.name == "AND" newgate = AND(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
	elseif gatedata.name == "NAND" newgate = NAND(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
	elseif gatedata.name == "OR" newgate = OR(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
	elseif gatedata.name == "NOR" newgate = NOR(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
	elseif gatedata.name == "XOR" newgate = XOR(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
	elseif gatedata.name == "XNOR" newgate = XNOR(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
	elseif gatedata.name == "NOT" newgate = NOT(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
    else print("ERROR: Unknown gate type: " .. gatedata.name)
    newgate.id = gatedata.id
    newgate.state = gatedata.state
    newgate.inputpincount = gatedata.inputpincount
    newgate.inputpins = {}
    table.insert newgate.inputpins, loadINPUTPIN(pin) for pin in *gatedata.inputpins
    newgate.outputpin = loadOUTPUTPIN(gatedata.outputpin)
    newgate

loadPERIPHERAL = (peripheraldata) ->
    newperipheral = PERIPHERAL(peripheraldata.pos.x, peripheraldata.pos.y, peripheraldata.inputpincount)
    if peripheraldata.name == "INPUT" newperipheral = INPUT(peripheraldata.pos.x, peripheraldata.pos.y, peripheraldata.inputpincount)
	elseif peripheraldata.name == "CLOCK" then
		peripheraldata.tickspeed = peripheraldata.tickspeed
		peripheraldata.lastMicroSec = love.timer.getTime()
		newperipheral = CLOCK(peripheraldata.pos.x, peripheraldata.pos.y, peripheraldata.inputpincount)
	elseif peripheraldata.name == "BUFFER" then
		peripheraldata.ticks = peripheraldata.ticks
		peripheraldata.tickcounter = 0
		peripheraldata.isBuffering = false
		newperipheral = BUFFER(peripheraldata.pos.x, peripheraldata.pos.y, peripheraldata.inputpincount)
	elseif peripheraldata.name == "OUTPUT" then newperipheral = OUTPUT(peripheraldata.pos.x, peripheraldata.pos.y, peripheraldata.inputpincount)
    else print("ERROR: Unknown peripheral type: " .. peripheraldata.name)
    newperipheral.id = peripheraldata.id
    newperipheral.state = peripheraldata.state
    newperipheral.inputpin = loadINPUTPIN(peripheraldata.inputpins)
    newperipheral.outputpin = loadOUTPUTPIN(peripheraldata.outputpin)
    newperipheral

{
:PIN, :INPUTPIN, :OUTPUTPIN,
:GATE, :AND, :OR, :NOT,
:NAND, :NOR, :XOR, :XNOR,
:PERIPHERAL, :INPUT, :OUTPUT, :BUFFER, :CLOCK,
:loadGATE, :loadPERIPHERAL
}