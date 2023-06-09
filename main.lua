-- ==============================================================[ IMPORTS ]===================================================================--
print'\nVersion: 1.8.2'
print'Starting...'
local startTime = love.timer.getTime()
local log = require 'lib.log'
log.level = 'info'
require 'fancyerror'

log.info'Loading libraries...'
require 'lib.noahsutils'
local lume = require 'lib.lume'
local messages = require 'lib.messages'
local classes = require 'classes'
local json = require 'lib.json'
local Camera = require 'lib.camera'
log.info'Done.'

log.info'Loading Font...'
local font = love.graphics.newFont('fonts/main.ttf', 20)
local namefont = love.graphics.newFont('fonts/main.ttf', 35)
local bigfont = love.graphics.newFont('fonts/main.ttf', 80)
local hugefont = love.graphics.newFont('fonts/main.ttf', 120)
font:setFilter('nearest', 'nearest', 8)
love.graphics.setFont(font)
log.info('Done. Took ' .. formatTime(love.timer.getTime() - startTime))

-- =============================================================[ VARIABLES ]==================================================================--

log.info'Initializing variables...'
local SAVECATCHMODE = false
if SAVECATCHMODE then log.info'SAVE CATCH MODE ENABLED' end

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
local currentMenu = menus.list
local menuX, menuTargetX, menuIsSliding = 0, 0, false

local boardslistui = {
	startx = 20,
	starty = 150,
	padding = 10,
	spacing = 10,
	rounding = 5,
	colors = {
		background = { 0.15, 0.15, 0.15 },
		border = { 0.25, 0.25, 0.25 },
		hover = { 0.3, 0.3, 0.3 },
		text = { 1, 1, 1 },
	}
}

boardslistui.createbutton = { w=font:getWidth('+ Create') + boardslistui.padding*2, h=font:getHeight() + boardslistui.padding*2, text='+ Create' }
boardslistui.renamebutton = { w=font:getWidth('Rename')   + boardslistui.padding*2, h=font:getHeight() + boardslistui.padding*2, text='Rename'   }
boardslistui.deletebutton = { w=font:getWidth('Delete')   + boardslistui.padding*2, h=font:getHeight() + boardslistui.padding*2, text='Delete'   }
-- boardslistui.boarditempreset = { x=100, y=0, padw=0, padh=0, name='NAME', id=0, filesize=0, lastmodified=0, created=0 }
boardslistui.boarditemheight = namefont:getHeight() + boardslistui.padding*2

boardslist = {}

local telemetryInterval, telemetryIntervalLast = 500, love.timer.getTime()
local telemetry, telemetryShow = {}, {}
local maxFPSRecorded = 60

local computeThread
local computeThreadUPS, computeThreadMaxUPS = 0, 10000

local style

local settings = {
	showGrid = true,
	useSmoothCubic = false,
	showPinIDs = false,
	showPinStates = false,
	showGateIDs = false,
	showPlotter = false,
	showHelp = false,
	showDebug = false,
	showTelemetry = false,
	showFPS = true,
	fullscreen = false,

	deleteWithX = false,
	-- showFPS = false
	-- VSync = false
}

local camera

local menuTransform, boardTransform

