local lume = require "lume"

local class = {}
function class:new(tbal)
    local obj = {}
	if tbal then
		for k, v in pairs(tbal) do
			obj[k] = v
		end
	end
    setmetatable(obj, self)
    self.__index = self
    return obj
end
function class:subclass()
    local subclass = {}
    setmetatable(subclass, self)
    self.__index = self
    return subclass
end

function newpos(x, y) return { x=x, y=y } end

function love.graphics.printCentered(text, x, y, rows)
	local font = love.graphics.getFont()
	rows = rows or 1
	love.graphics.print(text, x - (font:getWidth(text)/2), y - (font:getHeight()/(1+rows)))
end

graphicSettings = {
	betterGraphics = true,

	gateUseStateColors = false,
	gateStateColors = {
		ON  = { 0.06, 0.65, 0.16 },
		OFF = { 0.51, 0.19, 0.29 },
	},
	gateColor = { 0.18, 0.18, 0.18 },

	gateBorderRounding = 3,
	gateBorderWidth = 1.5,
	gateBorderColor = { 0.35, 0.35, 0.35 },
	gateBorderColorAlt = { 0.08, 0.08, 0.08 },
	gateUseAltBorderColor = false,

	gateDropshadowOffset = 7,
	gateDropshadowColor = { 0.05, 0.05, 0.05, 0.8 },
	gateDropshadowRounding = 4,

	gatePinSize = 5.5,
	gatePinColor = { 
		ON = { 0.47, 0.47, 0.47 },
		OFF = { 0.13, 0.13, 0.13 },
	},
}

--==============================================[ CLASSES ]==============================================--

PIN = class:new()
INPUTPIN = PIN:subclass()
OUTPUTPIN = PIN:subclass()

BOARDOBJECT = class:new()
GATE = BOARDOBJECT:subclass()
AND = GATE:subclass()
NAND = GATE:subclass()
OR = GATE:subclass()
NOR = GATE:subclass()
XOR = GATE:subclass()
XNOR = GATE:subclass()
NOT = GATE:subclass()

PERIPHERAL = BOARDOBJECT:subclass()
INPUT = PERIPHERAL:subclass()
CLOCK = PERIPHERAL:subclass()
OUTPUT = PERIPHERAL:subclass()
BUFFER = PERIPHERAL:subclass()

--==============================================[ STATICS ]==============================================--

PINID = 0
function generateNewPINID()
	PINID = PINID+1
	return PINID
end

GATEID = 1000
function generateNewGATEID()
	GATEID = GATEID+1
	return GATEID
end
GATEsize = { width=9, height=14, scale=7, space = 10 }
GATEgetWidth = function() return GATEsize.width*GATEsize.scale end
GATEgetHeight = function() return GATEsize.height*GATEsize.scale end

PERIPHERALID = 2000
function generateNewPERIPHERALID()	
	PERIPHERALID = PERIPHERALID+1
	return PERIPHERALID
end
PERIPHERALsize = { width=12, height=14, scale=7, space = 10 }
PERIPHERALgetWidth = function() return PERIPHERALsize.width*PERIPHERALsize.scale end
PERIPHERALgetHeight = function() return PERIPHERALsize.height*PERIPHERALsize.scale end

--==============================================[ CONSTRUCTORS ]==============================================--

function constructPIN(parentID)
	local me = {}
	me.name = "PIN"
	me.id = generateNewPINID()
	me.parentID = parentID
	me.state = false
	me.pos = newpos(0, 0)
	me.isConnected = false
	return PIN:new(me)
end

function constructINPUTPIN(parentID)
	local me = constructPIN(parentID)
	me.name = "INPUTPIN"
	return INPUTPIN:new(me)
end
function constructOUTPUTPIN(parentID)
	local me = constructPIN(parentID)
	me.name = "OUTPUTPIN"
	return OUTPUTPIN:new(me)
end


function constructBOARDOBJECT(x, y, type)
	local me = {}
	me.name = "BOARDOBJECT"
	me.pos = newpos(x, y)
	me.type = type
	return BOARDOBJECT:new(me)
end

function constructGATE(x, y, inputpincount)
	local me = constructBOARDOBJECT(x, y, "GATE")
	me.name = "GATE"
	me.inputpincount = inputpincount or 2
	me.id = generateNewGATEID()
	me.state = false
	me.inputpins = Collection:new()
	for i=1, me.inputpincount do
		me.inputpins:append(constructINPUTPIN(me.id))
	end
	me.outputpin = constructOUTPUTPIN(me.id)
	return GATE:new(me)
