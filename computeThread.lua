require 'love.math'
require 'love.timer'
require 'noahsutils'
-- require 'classes'
local json = require 'json'

local args = ...

local upsCounter, last = 0, love.timer.getTime()
local maxUps, maxReached = args, false
local timePerUpdate, lastTime = 0, 0


local gates = Collection:new()
local peripherals = Collection:new()
local connections = Collection:new()
local groups = Collection:new()


-- function getBobjects()
-- 	return gates:merge(peripherals:all())
-- end

-- function myConnections()
-- 	local index = 0
-- 	return function()
-- 		index = index + 1
-- 		local con = connections:get(index)
-- 		if con ~= nil and con.inputpin ~= nil and con.outputpin ~= nil then
-- 			return con, index
-- 		end
-- 	end
-- end
-- function myBobjects()
-- 	local index = 0
-- 	local bobjects = getBobjects()
-- 	return function()
-- 		index = index + 1
-- 		if bobjects:get(index) ~= nil then
-- 			return bobjects:get(index), index
-- 		end
-- 	end
-- end
-- function myGates()
-- 	local index = 0
-- 	return function()
-- 		index = index + 1
-- 		local gate = gates:get(index)
-- 		if (gate ~= nil) and (gate.type == "GATE") then
-- 			return gate, index
-- 		end
-- 	end
-- end
-- function myPeripherals()
-- 	local index = 0
-- 	return function()
-- 		index = index + 1
-- 		local per = peripherals:get(index)
-- 		if (per ~= nil) and (per.type == "PERIPHERAL") then
-- 			return per, index
-- 		end
-- 	end
-- end
-- -- tests
-- function printDebug()
--     print()
--     print(string.format("UPS: %d / %d [trueUPS: %s with %s]", 
--         upsCounter, 
--         maxUps, nfc(math.floor(1.0 / timePerUpdate)),
--         formatTime(timePerUpdate)
--     ))
--     print()

--     print("bobjects: ", getBobjects():count())
--     prinspect(getBobjects():all())
--     print("gates: ", gates:count())
--     prinspect(gates:all())
--     print("peripherals: ", peripherals:count())
--     prinspect(peripherals:all())
--     print("connections: ", connections:count())
--     print()
    
--     print("gate queue: ", love.thread.getChannel("addGate"):getCount())
-- end

local setupDone = love.thread.getChannel("setup"):demand()

-- add all gates in addGate channel queue
local gate = love.thread.getChannel("addGate"):pop()
print("gate: ", gate)
-- print("decoded gate: ", json.decode(gate))
-- while gate ~= nil do
--     gates:append(loadGATE(json.decode(gate)))
--     gate = love.thread.getChannel("addGate"):pop()
-- end

-- -- add all peripherals in addPeripheral channel queue
-- local peripheral = love.thread.getChannel("addPeripheral"):pop()
-- while peripheral ~= nil do
--     peripherals:append(loadPERIPHERAL(json.decode(peripheral)))
--     peripheral = love.thread.getChannel("addPeripheral"):pop()
-- end

-- -- add all connections in addConnection channel queue
-- local connection = love.thread.getChannel("addConnection"):pop()
-- while connection ~= nil do
--     connections:append(json.decode(connection))
--     connection = love.thread.getChannel("addConnection"):pop()
-- end


-- printDebug()

while false do
    -- check if we should kill the thread
	if love.thread.getChannel("kill"):pop() == true then return end

    if love.thread.getChannel("printDebug"):pop() then
        printDebug()
    end
    
    if not maxReached then
        -- add all gates in addGate channel queue
        -- local gate = love.thread.getChannel("addGate"):pop()
        -- while gate ~= nil do
        --     gates:append(gate)
        --     gate = love.thread.getChannel("addGate"):pop()
        -- end

        -- -- add all peripherals in addPeripheral channel queue
        -- local peripheral = love.thread.getChannel("addPeripheral"):pop()
        -- while peripheral ~= nil do
        --     peripherals:append(peripheral)
        --     peripheral = love.thread.getChannel("addPeripheral"):pop()
        -- end

        -- -- add all connections in addConnection channel queue
        -- local connection = love.thread.getChannel("addConnection"):pop()
        -- while connection ~= nil do
        --     connections:append(connection)
        --     connection = love.thread.getChannel("addConnection"):pop()
        -- end

        -- for bob in myBobjects() do bob:update() end

        -- for con in myConnections() do
		-- 	con.inputpin.state = con.outputpin.state
		-- end

        upsCounter = upsCounter + 1
    end

    -- check if we reached the max ups
    if upsCounter >= maxUps then
        maxReached = true
    end   

    -- push the ups to the channel and reset maxReached
    if love.timer.getTime() - last >= 1 then
        love.thread.getChannel("ups"):push(upsCounter)
        upsCounter = 0
        maxReached = false
        last = love.timer.getTime()
    end

    -- calc the time per update
    timePerUpdate = love.timer.getTime() - lastTime
    lastTime = love.timer.getTime()
end

print("[WARNING] computeThread.lua: Exiting")