log.info'Done.'

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

	lume.push(boardslist, { name='Davids Baord fsr', id=1, size=45000, lastmodified='07.06.23', created='05.06.23' })
	lume.push(boardslist, { name='Just a Test you see', id=2, size=0, lastmodified='07.06.23', created='07.06.23' })
	lume.push(boardslist, { name='HS3JN9-NY83OS-H9S2-HSK83GHS937', id=3, size='10', lastmodified='07.06.23', created='07.06.23' })

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
	love.graphics.push('transform')
	love.graphics.applyTransform(menuTransform)
	-- ##############################[  ABOUT  ]##############################
	if shouldShowMenu(menus.about) then
		love.graphics.print("About", bigfont, 10, 10)
	end

	love.graphics.translate(love.graphics.getWidth(), 0)
	-- ##############################[  SETTINGS  ]##############################
	if shouldShowMenu(menus.settings) then
		love.graphics.print("Settings", bigfont, 10, 10)
	end

	love.graphics.translate(love.graphics.getWidth(), 0)	
	-- ##############################[  TITLE  ]##############################
		if shouldShowMenu(menus.title) then
		love.graphics.print('L.C.S.', hugefont, 10, 10)
	end

	love.graphics.translate(love.graphics.getWidth(), 0)
	-- ##############################[  BOARDS LIST  ]##############################
	if shouldShowMenu(menus.list) then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Boards:", bigfont, 10, 10)
		
		local create = boardslistui.createbutton
		love.graphics.setColor(boardslistui.colors.background)
		love.graphics.rectangle("fill", boardslistui.startx, boardslistui.starty, create.w, create.h, boardslistui.rounding)
		love.graphics.setColor(boardslistui.colors.border)
		love.graphics.rectangle("line", boardslistui.startx, boardslistui.starty, create.w, create.h, boardslistui.rounding)
		love.graphics.setColor(boardslistui.colors.text)
		love.graphics.print(create.text, boardslistui.startx + boardslistui.padding, boardslistui.starty + boardslistui.padding)
		
		local w = love.graphics.getWidth() - boardslistui.startx - boardslistui.padding
		local h = namefont:getHeight() + font:getHeight() + boardslistui.padding*3
		for i,board in ipairs(boardslist) do
			local x = boardslistui.startx
			local y = boardslistui.starty + boardslistui.createbutton.h + boardslistui.spacing + ((i-1) * (h + boardslistui.spacing))
			local rounding = boardslistui.rounding
			local padding = boardslistui.padding
			local text = board.name
			local selected = board.selected

			love.graphics.setColor(boardslistui.colors.background)
			love.graphics.rectangle("fill", x, y, w, h, rounding)
			love.graphics.setColor(boardslistui.colors.border)
			love.graphics.rectangle("line", x, y, w, h, rounding)
			love.graphics.setColor(boardslistui.colors.text)
			love.graphics.print(text, namefont, x + padding, y + padding)
			local idlength = font:getWidth('ID: #00') + padding*4
			local sizelength = font:getWidth('Size: 00000KB') + padding*4
			local modlength = font:getWidth('Last Modified: 00.00.00') + padding*4
			love.graphics.print(lume.format('ID: #{id}', board),                     x + padding, y+padding + namefont:getHeight()+padding)
			love.graphics.print(lume.format('Size: {size}KB', board),                x + padding + idlength, y+padding + namefont:getHeight()+padding)
			love.graphics.print(lume.format('Last Modified: {lastmodified}', board), x + padding + idlength + sizelength, y+padding + namefont:getHeight()+padding)
			love.graphics.print(lume.format('Created: {created}', board),            x + padding + idlength + sizelength + modlength, y+padding + namefont:getHeight()+padding)
		end
	end

	love.graphics.translate(love.graphics.getWidth(), 0)
	-- ##############################[  BOARD  ]##############################
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
						mx - offset, my,
						mx, my
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
		love.graphics.print(("FPS: %s | UPS: %s | %.1f%% Lag | Current Board: %d (Press [F1] for Help)"):format(tostring(love.timer.getFPS()), nfc(computeThreadUPS), (100-love.timer.getFPS()/maxFPSRecorded*100), currentBoard), 10, 10)
		if isDraggingGroup or isDraggingObject or isDraggingSelection then
			love.graphics.print(isDraggingSelection and "Dragging Selection" or (isDraggingGroup and "Dragging Group ID: "..tostring(draggedGroupID) or (isDraggingObject and "Dragging Object ID: "..tostring(draggedObjectID) or "")), 10, 70)
		end
			
		messages.draw()
	end
	love.graphics.pop()

	-- love.graphics.pop()

	-- OTHERS
	if SAVECATCHMODE then
		love.graphics.print({{0.6, 0.89, 0.63}, 'SAVE CATCH MODE ENABLED'}, love.graphics.getWidth()-(font:getWidth('SAVE CATCH MODE ENABLED'))-10, 10)
	end
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
	-- ************************************[ BOARD ]************************************ --
	if currentMenu == menus.board then
		x,y = camera:getScreenPos( x,y )
		--=====================[ LEFT CLICK ]=====================--
		if button == 1 then
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
					if bob.__class.__name == "INPUT" then
						bob:flip()
					elseif bob.__class.__name == "OUTPUT" then
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
	if key == 'insert' then
		SAVECATCHMODE = not SAVECATCHMODE
		log.warn('SAVECATCHMODE: '..tostring(SAVECATCHMODE))
	end

	if SAVECATCHMODE then
		saveKeyPressed(key, scancode, isrepeat)
	else
		devKeyPressed(key, scancode, isrepeat)
	end