end

function constructAND(x, y, inputpincount)
	local me = constructGATE(x, y, inputpincount)
	me.name = "AND"
	return AND:new(me)
end
function constructNAND(x, y, inputpincount)
	local me = constructGATE(x, y, inputpincount)
	me.name = "NAND"
	return NAND:new(me)
end
function constructOR(x, y, inputpincount)
	local me = constructGATE(x, y, inputpincount)
	me.name = "OR"
	return OR:new(me)
end
function constructNOR(x, y, inputpincount)
	local me = constructGATE(x, y, inputpincount)
	me.name = "NOR"
	return NOR:new(me)
end
function constructXOR(x, y, inputpincount)
	local me = constructGATE(x, y, inputpincount)
	me.name = "XOR"
	return XOR:new(me)
end
function constructXNOR(x, y, inputpincount)
	local me = constructGATE(x, y, inputpincount)
	me.name = "XNOR"
	return XNOR:new(me)
end
function constructNOT(x, y, inputpincount)
	local me = constructGATE(x, y, inputpincount or 1)
	me.name = "NOT"
	return NOT:new(me)
end

function constructPERIPHERAL(x, y, inputpincount, outputpincount)
	local me = constructBOARDOBJECT(x, y, "PERIPHERAL")
	me.name = "PERIPHERAL"
	me.id = generateNewPERIPHERALID()
	me.inputpincount = inputpincount or 0
	me.outputpincount = outputpincount or 0
	me.inputpins = Collection:new()
	me.outputpins = Collection:new()
	for i=1,me.inputpincount do
		me.inputpins:append(constructINPUTPIN(me.pos.x, me.pos.y))
	end
	for i=1,me.outputpincount do
		me.outputpins:append(constructOUTPUTPIN(me.pos.x, me.pos.y))
	end
	return me
end

function constructINPUT(x, y)
	local me = constructPERIPHERAL(x, y, 0, 1)
	me.name = "INPUT"
	return INPUT:new(me)
end
function constructCLOCK(x, y)
	local me = constructPERIPHERAL(x, y, 0, 1)
	me.name = "CLOCK"
	me.tickspeed = 1 -- ticks per second
	me.lastMicroSec = love.timer.getTime()
	return CLOCK:new(me)
end
function constructOUTPUT(x, y)
	local me = constructPERIPHERAL(x, y, 1, 0)
	me.name = "OUTPUT"
	return OUTPUT:new(me)
end
function constructBUFFER(x, y)
	local me = constructPERIPHERAL(x, y, 1, 1)
	me.name = "BUFFER"
	me.ticks = 5
	me.tickcounter = 0
	me.isBuffering = false
	return BUFFER:new(me)
end

--==============================================[ LOAD FUNCTIONS ]==============================================--

function loadINPUTPIN(pin)
	local me = constructINPUTPIN(pin.parentID)
	me.id = pin.id
	me.state = pin.state
	me.pos = pin.pos
	me.isConnected = pin.isConnected
	return me
end

function loadOUTPUTPIN(pin)
	local me = constructOUTPUTPIN(pin.parentID)
	me.id = pin.id
	me.state = pin.state
	me.pos = pin.pos
	me.isConnected = pin.isConnected
	return me
end

function loadGATE(gatedata)
	local me = constructBOARDOBJECT(gatedata.pos.x, gatedata.pos.y, "GATE")
	me.id = gatedata.id
	me.state = gatedata.state
	me.inputpincount = gatedata.inputpincount
	me.inputpins = Collection:new()
	for i=1,gatedata.inputpincount do
		me.inputpins:append(loadINPUTPIN(gatedata.inputpins.table[i]))
	end
	me.outputpin = loadOUTPUTPIN(gatedata.outputpin)
	me.name = gatedata.name
	if me.name == "AND" then return AND:new(me)
	elseif me.name == "NAND" then return NAND:new(me)
	elseif me.name == "OR" then return OR:new(me)
	elseif me.name == "NOR" then return NOR:new(me)
	elseif me.name == "XOR" then return XOR:new(me)
	elseif me.name == "XNOR" then return XNOR:new(me)
	elseif me.name == "NOT" then return NOT:new(me)
	end
