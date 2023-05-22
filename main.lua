-- ==============================================================[ IMPORTS ]===================================================================--
print('\nVersion: 1.7.1')
print('Starting...')
require 'fancyerror'

require 'noahsutils'
require 'classes'
local json = require 'json'
local Camera = require 'camera'

local font = love.graphics.newFont('fonts/main.ttf', 20)
font:setFilter('nearest', 'nearest', 8)
love.graphics.setFont(font)

-- =============================================================[ VARIABLES ]==================================================================--

local lastX, lastY = 0, 0

-- worker
local gates = Collection:new()
local peripherals = Collection:new()
local connections = Collection:new()
local groups = Collection:new()

-- idk
local selectedPinID = 0

-- main
local isDraggingObject = false
local isDraggingSelection = false
local isDraggingGroup = false

local draggedObjectID = 0
local draggedGroupID = 0

local selection = { x1 = 0, y1 = 0, x2 = 0, y2 = 0, ids = {} }
local isSelecting = false
local dontSelect = false

local showPlotter = false
local plotterID = 0
local plotterData = {}

-- main?
local currentBoard = 1

-- main
local inMenu = false
local showHelp, showDebug, showTelemetry = false, false, false
local telemetryInterval, telemetryIntervalLast = 500, love.timer.getTime()
local telemetry, telemetryShow = {}, {}
local maxFPS = 60
local fullscreen = false

local timeOutMessage = ""
local timeOutTimer = 0

local computeThread = {}
local computeThreadUPS, computeThreadMaxUPS = 0, 10000

local style = {}

local camera = {}


-- ===========================================================[ MAIN FUNCTIONS ]===============================================================--

function love.load()
	love.graphics.setBackgroundColor(0.11, 0.11, 0.11)
    computeThread = love.thread.newThread("computeThread.lua")
	computeThread:start(computeThreadMaxUPS)

	-- loadBoard()
	addDefaults()

	camera = Camera.newSmooth(40, 0.5, 5)
	
	local done = love.thread.getChannel("setup"):supply(true)
end

