-- ==============================================================[ IMPORTS ]===================================================================--
print("Version: 1.7.1")
print("Starting...")
local utf8 = require("utf8")
function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end
function love.errorhandler(msg)
	msg = tostring(msg)
	error_printer(msg, 2)
	if not love.window or not love.graphics or not love.event then
		return
	end
	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then
			love.mouse.setCursor()
		end
	end
	if love.joystick then
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.audio then love.audio.stop() end
	love.graphics.reset()
	local font = love.graphics.setNewFont(16)
	love.graphics.setColor(246/255, 246/255, 246/255)
	local trace = debug.traceback()
	love.graphics.origin()
	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)
	local err = {}
	table.insert(err, "Error\n")
	table.insert(err, sanitizedmsg)
	if #sanitizedmsg ~= #msg then
		table.insert(err, "Invalid UTF-8 string in error message.")
	end
	table.insert(err, "\n")
	for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end
	local p = ""
	for i = 3, #err, 1 do p = p..err[i].."\n" end
	p = p:gsub("\t", "")
	p = p:gsub("%[string \"(.-)\"%]", "%1")
	local function draw()
		if not love.graphics.isActive() then return end
		local pos = 70
		love.graphics.clear(30/255, 30/255, 30/255)
		love.graphics.setColor(248/255, 46/255, 105/255)
		love.graphics.printf(err[1], pos, pos, love.graphics.getWidth() - pos)
		love.graphics.setColor(225/255, 157/255, 40/255)
		love.graphics.printf(err[2], pos, pos+40, love.graphics.getWidth() - pos)
		love.graphics.setColor(166/255, 226/255, 41/255)
		love.graphics.printf(p, pos, pos*2, love.graphics.getWidth() - pos)
		love.graphics.present()
	end
	return function()
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" then return 1
			elseif e == "keypressed" and a == "escape" then return 1 end
		end

		draw()

		if love.timer then love.timer.sleep(0.1) end
	end
end
local json = require("lib.json")
require "lib.noahsutils"
require "classes"
local font = love.graphics.newFont("fonts/main.ttf", 20)
font:setFilter("nearest", "nearest", 8)
love.graphics.setFont(font)

-- =============================================================[ VARIABLES ]==================================================================--

local lastX, lastY = 0, 0

local gates = Collection:new()
local peripherals = Collection:new()
local connections = Collection:new()
local groups = Collection:new()
local selectedPinID = 0
local isDraggingObject = false
local draggedObjectID = 0
local isDraggingSelection = false
local isSelecting = false
local selection = { x1 = 0, y1 = 0, x2 = 0, y2 = 0, ids = {} }
local isDraggingGroup = false
local draggedGroupID = 0
local showPlotter = false
local plotterID = 0
local plotterData = {}
local currentBoard = 1

local inMenu = false
local showHelp, showDebug, showTelemetry = false, false, false
local telemetryInterval, telemetryIntervalLast = 500, love.timer.getTime()
local telemetry, telemetryShow = {}, {}
local maxFPS = 500
local fullscreen = false

local timeOutMessage = ""
local timeOutTimer = 0

-- ===========================================================[ MAIN FUNCTIONS ]===============================================================--

function love.load()
	love.graphics.setBackgroundColor(0.11, 0.11, 0.11)
    addDefaults()
end

function love.update(dt)
	if inMenu then 
		-- do menu stuff
	else
		local time = love.timer.getTime()
		for bob in myBobjects() do bob:update() end
		telemetry.updateTimeBobjects = love.timer.getTime() - time

		time = love.timer.getTime()
		for con in myConnections() do
			local inputpin  = getPinByID(con.inputpinID)
			local outputpin = getPinByID(con.outputpinID)
			if inputpin and outputpin then
				inputpin.state = outputpin.state 
			end
		end
		telemetry.updateTimeConnections = love.timer.getTime() - time

		if isDraggingObject then
			local gate = getGateByID(draggedObjectID)
			local peripheral = getPeripheralByID(draggedObjectID)
			if gate then
				gate.pos.x = love.mouse.getX() - GATEgetWidth()/2
				gate.pos.y = love.mouse.getY() - gate:getHeight()/2
			elseif peripheral then
				peripheral.pos.x = love.mouse.getX() - PERIPHERALgetWidth()/2
				peripheral.pos.y = love.mouse.getY() - peripheral:getHeight()/2
			end
		end
	end
	if timeOutTimer > 0 then
		timeOutTimer = timeOutTimer - (dt * 1000)
	end
	if love.timer.getFPS() > maxFPS then
		maxFPS = love.timer.getFPS()
	end
	telemetry.dt = dt

