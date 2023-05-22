io.stdout:setvbuf("no")
inspect = require "lib.inspect"
Collection = require "lib.collections"
usingSublime = false

function prinspect(...)
	local value = ...
	if type(value) == "table" then
		local remove_all_metatables = function(item, path)
			if getmetatable(item) == nil then return item end
		end
		print(inspect(value, {process = remove_all_metatables})) 
	else
		print(value)
	end	
end

function printf(...) print(string.format(...)) end

function prints(...)
	printf("Printing: [ %s ]", tostring(...))
	print("First Level:")
	for k, v in pairs(...) do		
		printf("  %s: %s", tostring(k), type(v)=='table' and type(v) or tostring(v))
	end
	print("Done!")
end

function ioclear() -- ANSI clear screen (call once to clear)
	io.write("\027[2J")
end

function iohome() -- ANSI home cursor (call to update)
	io.write("\027[H")
end

function nfc(num)
    return tostring(num):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

function eo(a, b, c) -- entweder oder lol
	if c then return a
	else return b end
end

function map(value, start1, stop1, start2, stop2)
     return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1));
end

function constrain(value, start, stop)
    if value > stop then return stop
    elseif value < start then return start
    else return value end
end

function nt(s) -- remove tabs from string
	return s:gsub("\t", "")
end

function formatTimeA(timeInSeconds)
    if timeInSeconds < 0.000001 then
        return ">1ms"
    elseif timeInSeconds < 0.002 then
        return string.format("%dµs", timeInSeconds*1000000)
    elseif timeInSeconds < 2 then
        return return string.format("%dms", timeInSeconds*1000)
    else
        return string.format("%ds", timeInSeconds)
    end
end

function formatTime(timeInSeconds)
    if timeInSeconds < 0.000001 then
        return ">1μs"
    elseif timeInSeconds < 0.002 then
        local microseconds = math.floor(timeInSeconds * 1000000)
        return microseconds .. "μs"
    elseif timeInSeconds < 2 then
        local milliseconds = math.floor(timeInSeconds * 1000)
        return milliseconds .. "ms"
    else
        return timeInSeconds .. "s"
    end
end



function createVector(x, y)
	local vector_metatable = {
		__add = function(vec1, vec2)
			return { x = vec1.x + vec2.x, y = vec1.y + vec2.y }
		end,
		__sub = function(vec1, vec2)
			return { x = vec1.x - vec2.x, y = vec1.y - vec2.y }
		end,
		__mul = function(vec, scalar)
			return { x = vec.x * scalar, y = vec.y * scalar }
		end,
		__div = function(vec, scalar)
			return { x = vec.x / scalar, y = vec.y / scalar }
		end,
		__unm = function(vec)
			return { x = -vec.x, y = -vec.y }
		end,
		__eq = function(vec1, vec2)
			return vec1.x == vec2.x and vec1.y == vec2.y
		end,
		__len = function(vec)
			return math.sqrt(vec.x ^ 2 + vec.y ^ 2)
		end,
		__index = {
			dot = function(vec1, vec2)
				  return vec1.x * vec2.x + vec1.y * vec2.y
			end,
			cross = function(vec1, vec2)
				  return vec1.x * vec2.y - vec1.y * vec2.x
			end
		}
	}
	
    local vec = { x = x, y = y }
    setmetatable(vec, vector_metatable)
    return vec
end

function createBounds(x, y, width, height, scale)
	local bounds = {
		x = x,
		y = y,
		width = width,
		height = height,
		scale = scale
	}
  
	function bounds:getWidth()
	  	return self.width * self.scale
	end
  
	function bounds:getHeight()
	  	return self.height * self.scale
	end
  
	return bounds
end


--[[ 
	function love.load()
  		myTimer = createTimer(1, function() print("Hello, world!") end)
	end

	function love.update(dt)
		myTimer(dt)
	end
]]
function createTimer(interval, func)
	local t = 0
	
	return function(dt)
		t = t + dt		
		if t >= interval then
			func()
			t = t - interval
		end
	end
end  

  
timeRecordsTable = collect{}

function startTimeRecord(name_)
	local firstIndex = timeRecordsTable:search(function(key, value) return value.name == name_ end)
	if type(firstIndex) == "number" then
		timeRecordsTable.table[firstIndex].duration = 0
		timeRecordsTable.table[firstIndex].endTime = 0
		timeRecordsTable.table[firstIndex].startTime = love.timer.getTime()
	else
		timeRecordsTable:append{ name=name_, startTime=love.timer.getTime(), endTime=0, duration=0 }
	end
end

function stopTimeRecord(name_)
	local time = love.timer.getTime()
	local firstIndex = timeRecordsTable:search(function(key, value) return value.name == name_ end)
	if type(firstIndex) == "number" then
		timeRecordsTable.table[firstIndex].endTime = time
		timeRecordsTable.table[firstIndex].duration = time - timeRecordsTable.table[firstIndex].startTime
	end
end

function printTimeRecords()
	timeRecordsTable:each(function(key, value) printf("'%s' took %.3fms\n", value.name, value.duration*1000) end)
end

printHistory = collect{}
isCleared = false

function printc(msg_)	
	local firstIndex = printHistory:search(function(key, value) return value.msg == msg_ end)
	local refresh = false
	if type(firstIndex) == "number" then
		local c = printHistory.table[firstIndex].count
		if c < 100 then
			printHistory.table[firstIndex].count = c+1
			refresh = true
		end
	else
		printHistory:append{ msg=msg_, count=1 }
	end
	if refresh then
		if not isCleared then io.write("\027[2J") print() isCleared=true end
		io.write("\027[H")
		printHistory:each(function(key, value) printf("%s(%d)\n", value.msg, value.count) end)
	end
end


function printONCE(msg_)
	file = io.open("debug.log", "w")
	file:write(msg_)
	file:close()
	os.exit()
end