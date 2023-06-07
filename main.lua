-- ==============================================================[ IMPORTS ]===================================================================--
print('\nVersion: 1.7.1')
print('Starting...')
local log = require 'lib.log'
require 'fancyerror'

log.info('Loading libraries...')
require 'lib.noahsutils'
local lume = require 'lib.lume'
local messages = require 'lib.messages'
local classes = require 'classes'
local json = require 'lib.json'
local Camera = require 'lib.camera'
log.info('Done.')

log.info('Loading Font...')
local font = love.graphics.newFont('fonts/main.ttf', 20)
local bigfont = love.graphics.newFont('fonts/main.ttf', 80)
local hugefont = love.graphics.newFont('fonts/main.ttf', 120)
font:setFilter('nearest', 'nearest', 8)
love.graphics.setFont(font)
log.info('Done.')

-- =============================================================[ VARIABLES ]==================================================================--

log.info('Initializing variables...')
local lastX, lastY = 0, 0

-- worker
local gates = {}
local peripherals = {}
local connections = {}
local groups = {}

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

local plotterID = 0
local plotterData = {}

-- main?
local currentBoard = 1

-- main
local menus = {
	about = 0,
	settings = 1,
	title = 2,
	list = 3,
	board = 4
}
local currentMenu = menus.title
local menuX, menuTargetX, menuIsSliding = 0, 0, false
local telemetryInterval, telemetryIntervalLast = 500, love.timer.getTime()
local telemetry, telemetryShow = {}, {}
local maxFPSRecorded = 60

local computeThread
local computeThreadUPS, computeThreadMaxUPS = 0, 10000

local style

local settings = {
	showGrid = true,
	useSmoothCubic = true,
	showPinIDs = false,
	showPinStates = false,
	showGateIDs = false,
	showPlotter = false,
	showHelp = false,
	showDebug = false,
	showTelemetry = false,
	fullscreen = false
	-- showFPS = false
	-- VSync = false
}

local camera

local menuTransform, boardTransform


log.info('Done.')

-- ===========================================================[ MAIN FUNCTIONS ]===============================================================--


-- #################################################################
-- #                           LOVE LOAD                           #
-- #################################################################
function love.load()
	log.info('Loading main Program...')
	love.graphics.setBackgroundColor(0.11, 0.11, 0.11)
	messages.x = 10
	messages.y = 40

    -- computeThread = love.thread.newThread("computeThread.lua")
	-- computeThread:start(computeThreadMaxUPS)

	menuTransform = love.math.newTransform(0,0,0,1)
    boardTransform = love.math.newTransform(0,0,0,1)

	camera = Camera.newSmoothWithTransform(boardTransform, 40, 0.5, 5)
	
	-- loadBoard()
	addDefaults()
	
	-- local done = love.thread.getChannel("setup"):supply(true)
	log.info('Done.')
end

-- #################################################################
-- #                           LOVE UPDATE                         #
-- #################################################################
function love.update(dt)
	-- slide animation for menus
	currentMenu = lume.clamp(currentMenu, 0, 4)
	menuTargetX = love.graphics.getWidth() * currentMenu
	if menuX ~= menuTargetX then
		menuX = lume.lerp(menuX, menuTargetX, 10*dt)
	end
	menuTransform:setTransformation(-menuX, 0)
	
	-- MENUS
	if currentMenu == menus.title then
		
	elseif currentMenu == menus.board then
		camera:update(dt, settings.useSmoothCubic)
		mx, my = camera:getScreenPos(love.mouse.getPosition())
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
	elseif currentMenu == menus.list then
		-- do list stuff
	elseif currentMenu == menus.settings then
		-- do settings stuff
	elseif currentMenu == menus.about then
		-- do about stuff
	end

	-- OTHERS

	if love.timer.getFPS() > maxFPSRecorded then
		maxFPSRecorded = love.timer.getFPS()
	end
	telemetry.dt = dt
	
	computeThreadUPS = love.thread.getChannel("ups"):pop() or computeThreadUPS
	messages.update(dt)
end