end

function saveKeyPressed(key, scancode, isrepeat)
	-- ANY MENU
	whenKeyPressed(key, 'escape', nil, nil, function()
		if currentMenu>menus.title then currentMenu=currentMenu-1
		elseif currentMenu<menus.title then currentMenu=currentMenu+1
		end
	end)

	if key == 'left' and love.keyboard.isDown('lctrl') then
		currentMenu=currentMenu-1
	end
	if key == 'right' and love.keyboard.isDown('lctrl') then 
		currentMenu=currentMenu+1
	end

	whenKeyPressed(key, 'f11', nil, nil, function()
		settings.fullscreen = not settings.fullscreen
		love.window.setFullscreen(settings.fullscreen, "exclusive")
	end)

	whenKeyPressed(key, 'f9', nil, nil, function()
		for i=1,10 do 
			love.filesystem.write(
				string.format("board%d.json", i),
				json.encode({
					gates = {},
					peripherals = {},
					connections = {},
					groups = {}
				}))
		end
		messages.add({{0.9, 0.55, 0.66}, "Wiped Board Save Files"})
	end)

	-- BOARD MENU
	local mx,my = camera:getScreenPos(love.mouse.getPosition())

	whenKeyPressed(key, 'f1', nil, currentMenu==menus.board, function() settings.showHelp = not settings.showHelp end)
	whenKeyPressed(key, 'f2', nil, currentMenu==menus.board, function() settings.showDebug = not settings.showDebug end)
	whenKeyPressed(key, 'f3', nil, currentMenu==menus.board, function() settings.showFPS = not settings.showFPS end)
	whenKeyPressed(key, 'f4', nil, currentMenu==menus.board, function() settings.showGrid = not settings.showGrid end)

	whenKeyPressed(key, 'i', nil, currentMenu==menus.board, function()
		settings.useSmoothCubic = not settings.useSmoothCubic
		messages.add('Use Smooth Cubic: '..tostring(settings.useSmoothCubic))
	end)

	whenKeyPressed(key, 's', 'ctrl', currentMenu==menus.board, function() saveBoard() end)
	whenKeyPressed(key, 'l', 'ctrl', currentMenu==menus.board, function() loadBoard() end)
	whenKeyPressed(key, 'r', 'ctrl', currentMenu==menus.board, function() resetBoard() end)
	whenKeyPressed(key, 'd', 'ctrl', currentMenu==menus.board, function() addDefaults() end)
	whenKeyPressed(key, 'p', 'ctrl', currentMenu==menus.board, function() settings.showPlotter = not settings.showPlotter end)

	whenKeyPressed(key, 'c', 'ctrl', currentMenu==menus.board, function()
		love.system.setClipboardText(
			json.encode({
				gates = prepForSave(gates),
				peripherals = prepForSave(peripherals),
				connections = prepForSave(connections),
				groups = prepForSave(groups)
			}))
		messages.add({{0.6, 0.89, 0.63},"Board Data copied to Clipboard!"})
	end)
	whenKeyPressed(key, 'v', 'ctrl', currentMenu==menus.board, function()
		local text = love.system.getClipboardText()
		if text then
			if text:match("gates") and text:match("peripherals") and text:match("connections") then
				local data = json.decode(text)
				if data then
					resetBoard()
					if data.gates then
						for i, gatedata in ipairs(data.gates) do
							addGate(classes.loadGATE(gatedata))
						end
					end
					if data.peripherals then
						for i, peripheraldata in ipairs(data.peripherals) do
							addPeripheral(classes.loadPERIPHERAL(peripheraldata))
						end
					end
					if data.connections then
						for i, connection in ipairs(data.connections) do
							addConnection(connection)
						end
					end
					if data.groups then
						for i, group in ipairs(data.groups) do
							lume.push(groups, group)
						end
					end
					messages.add({{0.6, 0.89, 0.63},"Board Data loaded from Clipboard!"})
				end
			end
		end
	end)

	whenKeyPressed(key, 'q', 'ctrl', currentMenu==menus.board, function()
		love.event.quit()
	end)

	whenKeyPressed(key, 'g', nil, currentMenu==menus.board, function()
		addGroup()
		selection = {x1=0, y1=0, x2=0, y2=0, ids={}}
		messages.add({{0.71, 0.75, 0.86},"Group created!"})
	end)

	whenKeyPressed(key, 'delete', nil, currentMenu==menus.board, function()
		if selectedPinID ~= 0 then --------------------- First Pin of new Connection selected
			local pin = getPinByID(selectedPinID)
			if pin then pin.isConnected = false end
			selectedPinID = 0
		else ------------------------------------------- no Pin selected
			local pinID = getPinIDByPos(mx, my)
			if pinID then
				removeConnectionWithPinID(pinID)
			else
				local bobID = getBobIDByPos(mx, my)
				if bobID then
					removeBobByID(bobID)
				end
			end
		end
	end)

	whenKeyPressed(key, 'delete', 'shift', currentMenu==menus.board, function()
		local groupID = getGroupIDByPos(mx, my)
		if groupID then
			removeGroupByID(groupID, love.keyboard.isDown("lalt"))
		end
	end)	

	whenKeyPressed(key, any{'1','2','3','4','5','6','7','8','9'}, 'alt', currentMenu==menus.board, function()
		saveBoard()
		currentBoard = tonumber(key)
		loadBoard()
	end)

	whenKeyPressed(key, '1', nil, currentMenu==menus.board, function() addPeripheral(classes.INPUT (mx - classes.PERIPHERAL:getWidth()/2, my - classes.PERIPHERAL:getHeight()/2)) end)
	whenKeyPressed(key, '2', nil, currentMenu==menus.board, function() addPeripheral(classes.OUTPUT(mx - classes.PERIPHERAL:getWidth()/2, my - classes.PERIPHERAL:getHeight()/2)) end)
	whenKeyPressed(key, '3', nil, currentMenu==menus.board, function() addPeripheral(classes.CLOCK (mx - classes.PERIPHERAL:getWidth()/2, my - classes.PERIPHERAL:getHeight()/2)) end)
	whenKeyPressed(key, '4', nil, currentMenu==menus.board, function() addPeripheral(classes.BUFFER(mx - classes.PERIPHERAL:getWidth()/2, my - classes.PERIPHERAL:getHeight()/2)) end)
	whenKeyPressed(key, '5', nil, currentMenu==menus.board, function() addGate(classes.AND (mx - classes.GATE:getWidth()/2, my - classes.GATE:getHeight(2)/2)) end)
	whenKeyPressed(key, '6', nil, currentMenu==menus.board, function() addGate(classes.OR  (mx - classes.GATE:getWidth()/2, my - classes.GATE:getHeight(2)/2)) end)
	whenKeyPressed(key, '7', nil, currentMenu==menus.board, function() addGate(classes.NOT (mx - classes.GATE:getWidth()/2, my - classes.GATE:getHeight(1)/2)) end)


	whenKeyPressed(key, 'sapce', nil, currentMenu==menus.board, function()
		camera:reset()
		camera:center()
	end)	
