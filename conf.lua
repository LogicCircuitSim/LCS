local settings = require('settings')
local version = settings.version
local res = settings.resolution or 'HD'

function love.conf(t)
    t.title = "L.C.S. - Version "..version.." - Von Noah, David und Samuel"
    t.author = "Noah, David and Samuel"
    t.console = true
    t.identity = "LCS_SAVE_2"
    
    local resolutions = {
        HD  = {1280,  720},
        FHD = {1920, 1080},
        QHD = {2560, 1440},
        UHD = {3840, 2160}
    }
    t.window.width, t.window.height = unpack(resolutions[res])
    t.window.resizable = true
    t.window.msaa = 8
    t.window.vsync = false
    t.window.usedpiscale = false
    t.window.borderless = false

    t.modules.audio = false
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.sound = false
    t.modules.touch = false
end