end

function love.draw()
	if inMenu then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Menu", love.graphics.getWidth()/2-font:getWidth("Menu")/2, 20)
		love.graphics.print("Boards:", 20, 60)
		for i=1, 10 do
			if love.mouse.getX() > 20 and love.mouse.getX() < 20 + 100 and love.mouse.getY() > 80 + i*30 and love.mouse.getY() < 80 + i*30 + 30 then
				love.graphics.setColor(0.2, 0.4, 1)
				if love.mouse.isDown(1) then
					currentBoard = i
					load()
					inMenu = false
				end
			else
				love.graphics.setColor(1, 1, 1)
			end
			love.graphics.print("Board "..i, 20, 80 + i*30)
		end
	else
		-- grid points
		love.graphics.setColor(0.15, 0.15, 0.15)
		local step = 50
		for i=0, love.graphics.getWidth(), step do
			for j=0, love.graphics.getHeight(), step do
				love.graphics.circle("fill", i, j, 2)
			end
		end

		-- groups
		for i,group in ipairs(groups:all()) do
			if isDraggingGroup and draggedGroupID == i then
				group.x1 = group.x1 + (love.mouse.getX() - lastX)
				group.x2 = group.x2 + (love.mouse.getX() - lastX)
				group.y1 = group.y1 + (love.mouse.getY() - lastY)
				group.y2 = group.y2 + (love.mouse.getY() - lastY)

				-- move bobjects
				for bob in myBobjects() do
					if collect(group.ids):contains(bob.id) then
						bob.pos.x = bob.pos.x + (love.mouse.getX() - lastX)
						bob.pos.y = bob.pos.y + (love.mouse.getY() - lastY)
					end
				end
			end

			love.graphics.setColor(0.05, 0.05, 0.05, 0.6)
			love.graphics.rectangle("fill", group.x1, group.y1, group.x2 - group.x1, group.y2 - group.y1, 3)
		end

		--dragging selection
		if isDraggingSelection and not isDraggingGroup then
			for i,id in ipairs(selection.ids) do
				local bob = getBobByID(id)
				if bob then
					bob.pos.x = bob.pos.x + (love.mouse.getX() - lastX)
					bob.pos.y = bob.pos.y + (love.mouse.getY() - lastY)
				end
			end
			selection.x1 = selection.x1 + (love.mouse.getX() - lastX)
			selection.x2 = selection.x2 + (love.mouse.getX() - lastX)
			selection.y1 = selection.y1 + (love.mouse.getY() - lastY)
			selection.y2 = selection.y2 + (love.mouse.getY() - lastY)
		end

		-- selection
		if isSelecting then
			love.graphics.setColor(0.2, 0.2, 0.3, 0.5)
			love.graphics.rectangle("fill", selection.x1, selection.y1, love.mouse.getX() - selection.x1, love.mouse.getY() - selection.y1)
			love.graphics.setColor(0.2, 0.2, 0.3)
			love.graphics.rectangle("line", selection.x1, selection.y1, love.mouse.getX() - selection.x1, love.mouse.getY() - selection.y1)
		elseif selection.x1 ~= selection.x2 and selection.y1 ~= selection.y2 then
			love.graphics.setColor(0.2, 0.2, 0.3, 0.5)
			love.graphics.rectangle("fill", selection.x1, selection.y1, selection.x2 - selection.x1, selection.y2 - selection.y1, 2)
			love.graphics.setColor(0.2, 0.2, 0.3)
			love.graphics.rectangle("line", selection.x1, selection.y1, selection.x2 - selection.x1, selection.y2 - selection.y1, 2)
		end
		
		-- connections
		time = love.timer.getTime()
		love.graphics.setColor(0, 0.71, 0.48)
		love.graphics.setLineWidth(2)
		for con in myConnections() do
			local inputpinPos = getPinPosByID(con.inputpinID)
			local outputpinPos = getPinPosByID(con.outputpinID)
			if inputpinPos and outputpinPos then
				local offset = 80
				local curve = love.math.newBezierCurve({ 
					outputpinPos.x, outputpinPos.y,
					outputpinPos.x + offset, outputpinPos.y,
					inputpinPos.x - offset, inputpinPos.y,
					inputpinPos.x, inputpinPos.y
				})
				love.graphics.line(curve:render())
			end
		end
		telemetry.drawTimeConnections = love.timer.getTime() - time

		-- gates and periphs
		local time = love.timer.getTime()
		-- draw bobjects in order of their y position
		local bobjects = getBobjects():all()
		table.sort(bobjects, function(a, b) return a.pos.y < b.pos.y end)
		for i,bob in ipairs(bobjects) do bob:draw() end
		telemetry.drawTimeBobjects = love.timer.getTime() - time

		-- currently connecting pin
		love.graphics.setColor(0, 0.71, 0.48)
		love.graphics.setLineWidth(2)
		if selectedPinID > 0 then
			local pinPos = getPinPosByID(selectedPinID)
			love.graphics.print("Selected Pin: "..selectedPinID, 20, 80)
			if pinPos then
				local offset = 80
				local curve = love.math.newBezierCurve({ 
					pinPos.x, pinPos.y,
					pinPos.x + offset, pinPos.y,
					love.mouse.getX() - offset, love.mouse.getY(),
					love.mouse.getX(), love.mouse.getY()
				})
				love.graphics.line(curve:render())
			end
		end

		-- plotter
		time = love.timer.getTime()
		if showPlotter then
			local w, h = love.graphics.getDimensions()
			local pw, ph = w/4*2, 150
			love.graphics.setColor(0.2, 0.2, 0.2)
			love.graphics.rectangle("fill", w/4, h - ph/2-10, w/4*2, ph/2, 6)
			love.graphics.setColor(0.4, 0.4, 0.4)
			love.graphics.rectangle("line", w/4, h - ph/2-10, w/4*2, ph/2, 6)

			love.graphics.setColor(1, 1, 1)
			love.graphics.print("OUTPUT ID: "..tostring(plotterID-2000), w/4+pw+10, h-ph/2-5)
			love.graphics.print("FREQUENCY: "..tostring(0), w/4+pw+10, h-ph/2+30)

			if plotterID-2000 > 0 then
				local per = getPeripheralByID(plotterID)
				if per then
					table.insert(plotterData, per.state and 1 or 0)
					if #plotterData > pw then
						table.remove(plotterData, 1)
					end
					love.graphics.setColor(0.6, 0.6, 0.6)
					for i = 2, #plotterData do
						love.graphics.line(
							w/4 + i - 1, h - 15 - plotterData[i - 1] * ((ph/2)-10),
							w/4 + i,     h - 15 - plotterData[i] * ((ph/2)-10)
						)
					end
				end
			end
		end
		telemetry.drawTimePlotter = love.timer.getTime() - time

		if showHelp then
			love.graphics.setColor(1, 1, 1)
			love.graphics.print("1-AND", 10, 150)
			love.graphics.print("2-OR", 10, 180)
			love.graphics.print("3-NOT", 10, 210)
			love.graphics.print("4-NAND", 10, 240)
			love.graphics.print("5-NOR", 10, 270)
			love.graphics.print("6-XOR", 10, 300)
			love.graphics.print("7-XNOR", 10, 330)
			love.graphics.print("8-INPUT", 10, 360)
			love.graphics.print("9-CLOCK", 10, 390)
			love.graphics.print("0-OUTPUT", 10, 420)
			love.graphics.print("b-BUFFER", 10, 450)
			
			love.graphics.print("ESC-TOGGLE MENU", 10, 500)
			love.graphics.print("STRG+S-SAVE", 10, 530)
			love.graphics.print("STRG+L-LOAD", 10, 560)
			love.graphics.print("STRG+C-COPY", 10, 590)
			love.graphics.print("STRG+V-PASTE", 10, 620)
			love.graphics.print("STRG+R-RESET", 10, 650)
			love.graphics.print("STRG+D-DEFAULTS", 10, 680)
			love.graphics.print("STRG+P-PLOTTER", 10, 710)
			love.graphics.print("STRG+Q-QUIT", 10, 740)
		end

		if showDebug then
			love.graphics.setColor(0.6, 1, 0.6)
			love.graphics.print(string.format("Board Objects: %d\nConnections: %d\n", getBobjects():count(), connections:count()), love.graphics.getWidth()-250, 150)
		end

		if showTelemetry then
			if love.timer.getTime()*1000 - telemetryIntervalLast*1000 > telemetryInterval then
				for k,v in pairs(telemetry) do
					telemetryShow[k] = v
				end
				telemetryIntervalLast = love.timer.getTime()
			end
			love.graphics.setColor(1, 0.6, 0.6)
			love.graphics.print(string.format(
				"Timings:\n\nBoard Objects Update: %dµs\nConnections Update: %dµs\n\nBoard Objects Draw: %dµs\nConnections Draw: %dµs\nPlotter Draw: %dµs\n\nTotal: %dµs",
				telemetryShow.updateTimeBobjects*1000000, telemetryShow.updateTimeConnections*1000000, telemetryShow.drawTimeBobjects*1000000, telemetryShow.drawTimeConnections*1000000, telemetryShow.drawTimePlotter*1000000, telemetryShow.dt*1000000
			), love.graphics.getWidth()-300, 400)
		end
		
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(("FPS: %d | %.1f%% Lag | Current Board: %d (Press [H] for Help)"):format(tostring(love.timer.getFPS()), (100-love.timer.getFPS()/maxFPS*100), currentBoard), 10, 10)
		if isDraggingGroup or isDraggingObject or isDraggingSelection then
			love.graphics.print(isDraggingSelection and "Dragging Selection" or (isDraggingGroup and "Dragging Group ID: "..tostring(draggedGroupID) or (isDraggingObject and "Dragging Object ID: "..tostring(draggedObjectID) or "")), 10, 70)
		end
		if timeOutTimer > 0 then
			love.graphics.setColor(1, 0.5, 0)
			love.graphics.print(timeOutMessage, 13, 40)
		end
	end
	lastX, lastY = love.mouse.getPosition()
