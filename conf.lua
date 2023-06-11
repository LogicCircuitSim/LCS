local version = "1.8.3"

function love.conf(t)
    t.title = "L.C.S. - Version "..version.." - Von Noah, David und Samuel"
    t.author = "Noah, David and Samuel"
    t.console = true
    t.identity = "LCS_SAVE_2"
    
    -- t.window.width, t.window.height = 1280, 720
    t.window.width, t.window.height = 1920, 1080
    t.window.resizable = true
    t.window.msaa = 8
    t.window.vsync = false
    t.window.usedpiscale = false

    t.modules.audio = false
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.sound = false
    t.modules.touch = false
end