function love.update(dt)
	if inMenu then
		-- do menu stuff
	else
		camera:update(dt)
		mx, my = camera:getScreenPos( love.mouse.getPosition() )
		-- update board objects
		local time = love.timer.getTime()
		for bob in myBobjects() do bob:update() end
		telemetry.updateTimeBobjects = love.timer.getTime() - time

		-- update connections
		time = love.timer.getTime()
		for con in myConnections() do
			con.inputpin.state = con.outputpin.state
		end
		telemetry.updateTimeConnections = love.timer.getTime() - time

	end
	if timeOutTimer > 0 then
		timeOutTimer = timeOutTimer - (dt * 1000)
	end
	if love.timer.getFPS() > maxFPS then
		maxFPS = love.timer.getFPS()
	end
	telemetry.dt = dt
	
	computeThreadUPS = love.thread.getChannel("ups"):pop() or computeThreadUPS
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
					loadBoard()
					inMenu = false
				end
			else
				love.graphics.setColor(1, 1, 1)
			end
			love.graphics.print("Board "..i, 20, 80 + i*30)
		end
	else
		-- camera
		mx, my = camera:getScreenPos( love.mouse.getPosition() )
		camera:set()
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
			love.graphics.setColor(0.05, 0.05, 0.05, 0.6)
			love.graphics.rectangle("fill", group.x1, group.y1, group.x2 - group.x1, group.y2 - group.y1, 3)
		end

		-- selection
		if isSelecting then
			love.graphics.setColor(0.2, 0.2, 0.3, 0.5)
			love.graphics.rectangle("fill", selection.x1, selection.y1, mx - selection.x1, my - selection.y1)
			love.graphics.setColor(0.2, 0.2, 0.3)
			love.graphics.rectangle("line", selection.x1, selection.y1, mx - selection.x1, my - selection.y1)
		elseif selection.x1 ~= selection.x2 and selection.y1 ~= selection.y2 then
			love.graphics.setColor(0.2, 0.2, 0.3, 0.5)
			love.graphics.rectangle("fill", selection.x1, selection.y1, selection.x2 - selection.x1, selection.y2 - selection.y1, 2)
			love.graphics.setColor(0.2, 0.2, 0.3)
			love.graphics.rectangle("line", selection.x1, selection.y1, selection.x2 - selection.x1, selection.y2 - selection.y1, 2)
		end
		
		-- GET FROM COMPUTE THREAD

		-- connections
		time = love.timer.getTime()
		love.graphics.setColor(0, 0.71, 0.48)
		love.graphics.setLineWidth(2)
		for con in myConnections() do
			local inputpinPos = con.inputpin.pos or false
			local outputpinPos = con.outputpin.pos or false
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

		camera:set()

		-- plotter
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

		if showHelp then
			love.graphics.setColor(1, 1, 1)
			love.graphics.print(nt[[
				1-AND
				2-OR
				3-NOT
				4-NAND
				5-NOR
				6-XOR
				7-XNOR
				8-INPUT
				9-CLOCK
				0-OUTPUT
				b-BUFFER
				
				ESC-TOGGLE MENU
				STRG+S-SAVE
				STRG+L-LOAD
				STRG+C-COPY
				STRG+V-PASTE
				STRG+R-RESET
				STRG+D-DEFAULTS
				STRG+P-PLOTTER
				STRG+Q-QUIT
				]], 10, 150)
		end

		if showDebug then
			love.graphics.setColor(0.6, 1, 0.6)
			love.graphics.print(string.format("Board Objects: %d\nConnections: %d\n", getBobjects():count(), connections:count()), love.graphics.getWidth()-250, 150)
		end

		if showTelemetry then
			if love.timer.getTime() - telemetryIntervalLast > telemetryInterval/1000 then
				for k,v in pairs(telemetry) do
					telemetryShow[k] = v
				end
				telemetryShow.stats = love.graphics.getStats()
				telemetryIntervalLast = love.timer.getTime()
			end
			love.graphics.setColor(1, 0.6, 0.6)
			love.graphics.print(string.format(
				nt[[
					Timings:
					
					Board Objects Update: %s
					Connections Update: %s
					
					Board Objects Draw: %s
					Connections Draw: %s
					
					Total: %s


					Love Stats:

					Drawcalls: %d
					Canvas Switches: %d
					Texture Memory: %d
					Images: %d
					Canvases: %d
					Shader Switches: %d
					Drawcalls Batched: %d
				]],
				formatTime(telemetryShow.updateTimeBobjects),
				formatTime(telemetryShow.updateTimeConnections),
				formatTime(telemetryShow.drawTimeBobjects),
				formatTime(telemetryShow.drawTimeConnections),
				formatTime(telemetryShow.dt),
				telemetryShow.stats.drawcalls,
				telemetryShow.stats.canvasswitches,
				telemetryShow.stats.texturememory,
				telemetryShow.stats.images,
				telemetryShow.stats.canvases,
				telemetryShow.stats.shaderswitches,
				telemetryShow.stats.drawcallsbatched
			),
			love.graphics.getWidth()-300, 400)
		end
		
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(("FPS: %s | UPS: %s | %.1f%% Lag | Current Board: %d (Press [H] for Help)"):format(tostring(love.timer.getFPS()), nfc(computeThreadUPS), (100-love.timer.getFPS()/maxFPS*100), currentBoard), 10, 10)
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

function love.quit()
	local id = love.thread.getChannel("kill"):push(true)
	repeat until love.thread.getChannel("kill"):hasRead(id)
end

-- ==========================================================[ INPUT FUNCTIONS ]===============================================================--