end

function love.resize(w, h)
	for bob in myBobjects() do 
		if bob.pos.x+50 > w then bob.pos.x = w-100 end
		if bob.pos.y+50 > h then bob.pos.y = h-100 end
	end
end

-- ==========================================================[ INPUT FUNCTIONS ]===============================================================--

function love.mousepressed(x, y, button)
	--=====================[ LEFT CLICK ]=====================--
	if button == 1 then
		for bob in myBobjects() do			
			local inpin  = bob:getInputPinAt(x, y)
			local outpin = bob:getOutputPinAt(x, y)

			if selectedPinID == 0 then
				if outpin then
					outpin.isConnected = true
					selectedPinID = outpin.id or selectedPinID
				end
			else
				if inpin then
					if not inpin.isConnected then
						inpin.isConnected = true
						connections:append({ outputpinID=selectedPinID, inputpinID=inpin.id })
						selectedPinID = 0
					end
				end
			end

			if bob:isInside(x, y) and inpin == nil and outpin == nil then
				if bob.name == "INPUT" then
				bob:flip()
				elseif bob.name == "OUTPUT" then
					if plotterID == bob.id then
						showPlotter = false
						plotterID = 0
					else
						plotterID = bob.id
						plotterData = {}
						showPlotter = true
					end
				end
			else
				isSelecting = true
				selection.x1 = x
				selection.y1 = y
				selection.x2 = x
				selection.y2 = y
			end
		end
	--=====================[ RIGHT CLICK ]=====================--
	elseif button == 2 then
		if selectedPinID > 0 then
			local pin = getPinByID(selectedPinID)
			pin.isConnected = false
			selectedPinID = 0
		else
			local pinID = getPinIDByPos(x, y)
			if pinID then
				removeConnectionWithPinID(pinID)
			end
		end
	--=====================[ MIDDLE CLICK ]=====================--
	elseif button == 3 then
		for i,group in ipairs(groups:all()) do
			if x > group.x1 and x < group.x2 and y > group.y1 and y < group.y2 then
				draggedGroupID = i
				isDraggingGroup = true
			end
		end

		if not isDraggingGroup then
			if x > selection.x1 and x < selection.x2 and y > selection.y1 and y < selection.y2 then
				isDraggingSelection = true
			end

			if not isDraggingGroup then
				for bob in myBobjects() do
					if bob:isInside(x, y) then
						draggedObjectID = bob.id
						isDraggingObject = true
					end
				end
			end
		end
	end