-- #################################################################
-- #                           LOVE DRAW                           #
-- #################################################################
function love.draw()
	-- draw menus
	-- love.graphics.setColor(1, 1, 1)
	-- love.graphics.rectangle('line', 1500, 400, love.graphics.getWidth(), love.graphics.getHeight())
	-- love.graphics.push()
	-- love.graphics.translate(1500, 400)
	-- love.graphics.scale(0.3)

	love.graphics.push('transform')
	love.graphics.applyTransform(menuTransform)
	-- ############################## ABOUT ##############################
	if shouldShowMenu(menus.about) then
		love.graphics.print("About", bigfont, 10, 10)
	end
	love.graphics.translate(love.graphics.getWidth(), 0)
	-- ############################## SETTINGS ##############################
	if shouldShowMenu(menus.settings) then
		love.graphics.print("Settings", bigfont, 10, 10)
	end
		love.graphics.translate(love.graphics.getWidth(), 0)	
		-- ############################## TITLE ##############################
		if shouldShowMenu(menus.title) then
		love.graphics.print('L.C.S.', hugefont, 10, 10)
	end
		love.graphics.translate(love.graphics.getWidth(), 0)
		-- ############################## BOARDS LIST ##############################
		if shouldShowMenu(menus.list) then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Menu", bigfont, 10, 10)
		love.graphics.print("Boards:", 20, 150)
		local ystart = 160
		for i=1, 10 do
			if love.mouse.getX() > 20 and love.mouse.getX() < 20 + 100 and love.mouse.getY() > 80 + i*30 + ystart and love.mouse.getY() < 80 + i*30 + 30 + ystart then
				love.graphics.setColor(0.2, 0.4, 1)
				if love.mouse.isDown(1) then
					currentBoard = i
					loadBoard()
					inMenu = false
				end
			else
				love.graphics.setColor(1, 1, 1)
			end
			love.graphics.print("Board "..i, 20, 80 + i*30 + ystart)
		end
	end
		love.graphics.translate(love.graphics.getWidth(), 0)
		-- ############################## BOARD ##############################
		if shouldShowMenu(menus.board) then
		-- camera
		mx, my = camera:getScreenPos(love.mouse.getPosition())
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
			for i,group in ipairs(groups) do
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
			local bobjects = getBobjects()
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
		if settings.showPlotter then
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

		if settings.showHelp then
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

		if settings.showDebug then
			love.graphics.setColor(0.6, 1, 0.6)
			love.graphics.print(string.format("Board Objects: %d\nConnections: %d\n", lume.count(getBobjects()),  lume.count(connections), love.graphics.getWidth()-250, 150))
		
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
		love.graphics.print(("FPS: %s | UPS: %s | %.1f%% Lag | Current Board: %d (Press [H] for Help)"):format(tostring(love.timer.getFPS()), nfc(computeThreadUPS), (100-love.timer.getFPS()/maxFPSRecorded*100), currentBoard), 10, 10)
		if isDraggingGroup or isDraggingObject or isDraggingSelection then
			love.graphics.print(isDraggingSelection and "Dragging Selection" or (isDraggingGroup and "Dragging Group ID: "..tostring(draggedGroupID) or (isDraggingObject and "Dragging Object ID: "..tostring(draggedObjectID) or "")), 10, 70)
		end
			
		messages.draw()
	end
	love.graphics.pop()

	-- love.graphics.pop()

	-- OTHERS
	lastX, lastY = love.mouse.getPosition()
	love.graphics.setColor(1, 1, 1)

	-- love.graphics.print(('Menu: #%d'):format(currentMenu), love.graphics.getWidth()-100, 10)
end

function love.quit()
	-- local id = love.thread.getChannel("kill"):push(true)
	-- repeat until love.thread.getChannel("kill"):hasRead(id)
end

-- ==========================================================[ INPUT FUNCTIONS ]===============================================================--


-- #################################################################
-- #                       LOVE MOUSE PRESSED                      #
-- #################################################################
function love.mousepressed(x, y, button)

	x,y = camera:getScreenPos( x,y )
	--=====================[ LEFT CLICK ]=====================--
	if button == 1 then
		-- log.debug'Left Click'
		dontSelect = false
		for bob in myBobjects() do
			local inpin  = bob:getInputPinAt(x, y)
			local outpin = bob:getOutputPinAt(x, y)

			if selectedPinID == 0 then
				if outpin then
					log.debug'Left Click on Output Pin'
					dontSelect = true
					outpin.isConnected = true
					selectedPinID = outpin.id or selectedPinID
				end
			else
				if inpin then
					log.debug'Left Click on Input Pin'
					dontSelect = true
					if not inpin.isConnected then
						inpin.isConnected = true
						addConnection({ outputpin=getPinByID(selectedPinID), inputpin=inpin })
						selectedPinID = 0
					end
				end
			end
			if bob:isInside(x, y) and not dontSelect then
				if bob.__name == "INPUT" then
					bob:flip()
				elseif bob.__name == "OUTPUT" then
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
		for i,group in ipairs(groups) do
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