function love.mousepressed(x, y, button)
	x,y = camera:getScreenPos( x,y )
	--=====================[ LEFT CLICK ]=====================--
	if button == 1 then
		dontSelect = false
		for bob in myBobjects() do
			local inpin  = bob:getInputPinAt(x, y)
			local outpin = bob:getOutputPinAt(x, y)

			if selectedPinID == 0 then
				if outpin then
					dontSelect = true
					outpin.isConnected = true
					selectedPinID = outpin.id or selectedPinID
				end
			else
				if inpin then
					dontSelect = true
					if not inpin.isConnected then
						inpin.isConnected = true
						addConnection({ outputpin=getPinByID(selectedPinID), inputpin=inpin })
						selectedPinID = 0
					end
				end
			end
			if bob:isInside(x, y) and not dontSelect then
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
				dontSelect = true
			end
		end
		if not dontSelect then
			isSelecting = true
			selection.x1 = x
			selection.y1 = y
			selection.x2 = x
			selection.y2 = y
		end
	--=====================[ RIGHT CLICK ]=====================--
	elseif button == 2 then
		
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

function love.mousemoved(x, y, dx, dy)
	x, y = camera:getScreenPos(x, y)
	sdx, sdy = camera:applyScale(dx, dy)
	
	if isDraggingGroup then
		local group = groups:get(draggedGroupID)
		group.x1 = group.x1 + sdx
		group.y1 = group.y1 + sdy
		group.x2 = group.x2 + sdx
		group.y2 = group.y2 + sdy

		for i,id in ipairs(group.ids) do
			local bob = getBobByID(id)
			if bob then
				bob.pos.x = bob.pos.x + sdx
				bob.pos.y = bob.pos.y + sdy
			end
		end
	elseif isDraggingSelection then
		selection.x1 = selection.x1 + sdx
		selection.y1 = selection.y1 + sdy
		selection.x2 = selection.x2 + sdx
		selection.y2 = selection.y2 + sdy

		for i,id in ipairs(selection.ids) do
			local bob = getBobByID(id)
			if bob then
				bob.pos.x = bob.pos.x + sdx
				bob.pos.y = bob.pos.y + sdy
			end
		end
	elseif isDraggingObject then
		local bob = getBobByID(draggedObjectID)
		bob.pos.x = bob.pos.x + sdx
		bob.pos.y = bob.pos.y + sdy
	else
		if love.mouse.isDown(2) then
			camera:move( dx,dy )
		end
	end

	--dragging selection
	-- if isDraggingSelection and not isDraggingGroup then
	-- 	for i,id in ipairs(selection.ids) do
	-- 		local bob = getBobByID(id)
	-- 		if bob then
	-- 			bob.pos.x = bob.pos.x + (love.mouse.getX() - lastX)
	-- 			bob.pos.y = bob.pos.y + (love.mouse.getY() - lastY)
	-- 		end
	-- 	end
	-- 	selection.x1 = selection.x1 + (love.mouse.getX() - lastX)
	-- 	selection.x2 = selection.x2 + (love.mouse.getX() - lastX)
	-- 	selection.y1 = selection.y1 + (love.mouse.getY() - lastY)
	-- 	selection.y2 = selection.y2 + (love.mouse.getY() - lastY)
	-- end

	-- if isDraggingObject then
	-- 	local gate = getGateByID(draggedObjectID)
	-- 	local peripheral = getPeripheralByID(draggedObjectID)
	-- 	if gate then
	-- 		gate.pos.x = love.mouse.getX() - GATEgetWidth()/2
	-- 		gate.pos.y = love.mouse.getY() - gate:getHeight()/2
	-- 	elseif peripheral then
	-- 		peripheral.pos.x = love.mouse.getX() - PERIPHERALgetWidth()/2
	-- 		peripheral.pos.y = love.mouse.getY() - peripheral:getHeight()/2
	-- 	end
	-- end
end

function love.mousereleased(x, y, button)
	x, y = camera:getScreenPos(x, y)
	if button == 1 and not dontSelect then
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
		-- check if dragged object is below or above any near bobject | TODO
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
    elseif love.keyboard.isDown("lctrl") then
    else
		camera:zoom(dy)
	end
end