end

function devKeyPressed(key, scancode, isrepeat)
	-- ANY MENU
	if checkKeyPressed(key, 'escape') then
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
	
	if checkKeyPressed(key, 'f11') then
		settings.fullscreen = not settings.fullscreen
		love.window.setFullscreen(settings.fullscreen, "exclusive")
	end

	if checkKeyPressed(key, 'f9') then
		for i=1,10 do 
			love.filesystem.write(
				string.format("board%d.json", i),
				json.encode({
					gates = {},
					peripherals = {},
					connections = {},
					groups = {}
				})
			)
		end
		messages.add({{0.9, 0.55, 0.66}, "Wiped Board Save Files"})
	end
	

	-- BOARD MENU
	local mx,my = camera:getScreenPos(love.mouse.getPosition())
	if checkKeyPressed(key, 'f1', 'none', currentMenu==menus.board) then settings.showHelp = not settings.showHelp end
	if checkKeyPressed(key, 'f2', 'none', currentMenu==menus.board) then settings.showDebug = not settings.showDebug end
	if checkKeyPressed(key, 'f3', 'none', currentMenu==menus.board) then settings.showFPS = not settings.showFPS end
	if checkKeyPressed(key, 'f4', 'none', currentMenu==menus.board) then settings.showGrid = not settings.showGrid end

	if checkKeyPressed(key, 'i', 'none', currentMenu==menus.board) then
		settings.useSmoothCubic = not settings.useSmoothCubic
		messages.add('Use Smooth Cubic: '..tostring(settings.useSmoothCubic))
	end

	if checkKeyPressed(key, 's', 'ctrl', currentMenu==menus.board) then saveBoard() end
	if checkKeyPressed(key, 'l', 'ctrl', currentMenu==menus.board) then loadBoard() end
	if checkKeyPressed(key, 'r', 'ctrl', currentMenu==menus.board) then resetBoard() end
	if checkKeyPressed(key, 'd', 'ctrl', currentMenu==menus.board) then addDefaults() end

	if checkKeyPressed(key, 'p', 'ctrl', currentMenu==menus.board) then settings.showPlotter = not settings.showPlotter end
	if checkKeyPressed(key, 'g', 'ctrl', currentMenu==menus.board) then graphicSettings.betterGraphics = not graphicSettings.betterGraphics; messages.add('Use Better Graphics: '..tostring(settings.useSmoothCubic)) end

	if checkKeyPressed(key, 'c', 'ctrl', currentMenu==menus.board) then -- HERE update to save groups too
		love.system.setClipboardText(json.encode({ gates=gates, peripherals=peripherals, connections=connections }))
		messages.add({{0.6, 0.89, 0.63},"Board Data copied to Clipboard!"})
	end
	if checkKeyPressed(key, 'v', 'ctrl', currentMenu==menus.board) then
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
					messages.add({{0.6, 0.89, 0.63},"Board Data loaded from Clipboard!"})
				end
			end
		end
	end

	if checkKeyPressed(key, 'q', 'ctrl', currentMenu==menus.board) then love.event.quit() end

	if checkKeyPressed(key, 'g', 'none', currentMenu==menus.board) then
		addGroup()
		selection = {x1=0, y1=0, x2=0, y2=0, ids={}}
		messages.add({{0.71, 0.75, 0.86},"Group created!"})
	end

	if checkKeyPressed(key, 'delete', 'none', currentMenu==menus.board) then
		if selectedPinID ~= 0 then -- First Pin of new Connection selected
			local pin = getPinByID(selectedPinID)
			if pin then pin.isConnected = false end
			selectedPinID = 0
		else  -- no Pin selected
			local pinID = getPinIDByPos(mx, my)
			if pinID then
				removeConnectionWithPinID(pinID)
			else
				local bobID = getBobIDByPos(mx, my)
				if bobID then
					removeBobByID(bobID)
				end
			end
		end
	end

	if checkKeyPressed(key, 'delete', 'shift', currentMenu==menus.board) then
		local groupID = getGroupIDByPos(mx, my)
		if groupID then
			removeGroupByID(groupID, love.keyboard.isDown("lalt"))
		end
	end

	if checkKeyPressed(key, any{'1','2','3','4','5','6','7','8','9'}, 'alt', currentMenu==menus.board) then
		saveBoard()
		currentBoard = tonumber(key)
		loadBoard()
	end

	if checkKeyPressed(key, '1', 'none', currentMenu==menus.board) then addPeripheral(classes.INPUT (mx - classes.PERIPHERAL:getWidth()/2, my - classes.PERIPHERAL:getHeight()/2)) end
	if checkKeyPressed(key, '2', 'none', currentMenu==menus.board) then addPeripheral(classes.OUTPUT(mx - classes.PERIPHERAL:getWidth()/2, my - classes.PERIPHERAL:getHeight()/2)) end
	if checkKeyPressed(key, '3', 'none', currentMenu==menus.board) then addPeripheral(classes.CLOCK (mx - classes.PERIPHERAL:getWidth()/2, my - classes.PERIPHERAL:getHeight()/2)) end
	if checkKeyPressed(key, '4', 'none', currentMenu==menus.board) then addPeripheral(classes.BUFFER(mx - classes.PERIPHERAL:getWidth()/2, my - classes.PERIPHERAL:getHeight()/2)) end
	if checkKeyPressed(key, '5', 'none', currentMenu==menus.board) then addGate(classes.AND (mx - classes.GATE:getWidth()/2, my - classes.GATE:getHeight(2)/2)) end
	if checkKeyPressed(key, '6', 'none', currentMenu==menus.board) then addGate(classes.OR  (mx - classes.GATE:getWidth()/2, my - classes.GATE:getHeight(2)/2)) end
	if checkKeyPressed(key, '7', 'none', currentMenu==menus.board) then addGate(classes.NOT (mx - classes.GATE:getWidth()/2, my - classes.GATE:getHeight(1)/2)) end

	if checkKeyPressed(key, '0', 'none', currentMenu==menus.board) then camera:reset() end
	if checkKeyPressed(key, 'space', 'none', currentMenu==menus.board) then camera:center() end

	if checkKeyPressed(key, 'f') then
		-- print(classes.GATE(0,0))
		-- print(classes.GATE(0,0).__class)
		-- print(classes.GATE(0,0).__name)
		-- print(classes.GATE(0,0).__class.__name)
	end