end

function loadPERIPHERAL(peripheraldata)
	local me = constructBOARDOBJECT(peripheraldata.pos.x, peripheraldata.pos.y, "PERIPHERAL")
	me.id = peripheraldata.id
	me.inputpincount = peripheraldata.inputpincount
	me.outputpincount = peripheraldata.outputpincount
	me.inputpins = Collection:new()
	me.outputpins = Collection:new()
	for i=1,me.inputpincount do
		me.inputpins:append(loadINPUTPIN(peripheraldata.inputpins.table[i]))
	end
	for i=1,me.outputpincount do
		me.outputpins:append(loadOUTPUTPIN(peripheraldata.outputpins.table[i]))
	end
	me.state = peripheraldata.state
	me.name = peripheraldata.name
	if me.name == "INPUT" then return INPUT:new(me)
	elseif me.name == "CLOCK" then
		me.tickspeed = peripheraldata.tickspeed
		me.lastMicroSec = love.timer.getTime()
		return CLOCK:new(me)
	elseif me.name == "BUFFER" then
		me.ticks = peripheraldata.ticks
		me.tickcounter = 0
		me.isBuffering = false
		return BUFFER:new(me)
	elseif me.name == "OUTPUT" then return OUTPUT:new(me)
	end
end

--==============================================[ FUNCTIONS ]==============================================--

------------------[ GATE ]------------------
function GATE:update() end
function GATE:drawMe() end

function GATE:getWidth()
	return GATEgetWidth()
end
function GATE:getHeight()
	return GATEsize.space * (4+(3*(self.inputpincount-1))) * (GATEsize.scale/7)
end
function GATE:draw()
	-- dropshadow
	love.graphics.setColor(graphicSettings.gateDropshadowColor)
	local height = self:getHeight()
	love.graphics.rectangle("fill", self.pos.x + graphicSettings.gateDropshadowOffset, self.pos.y + graphicSettings.gateDropshadowOffset, GATEgetWidth(), height, graphicSettings.gateDropshadowRounding)

	-- gate background color
	if graphicSettings.gateUseStateColors then
		if self.state then love.graphics.setColor(graphicSettings.gateStateColors.ON)
		else love.graphics.setColor(graphicSettings.gateStateColors.OFF) end
	else
		love.graphics.setColor(graphicSettings.gateColor)
	end

	-- base rectangle
	love.graphics.rectangle("fill", self.pos.x, self.pos.y, GATEgetWidth(), height, graphicSettings.betterGraphics and graphicSettings.gateBorderRounding or nil)
	
	-- base rectangle border
	love.graphics.setColor(graphicSettings.gateUseAltBorderColor and graphicSettings.gateBorderColorAlt or graphicSettings.gateBorderColor)
	love.graphics.setLineWidth(graphicSettings.gateBorderWidth)
	love.graphics.rectangle("line", self.pos.x, self.pos.y, GATEgetWidth(), height, graphicSettings.betterGraphics and graphicSettings.gateBorderRounding or nil)
	
	-- input pins, circles
	for i=1,self.inputpincount do
		local pin = self.inputpins:get(i)
		if pin then
			local ypos = self.pos.y + (GATEsize.space*2) + ((GATEsize.space*3)*(i-1))
			if self.inputpins:get(i).isConnected then love.graphics.setColor(graphicSettings.gatePinColor.ON)
			else love.graphics.setColor(graphicSettings.gatePinColor.OFF) end
			love.graphics.circle("fill", self.pos.x, ypos, graphicSettings.gatePinSize)
			love.graphics.setLineWidth(1)
			love.graphics.setColor(1, 1, 1)
			love.graphics.circle("line", self.pos.x, ypos, graphicSettings.gatePinSize)
			self.inputpins:get(i).pos = newpos(self.pos.x, ypos)
		end
	end

	-- output pin, circle
	if self.outputpin.isConnected then love.graphics.setColor(graphicSettings.gatePinColor.ON)
	else love.graphics.setColor(graphicSettings.gatePinColor.OFF) end
	love.graphics.circle("fill", self.pos.x + GATEgetWidth(), self.pos.y + (height/2), graphicSettings.gatePinSize)
	love.graphics.setLineWidth(1)
	love.graphics.setColor(1, 1, 1)
	love.graphics.circle("line", self.pos.x + GATEgetWidth(), self.pos.y + (height/2), graphicSettings.gatePinSize)
	self.outputpin.pos = newpos(self.pos.x + GATEgetWidth(), self.pos.y + (height/2))

	-- Gate Type dependant drawing
	self:drawMe()