function love.keypressed(key, scancode, isrepeat)
	if keyPressed(key, 'escape') then inMenu = not inMenu end

	if keyPressed(key, 'f11') then
		fullscreen = not fullscreen
		love.window.setFullscreen(fullscreen, "exclusive")
	end

	if keyPressed(key, 's', 'ctrl', not inMenu) then saveBoard() end
	if keyPressed(key, 'l', 'ctrl', not inMenu) then loadBoard() end
	if keyPressed(key, 'r', 'ctrl', not inMenu) then resetBoard() end
	if keyPressed(key, 'd', 'ctrl', not inMenu) then addDefaults() end

	if keyPressed(key, 'p', 'ctrl', not inMenu) then showPlotter = not showPlotter end
	if keyPressed(key, 'g', 'ctrl', not inMenu) then graphicSettings.betterGraphics = not graphicSettings.betterGraphics end

	if keyPressed(key, 'c', 'ctrl', not inMenu) then -- HERE update to save groups too
		love.system.setClipboardText(json.encode({ gates=gates:all(), peripherals=peripherals:all(), connections=connections:all() }))
		showMessage("Board Data copied to Clipboard!")
	end
	if keyPressed(key, 'v', 'ctrl', not inMenu) then
		local text = love.system.getClipboardText()
		if text then
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
		end
	end

	if keyPressed(key, 'q', 'ctrl', not inMenu) then love.event.quit() end

	if keyPressed(key, 'f1', nil, not inMenu) then showDebug = not showDebug end
	if keyPressed(key, 'f3', nil, not inMenu) then showTelemetry = not showTelemetry end

	if keyPressed(key, 'h', nil, not inMenu) then showHelp = not showHelp end

	if keyPressed(key, 'g', nil, not inMenu) then
		addGroup()
		selection = {x1=0, y1=0, x2=0, y2=0, ids={}}
	end

	if keyPressed(key, 'delete', nil, not inMenu) then
		if selectedPinID ~= 0 then -- First Pin of new Connection selected
			local pin = getPinByID(selectedPinID)
			if pin then pin.isConnected = false end
			selectedPinID = 0
		else  -- no Pin selected
			local pinID = getPinIDByPos(x, y)
			if pinID then
				removeConnectionWithPinID(pinID)
			else
				local bobID = getBobIDByPos(love.mouse.getX(), love.mouse.getY())
				if bobID then
					removeBobByID(bobID)
				end
			end
		end
	end

	if keyPressed(key, 'delete', 'shift', not inMenu) then
		local groupID = getGroupIDByPos(love.mouse.getX(), love.mouse.getY())
		if groupID then
			removeGroupByID(groupID, love.keyboard.isDown("lalt"))
		end
	end

	if keyPressed(key, any{'1','2','3','4','5','6','7','8','9'}, 'alt', not inMenu) then
		saveBoard()
		currentBoard = tonumber(key)
		loadBoard()
	end

	if keyPressed(key, '1', nil, not inMenu) then addPeripheral(constructINPUT (love.mouse.getX() - PERIPHERALgetWidth()/2, love.mouse.getY() - PERIPHERALgetHeight()/2)) end
	if keyPressed(key, '2', nil, not inMenu) then addPeripheral(constructOUTPUT(love.mouse.getX() - PERIPHERALgetWidth()/2, love.mouse.getY() - PERIPHERALgetHeight()/2)) end
	if keyPressed(key, '3', nil, not inMenu) then addPeripheral(constructCLOCK (love.mouse.getX() - PERIPHERALgetWidth()/2, love.mouse.getY() - PERIPHERALgetHeight()/2)) end
	if keyPressed(key, '4', nil, not inMenu) then addPeripheral(constructBUFFER(love.mouse.getX() - PERIPHERALgetWidth()/2, love.mouse.getY() - PERIPHERALgetHeight()/2)) end
	if keyPressed(key, '5', nil, not inMenu) then addGate(constructAND (love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2)) end
	if keyPressed(key, '6', nil, not inMenu) then addGate(constructOR  (love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2)) end
	if keyPressed(key, '7', nil, not inMenu) then addGate(constructNOT (love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2)) end
	-- if keyPressed(key, '7', nil, not inMenu) then addGate(constructNAND(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2)) end
	-- if keyPressed(key, '8', nil, not inMenu) then addGate(constructNOR (love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2)) end
	-- if keyPressed(key, '9', nil, not inMenu) then addGate(constructXOR (love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2)) end
	-- if keyPressed(key, '0', nil, not inMenu) then addGate(constructXNOR(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2)) end

	if keyPressed(key, '0', nil, not inMenu) then camera:reset() end
	if keyPressed(key, 'space', nil, not inMenu) then camera:center() end

	if keyPressed(key, 'f') then
		love.thread.getChannel("printDebug"):push(true)
	end

	if false then
		if love.keyboard.isDown("lctrl", "rctrl") then
			if key == "s" then     saveBoard()
			elseif key == "l" then loadBoard()
			elseif key == "r" then resetBoard()
			elseif key == "d" then addDefaults()
			elseif key == "p" then showPlotter = not showPlotter
			elseif key == "g" then graphicSettings.betterGraphics = not graphicSettings.betterGraphics
			elseif key == "t" then graphicSettings.gateUseAltBorderColor = not graphicSettings.gateUseAltBorderColor
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
			if key == "d" then showDebug = not showDebug
			elseif key == "t" then showTelemetry = not showTelemetry
			elseif key == "g" then
				addGroup()
				selection = {x1=0, y1=0, x2=0, y2=0, ids={}}
			end
		end
		if key == "delete" then
			if selectedPinID ~= 0 then -- First Pin of new Connection selected
				local pin = getPinByID(selectedPinID)
				if pin then pin.isConnected = false end
				selectedPinID = 0
			else  -- no Pin selected
				local pinID = getPinIDByPos(x, y)
				if pinID then
					removeConnectionWithPinID(pinID)
				else
					-- local groupID = getGroupIDByPos(love.mouse.getX(), love.mouse.getY())
					-- if groupID then
					-- 	removeGroupByID(groupID, love.keyboard.isDown("lshift"))
					-- else
					-- 	if getBobjects():count() > 0 then
					-- 		local bobID = getBobIDByPos(love.mouse.getX(), love.mouse.getY())
					-- 		if bobID then
					-- 			removeBobByID(bobID)
					-- 		end
					-- 	end
					-- end

					local bobID = getBobIDByPos(love.mouse.getX(), love.mouse.getY())
					if bobID then
						removeBobByID(bobID)
					else
						local groupID = getGroupIDByPos(love.mouse.getX(), love.mouse.getY())
						if groupID then
							removeGroupByID(groupID, love.keyboard.isDown("lshift"))
						end
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
				addGate(constructNOT(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2))
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

