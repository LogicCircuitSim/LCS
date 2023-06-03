io.stdout:setvbuf("no")
inspect = require "inspect"
lume = require "lume"

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

function ioclear() -- ANSI clear screen (call once to clear)
    io.write("\027[2J")
end

function iohome() -- ANSI home cursor (call to update)
    io.write("\027[H")
end

function nfc(num)
    return tostring(num):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

function nt(s) -- remove tabs from string
    return s:gsub("\t", "")
end

-- {0.5,0.5,0.5}, {0.5,0.5,0.5}, {1,1,1}, {0,1/3,2/3}
function gradient(t, a, b, c, d)
    local a1, a2, a3 = a[1], a[2], a[3]
    local b1, b2, b3 = b[1], b[2], b[3]
    local c1, c2, c3 = c[1], c[2], c[3]
    local d1, d2, d3 = d[1], d[2], d[3]

    local pi = math.pi
    local cos1 = math.cos(2 * pi * (c1 * t + d1))
    local cos2 = math.cos(2 * pi * (c2 * t + d2))
    local cos3 = math.cos(2 * pi * (c3 * t + d3))

    local result1 = a1 + b1 * cos1
    local result2 = a2 + b2 * cos2
    local result3 = a3 + b3 * cos3

    return result1, result2, result3
end

-- vec2_metatable = {
--     __add = function(vec1, vec2)
--         local newvec = {x = vec1.x + vec2.x, y = vec1.y + vec2.y}
--         setmetatable(newvec, vec2_metatable)
--         return newvec
--     end,
--     __sub = function(vec1, vec2)
--         local newvec = {x = vec1.x - vec2.x, y = vec1.y - vec2.y}
--         setmetatable(newvec, vec2_metatable)
--         return newvec
--     end,
--     __mul = function(vec, scalar)
--         local newvec = {x = vec.x * scalar, y = vec.y * scalar}
--         setmetatable(newvec, vec2_metatable)
--         return newvec
--     end,
--     __div = function(vec, scalar)
--         local newvec = {x = vec.x / scalar, y = vec.y / scalar}
--         setmetatable(newvec, vec2_metatable)
--         return newvec
--     end,
--     __unm = function(vec)
--         local newvec = {x = -vec.x, y = -vec.y}
--         setmetatable(newvec, vec2_metatable)
--         return newvec
--     end,
--     __eq = function(vec1, vec2) return vec1.x == vec2.x and vec1.y == vec2.y end,
--     __len = function(vec) return math.sqrt(vec.x ^ 2 + vec.y ^ 2) end,
--     __index = {
--         dot = function(vec1, vec2)
--             return vec1.x * vec2.x + vec1.y * vec2.y
--         end,
--         cross = function(vec1, vec2)
--             return vec1.x * vec2.y - vec1.y * vec2.x
--         end
--     }
-- }

-- function vec2(x, y)
--     local vec = {x = x, y = y}
--     setmetatable(vec, vec2_metatable)
--     return vec
-- end

vector_metatable = {
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

function create_vector(x, y)
    local vec = { x = x, y = y }
    setmetatable(vec, vector_metatable)
    return vec
end

function createBounds(x, y, width, height, scale)
    local bounds = {x = x, y = y, width = width, height = height, scale = scale}

    function bounds:getWidth() return self.width * self.scale end

    function bounds:getHeight() return self.height * self.scale end

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

function formatTimeA(timeInSeconds)
    if timeInSeconds < 0.000001 then
        return ">1ms"
    elseif timeInSeconds < 0.002 then
        return string.format("%dµs", timeInSeconds * 1000000)
    elseif timeInSeconds < 2 then
        return string.format("%dms", timeInSeconds * 1000)
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

timeRecordsTable = collect {}

function startTimeRecord(name_)
    local firstIndex = timeRecordsTable:search(
		function(key, value)
            return value.name == name_
        end)
    if type(firstIndex) == "number" then
        timeRecordsTable.table[firstIndex].duration = 0
        timeRecordsTable.table[firstIndex].endTime = 0
        timeRecordsTable.table[firstIndex].startTime = love.timer.getTime()
    else
        timeRecordsTable:append{
            name = name_,
            startTime = love.timer.getTime(),
            endTime = 0,
            duration = 0
        }
    end
end

function stopTimeRecord(name_)
    local time = love.timer.getTime()
    local firstIndex = timeRecordsTable:search(
                           function(key, value)
            return value.name == name_
        end)
    if type(firstIndex) == "number" then
        timeRecordsTable.table[firstIndex].endTime = time
        timeRecordsTable.table[firstIndex].duration = time - timeRecordsTable.table[firstIndex].startTime
    end
end

function printTimeRecords()
    timeRecordsTable:each(function(key, value)
        printf("'%s' took %.3fms\n", value.name, value.duration * 1000)
    end)
end