end

function GATE:resetPins()
	for i=1,self.inputpincount do
		self.inputpins:get(i).state = false
	end
end
function GATE:addPin()
	self.inputpincount = self.inputpincount + 1
	self.inputpins:append(constructINPUTPIN(self.id))
end
function GATE:removePin()
	if self.inputpincount > 2 then
		self.inputpincount = self.inputpincount - 1
		self.inputpins:pop()
	end
end

function GATE:isInside(x, y)
	local width = GATEgetWidth()
	local height = self:getHeight()
	return x >= self.pos.x and x <= self.pos.x + width and y >= self.pos.y and y <= self.pos.y + height
end

function GATE:getInputPinAt(x, y)
	local pinwidth = usePinArms and GATEgetWidth()/(GATEsize.width/3) or 0
	local pinx = self.pos.x - pinwidth
	local piny = self.pos.y + (GATEsize.space*2)
	for i=1,self.inputpincount do
		if lume.distance(pinx, piny, x, y, false) < 10 then
			return self.inputpins:get(i)
		end
		piny = piny + (GATEsize.space*3)
	end
	return nil
end
function GATE:getOutputPinAt(x, y)
	local pinwidth = usePinArms and GATEgetWidth()/(GATEsize.width/3) or 0
	local pinx = self.pos.x + GATEgetWidth() + pinwidth
	local piny = self.pos.y + self:getHeight()/2
	if lume.distance(pinx, piny, x, y, false) < 10 then
		return self.outputpin
	end
	return nil
end

function GATE:getInputPinByID(id)
	for i=1,self.inputpincount do
		if self.inputpins:get(i).id == id then
			return self.inputpins:get(i)
		end
	end
	return nil
end
function GATE:getOutputPinByID(id)
	if self.outputpin.id == id then
		return self.outputpin
	end
	return nil