end

function love.mousereleased(x, y, button)
	if button == 1 then
		isSelecting = false
		selection.x2 = x
		selection.y2 = y

		if selection.x1 > selection.x2 then
			selection.x1, selection.x2 = selection.x2, selection.x1
		end
		if selection.y1 > selection.y2 then
			selection.y1, selection.y2 = selection.y2, selection.y1
		end

		selection.ids = {}
		for bob in myBobjects() do
			if bob.pos.x > selection.x1 and bob.pos.x < selection.x2 and bob.pos.y > selection.y1 and bob.pos.y < selection.y2 then
				table.insert(selection.ids, bob.id)
			end
		end
	elseif button == 3 then
		-- check if dragged object is below or above any near bobject
		if draggedObjectID > 0 then	end

		isDraggingObject = false
		draggedObjectID = 0
		isDraggingGroup = false
		draggedGroupID = 0
		isDraggingSelection = false
	end
end

function love.wheelmoved(dx, dy)
    if love.keyboard.isDown("lshift") then
    elseif love.keyboard.isDown("lctrl") then
    else
		for bob in myBobjects() do
			if bob:isInside(love.mouse.getX(), love.mouse.getY()) then
				if bob.name == "CLOCK" then
					bob.tickspeed = bob.tickspeed + dy
					if bob.tickspeed < 1 then bob.tickspeed = 1 end
				elseif bob.type == "GATE" then
					if dy > 0 then
						bob:addPin()
					elseif dy < 0 then
						bob:removePin()
					end
				elseif bob.name == "BUFFER" then
					bob.ticks = bob.ticks + dy
					if bob.ticks < 1 then bob.ticks = 1 end
				end
			end
		end
	end