-- #################################################################
-- #                       LOVE MOUSE RELEASED                     #
-- #################################################################
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

-- #################################################################
-- #                        LOVE MOUSE MOVED                       #
-- #################################################################
function love.mousemoved(x, y, dx, dy)
	x, y = camera:getScreenPos(x, y)
	sdx, sdy = camera:applyScale(dx, dy)
	
	if isDraggingGroup then
		local group = groups[draggedGroupID]
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

-- #################################################################
-- #                        LOVE WHEEL MOVED                       #
-- #################################################################
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

-- #################################################################
-- #                        LOVE KEY PRESSED                       #
-- #################################################################
function love.keypressed(key, scancode, isrepeat)
	-- ANY MENU
	if keyPressed(key, 'escape') then
		if currentMenu>menus.title then currentMenu=currentMenu-1
		elseif currentMenu<menus.title then currentMenu=currentMenu+1
		end
	end

	if key == 'left' and love.keyboard.isDown('lctrl') then
		currentMenu=currentMenu-1
	end
	if key == 'right' and love.keyboard.isDown('lctrl') then 
		currentMenu=currentMenu+1
	end
	
	if keyPressed(key, 'f11') then
		settings.fullscreen = not settings.fullscreen
		love.window.setFullscreen(settings.fullscreen, "exclusive")
		messages.add("Toggled Fullscreen to: ", settings.fullscreen)
	end

	-- BOARD MENU
	if keyPressed(key, 'f1', currentMenu==menus.board) then settings.showHelp = not settings.showHelp end
	if keyPressed(key, 'f2', currentMenu==menus.board) then settings.showDebug = not settings.showDebug end
	if keyPressed(key, 'f3', currentMenu==menus.board) then settings.showFPS = not settings.showFPS end
	if keyPressed(key, 'f4', currentMenu==menus.board) then settings.showGrid = not settings.showGrid end

	if keyPressed(key, 'i', currentMenu==menus.board) then settings.useSmoothCubic = not settings.useSmoothCubic; messages.add('Use Smooth Cubic: '..tostring(settings.useSmoothCubic)) end

	if keyPressed(key, 's', 'ctrl', currentMenu==menus.board) then saveBoard() end
	if keyPressed(key, 'l', 'ctrl', currentMenu==menus.board) then loadBoard() end
	if keyPressed(key, 'r', 'ctrl', currentMenu==menus.board) then resetBoard() end
	if keyPressed(key, 'd', 'ctrl', currentMenu==menus.board) then addDefaults() end

	if keyPressed(key, 'p', 'ctrl', currentMenu==menus.board) then settings.showPlotter = not settings.showPlotter end
	if keyPressed(key, 'g', 'ctrl', currentMenu==menus.board) then graphicSettings.betterGraphics = not graphicSettings.betterGraphics; messages.add('Use Better Graphics: '..tostring(settings.useSmoothCubic)) end

	if keyPressed(key, 'c', 'ctrl', currentMenu==menus.board) then -- HERE update to save groups too
		love.system.setClipboardText(json.encode({ gates=gates, peripherals=peripherals, connections=connections }))
		messages.add("Board Data copied to Clipboard!")
	end
	if keyPressed(key, 'v', 'ctrl', currentMenu==menus.board) then
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
						lume.push(connections, connection)
					end
					messages.add("Board Data loaded from Clipboard!")
				end
			end
		end
	end

	if keyPressed(key, 'q', 'ctrl', currentMenu==menus.board) then love.event.quit() end

	if keyPressed(key, 'g', nil, currentMenu==menus.board) then
		addGroup()
		selection = {x1=0, y1=0, x2=0, y2=0, ids={}}
		messages.add("Group created!")
	end

	if keyPressed(key, 'delete', nil, currentMenu==menus.board) then
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

	if keyPressed(key, 'delete', 'shift', currentMenu==menus.board) then
		local groupID = getGroupIDByPos(love.mouse.getX(), love.mouse.getY())
		if groupID then
			removeGroupByID(groupID, love.keyboard.isDown("lalt"))
		end
	end

	if keyPressed(key, any{'1','2','3','4','5','6','7','8','9'}, 'alt', currentMenu==menus.board) then
		saveBoard()
		currentBoard = tonumber(key)
		loadBoard()
	end

	if keyPressed(key, '1', nil, currentMenu==menus.board) then addPeripheral(classes.INPUT (love.mouse.getX() - classes.PERIPHERAL:getWidth()/2, love.mouse.getY() - classes.PERIPHERAL:getHeight()/2)) end
	if keyPressed(key, '2', nil, currentMenu==menus.board) then addPeripheral(classes.OUTPUT(love.mouse.getX() - classes.PERIPHERAL:getWidth()/2, love.mouse.getY() - classes.PERIPHERAL:getHeight()/2)) end
	if keyPressed(key, '3', nil, currentMenu==menus.board) then addPeripheral(classes.CLOCK (love.mouse.getX() - classes.PERIPHERAL:getWidth()/2, love.mouse.getY() - classes.PERIPHERAL:getHeight()/2)) end
	if keyPressed(key, '4', nil, currentMenu==menus.board) then addPeripheral(classes.BUFFER(love.mouse.getX() - classes.PERIPHERAL:getWidth()/2, love.mouse.getY() - classes.PERIPHERAL:getHeight()/2)) end
	if keyPressed(key, '5', nil, currentMenu==menus.board) then addGate(classes.AND (love.mouse.getX() - classes.GATE:getWidth()/2, love.mouse.getY() - classes.GATE:getHeight(2)/2)) end
	if keyPressed(key, '6', nil, currentMenu==menus.board) then addGate(classes.OR  (love.mouse.getX() - classes.GATE:getWidth()/2, love.mouse.getY() - classes.GATE:getHeight(2)/2)) end
	if keyPressed(key, '7', nil, currentMenu==menus.board) then addGate(classes.NOT (love.mouse.getX() - classes.GATE:getWidth()/2, love.mouse.getY() - classes.GATE:getHeight(1)/2)) end


	-- if keyPressed(key, '7', nil, currentMenu==menus.board) then addGate(constructNAND(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2)) end
	-- if keyPressed(key, '8', nil, currentMenu==menus.board) then addGate(constructNOR (love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2)) end
	-- if keyPressed(key, '9', nil, currentMenu==menus.board) then addGate(constructXOR (love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2)) end
	-- if keyPressed(key, '0', nil, currentMenu==menus.board) then addGate(constructXNOR(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2)) end

	if keyPressed(key, '0', nil, currentMenu==menus.board) then camera:reset() end
	if keyPressed(key, 'space', nil, currentMenu==menus.board) then camera:center() end

	-- if keyPressed(key, 'f') then
	-- 	love.thread.getChannel("printDebug"):push(true)
	-- end