end



--==============================================[ CUSTOM FUNCTIONS ]==============================================--

function shouldShowMenu(menu)
	return menu==currentMenu or menu==currentMenu-1 or menu==currentMenu+1
end

function prepForSave(t)
	local newTable = lume.deepclone(t)
	-- remove functions
	for k, v in pairs(newTable) do
		if type(v) == 'function' then
			newTable[k] = nil
		elseif type(v) == 'table' then
			newTable[k] = prepForSave(v)
		end
	end
	
	return newTable
end

function any(tbl)
	tbl.mode = 'any'
	return tbl
end

function all(tbl)
	tbl.mode = 'all'
	return tbl
end

function checkKeyPressed(key, keysToCompare, modifiers, additionalConditions)
    -- Check if the key matches any of the keys to compare
    local function keyMatches(pressedKey)
        if type(keysToCompare) == "string" then
            return pressedKey == keysToCompare
        elseif type(keysToCompare) == "table" then
            if keysToCompare.mode and keysToCompare.mode == "any" then
                for _, k in ipairs(keysToCompare) do
                    if k == pressedKey then
                        return true
                    end
                end
                return false
            else
                for _, k in ipairs(keysToCompare) do
                    if k ~= pressedKey then
                        return false
                    end
                end
                return true
            end
        end
        return false
    end

    -- Check if the modifier matches the key
    local function modifierMatches(modifier)
        if modifier == "ignore" then
            return true
        elseif modifier == "none" then
            return not love.keyboard.isDown("lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt")
        elseif type(modifier) == "string" then
            if modifier == "shift" then
                return love.keyboard.isDown("lshift", "rshift")
            elseif modifier == "ctrl" then
                return love.keyboard.isDown("lctrl", "rctrl")
            elseif modifier == "alt" then
                return love.keyboard.isDown("lalt", "ralt")
            end
        else
            return not love.keyboard.isDown("lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt")
        end
        return false
    end      

    -- Check if additional conditions are met
    local function additionalConditionsMet()
        if type(additionalConditions) == "boolean" then
            return additionalConditions
        elseif type(additionalConditions) == "table" then
            if additionalConditions.mode and additionalConditions.mode == "any" then
                for _, condition in ipairs(additionalConditions) do
                    if not condition then
                        return false
                    end
                end
                return true
            else
                for _, condition in ipairs(additionalConditions) do
                    if condition then
                        return false
                    end
                end
                return true
            end
        end
        return true
    end

    -- Main logic
    return keyMatches(key) and modifierMatches(modifiers) and additionalConditionsMet()
