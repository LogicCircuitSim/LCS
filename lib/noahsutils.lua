io.stdout:setvbuf("no")
inspect = require "lib.inspect"
Collection = require "lib.collections"
usingSublime = false

function prinspect(...)
	local ram = function(item, path)
		if path[#path] ~= inspect.METATABLE then return item end
	end
	local test = function(item, path)
		-- if #path > 0 then
		-- 	if not path[#path]:match("__") then return item end
		-- end
		return item
	end
	print(inspect(..., {process = test})) 
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
	if not usingSublime then
		io.write("\027[2J")
	end
end

function iohome() -- ANSI home cursor (call to update)
	if not usingSublime then
		io.write("\027[H")
	end
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

function clamp(v, M, m)
	return (v > M and M or v) < m and m or v
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

function printc(msg_) -- print compressed, no spam, NOT WORKING IN THE SUBLIME CONSOLE LOL
	if usingSublime then
		local firstIndex = printHistory:search(function(key, value) return value.msg == msg_ end)
		if type(firstIndex) ~= "number" then
			printHistory:append{ msg=msg_ }
			printf("%s\n", msg_)
		end
	else
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
			if not isCleared then ioclear() print() isCleared=true end
			iohome()
			printHistory:each(function(key, value) printf("%s(%d)\n", value.msg, value.count) end)
		end
	end
end

function printBetter(msg_)
	local firstIndex = printHistory:search(function(key, value) return value.msg == msg_ end)
	if type(firstIndex) == "number" then
		local c = printHistory.table[firstIndex].count
		if c < 100 then
			printHistory.table[firstIndex].count = c+1
		end
	else
		printHistory:append{ msg=msg_, count=1 }
	end
end

function getBetterPrint()
	local result = collect{}	
	printHistory:each(function(key, value) result:append(string.format("%s(%d)\n", value.msg, value.count)) end)
	return table.concat(result:all(), "")
end

function printOnce(msg_)
	local firstIndex = printHistory:search(function(key, value) return value.msg == msg_ end)
	if type(firstIndex) ~= "number" then
		printHistory:append{ msg=msg_ }
		printf("%s\n", msg_)
	end
end

function printONCE(msg_)
	file = io.open("debug.log", "w")
	file:write(msg_)
	file:close()
	os.exit()
end