end

function love.keypressed(key, scancode, isrepeat)
	if key == "space" then
		prinspect(telemetry)
	end
	if key == "f11" then
		fullscreen = not fullscreen
		love.window.setFullscreen(fullscreen, "exclusive")
	end	
	if key == "escape" then
		inMenu = not inMenu
	end
	if not inMenu then
		if love.keyboard.isDown("lctrl", "rctrl") then
			if key == "s" then
				save()
			elseif key == "l" then
				load()
			elseif key == "r" then
				resetBoard()
			elseif key == "d" then
				addDefaults()
			elseif key == "p" then
				showPlotter = not showPlotter
			elseif key == "g" then
				graphicSettings.betterGraphics = not graphicSettings.betterGraphics
			elseif key == "t" then
				graphicSettings.gateUseAltBorderColor = not graphicSettings.gateUseAltBorderColor
			elseif key == "c" then
				love.system.setClipboardText(json.encode({ gates=gates:all(), peripherals=peripherals:all(), connections=connections:all() }))
				showMessage("Board Data copied to Clipboard!")
			elseif key == "v" then
				local text = love.system.getClipboardText()
				if text:match("gates") and text:match("peripherals") and text:match("connections") then
					local data = json.decode(text)
					if data then
						resetBoard()
						for i, gatedata in ipairs(data.gates) do			
							addGate(loadGATE(gatedata))
						end
						for i, peripheraldata in ipairs(data.peripherals) do
							addPeripheral(loadPERIPHERAL(peripheraldata))
						end
						for i, connection in ipairs(data.connections) do
							connections:append(connection)
						end
						showMessage("Board Data loaded from Clipboard!")
					end
				end
			elseif key == "q" then
				love.event.quit()
			end
		else
			if key == "d" then
				showDebug = not showDebug
			elseif key == "t" then
				showTelemetry = not showTelemetry
			elseif key == "g" then
				addGroup()
				selection = {x1=0, y1=0, x2=0, y2=0, ids={}}
			end
		end
		if key == "delete" then
			local groupID = getGroupIDByPos(love.mouse.getX(), love.mouse.getY())
			if groupID then
				removeGroupByID(groupID, love.keyboard.isDown("lshift"))
			else
				if getBobjects():count() > 0 then
					local bobID = getBobIDByPos(love.mouse.getX(), love.mouse.getY())
					if bobID then
						removeBobByID(bobID)
					end
				end
			end
		end
		if key == "h" then
			showHelp = not showHelp
		end
		if love.keyboard.isDown("lalt") then
			if key == "1" then
				save()
				currentBoard = 1
				load()
			elseif key == "2" then
				save()
				currentBoard = 2
				load()
			elseif key == "3" then
				save()
				currentBoard = 3
				load()
			elseif key == "4" then
				save()
				currentBoard = 4
				load()
			elseif key == "5" then
				save()
				currentBoard = 5
				load()
			elseif key == "6" then
				save()
				currentBoard = 6
				load()
			elseif key == "7" then
				save()
				currentBoard = 7
				load()
			elseif key == "8" then
				save()
				currentBoard = 8
				load()
			elseif key == "9" then
				save()
				currentBoard = 9
				load()
			elseif key == "0" then
				save()
				currentBoard = 10
				load()
			end							
		elseif not love.keyboard.isDown("lgui") then
			if key == "1" then
				addGate(constructAND(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2))
			elseif key == "2" then
				addGate(constructOR(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2))
			elseif key == "3" then
				addGate(constructNOT(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2, 1))
			elseif key == "4" then
				addGate(constructNAND(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2))
			elseif key == "5" then
				addGate(constructNOR(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2))
			elseif key == "6" then
				addGate(constructXOR(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2))
			elseif key == "7" then
				addGate(constructXNOR(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2))
			elseif key == "8" then
				addPeripheral(constructINPUT(love.mouse.getX() - PERIPHERALgetWidth()/2, love.mouse.getY() - PERIPHERALgetHeight()/2))
			elseif key == "9" then
				addPeripheral(constructCLOCK(love.mouse.getX() - PERIPHERALgetWidth()/2, love.mouse.getY()- PERIPHERALgetHeight()/2))
			elseif key == "0" then
				addPeripheral(constructOUTPUT(love.mouse.getX() - PERIPHERALgetWidth()/2, love.mouse.getY()- PERIPHERALgetHeight()/2))
			elseif key == "b" then
				addPeripheral(constructBUFFER(love.mouse.getX() - PERIPHERALgetWidth()/2, love.mouse.getY()- PERIPHERALgetHeight()/2))
			end
		end
	end