function any(tbl)
	tbl.mode = 'any'
	return tbl
end

function all(tbl)
	tbl.mode = 'all'
	return tbl
end

function keyPressed(key, keys, mods, others)
	local isPressed = true

	-- keys
	if type(keys) == 'table' then
		if keys.mode == 'any' then
			isPressed = false
			collect(keys):each(function(k)
				if key == k then isPressed = true end
			end)
		elseif keys.mode == 'all' then
			collect(keys):each(function(k)
				if key ~= k then isPressed = false end
			end)
		end
	else
		isPressed = key == keys
	end

	if not isPressed then return false end

	-- mods
	if mods ~= nil then
		if type(mods) == 'table' then
			if collect(mods):contains('shift') then
				isPressed = isPressed and love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift')
			else
				isPressed = isPressed and not love.keyboard.isDown('lshift') and not love.keyboard.isDown('rshift')
			end
			if collect(mods):contains('ctrl') then
				isPressed = isPressed and love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')
			else
				isPressed = isPressed and not love.keyboard.isDown('lshift') and not love.keyboard.isDown('rshift')
			end
			if collect(mods):contains('alt') then
				isPressed = isPressed and love.keyboard.isDown('lalt') or love.keyboard.isDown('ralt')
			else
				isPressed = isPressed and not love.keyboard.isDown('lalt') and not love.keyboard.isDown('ralt')
			end
			if collect(mods):contains('gui') then
				isPressed = isPressed and love.keyboard.isDown('lgui') or love.keyboard.isDown('rgui')
			else
				isPressed = isPressed and not love.keyboard.isDown('lgui') and not love.keyboard.isDown('rgui')
			end
		else
			if mods == 'shift' then
				isPressed = isPressed and love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift')
			else
				isPressed = isPressed and not love.keyboard.isDown('lshift') and not love.keyboard.isDown('rshift')
			end
			if mods == 'ctrl' then
				isPressed = isPressed and love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')
			else
				isPressed = isPressed and not love.keyboard.isDown('lshift') and not love.keyboard.isDown('rshift')
			end
			if mods == 'alt' then
				isPressed = isPressed and love.keyboard.isDown('lalt') or love.keyboard.isDown('ralt')
			else
				isPressed = isPressed and not love.keyboard.isDown('lalt') and not love.keyboard.isDown('ralt')
			end
			if mods == 'gui' then
				isPressed = isPressed and love.keyboard.isDown('lgui') or love.keyboard.isDown('rgui')
			else
				isPressed = isPressed and not love.keyboard.isDown('lgui') and not love.keyboard.isDown('rgui')
			end
		end
	end

	-- others like inMenu etc.
	if others ~= nil then
		if type(others) == 'table' then			
			collect(others):each(function(o)
				if not o then isPressed = false end
			end)
		end
		if type(others) == 'boolean' then
			isPressed = isPressed and others
		end
		print("[WARNING] keyPressed: unusable type of 'others':", others, type(others))
	end

	return isPressed
