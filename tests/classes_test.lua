log = require'log'
-- log.outfile = 'classes test.log'
log.level = 'debug'

--------------------------------------------------------------------------

log.debug'add lib to package.path'

local dir = io.popen"cd":read'*l'
local parentdir = string.sub(dir, 1, string.find(dir, "\\[^\\]*$")-1)
package.path = parentdir .. "\\?.lua;" .. package.path

log.debug'Done!'

--------------------------------------------------------------------------

log.debug'require classes'

local classes = require'classes'
if not classes then
    log.error'classes not loaded'
    return false
end

log.debug'Done!'

--------------------------------------------------------------------------

log.debug'IDs before creating objects'

log.debug('GATE: ' .. classes.GATE.ID)
log.debug('AND: ' .. classes.AND.ID)
log.debug('OR: ' .. classes.OR.ID)
log.debug('NOT: ' .. classes.NOT.ID)
log.debug('XOR: ' .. classes.XOR.ID)

log.debug('PERIPHERAL: ' .. classes.PERIPHERAL.ID)
log.debug('INPUT: ' .. classes.INPUT.ID)
log.debug('OUTPUT: ' .. classes.OUTPUT.ID)
log.debug('CLOCK: ' .. classes.CLOCK.ID)
log.debug('BUFFER: ' .. classes.BUFFER.ID)

log.debug'Done!'

--------------------------------------------------------------------------

log.debug'create Gates'

local gate = classes.GATE(100, 100)
local gate2 = classes.GATE(100, 200)
local andGate = classes.AND(100, 100)
local orGate = classes.OR(100, 200)
local notGate = classes.NOT(100, 300)
local xorGate = classes.XOR(100, 400)
local xorGate = classes.XNOR(100, 500)
local xorGate = classes.NAND(100, 600)

log.debug'Done!'

--------------------------------------------------------------------------

log.debug'create Peripherals'
-- create dummy function for getTime()
love = { timer = { getTime = function() return 0 end } }

local peripheral = classes.PERIPHERAL(100, 100)
local input = classes.INPUT(100, 100)
local output = classes.OUTPUT(100, 200)
local clock = classes.CLOCK(100, 300)
local buffer = classes.BUFFER(100, 400)

log.debug'Done!'

--------------------------------------------------------------------------

log.debug'check if Gates are not nil'

if not gate then
    log.error'gate is nil'
    return false
end
if not andGate then
    log.error'andGate is nil'
    return false
end
if not orGate then
    log.error'orGate is nil'
    return false
end
if not notGate then
    log.error'notGate is nil'
    return false
end
if not xorGate then
    log.error'xorGate is nil'
    return false
end

log.debug'Done!'

--------------------------------------------------------------------------

log.debug'check if ids are unique'

log.debug('GATE.ID = \t' .. classes.GATE.ID)
log.debug('gate.id = \t' .. gate.id)
log.debug('gate2.id = \t' .. gate2.id)
log.debug('andGate.id = \t' .. andGate.id)
log.debug('orGate.id = \t' .. orGate.id)
log.debug('notGate.id = \t' .. notGate.id)
log.debug('xorGate.id = \t' .. xorGate.id)

if gate.id == andGate.id then
    log.error'gate.id == andGate.id'
    return false
end
if andGate.id == orGate.id then
    log.error'andGate.id == orGate.id'
    return false
end

log.debug'Done!'

--------------------------------------------------------------------------

log.debug'static methods for Dimensions'

local gateHeight = classes.GATE:getHeight(1)
local gateHeightNoArgs = classes.GATE:getHeight()

log.debug'Done!'

--------------------------------------------------------------------------

log.debug'instance methods for Dimensions'

local gateHeightInstance = gate:getHeight(1)
local gateHeightInstanceNoArgs = gate:getHeight()
gate:getWidth()

log.debug'Done!'

--------------------------------------------------------------------------



return true