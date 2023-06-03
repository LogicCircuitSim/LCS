log = require'log'
log.outfile = 'classes test.log'

log.info'add lib to package.path'
local currentDir = io.popen"cd":read'*l'c
log.debug('dir of this file is', currentDir)

package.path = currentDir .. "\\..\\lib\\?.lua;" .. package.path


log.info'require classes'
local classes = require'newclasses'
log.info'classes required'
if not classes then
    log.error'classes not loaded'
    return false
end


return true