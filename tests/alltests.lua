log = require'log'
log.outfile = 'alltests.log'

success = true
log.info'Running classes test'
classestestresult = dofile'classes_test.lua'
log.info'Done running classes test'
if not classestestresult then
    success = false
    log.error'classes test failed'
end



log.info'Done running all tests'
if success then
    log.info'All tests passed'
else
    log.error'Some tests failed'
end

log.info'Exiting'