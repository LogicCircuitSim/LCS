local version = '1.9.8'

function love.conf(t)
    t.title = "L.C.S. - Version "..version
    t.author = "Noah"

    local resolutions = {
        HD  = {1280,  720},
        FHD = {1920, 1080},
        QHD = {2560, 1440}
    }
    t.window.width, t.window.height = unpack(resolutions['HD'])
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