end

function keyPressed(key, keys, mods, others)
	local isPressed = true

	-- keys
	if type(keys) == 'table' then
		if keys.mode == 'any' then
			isPressed = false
			for i, k in ipairs(keys) do
				if key == k then isPressed = true end
			end
		elseif keys.mode == 'all' then
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

	-- others like menu etc.
	if others ~= nil then
		if type(others) == 'table' then		
			for i, o in ipairs(others) do
				if not o then isPressed = false end
			end
		elseif type(others) == 'boolean' then
			isPressed = isPressed and others
		else
			log.info("keyPressed: unusable type of 'others': "..tostring(others)..', type:'..type(others))
		end
	end

	return isPressed
end

function whenKeyPressed(key, keys, mods, others, func)
	if checkKeyPressed(key, keys, mods, others) then
		local success, result = pcall(func)
		if not success then
			log.error('whenKeyPressed for key ['..tostring(keys)..']: '..result)
		end
		return success, result
	end
	return false
end

function addGate(gate)
	local addgatefunc = function()
		log.debug('Added Gate with ID: '..gate.id)
		lume.push(gates, gate)
		-- love.thread.getChannel("addGate"):push(json.encode(gate))
	end

	if SAVECATCHMODE then
		local success, result = pcall(addgatefunc)
		if not success then
			log.error('addGate: '..result)
		end
	else
		addgatefunc()
	end