end

--==============================================[ CUSTOM FUNCTIONS ]==============================================--

function showMessage(msg)
	timeOutMessage = msg
	timeOutTimer = 2000
end

function resetBoard()
	connections = Collection:new()
	gates = Collection:new()
	peripherals = Collection:new()
	groups = Collection:new()	
	selectedPinID = 0
	isDraggingObject = false
	draggedObjectID = 0
	isDraggingSelection = false
	selection = { x1 = 0, y1 = 0, x2 = 0, y2 = 0, ids = {} }
	isDraggingGroup = false
	draggedGroupID = 0
	showPlotter = false
	plotterID = 0
	plotterData = {}
	showMessage("Board Reset...")
end

function addDefaults()
	addGate(constructAND(200, 100))
	addGate(constructOR(400, 100))
	addGate(constructNOT(600, 100, 1))
	addPeripheral(constructBUFFER(200, 300))
	addPeripheral(constructINPUT(200, 500))
	addPeripheral(constructCLOCK(400, 500))
	addPeripheral(constructOUTPUT(600, 500))
	showMessage("Default Board Loaded!")
end

function load()
	resetBoard()
	contents = love.filesystem.read(string.format("board%d.json", currentBoard))
	if contents then
		local data = json.decode(contents)
		if data.gates then
			for i, gatedata in ipairs(data.gates) do
				addGate(loadGATE(gatedata))			
		end end
		if data.peripherals then
			for i, peripheraldata in ipairs(data.peripherals) do
				addPeripheral(loadPERIPHERAL(peripheraldata))
		end end
		if data.connections then
			for i, connection in ipairs(data.connections) do
				connections:append(connection)
		end end
		if data.groups then
			for i, group in ipairs(data.groups) do
				groups:append(group)
		end end
	else
		print('file not found')
	end
	showMessage(string.format("Board %d Loaded!", currentBoard))