end
function GATE:getAllPins()
	local pins = {}
	for i=1,self.inputpincount do
		pins[#pins+1] = self.inputpins:get(i)
	end
	pins[#pins+1] = self.outputpin
	return pins
end

------------------[ GATE TYPES ]------------------
function AND:drawMe()
	love.graphics.setColor(1, 1, 1)
	love.graphics.printCentered("AND", self.pos.x + (GATEgetWidth()/2), self.pos.y + (self:getHeight()/2))
end
function AND:update()
	local newstate = true
	for i=1,self.inputpincount do
		newstate = newstate and self.inputpins:get(i).state
	end
	self.state = newstate
	self.outputpin.state = self.state
end

function NAND:drawMe()
	love.graphics.setColor(1, 1, 1)
	love.graphics.printCentered("NAND", self.pos.x + (GATEgetWidth()/2), self.pos.y + (self:getHeight()/2))
end
function NAND:update()
	local newstate = true
	for i=1,self.inputpincount do
		newstate = newstate and self.inputpins:get(i).state
	end
	self.state = not newstate
	self.outputpin.state = self.state
end

function OR:drawMe()
	love.graphics.setColor(1, 1, 1)
	love.graphics.printCentered("OR", self.pos.x + (GATEgetWidth()/2), self.pos.y + (self:getHeight()/2))
end
function OR:update()
	local newstate = false
	for i=1,self.inputpincount do
		newstate = newstate or self.inputpins:get(i).state
	end
	self.state = newstate
	self.outputpin.state = self.state
end

function NOR:drawMe()
	love.graphics.setColor(1, 1, 1)
	love.graphics.printCentered("NOR", self.pos.x + (GATEgetWidth()/2), self.pos.y + (self:getHeight()/2))
end
function NOR:update()
	local newstate = false
	for i=1,self.inputpincount do
		newstate = newstate or self.inputpins:get(i).state
	end
	self.state = not newstate
	self.outputpin.state = self.state
end

function XOR:drawMe()
	love.graphics.setColor(1, 1, 1)
	love.graphics.printCentered("XOR", self.pos.x + (GATEgetWidth()/2), self.pos.y + (self:getHeight()/2))
end
function XOR:update()
	local newstate = false
	for i=1,self.inputpincount do
		if self.inputpins:get(i).state then newstate = not newstate end
	end
	self.state = newstate
	self.outputpin.state = self.state
end

function XNOR:drawMe()
	love.graphics.setColor(1, 1, 1)
	love.graphics.printCentered("XNOR", self.pos.x + (GATEgetWidth()/2), self.pos.y + (self:getHeight()/2))
end
function XNOR:update()
	local newstate = true
	for i=1,self.inputpincount do
		if self.inputpins:get(i).state then newstate = not newstate end
	end
	self.state = newstate
	self.outputpin.state = self.state
end

function NOT:removePin() end
function NOT:addPin() end
function NOT:drawMe()
	love.graphics.setColor(1, 1, 1)
	love.graphics.printCentered("NOT", self.pos.x + (GATEgetWidth()/2), self.pos.y + (self:getHeight()/2))
end
function NOT:update()
	local newstate = true
	for i=1,self.inputpincount do
		if self.inputpins:get(i).state then newstate = false break end
	end
	self.state = newstate
	self.outputpin.state = self.state
end

------------------[ PERIPHERAL ]------------------
function PERIPHERAL:update() end
function PERIPHERAL:drawMe() end

function PERIPHERAL:getWidth()
	return PERIPHERALgetWidth()
end
function PERIPHERAL:getHeight()
	return PERIPHERALsize.space * (4+(3*(math.max(self.inputpincount, self.outputpincount)-1))) * (GATEsize.scale/7)
end
function PERIPHERAL:draw()
	-- dropshadow
	love.graphics.setColor(graphicSettings.gateDropshadowColor)
	local height = self:getHeight()
	love.graphics.rectangle("fill", self.pos.x + graphicSettings.gateDropshadowOffset, self.pos.y + graphicSettings.gateDropshadowOffset, PERIPHERALgetWidth(), height, graphicSettings.gateDropshadowRounding)

	-- background
	if self.state then love.graphics.setColor(graphicSettings.gateStateColors.ON)
	else love.graphics.setColor(graphicSettings.gateStateColors.OFF) end
	love.graphics.rectangle("fill", self.pos.x, self.pos.y, PERIPHERALgetWidth(), height, graphicSettings.betterGraphics and graphicSettings.gateBorderRounding or nil)

	-- border
	love.graphics.setColor(graphicSettings.gateUseAltBorderColor and graphicSettings.gateBorderColorAlt or graphicSettings.gateBorderColor)
	love.graphics.setLineWidth(graphicSettings.gateBorderWidth)
	love.graphics.rectangle("line", self.pos.x, self.pos.y, PERIPHERALgetWidth(), height, graphicSettings.betterGraphics and graphicSettings.gateBorderRounding or nil)

	-- pins
	-- output
	if self.outputpincount > 0 then
		local xpos = self.pos.x + PERIPHERALgetWidth()
		local ypos = self.pos.y + (self:getHeight()/2)

		if self.outputpins:get(1).isConnected then love.graphics.setColor(graphicSettings.gatePinColor.ON)
		else love.graphics.setColor(graphicSettings.gatePinColor.OFF) end
		love.graphics.circle("fill", xpos, ypos, graphicSettings.gatePinSize)
		love.graphics.setLineWidth(1)
		love.graphics.setColor(1, 1, 1)
		love.graphics.circle("line", xpos, ypos, graphicSettings.gatePinSize)
		self.outputpins:get(1).pos = newpos(xpos, ypos)
	end

	-- input
	if self.inputpincount > 0 then
		local xpos = self.pos.x
		local ypos = self.pos.y + (self:getHeight()/2)

		if self.inputpins:get(1).isConnected then love.graphics.setColor(graphicSettings.gatePinColor.ON)
		else love.graphics.setColor(graphicSettings.gatePinColor.OFF) end
		love.graphics.circle("fill", xpos, ypos, graphicSettings.gatePinSize)
		love.graphics.setLineWidth(1)
		love.graphics.setColor(1, 1, 1)
		love.graphics.circle("line", xpos, ypos, graphicSettings.gatePinSize)
		self.inputpins:get(1).pos = newpos(xpos, ypos)
	end

	self:drawMe()
end

function PERIPHERAL:resetPins()
	for i=1,self.inputpincount do
		self.inputpins:get(i).state = false
	end
end

function PERIPHERAL:set(state)
	self.state = state
end
function PERIPHERAL:flip() 
	self.state = not self.state
end

function PERIPHERAL:isInside(x, y)
	return  x >= self.pos.x and x <= self.pos.x + PERIPHERALgetWidth()
		and y >= self.pos.y and y <= self.pos.y + self:getHeight()
end

function PERIPHERAL:getInputPinAt(x, y)
	local pinwidth = usePinArms and PERIPHERALgetWidth()/(PERIPHERALsize.width/3) or 0
	local pinx = self.pos.x - pinwidth
	local piny = self.pos.y + (PERIPHERALsize.space*2)
	for i=1,self.inputpincount do
		if lume.distance(pinx, piny, x, y, false) < 10 then
			return self.inputpins:get(i)
		end
		piny = piny + (PERIPHERALsize.space*3)
	end
	return nil
end
function PERIPHERAL:getOutputPinAt(x, y)
	local pinwidth = usePinArms and PERIPHERALgetWidth()/(PERIPHERALsize.width/3) or 0
	local pinx = self.pos.x + PERIPHERALgetWidth() + pinwidth
	local piny = self.pos.y + self:getHeight()/2
	for i=1,self.outputpincount do
		if lume.distance(pinx, piny, x, y, false) < 10 then
			return self.outputpins:get(i)
		end
		piny = piny + (PERIPHERALsize.space*3)
	end
	return nil
end

function PERIPHERAL:getInputPinByID(id)
	for i=1,self.inputpincount do
		if self.inputpins:get(i).id == id then
			return self.inputpins:get(i)
		end
	end	
	return nil
end
function PERIPHERAL:getOutputPinByID(id)
	for i=1,self.outputpincount do
		if self.outputpins:get(i).id == id then
			return self.outputpins:get(i)
		end
	end
	return nil
end
function PERIPHERAL:getAllPins()
	local pins = {}
	for i=1,self.inputpincount do
		pins[#pins+1] = self.inputpins:get(i)
	end
	for i=1,self.outputpincount do
		pins[#pins+1] = self.outputpins:get(i)
	end
	return pins
end

------------------[ PERIPHERAL TYPES ]------------------
function INPUT:update()	
	self.outputpins:get(1).state = self.state
end
function INPUT:drawMe()
	-- state
	local pad = 5
	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle("fill", self.pos.x+pad + (self.state and PERIPHERALgetWidth()/2-pad or 0), self.pos.y+pad, PERIPHERALgetWidth()/2-pad, self:getHeight()-pad*2)
end

function OUTPUT:update()
	self.state = self.inputpins:get(1).state
end
function OUTPUT:drawMe()
	love.graphics.setColor(1, 1, 1)
	love.graphics.printCentered(("OUT %d"):format(self.id-2000), self.pos.x + (PERIPHERALgetWidth()/2), self.pos.y + (self:getHeight()/2))
end

function CLOCK:update()
	local now = love.timer.getTime()
	if now - self.lastMicroSec > 1/self.tickspeed then
		self.state = not self.state
		self.lastMicroSec = now
	end
	self.outputpins:get(1).state = self.state
end
function CLOCK:getHeight()
	return PERIPHERALsize.space*6
end
function CLOCK:drawMe()
	love.graphics.setColor(1, 1, 1)
	love.graphics.printCentered(("CLOCK\n%d Hz"):format(self.tickspeed), self.pos.x + (PERIPHERALgetWidth()/2), self.pos.y + (self:getHeight()/4), 2)
end

function BUFFER:update()
	if self.isBuffering then
		if self.tickcounter > 0 then
			self.tickcounter = self.tickcounter - 1
		else
			self.state = self.inputpins:get(1).state
			self.outputpins:get(1).state = self.state
			self.isBuffering = false
		end
	else
		if self.state ~= self.inputpins:get(1).state then
			self.isBuffering = true
			self.tickcounter = self.ticks
		end
	end
end
function BUFFER:getHeight()
	return PERIPHERALsize.space*6
end
function BUFFER:drawMe()
	love.graphics.setColor(1, 1, 1)
	love.graphics.printCentered(("BUFFER \n%d tks"):format(self.ticks), self.pos.x + (PERIPHERALgetWidth()/2), self.pos.y + (self:getHeight()/4), 2)
end