end
function addPeripheral(peripheral)
	local addperfunc = function()		
		log.debug('Added Peripheral with ID: '..peripheral.id)
		lume.push(peripherals, peripheral)
		-- love.thread.getChannel("addPeripheral"):push(json.encode(peripheral))
	end

	if SAVECATCHMODE then
		local success, result = pcall(addperfunc)
		if not success then
			log.error('addPeripheral: '..result)
		end
	else
		addperfunc()
	end
end
function addConnection(con)
	local addconfunc = function()
		log.debug('Added Connection, Outputpin ID:'..con.outputpin.id..' and Inputpin ID:'..con.inputpin.id)
		lume.push(connections, con)
		-- love.thread.getChannel("addConnection"):push(json.encode(con))
	end

	if SAVECATCHMODE then
		local success, result = pcall(addconfunc)
		if not success then
			log.error('addConnection: '..result)
		end
	else
		addconfunc()
	end
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
	plotterID = 0
	plotterData = {}
	-- love.thread.getChannel("reset"):push(true)
	messages.add({{0.93, 0.7, 0.53},"Board Reset..."})
end

function addDefaults()
	addGate(classes.AND(200, 100))
	addGate(classes.OR(400, 100))
	addGate(classes.NOT(600, 100, 1))
	addPeripheral(classes.BUFFER(200, 300))
	addPeripheral(classes.INPUT(200, 500))
	addPeripheral(classes.CLOCK(400, 500))
	addPeripheral(classes.OUTPUT(600, 500))
	messages.add({{0.6, 0.89, 0.63},"Default Board Loaded!"})
end

function loadBoard()
	local loadingfunc = function()
		contents = love.filesystem.read(string.format("board%d.json", currentBoard))
		if contents then
			local data = json.decode(contents)
			resetBoard()
			if data.gates then
				for i, gatedata in ipairs(data.gates) do
					addGate(classes.loadGATE(gatedata))
				end
			end
			if data.peripherals then
				for i, peripheraldata in ipairs(data.peripherals) do
					addPeripheral(classes.loadPERIPHERAL(peripheraldata))
				end
			end
			if data.connections then
				for i, connection in ipairs(data.connections) do
					addConnection({ outputpin=getPinByID(connection.outputpin.id), inputpin=getPinByID(connection.inputpin.id) })
				end
			end
			if data.groups then
				for i, group in ipairs(data.groups) do
					lume.push(groups, group)
				end
			end
		else
			log.warn('board file not found')
		end
	end

	if SAVECATCHMODE then
		local success, result = pcall(loadingfunc)
		if not success then
			log.error('loading board failed: '..tostring(result))
		else
			messages.add({{0.6, 0.89, 0.63},string.format("Board %d Loaded!", currentBoard)})
		end
	else
		loadingfunc()
		messages.add({{0.6, 0.89, 0.63},string.format("Board %d Loaded!", currentBoard)})
	end
end

function saveBoard()
	local savefunc = function()
		local lsucc, lmessage = love.filesystem.write(
			string.format("board%d.json", currentBoard),
			json.encode({
				gates = prepForSave(gates),
				peripherals = prepForSave(peripherals),
				connections = prepForSave(connections),
				groups = prepForSave(groups)
			})
		)
		return lmessage
	end

	if SAVECATCHMODE then
		local success, result = pcall(savefunc)
		if not success then
			log.error('saving board failed: '..tostring(result))
		else
			messages.add({{0.6, 0.89, 0.63},string.format("Board %d Saved!", currentBoard)})
		end
	else
		savefunc()
		messages.add({{0.6, 0.89, 0.63},string.format("Board %d Saved!", currentBoard)})
	end
end

function addGroup()
	local addgroupfunc = function()
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

	if SAVECATCHMODE then
		local success, result = pcall(addgroupfunc)
		if not success then
			log.error('adding group failed: '..tostring(result))
		end
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
