log = require'log'
log.outfile = 'alltests.log'


success = true
log.debug'Running classes test'
classestestresult = dofile'classes_test.lua'
log.debug'Done running classes test'
if not classestestresult then
    success = false
    log.error'classes test failed'
else
    log.info'classes test passed'
end




if success then
    log.info'Done running all tests'
    log.info'All tests passed'
    log.info'Exiting'
else
    log.error'Done running all tests'
    log.error'Some tests failed'
end
