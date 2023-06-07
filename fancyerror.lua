local utf8 = require("utf8")

-- ==========================================================[ DEBUG FUNCTIONS ]==============================================================--

debugs = {}

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

	local debugslen = 0
    for key, value in pairs(debugs) do
        debugslen = debugslen + 1
    end

	success = love.window.setMode(800, 600, {resizable=true, vsync=true, minwidth=400, minheight=300})

	local function draw()
		if not love.graphics.isActive() then return end
		local pos, width = 70, love.graphics.getWidth()
		love.graphics.clear(30/255, 30/255, 30/255)
		love.graphics.setColor(248/255, 46/255, 105/255)
		love.graphics.printf(err[1], pos, pos, width - pos)
		love.graphics.setColor(225/255, 157/255, 40/255)
		love.graphics.printf(err[2], pos, pos+40, width - pos)
		love.graphics.setColor(166/255, 226/255, 41/255)
		love.graphics.printf(p, pos, pos*2, width - pos)

		if debugslen > 0 then
			love.graphics.setColor(225/255, 157/255, 40/255)
			love.graphics.print("Debug Variables:", width/2, pos)
			love.graphics.setColor(166/255, 226/255, 41/255)
			local i = 0
			for k,v in pairs(debugs) do
				love.graphics.printf(("%s = %s"):format(k,tostring(v)), width/2, pos*2 + (pos*i)/2, width - pos)
				i = i + 1
			end
		end

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