end

function save()
	local success, message = love.filesystem.write(string.format("board%d.json", currentBoard), json.encode({ gates=gates:all(), peripherals=peripherals:all(), connections=connections:all(), groups=groups:all() }))
	if success then showMessage(string.format("Board %d Saved!", currentBoard))
	else showMessage(string.format("Board could not be Saved...")) end
end

function addGroup()
	local group = { x1 = 10000, y1 = 10000, x2 = 0, y2 = 0, ids = {}}
	local hasBobjects = false
	local padding = 20

	for bob in myBobjects() do
		if collect(selection.ids):contains(bob.id) and groups:every(function(key,group) return not collect(group.ids):contains(bob.id) end) then
			hasBobjects = true
			if bob.pos.x < group.x1 then
				group.x1 = bob.pos.x
			end
			if bob.pos.y < group.y1 then
				group.y1 = bob.pos.y
			end
			if bob.pos.x > group.x2 then
				group.x2 = bob.pos.x + bob:getWidth() + padding
			end
			if bob.pos.y > group.y2 then
				group.y2 = bob.pos.y + bob:getHeight() + padding
			end

			table.insert(group.ids, bob.id)
		end
	end

	if hasBobjects then
		group.x1 = group.x1 - padding
		group.y1 = group.y1 - padding
		group.x2 = group.x2 + padding
		group.y2 = group.y2 + padding

		groups:append(group)
	end	
end


function getPinByID(id)
	for bob in myBobjects() do
		local inpin = bob:getInputPinByID(id)
		local outpin = bob:getOutputPinByID(id)
		if inpin ~= nil then
			return inpin
		elseif outpin ~= nil then
			return outpin
		end
	end
	return nil
end
function getPinPosByID(id)
	for bob in myBobjects() do
		local inpin = bob:getInputPinByID(id)
		local outpin = bob:getOutputPinByID(id)
		if inpin ~= nil then
			return inpin.pos
		elseif outpin ~= nil then
			return outpin.pos
		end
	end
	return nil
end
function getPinIDByPos(x, y)
	for bob in myBobjects() do
		local inpin = bob:getInputPinAt(x, y)
		local outpin = bob:getOutputPinAt(x, y)
		if inpin ~= nil then
			return inpin.id
		elseif outpin ~= nil then
			return outpin.id
		end
	end
	return nil
end

function getBobIDByPos(x, y)
	for bob in myBobjects() do
		if bob:isInside(x, y) then
			return bob.id
		end
	end
	return nil
