-- ==============================================================[ IMPORTS ]===================================================================--
local version = require("settings").version

require("lib.noahsutils")
local lume = require("lib.lume")
local messages = require("lib.messages")
local classes = require("classes")
-- local json = require 'lib.json'
local serpent = require("lib.serpent")
local Camera = require("lib.camera")

local font = love.graphics.newFont("fonts/main.ttf", 20)
font:setFilter("nearest", "nearest", 8)
love.graphics.setFont(font)

-- =============================================================[ VARIABLES ]==================================================================--

local unpack = table.unpack

local helpText = nt([[
	1 = EINGANG
	2 = AUSGANG
	3 = NOT
	4 = AND
	5 = OR
	6 = XOR
	7 = NAND
	8 = NOR
	9 = XNOR
	c = CLOCK
	b = PUFFER
	
	STRG+C = KOPIEREN
	STRG+V = EINFÜGEN
	STRG+R = RESET
	STRG+D = DEFAULTS
	STRG+P = PLOTTER

	F2 = DEBUG
	F3 = FPS
	F4 = NACHRICHTEN
	F5 = SMOOTHING
]])

local settings = {
	useSmoothDrag = true,
	showPinIDs = false,
	showPinStates = false,
	showGateIDs = false,
	showPlotter = false,
	showHelp = false,
	showDebug = false,
	showMessages = true,
	showFPS = true,
	fullscreen = false,
	deleteWithX = true,
}

local gates = {}
local peripherals = {}
local connections = {}
local groups = {}

local selectedPinID = 0

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

local currentBoard = "none"

local telemetryInterval, telemetryIntervalLast = 500, love.timer.getTime()
local telemetry, telemetryShow = {}, {}
local maxFPSRecorded = 60

local updatesPerTick = 1

local camera

local boardTransform

-- ===========================================================[ MAIN FUNCTIONS ]===============================================================--

-- #################################################################
-- #                           LOVE LOAD                           #
-- #################################################################
function love.load()
	love.graphics.setBackgroundColor(0.11, 0.11, 0.11)
	love.keyboard.setKeyRepeat(true)
	local deskDimX, deskDimY = love.window.getDesktopDimensions()
	settings.desktopDim = { x = deskDimX, y = deskDimY }
	local windowDimX, windowDimY = love.graphics.getDimensions()
	settings.windowDim = { x = windowDimX, y = windowDimY }
	messages.x = 10
	messages.y = 40

	boardTransform = love.math.newTransform(0, 0, 0, 1)

	camera = Camera.newSmoothWithTransform(boardTransform, 30, 0.5, 5)

	resetBoard()
	addDefaults()
end

-- #################################################################
-- #                           LOVE UPDATE                         #
-- #################################################################
function love.update(dt)
	-- MENUS
	camera:update(dt, settings.useSmoothDrag)
	mx, my = camera:getScreenPos(love.mouse.getPosition())

	local time = love.timer.getTime()
	for i = 1, updatesPerTick do
		-- update board objects
		for bob in myBobjects() do
			bob:update()
		end
		telemetry.updateTimeBobjects = love.timer.getTime() - time

		-- update connections
		time = love.timer.getTime()
		for con in myConnections() do
			con.inputpin.state = con.outputpin.state
		end
	end
	telemetry.updateTimeConnections = love.timer.getTime() - time

	-- OTHERS

	if love.timer.getFPS() > maxFPSRecorded then
		maxFPSRecorded = love.timer.getFPS()
	end
	telemetry.dt = dt

	messages.update(dt)
end