end


--==============================================[ CUSTOM FUNCTIONS ]==============================================--

function shouldShowMenu(menu)
	return menu==currentMenu or menu==currentMenu-1 or menu==currentMenu+1
end

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
			-- collect(keys):each(function(k)
			-- 	if key == k then isPressed = true end
			-- end)
			for i, k in ipairs(keys) do
				if key == k then isPressed = true end
			end
		elseif keys.mode == 'all' then
			-- collect(keys):each(function(k)
			-- 	if key ~= k then isPressed = false end
			-- end)
			for i, k in ipairs(keys) do
				if key ~= k then isPressed = false end
			end
		end
	else
		isPressed = key == keys
	end

	if not isPressed then return false end

	-- mods
	if mods ~= nil then
		if type(mods) == 'table' then
			-- if collect(mods):contains('shift') then
			-- 	isPressed = isPressed and love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift')
			-- else
			-- 	isPressed = isPressed and not love.keyboard.isDown('lshift') and not love.keyboard.isDown('rshift')
			-- end
			-- if collect(mods):contains('ctrl') then
			-- 	isPressed = isPressed and love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl')
			-- else
			-- 	isPressed = isPressed and not love.keyboard.isDown('lshift') and not love.keyboard.isDown('rshift')
			-- end
			-- if collect(mods):contains('alt') then
			-- 	isPressed = isPressed and love.keyboard.isDown('lalt') or love.keyboard.isDown('ralt')
			-- else
			-- 	isPressed = isPressed and not love.keyboard.isDown('lalt') and not love.keyboard.isDown('ralt')
			-- end
			-- if collect(mods):contains('gui') then
			-- 	isPressed = isPressed and love.keyboard.isDown('lgui') or love.keyboard.isDown('rgui')
			-- else
			-- 	isPressed = isPressed and not love.keyboard.isDown('lgui') and not love.keyboard.isDown('rgui')
			-- end
			
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
			-- collect(others):each(function(o)
			-- 	if not o then isPressed = false end
			-- end)
			for i, o in ipairs(others) do
				if not o then isPressed = false end
			end
		end
		if type(others) == 'boolean' then
			isPressed = isPressed and others
		end
		print("[WARNING] keyPressed: unusable type of 'others':", others, type(others))
	end

	return isPressed
