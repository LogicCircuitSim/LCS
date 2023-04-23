function love.conf(t)
    t.title = "LCS - Von Noah, David und Samuel"
    t.author = "Noah, David and Samuel"

    -- t.window.width, t.window.height = 1280, 720
    t.window.width, t.window.height = 1920, 1080
    t.window.resizable = true
    t.window.msaa = 8
    t.window.vsync = false

    t.modules.audio = false
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.sound = false
    t.modules.touch = false
end