-- #################################################################
-- #                           LOVE DRAW                           #
-- #################################################################
function love.draw()
	love.graphics.setScissor(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	-- love.graphics.push('transform')
	-- love.graphics.applyTransform(menuTransform)

	-- ##############################[  BOARD  ]##############################
	mx, my = camera:getScreenPos(love.mouse.getPosition())

	love.graphics.stencil(boardStencil, "replace", 1)
	love.graphics.setStencilTest("greater", 0)
	-- grid points
	love.graphics.setColor(0.15, 0.15, 0.15)
	local scale = camera:getScale()
	local camoffset = camera:getOffset()
	local step = 50 * scale
	for i = 0 + (camoffset.x % step), love.graphics.getWidth(), step do
		for j = 0 + (camoffset.y % step), love.graphics.getHeight(), step do
			love.graphics.circle("fill", i, j, 2 * scale)
		end
	end

	love.graphics.setColor(0.11, 0.11, 0.11)
	love.graphics.circle("fill", camoffset.x, camoffset.y, 3 * scale)
	love.graphics.setColor(0.18, 0.18, 0.18)
	love.graphics.setLineWidth(2 * scale)
	love.graphics.circle("line", camoffset.x, camoffset.y, 3 * scale)

	camera:set()
	-- groups
	for i, group in ipairs(groups) do
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
		love.graphics.rectangle(
			"fill",
			selection.x1,
			selection.y1,
			selection.x2 - selection.x1,
			selection.y2 - selection.y1,
			2
		)
		love.graphics.setColor(0.2, 0.2, 0.3)
		love.graphics.rectangle(
			"line",
			selection.x1,
			selection.y1,
			selection.x2 - selection.x1,
			selection.y2 - selection.y1,
			2
		)
	end

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
				outputpinPos.x,
				outputpinPos.y,
				outputpinPos.x + offset,
				outputpinPos.y,
				inputpinPos.x - offset,
				inputpinPos.y,
				inputpinPos.x,
				inputpinPos.y,
			})
			love.graphics.line(curve:render())
		end
	end
	telemetry.drawTimeConnections = love.timer.getTime() - time

	-- gates and periphs
	local time = love.timer.getTime()
	-- draw bobjects in order of their y position
	local bobjects = getBobjects()
	table.sort(bobjects, function(a, b)
		return a.pos.y < b.pos.y
	end)
	for i, bob in ipairs(bobjects) do
		bob:draw()
	end
	telemetry.drawTimeBobjects = love.timer.getTime() - time

	-- currently connecting pin
	love.graphics.setColor(0, 0.71, 0.48)
	love.graphics.setLineWidth(2)
	if selectedPinID > 0 then
		local pinPos = getPinPosByID(selectedPinID)
		-- love.graphics.print("Selected Pin: "..selectedPinID, 20, 80)
		if pinPos then
			local offset = 80
			local curve = love.math.newBezierCurve({
				pinPos.x,
				pinPos.y,
				pinPos.x + offset,
				pinPos.y,
				mx - offset,
				my,
				mx,
				my,
			})
			love.graphics.line(curve:render())
		end
	end
	camera:set()

	-- plotter
	if settings.showPlotter then
		local w, h = love.graphics.getDimensions()
		local pw, ph = w / 4 * 2, 150
		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.rectangle("fill", w / 4, h - ph / 2 - 10, w / 4 * 2, ph / 2, 6)
		love.graphics.setColor(0.4, 0.4, 0.4)
		love.graphics.rectangle("line", w / 4, h - ph / 2 - 10, w / 4 * 2, ph / 2, 6)

		love.graphics.setColor(1, 1, 1)
		love.graphics.print("AUSGANG ID: " .. tostring(plotterID - 2000), w / 4 + pw + 10, h - ph / 2 - 5)
		love.graphics.print("FREQUENZ: " .. tostring(0), w / 4 + pw + 10, h - ph / 2 + 30)

		if plotterID - 2000 > 0 then
			local per = getPeripheralByID(plotterID)
			if per then
				table.insert(plotterData, per.state and 1 or 0)
				if #plotterData > pw then
					table.remove(plotterData, 1)
				end
				love.graphics.setColor(0.6, 0.6, 0.6)
				for i = 2, #plotterData do
					love.graphics.line(
						w / 4 + i - 1,
						h - 15 - plotterData[i - 1] * ((ph / 2) - 10),
						w / 4 + i,
						h - 15 - plotterData[i] * ((ph / 2) - 10)
					)
				end
			end
		end
	end

	if settings.showHelp then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(helpText, 10, 150)
	end

	if settings.showDebug then
		love.graphics.setColor(0.6, 1, 0.6)
		love.graphics.print(
			lume.format(
				"Board Objekte: {1}\nVerbindungen: {2}\n",
				{ lume.count(getBobjects()), lume.count(connections) }
			),
			love.graphics.getWidth() - 250,
			100
		)

		if love.timer.getTime() - telemetryIntervalLast > telemetryInterval / 1000 then
			for k, v in pairs(telemetry) do
				telemetryShow[k] = v
			end
			telemetryShow.stats = love.graphics.getStats()
			telemetryIntervalLast = love.timer.getTime()
		end
		love.graphics.setColor(1, 0.6, 0.6)
		love.graphics.print(
			string.format(
				nt([[
					Timings:
					
					Board Objekte Update: %s
					Verbindungen  Update: %s
					
					Board Objekte Render: %s
					Verbindungen  Render: %s
					
					Gesamt: %s


					Love2D Statistiken:

					Drawcalls: %d
					Canvas Switches: %d
					Texture Memory: %d
					Images: %d
					Canvases: %d
					Shader Switches: %d
					Drawcalls Batched: %d
				]]),
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
			love.graphics.getWidth() - 300,
			400
		)
	end

	if settings.showFPS then
		love.graphics.setColor(1, 1, 1)
		local performancecolor = {
			gradient(
				love.timer.getFPS() / maxFPSRecorded,
				{ 0.500, 0.500, -3.142 },
				{ 0.980, 0.498, 0.500 },
				{ 0.060, 0.358, 1.000 },
				{ 0.168, 0.608, 0.667 }
			),
		}
		love.graphics.print({
			{ 1, 1, 1 },
			"FPS: ",
			performancecolor,
			love.timer.getFPS(),
			{ 1, 1, 1 },
			" | Lag: ",
			performancecolor,
			string.format("%2d%%", lume.round(100 - love.timer.getFPS() / maxFPSRecorded * 100)),
			{ 1, 1, 1 },
			" | UPT: ",
			{ 0.48, 0.86, 0.92 },
			updatesPerTick,
			{ 1, 1, 1 },
			" | Effektive UPS: ",
			{ 0.48, 0.86, 0.92 },
			updatesPerTick * love.timer.getFPS(),
			{ 1, 1, 1 },
			" | Offenes Board: ",
			{ 0.54, 0.71, 0.93 },
			currentBoard,
			{ 1, 1, 1 },
			" | [F1] für Hilfe",
		}, 10, 10)
	end
	love.graphics.setStencilTest()
	if settings.showMessages then
		messages.draw()
	end

	love.graphics.setScissor()
end

function boardStencil()
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

function love.quit() end

-- ==========================================================[ INPUT FUNCTIONS ]===============================================================--

-- #################################################################
-- #                       LOVE MOUSE PRESSED                      #
-- #################################################################
function love.mousepressed(x, y, button)
	-- ************************************[ BOARD ]************************************ --

	x, y = camera:getScreenPos(x, y)
	--=====================[ LEFT CLICK ]=====================--
	if button == 1 then
		dontSelect = false
		for bob in myBobjects() do
			local inpin = bob:getInputPinAt(x, y)
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
						addConnection({ outputpin = getPinByID(selectedPinID), inputpin = inpin })
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
		for i, group in ipairs(groups) do
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
			if
				bob.pos.x > selection.x1
				and bob.pos.x < selection.x2
				and bob.pos.y > selection.y1
				and bob.pos.y < selection.y2
			then
				lume.push(selection.ids, bob.id)
			end
		end
	elseif button == 3 then
		if draggedObjectID > 0 then
		end

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

		for i, id in ipairs(group.ids) do
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

		for i, id in ipairs(selection.ids) do
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
			camera:move(dx, dy)
		end
	end
end

-- #################################################################
-- #                        LOVE WHEEL MOVED                       #
-- #################################################################
function love.wheelmoved(dx, dy)
	-- on macos shift and scroll is horizontal (dx)
	local delta = dy + dx
	local x, y = camera:getScreenPos(love.mouse.getPosition())
	if love.keyboard.isDown("lshift") then
		delta = delta * -1
		-- Find the object under the cursor
		local bobID = getBobIDByPos(x, y)
		if bobID then
			local bob = getBobByID(bobID) -- This will get the actual reference
			if bob.name == "CLOCK" then
				bob.tickspeed = bob.tickspeed + delta
				if bob.tickspeed < 1 then
					bob.tickspeed = 1
				end
			elseif bob.name == "AND" or bob.name == "NAND" or bob.name == "OR" then
				if delta > 0 then
					local inputPins = bob.inputpins
					local maxId = -1
					local maxIdIndex = 1
					for i, pin in ipairs(inputPins) do
						if pin.id > maxId then
							maxId = pin.id
							maxIdIndex = i
						end
					end
					local lastPin = inputPins[maxIdIndex]
					if not lastPin.isConnected then
						bob:removePin()
					end
				elseif delta < 0 then
					bob:addPin()
				end
			elseif bob.name == "BUFFER" then
				bob.ticks = bob.ticks + delta
				if bob.ticks < 1 then
					bob.ticks = 1
				end
			end
		end
	elseif love.keyboard.isDown("lctrl") or love.keyboard.isDown("lgui") then
		updatesPerTick = lume.clamp(updatesPerTick + delta, 1, 50)
	else
		camera:zoom(delta)
	end
end

-- #################################################################
-- #                        LOVE KEY PRESSED                       #
-- #################################################################
function love.keypressed(key, scancode, isrepeat)
	local mx, my = camera:getScreenPos(love.mouse.getPosition())
	if checkKeyPressed(key, "f1", "none", true) then
		settings.showHelp = not settings.showHelp
	end
	if checkKeyPressed(key, "f2", "none", true) then
		settings.showDebug = not settings.showDebug
	end
	if checkKeyPressed(key, "f3", "none", true) then
		settings.showFPS = not settings.showFPS
	end
	if checkKeyPressed(key, "f4", "none", true) then
		settings.showGrid = not settings.showGrid
	end

	if checkKeyPressed(key, "i", "none", true) then
		settings.useSmoothDrag = not settings.useSmoothDrag
		messages.add("Use Smooth Cubic: " .. tostring(settings.useSmoothDrag))
	end
	if checkKeyPressed(key, "r", "ctrl", true) then
		resetBoard()
	end
	if checkKeyPressed(key, "d", "ctrl", true) then
		addDefaults()
	end

	if checkKeyPressed(key, "p", "ctrl", true) then
		settings.showPlotter = not settings.showPlotter
	end
	if checkKeyPressed(key, "g", "ctrl", true) then
		graphicSettings.betterGraphics = not graphicSettings.betterGraphics
		messages.add("Use Better Graphics: " .. tostring(settings.betterGraphics))
	end

	if checkKeyPressed(key, "c", "ctrl", true) or checkKeyPressed(key, "c", "cmd", true) then
		love.system.setClipboardText(serpent.block({
			gates = prepForSave(gates),
			peripherals = prepForSave(peripherals),
			connections = prepForSave(connections),
			groups = prepForSave(groups),
		}))
		messages.add({ { 0.6, 0.89, 0.63 }, "Board Data copied to Clipboard!" })
	end
	if checkKeyPressed(key, "v", "ctrl", true) or checkKeyPressed(key, "v", "cmd", true) then
		local text = love.system.getClipboardText()
		if text then
			if text:match("gates") and text:match("peripherals") and text:match("connections") then
				local ok, data = serpent.load(text)
				if ok and data then
					-- resetBoard()
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
							addConnection({
								outputpin = getPinByID(connection.outputpin.id),
								inputpin = getPinByID(connection.inputpin.id),
							})
						end
					end
					if data.groups then
						for i, group in ipairs(data.groups) do
							lume.push(groups, group)
						end
					end
					messages.add({ { 0.6, 0.89, 0.63 }, "Board Data loaded from Clipboard!" })
				end
			end
		end
	end

	if checkKeyPressed(key, "g", "none", true) then
		addGroup()
		selection = { x1 = 0, y1 = 0, x2 = 0, y2 = 0, ids = {} }
		messages.add({ { 0.71, 0.75, 0.86 }, "Group created!" })
	end

	if checkKeyPressed(key, "delete", "none", true) then
		if selectedPinID ~= 0 then --------------------- First Pin of new Connection selected
			local pin = getPinByID(selectedPinID)
			if pin then
				pin.isConnected = false
			end
			selectedPinID = 0
		else ------------------------------------------- no Pin selected
			if #selection.ids > 0 then
				for i, id in ipairs(selection.ids) do
					local bob = getBobByID(id)
					if bob then
						removeBobByID(id)
					end
				end
				selection = { x1 = 0, y1 = 0, x2 = 0, y2 = 0, ids = {} }
			else
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
	end

	if checkKeyPressed(key, "delete", "shift", true) then
		local groupID = getGroupIDByPos(mx, my)
		if groupID then
			removeGroupByID(groupID, love.keyboard.isDown("lalt"))
		end
	end

	if settings.deleteWithX and checkKeyPressed(key, "x", "none", true) then
		if selectedPinID ~= 0 then --------------------- First Pin of new Connection selected
			local pin = getPinByID(selectedPinID)
			if pin then
				pin.isConnected = false
			end
			selectedPinID = 0
		else ------------------------------------------- no Pin selected
			if #selection.ids > 0 then
				for i, id in ipairs(selection.ids) do
					local bob = getBobByID(id)
					if bob then
						removeBobByID(id)
					end
				end
				selection = { x1 = 0, y1 = 0, x2 = 0, y2 = 0, ids = {} }
			else
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
	end

	if settings.deleteWithX and checkKeyPressed(key, "x", "shift", true) then
		local groupID = getGroupIDByPos(mx, my)
		if groupID then
			removeGroupByID(groupID, love.keyboard.isDown("lalt"))
		end
	end

	if checkKeyPressed(key, "1", "none", true) then
		addPeripheral(classes.INPUT(mx - classes.PERIPHERAL:getWidth() / 2, my - classes.PERIPHERAL:getHeight() / 2))
	end
	if checkKeyPressed(key, "2", "none", true) then
		addPeripheral(classes.OUTPUT(mx - classes.PERIPHERAL:getWidth() / 2, my - classes.PERIPHERAL:getHeight() / 2))
	end
	if checkKeyPressed(key, "3", "none", true) then
		addGate(classes.NOT(mx - classes.GATE:getWidth() / 2, my - classes.GATE:getHeight(2) / 2))
	end
	if checkKeyPressed(key, "4", "none", true) then
		addGate(classes.AND(mx - classes.GATE:getWidth() / 2, my - classes.GATE:getHeight(2) / 2))
	end
	if checkKeyPressed(key, "5", "none", true) then
		addGate(classes.OR(mx - classes.GATE:getWidth() / 2, my - classes.GATE:getHeight(2) / 2))
	end
	if checkKeyPressed(key, "6", "none", true) then
		addGate(classes.XOR(mx - classes.GATE:getWidth() / 2, my - classes.GATE:getHeight(2) / 2))
	end
	if checkKeyPressed(key, "7", "none", true) then
		addGate(classes.NAND(mx - classes.GATE:getWidth() / 2, my - classes.GATE:getHeight(2) / 2))
	end
	if checkKeyPressed(key, "8", "none", true) then
		addGate(classes.NOR(mx - classes.GATE:getWidth() / 2, my - classes.GATE:getHeight(2) / 2))
	end
	if checkKeyPressed(key, "9", "none", true) then
		addGate(classes.XNOR(mx - classes.GATE:getWidth() / 2, my - classes.GATE:getHeight(2) / 2))
	end

	if checkKeyPressed(key, "c", "none", true) then
		addPeripheral(classes.CLOCK(mx - classes.PERIPHERAL:getWidth() / 2, my - classes.PERIPHERAL:getHeight() / 2))
	end
	if checkKeyPressed(key, "b", "none", true) then
		addPeripheral(classes.BUFFER(mx - classes.PERIPHERAL:getWidth() / 2, my - classes.PERIPHERAL:getHeight() / 2))
	end

	if checkKeyPressed(key, "space", "none", true) then
		camera:reset()
		camera:center()
	end
end

--==============================================[ CUSTOM FUNCTIONS ]==============================================--


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
			return not love.keyboard.isDown("lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt", "lgui", "rgui")
		elseif type(modifier) == "string" then
			if modifier == "shift" then
				return love.keyboard.isDown("lshift", "rshift")
			elseif modifier == "cmd" then
				return love.keyboard.isDown("lgui", "rgui")
			elseif modifier == "ctrl" then
				return love.keyboard.isDown("lctrl", "rctrl")
			elseif modifier == "alt" then
				return love.keyboard.isDown("lalt", "ralt")
			end
		else
			return not love.keyboard.isDown("lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt", "lgui", "rgui")
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
	if type(keys) == "table" then
		if keys.mode == "any" then
			isPressed = false
			for i, k in ipairs(keys) do
				if key == k then
					isPressed = true
				end
			end
		elseif keys.mode == "all" then
			for i, k in ipairs(keys) do
				if key ~= k then
					isPressed = false
				end
			end
		end
	else
		isPressed = key == keys
	end

	if not isPressed then
		return false
	end

	-- mods
	if mods ~= nil then
		if type(mods) == "table" then
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
			if mods == "shift" then
				isPressed = isPressed and love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
			else
				isPressed = isPressed and not love.keyboard.isDown("lshift") and not love.keyboard.isDown("rshift")
			end
			if mods == "ctrl" then
				isPressed = isPressed and love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
			else
				isPressed = isPressed and not love.keyboard.isDown("lshift") and not love.keyboard.isDown("rshift")
			end
			if mods == "alt" then
				isPressed = isPressed and love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
			else
				isPressed = isPressed and not love.keyboard.isDown("lalt") and not love.keyboard.isDown("ralt")
			end
			if mods == "gui" then
				isPressed = isPressed and love.keyboard.isDown("lgui") or love.keyboard.isDown("rgui")
			else
				isPressed = isPressed and not love.keyboard.isDown("lgui") and not love.keyboard.isDown("rgui")
			end
		end
	end

	-- others like menu etc.
	if others ~= nil then
		if type(others) == "table" then
			for i, o in ipairs(others) do
				if not o then
					isPressed = false
				end
			end
		elseif type(others) == "boolean" then
			isPressed = isPressed and others
		end
	end

	return isPressed
end

function addGate(gate)
	local addgatefunc = function()
		lume.push(gates, gate)
		-- love.thread.getChannel("addGate"):push(json.encode(gate))
	end

	addgatefunc()
end
function addPeripheral(peripheral)
	local addperfunc = function()
		lume.push(peripherals, peripheral)
		-- love.thread.getChannel("addPeripheral"):push(json.encode(peripheral))
	end

	addperfunc()
end
function addConnection(con)
	local addconfunc = function()
		lume.push(connections, con)
		-- love.thread.getChannel("addConnection"):push(json.encode(con))
	end

	addconfunc()
end

function prepForSave(t)
	local newTable = lume.deepclone(t)
	-- remove functions
	for k, v in pairs(newTable) do
		if type(v) == "function" then
			newTable[k] = nil
		elseif type(v) == "table" then
			newTable[k] = prepForSave(v)
		end
	end

	return newTable
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
	messages.add({ { 0.93, 0.7, 0.53 }, "Board Reset..." })
end

function addDefaults()
	addGate(classes.AND(200, 100))
	addGate(classes.OR(400, 100))
	addGate(classes.NOT(600, 100))

	addGate(classes.NAND(200, 300))
	addGate(classes.NOR(400, 300))
	addGate(classes.XOR(600, 300))
	addGate(classes.XNOR(800, 300))

	addPeripheral(classes.INPUT(200, 500))
	addPeripheral(classes.CLOCK(200, 600))
	addPeripheral(classes.BUFFER(400, 500))
	addPeripheral(classes.OUTPUT(600, 500))

	messages.add({ { 0.6, 0.89, 0.63 }, "Default Board Loaded!" })
end

function addGroup()
	local addgroupfunc = function()
		local group = { x1 = math.huge, y1 = math.huge, x2 = -math.huge, y2 = -math.huge, ids = {} }
		local padding = 20

		for i, id in ipairs(selection.ids) do
			if not lume.any(groups, function(group)
				return lume.find(group.ids, id)
			end) then
				local bob = getBobByID(id)
				if bob.pos.x < group.x1 then
					group.x1 = bob.pos.x
				elseif bob.pos.x > group.x2 then
					group.x2 = bob.pos.x + bob:getWidth() + padding
				end

				if bob.pos.y < group.y1 then
					group.y1 = bob.pos.y
				elseif bob.pos.y > group.y2 then
					group.y2 = bob.pos.y + bob:getHeight() + padding
				end

				lume.push(group.ids, id)
			end
		end

		group.ids = lume.unique(group.ids)

		if lume.count(group.ids) > 1 then
			group.x1 = group.x1 - padding
			group.y1 = group.y1 - padding
			group.x2 = group.x2 + padding
			group.y2 = group.y2 + padding

			lume.push(groups, group)
		end
	end

	addgroupfunc()
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
	for i, group in ipairs(groups) do
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
	for gate, index in myGates() do
		if gate.id == id then
			for _, pin in ipairs(gate:getAllPins()) do
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
	for per, index in myPeripherals() do
		if per.id == id then
			for _, pin in ipairs(per:getAllPins()) do
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
	for i, group in ipairs(groups) do
		if i == id then
			if deleteBobs then
				for _, bobID in ipairs(group.ids) do
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