end

function addGate(gate)
	log.debug('Added Gate with ID: '..gate.id)
	lume.push(gates, gate)
	-- love.thread.getChannel("addGate"):push(json.encode(gate))
end
function addPeripheral(peripheral)
	log.debug('Added Peripheral with ID: '..peripheral.id)
	lume.push(peripherals, peripheral)
	-- love.thread.getChannel("addPeripheral"):push(json.encode(peripheral))
end
function addConnection(con)
	log.debug('Added Connection, Outputpin ID:'..con.outputPin.id..' and Inputpin ID:'..con.inputPin.id)
	lume.push(connections, con)
	-- love.thread.getChannel("addConnection"):push(json.encode(con))
end


function resetBoard()
	connections = {}
	gates = {}
	peripherals = {}
	groups = {}	
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
	-- love.thread.getChannel("reset"):push(true)
	messages.add("Board Reset...")
end

function addDefaults()
	addGate(classes.AND(200, 100))
	addGate(classes.OR(400, 100))
	addGate(classes.NOT(600, 100, 1))
	addPeripheral(classes.BUFFER(200, 300))
	addPeripheral(classes.INPUT(200, 500))
	addPeripheral(classes.CLOCK(400, 500))
	addPeripheral(classes.OUTPUT(600, 500))
	messages.add("Default Board Loaded!")
end

function loadBoard()
	resetBoard()
	contents = love.filesystem.read(string.format("board%d.json", currentBoard))
	if contents then
		local data = json.decode(contents)
		if data.gates then
			for i, gatedata in ipairs(data.gates) do
				addGate(classes.loadGATE(gatedata))			
		end end
		if data.peripherals then
			for i, peripheraldata in ipairs(data.peripherals) do
				addPeripheral(classes.loadPERIPHERAL(peripheraldata))
		end end
		if data.connections then
			for i, connection in ipairs(data.connections) do
				addConnection(connection)
		end end
		if data.groups then
			for i, group in ipairs(data.groups) do
				lume.push(groups, group)
		end end
	else
		print('file not found')
	end
	messages.add(string.format("Board %d Loaded!", currentBoard))
end

function saveBoard()
	local success, message = love.filesystem.write(
		string.format("board%d.json", currentBoard),
		json.encode({
			gates = gates,
			peripherals = peripherals,
			connections = connections,
			groups = groups
		})
	)
	love.filesystem.write(
		string.format("board%d.lua", currentBoard), 
		lume.serialize({	
			gates = gates,
			peripherals = peripherals,
			connections = connections,
			groups = groups
		}
	)
	if success then messages.add(string.format("Board %d Saved!", currentBoard))
	else messages.add(string.format("Board could not be Saved...")) end
end

function addGroup()
	local group = { x1 = 10000, y1 = 10000, x2 = 0, y2 = 0, ids = {}}
	local hasBobjects = false
	local padding = 20

	for bob in myBobjects() do
		-- if collect(selection.ids):contains(bob.id)
		-- and groups:every(function(key,group) return not collect(group.ids):contains(bob.id) end) then
		-- end
		log.debug(bob.id)
		if lume.find(selection.ids, bob.id) and
		not lume.any(groups, function(x) return lume.find(x, bob,id) end) then
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

		lume.push(groups, group)
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
	for i,group in ipairs(groups) do
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

			table.remove(connections, index)
			-- updateThread()
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
			table.remove(gates, index)
			-- updateThread()
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
			table.remove(peripherals, index)
			-- updateThread()
		end
	end
end
function removeGroupByID(id, deleteBobs)
	for i,group in ipairs(groups) do
		if i == id then
			if deleteBobs then
				for _,bobID in ipairs(group.ids) do
					removeBobByID(bobID)
				end
			end
			table.remove(groups, i)
		end
	end
end


function getBobjects()
	return lume.concat(gates, peripherals)
end

function myConnections()
	local index = 0
	return function()
		index = index + 1
		local con = connections[index]
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
		if bobjects[index] ~= nil then
			return bobjects[index], index
		end
	end
end
function myGates()
	local index = 0
	return function()
		index = index + 1
		local gate = gates[index]
		if gate ~= nil then
			return gate, index
		end
	end
end
function myPeripherals()
	local index = 0
	return function()
		index = index + 1
		local per = peripherals[index]
		if per ~= nil then
			return per, index
		end
	end
end