end
function getGroupIDByPos(x, y)
	for i,group in ipairs(groups:all()) do
		if x > group.x1 and x < group.x2 and y > group.y1 and y < group.y2 then
			return i
		end
	end
	return nil
end

function getGateByID(id)
	for gate in myGates() do
		if gate.id == id then
			return gate
		end
	end
	return nil
end
function getPeripheralByID(id)
	for per in myPeripherals() do
		if per.id == id then
			return per
		end
	end
	return nil
end
function getBobByID(id)
	for bob in myBobjects() do
		if bob.id == id then
			return bob
		end
	end
	return nil
end


function removeConnectionWithPinID(id)
	for con,index in myConnections() do
		if con.inputpinID == id or con.outputpinID == id then
			connections:forget(index)
			
			local inputpin = getPinByID(con.inputpinID)
			local outputpin = getPinByID(con.outputpinID)

			inputpin.isConnected = false
			outputpin.isConnected = false

			local inputpinGate = getGateByID(inputpin.parentID)
			local inputpinPer = getPeripheralByID(inputpin.parentID)
			local outputpinGate = getGateByID(outputpin.parentID)
			local outputpinPer = getPeripheralByID(outputpin.parentID)

			if inputpinGate ~= nil then
				inputpinGate:resetPins()
				inputpinGate:update()
			end
			if inputpinPer ~= nil then
				inputpinPer:resetPins()
				inputpinPer:update()
			end

			if outputpinGate ~= nil then
				outputpinGate:resetPins()
				outputpinGate:update()
			end
			if outputpinPer ~= nil then
				outputpinPer:resetPins()
				outputpinPer:update()
			end

		end
	end
	connections = connections:resort()
end
function removeBobByID(id)
	removeGateByID(id)
	removePeripheralByID(id)
end
function removeGateByID(id)
	for gate,index in myGates() do
		if gate.id == id then
			for _,pin in ipairs(gate:getAllPins()) do
				if pin.isConnected then
					removeConnectionWithPinID(pin.id)
				end
			end
			gates:forget(index)
			gates = gates:resort()
		end
	end
end
function removePeripheralByID(id)
	for per,index in myPeripherals() do
		if per.id == id then
			for _,pin in ipairs(per:getAllPins()) do
				if pin.isConnected then
					removeConnectionWithPinID(pin.id)
				end
			end
			peripherals:forget(index)
			peripherals = peripherals:resort()
		end
	end
end
function removeGroupByID(id, deleteBobs)
	for i,group in ipairs(groups:all()) do
		if i == id then
			if deleteBobs then
				for _,bobID in ipairs(group.ids) do
					removeBobByID(bobID)
				end
			end
			groups:forget(i)
			groups = groups:resort()
		end
	end
end

function checkIfInputpinHasConnection(pin)
	for con in myConnections() do
		if con.inputpinID == pin.id then
			return true
		end
	end
	return false
end

function addGate(gate)
	-- history:append(gate.id)
	gates:append(gate)
end
function addPeripheral(peripheral)
	-- history:append(peripheral.id)
	peripherals:append(peripheral)
end

function getBobjects()
	return gates:merge(peripherals:all())
end

function myConnections()
	local index = 0
	return function()
		index = index + 1
		local con = connections:get(index)
		if con ~= nil and con.inputpinID ~= nil and con.outputpinID ~= nil then
			return con, index
		end
	end
end
function myBobjects()
	local index = 0
	local bobjects = getBobjects()
	return function()
		index = index + 1
		if bobjects:get(index) ~= nil then
			return bobjects:get(index), index
		end
	end
end
function myGates()
	local index = 0
	return function()
		index = index + 1
		local gate = gates:get(index)
		if (gate ~= nil) and (gate.type == "GATE") then
			return gate, index
		end
	end
end
function myPeripherals()
	local index = 0
	return function()
		index = index + 1
		local per = peripherals:get(index)
		if (per ~= nil) and (per.type == "PERIPHERAL") then
			return per, index
		end
	end
end