end

function showMessage(msg)
	timeOutMessage = msg
	timeOutTimer = 2000
end


function addGate(gate)
	gates:append(gate)
	love.thread.getChannel("addGate"):push(json.encode(gate))
end
function addPeripheral(peripheral)
	peripherals:append(peripheral)
	love.thread.getChannel("addPeripheral"):push(json.encode(peripheral))
end
function addConnection(con)
	connections:append(con)
	love.thread.getChannel("addConnection"):push(json.encode(con))
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
	love.thread.getChannel("reset"):push(true)
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

function loadBoard()
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
				addConnection(connection)
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

function saveBoard()
	local success, message = love.filesystem.write(
		string.format("board%d.json", currentBoard),
		json.encode({
			gates=gates:all(),
			peripherals=peripherals:all(),
			connections=connections:all(),
			groups=groups:all()
		})
	)
	if success then showMessage(string.format("Board %d Saved!", currentBoard))
	else showMessage(string.format("Board could not be Saved...")) end
end

function addGroup()
	local group = { x1 = 10000, y1 = 10000, x2 = 0, y2 = 0, ids = {}}
	local hasBobjects = false
	local padding = 20

	for bob in myBobjects() do
		if collect(selection.ids):contains(bob.id)
		and groups:every(function(key,group) return not collect(group.ids):contains(bob.id) end) then
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

function checkIfInputpinHasConnection(pin)
	for con in myConnections() do
		if con.inputpin.id == pin.id then
			return true
		end
	end
	return false
end

function removeConnectionWithPinID(id)
	for con, index in myConnections() do
		if con.inputpin.id == id or con.outputpin.id == id then
			con.inputpin.isConnected = false
			con.outputpin.isConnected = false

			local inputpinGate = getGateByID(con.inputpin.parentID)
			local inputpinPer = getPeripheralByID(con.inputpin.parentID)
			local outputpinGate = getGateByID(con.outputpin.parentID)
			local outputpinPer = getPeripheralByID(con.outputpin.parentID)

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

			connections:forget(index)
			connections = connections:resort()
			updateThread()
		end
	end
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
			updateThread()
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
			updateThread()
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


function getBobjects()
	return gates:merge(peripherals:all())
end

function myConnections()
	local index = 0
	return function()
		index = index + 1
		local con = connections:get(index)
		if con ~= nil and con.inputpin ~= nil and con.outputpin ~= nil then
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
