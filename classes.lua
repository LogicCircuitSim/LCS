local lume = require("lib.lume")
local printCentered
printCentered = function(text, x, y, rows)
  if rows == nil then
    rows = 1
  end
  local font = love.graphics.getFont()
  return love.graphics.print(text, x - (font:getWidth(text) / 2), y - (font:getHeight() / (1 + rows)))
end
graphicSettings = {
  betterGraphics = true,
  gateUseStateColors = false,
  gateStateColors = {
    ON = {
      0.06,
      0.65,
      0.16
    },
    OFF = {
      0.51,
      0.19,
      0.29
    }
  },
  gateColor = {
    0.18,
    0.18,
    0.18
  },
  gateBorderRounding = 3,
  gateBorderWidth = 1.5,
  gateBorderColor = {
    0.35,
    0.35,
    0.35
  },
  gateBorderColorAlt = {
    0.08,
    0.08,
    0.08
  },
  gateUseAltBorderColor = false,
  gateDropshadowOffset = 7,
  gateDropshadowColor = {
    0.05,
    0.05,
    0.05,
    0.8
  },
  gateDropshadowRounding = 4,
  gatePinSize = 5.5,
  gatePinColor = {
    ON = {
      0.47,
      0.47,
      0.47
    },
    OFF = {
      0.13,
      0.13,
      0.13
    }
  }
}
local vec2
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, x, y)
      self.x = x
      self.y = y
    end,
    __base = _base_0,
    __name = "vec2"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  vec2 = _class_0
end
local PIN
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, parentID)
      self.id = self.__class:newID()
      self.parentID = parentID
      self.state = false
      self.pos = vec2(0, 0)
      self.isConnected = false
    end,
    __base = _base_0,
    __name = "PIN"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.ID = 0
  self.newID = function(self)
    PIN.ID = PIN.ID + 1
    return PIN.ID
  end
  PIN = _class_0
end
local INPUTPIN
do
  local _class_0
  local _parent_0 = PIN
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, parentID)
      return _class_0.__parent.__init(self, parentID)
    end,
    __base = _base_0,
    __name = "INPUTPIN",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  INPUTPIN = _class_0
end
local OUTPUTPIN
do
  local _class_0
  local _parent_0 = PIN
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, parentID)
      return _class_0.__parent.__init(self, parentID)
    end,
    __base = _base_0,
    __name = "OUTPUTPIN",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  OUTPUTPIN = _class_0
end
local BOARDOBJECT
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, x, y)
      self.pos = vec2(x, y)
    end,
    __base = _base_0,
    __name = "BOARDOBJECT"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  BOARDOBJECT = _class_0
end
local GATE
do
  local _class_0
  local _parent_0 = BOARDOBJECT
  local _base_0 = {
    update = function(self) end,
    drawMe = function(self) end,
    draw = function(self)
      love.graphics.setColor(graphicSettings.gateDropshadowColor)
      local height = self:getHeight(self.inputpincount)
      love.graphics.rectangle("fill", self.pos.x + graphicSettings.gateDropshadowOffset, self.pos.y + graphicSettings.gateDropshadowOffset, self:getWidth(), height, graphicSettings.gateDropshadowRounding)
      if graphicSettings.gateUseStateColors then
        if self.state then
          love.graphics.setColor(graphicSettings.gateStateColors.ON)
        else
          love.graphics.setColor(graphicSettings.gateStateColors.OFF)
        end
      else
        love.graphics.setColor(graphicSettings.gateColor)
      end
      love.graphics.rectangle("fill", self.pos.x, self.pos.y, self:getWidth(), height, graphicSettings.betterGraphics and graphicSettings.gateBorderRounding or nil)
      love.graphics.setColor(graphicSettings.gateUseAltBorderColor and graphicSettings.gateBorderColorAlt or graphicSettings.gateBorderColor)
      love.graphics.setLineWidth(graphicSettings.gateBorderWidth)
      love.graphics.rectangle("line", self.pos.x, self.pos.y, self:getWidth(), height, graphicSettings.betterGraphics and graphicSettings.gateBorderRounding or nil)
      for i = 1, self.inputpincount do
        local pin = self.inputpins[i]
        if pin then
          local ypos = self.pos.y + (self.__class.size.space * 2) + ((self.__class.size.space * 3) * (i - 1))
          if pin.isConnected then
            love.graphics.setColor(graphicSettings.gatePinColor.ON)
          else
            love.graphics.setColor(graphicSettings.gatePinColor.OFF)
          end
          love.graphics.circle("fill", self.pos.x, ypos, graphicSettings.gatePinSize)
          love.graphics.setLineWidth(1)
          love.graphics.setColor(1, 1, 1)
          love.graphics.circle("line", self.pos.x, ypos, graphicSettings.gatePinSize)
          pin.pos = vec2(self.pos.x, ypos)
        end
      end
      if self.outputpin.isConnected then
        love.graphics.setColor(graphicSettings.gatePinColor.ON)
      else
        love.graphics.setColor(graphicSettings.gatePinColor.OFF)
      end
      love.graphics.circle("fill", self.pos.x + self:getWidth(), self.pos.y + (height / 2), graphicSettings.gatePinSize)
      love.graphics.setLineWidth(1)
      love.graphics.setColor(1, 1, 1)
      love.graphics.circle("line", self.pos.x + self:getWidth(), self.pos.y + (height / 2), graphicSettings.gatePinSize)
      self.outputpin.pos = vec2(self.pos.x + self:getWidth(), self.pos.y + (height / 2))
      return self:drawMe()
    end,
    resetPins = function(self)
      for i = 1, self.inputpincount do
        self.inputpins[i].state = false
      end
    end,
    addPin = function(self)
      self.inputpincount = self.inputpincount + 1
      return table.insert(self.inputpins, INPUTPIN(self.id))
    end,
    removePin = function(self)
      if self.inputpincount > 2 then
        self.inputpincount = self.inputpincount - 1
        return table.remove(self.inputpins, self.inputpincount)
      end
    end,
    isInside = function(self, x, y)
      local width, height = self:getWidth(), self:getHeight(self.inputpincount)
      return x >= self.pos.x and x <= self.pos.x + width and y >= self.pos.y and y <= self.pos.y + height
    end,
    getInputPinAt = function(self, x, y)
      local piny = self.pos.y + self.__class.size.space * 2
      for i = 1, self.inputpincount do
        if lume.distance(x, y, self.pos.x, piny, false) < 10 then
          return self.inputpins[i]
        end
        piny = piny + (self.__class.size.space * 3)
      end
    end,
    getOutputPinAt = function(self, x, y)
      if lume.distance(x, y, self.pos.x + self:getWidth(), self.pos.y + self:getHeight(self.inputpincount) / 2, false) < 10 then
        return self.outputpin
      end
    end,
    getInputPinByID = function(self, id)
      for i = 1, self.inputpincount do
        if self.inputpins[i].id == id then
          return self.inputpins[i]
        end
      end
    end,
    getOutputPinByID = function(self, id)
      if self.outputpin.id == id then
        return self.outputpin
      end
    end,
    getAllPins = function(self)
      local pins = { }
      for i = 1, self.inputpincount do
        table.insert(pins, self.inputpins[i])
      end
      table.insert(pins, self.outputpin)
      return pins
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, x, y, inputpincount)
      if inputpincount == nil then
        inputpincount = 2
      end
      _class_0.__parent.__init(self, x, y)
      self.id = self.__class:newID()
      self.state = false
      self.inputpincount = inputpincount
      self.inputpins = { }
      for i = 1, self.inputpincount do
        table.insert(self.inputpins, INPUTPIN(self.id))
      end
      self.outputpin = OUTPUTPIN(self.id)
      self.getWidth = function(self)
        return self.__class.size.width * self.__class.size.scale
      end
      self.getHeight = function(self)
        return self.__class.size.space * (4 + (3 * (self.inputpincount - 1))) * (self.__class.size.scale / 7)
      end
    end,
    __base = _base_0,
    __name = "GATE",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.ID = 1000
  self.newID = function(self)
    GATE.ID = GATE.ID + 1
    return GATE.ID
  end
  self.size = {
    width = 9,
    height = 14,
    scale = 7,
    space = 10
  }
  self.getWidth = function(self)
    return self.__class.size.width * self.__class.size.scale
  end
  self.getHeight = function(self, inputpincount)
    if inputpincount == nil then
      inputpincount = 2
    end
    return self.__class.size.space * (4 + (3 * (inputpincount - 1))) * (self.__class.size.scale / 7)
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  GATE = _class_0
end
local PERIPHERAL
do
  local _class_0
  local _parent_0 = BOARDOBJECT
  local _base_0 = {
    update = function(self) end,
    drawMe = function(self) end,
    draw = function(self)
      love.graphics.setColor(graphicSettings.gateDropshadowColor)
      local height = self.__class:getHeight()
      love.graphics.rectangle("fill", self.pos.x + graphicSettings.gateDropshadowOffset, self.pos.y + graphicSettings.gateDropshadowOffset, self.__class:getWidth(), height, graphicSettings.gateDropshadowRounding)
      if self.state then
        love.graphics.setColor(graphicSettings.gateStateColors.ON)
      else
        love.graphics.setColor(graphicSettings.gateStateColors.OFF)
      end
      love.graphics.rectangle("fill", self.pos.x, self.pos.y, self.__class:getWidth(), height, graphicSettings.betterGraphics and graphicSettings.gateBorderRounding or nil)
      love.graphics.setColor(graphicSettings.gateUseAltBorderColor and graphicSettings.gateBorderColorAlt or graphicSettings.gateBorderColor)
      love.graphics.setLineWidth(graphicSettings.gateBorderWidth)
      love.graphics.rectangle("line", self.pos.x, self.pos.y, self.__class:getWidth(), height, graphicSettings.betterGraphics and graphicSettings.gateBorderRounding or nil)
      if self.hasinputpin then
        local xpos, ypos = self.pos.x, self.pos.y + (height / 2)
        if self.inputpin.isConnected then
          love.graphics.setColor(graphicSettings.gatePinColor.ON)
        else
          love.graphics.setColor(graphicSettings.gatePinColor.OFF)
        end
        love.graphics.circle("fill", xpos, ypos, graphicSettings.gatePinSize)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("line", xpos, ypos, graphicSettings.gatePinSize)
        self.inputpin.pos = vec2(xpos, ypos)
      end
      if self.hasoutputpin then
        local xpos, ypos = self.pos.x + self.__class:getWidth(), self.pos.y + (height / 2)
        if self.outputpin.isConnected then
          love.graphics.setColor(graphicSettings.gatePinColor.ON)
        else
          love.graphics.setColor(graphicSettings.gatePinColor.OFF)
        end
        love.graphics.circle("fill", xpos, ypos, graphicSettings.gatePinSize)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("line", xpos, ypos, graphicSettings.gatePinSize)
        self.outputpin.pos = vec2(xpos, ypos)
      end
      return self:drawMe()
    end,
    resetPins = function(self)
      if self.hasinputpin then
        self.inputpin.state = false
      end
    end,
    set = function(self, state)
      self.state = state
    end,
    flip = function(self)
      self.state = not self.state
    end,
    isInside = function(self, x, y)
      return x >= self.pos.x and x <= self.pos.x + self.__class:getWidth() and y >= self.pos.y and y <= self.pos.y + self.__class:getHeight()
    end,
    getInputPinAt = function(self, x, y)
      if lume.distance(x, y, self.pos.x, self.pos.y + (self.__class:getHeight() / 2)) < 10 then
        return self.inputpin
      end
    end,
    getOutputPinAt = function(self, x, y)
      if lume.distance(x, y, self.pos.x + self.__class:getWidth(), self.pos.y + (self.__class:getHeight() / 2)) < 10 then
        return self.outputpin
      end
    end,
    getInputPinByID = function(self, id)
      if self.hasinputpin and self.inputpin.id == id then
        return self.inputpin
      end
    end,
    getOutputPinByID = function(self, id)
      if self.hasoutputpin and self.outputpin.id == id then
        return self.outputpin
      end
    end,
    getAllPins = function(self)
      return {
        self.inputpin,
        self.outputpin
      }
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, x, y, inputpincount, outputpincount)
      if inputpincount == nil then
        inputpincount = 0
      end
      if outputpincount == nil then
        outputpincount = 0
      end
      _class_0.__parent.__init(self, x, y)
      self.id = self.__class:newID()
      self.hasinputpin = inputpincount > 0
      self.hasoutputpin = outputpincount > 0
      if self.hasinputpin then
        self.inputpin = INPUTPIN(self.id)
      end
      if self.hasoutputpin then
        self.outputpin = OUTPUTPIN(self.id)
      end
      self.state = false
      self.getWidth = function(self)
        return self.__class.size.width * self.__class.size.scale
      end
      self.getHeight = function(self)
        return self.__class.size.space * 4 * (self.__class.size.scale / 7)
      end
    end,
    __base = _base_0,
    __name = "PERIPHERAL",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.ID = 2000
  self.newID = function(self)
    PERIPHERAL.ID = PERIPHERAL.ID + 1
    return PERIPHERAL.ID
  end
  self.size = {
    width = 12,
    height = 14,
    scale = 7,
    space = 10
  }
  self.getWidth = function(self)
    return self.__class.size.width * self.__class.size.scale
  end
  self.getHeight = function(self)
    return self.__class.size.space * 4 * (self.__class.size.scale / 7)
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  PERIPHERAL = _class_0
end
local AND
do
  local _class_0
  local _parent_0 = GATE
  local _base_0 = {
    drawMe = function(self)
      love.graphics.setColor(1, 1, 1)
      return printCentered("AND", self.pos.x + (self.__class:getWidth() / 2), self.pos.y + (self.__class:getHeight(self.inputpincount) / 2))
    end,
    update = function(self)
      local newstate = true
      for i = 1, self.inputpincount do
        if not self.inputpins[i].state then
          newstate = false
        end
      end
      self.state = newstate
      self.outputpin.state = self.state
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, x, y, inputpincount)
      _class_0.__parent.__init(self, x, y, inputpincount)
      self.name = "AND"
    end,
    __base = _base_0,
    __name = "AND",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  AND = _class_0
end
local OR
do
  local _class_0
  local _parent_0 = GATE
  local _base_0 = {
    drawMe = function(self)
      love.graphics.setColor(1, 1, 1)
      return printCentered("OR", self.pos.x + (self.__class:getWidth() / 2), self.pos.y + (self.__class:getHeight(self.inputpincount) / 2))
    end,
    update = function(self)
      local newstate = false
      for i = 1, self.inputpincount do
        if self.inputpins[i].state then
          newstate = true
        end
      end
      self.state = newstate
      self.outputpin.state = self.state
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, x, y, inputpincount)
      _class_0.__parent.__init(self, x, y, inputpincount)
      self.name = "OR"
    end,
    __base = _base_0,
    __name = "OR",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  OR = _class_0
end
local NAND
do
  local _class_0
  local _parent_0 = GATE
  local _base_0 = {
    drawMe = function(self)
      love.graphics.setColor(1, 1, 1)
      return printCentered("NAND", self.pos.x + (self.__class:getWidth() / 2), self.pos.y + (self.__class:getHeight(self.inputpincount) / 2))
    end,
    update = function(self)
      local newstate = true
      for i = 1, self.inputpincount do
        if not self.inputpins[i].state then
          newstate = false
        end
      end
      self.state = not newstate
      self.outputpin.state = self.state
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, x, y, inputpincount)
      _class_0.__parent.__init(self, x, y, inputpincount)
      self.name = "NAND"
    end,
    __base = _base_0,
    __name = "NAND",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  NAND = _class_0
end
local NOR
do
  local _class_0
  local _parent_0 = GATE
  local _base_0 = {
    drawMe = function(self)
      love.graphics.setColor(1, 1, 1)
      return printCentered("NOR", self.pos.x + (self.__class:getWidth() / 2), self.pos.y + (self.__class:getHeight(self.inputpincount) / 2))
    end,
    update = function(self)
      local newstate = false
      for i = 1, self.inputpincount do
        if self.inputpins[i].state then
          newstate = true
        end
      end
      self.state = not newstate
      self.outputpin.state = self.state
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, x, y, inputpincount)
      _class_0.__parent.__init(self, x, y, inputpincount)
      self.name = "NOR"
    end,
    __base = _base_0,
    __name = "NOR",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  NOR = _class_0
end
local XOR
do
  local _class_0
  local _parent_0 = GATE
  local _base_0 = {
    drawMe = function(self)
      love.graphics.setColor(1, 1, 1)
      return printCentered("XOR", self.pos.x + (self.__class:getWidth() / 2), self.pos.y + (self.__class:getHeight(self.inputpincount) / 2))
    end,
    update = function(self)
      local newstate = false
      for i = 1, self.inputpincount do
        if self.inputpins[i].state then
          newstate = not newstate
        end
      end
      self.state = newstate
      self.outputpin.state = self.state
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, x, y, inputpincount)
      _class_0.__parent.__init(self, x, y, inputpincount)
      self.name = "XOR"
    end,
    __base = _base_0,
    __name = "XOR",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  XOR = _class_0
end
local XNOR
do
  local _class_0
  local _parent_0 = GATE
  local _base_0 = {
    drawMe = function(self)
      love.graphics.setColor(1, 1, 1)
      return printCentered("XNOR", self.pos.x + (self.__class:getWidth() / 2), self.pos.y + (self.__class:getHeight(self.inputpincount) / 2))
    end,
    update = function(self)
      local newstate = true
      for i = 1, self.inputpincount do
        if self.inputpins[i].state then
          newstate = not newstate
        end
      end
      self.state = newstate
      self.outputpin.state = self.state
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, x, y, inputpincount)
      _class_0.__parent.__init(self, x, y, inputpincount)
      self.name = "XNOR"
    end,
    __base = _base_0,
    __name = "XNOR",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  XNOR = _class_0
end
local NOT
do
  local _class_0
  local _parent_0 = GATE
  local _base_0 = {
    drawMe = function(self)
      love.graphics.setColor(1, 1, 1)
      return printCentered("NOT", self.pos.x + (self.__class:getWidth() / 2), self.pos.y + (self.__class:getHeight(self.inputpincount) / 2))
    end,
    update = function(self)
      self.state = not self.inputpins[1].state
      self.outputpin.state = self.state
    end,
    removePin = function(self) end,
    addPin = function(self) end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, x, y, inputpincount)
      if inputpincount == nil then
        inputpincount = 1
      end
      _class_0.__parent.__init(self, x, y, inputpincount)
      self.name = "NOT"
    end,
    __base = _base_0,
    __name = "NOT",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  NOT = _class_0
end
local INPUT
do
  local _class_0
  local _parent_0 = PERIPHERAL
  local _base_0 = {
    update = function(self)
      self.outputpin.state = self.state
    end,
    drawMe = function(self)
      local pad = 5
      love.graphics.setColor(0, 0, 0, 0.6)
      return love.graphics.rectangle("fill", self.pos.x + pad + (self.state and self.__class:getWidth() / 2 - pad or 0), self.pos.y + pad, self.__class:getWidth() / 2 - pad, self.__class:getHeight() - pad * 2)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, x, y)
      _class_0.__parent.__init(self, x, y, 0, 1)
      self.name = "INPUT"
    end,
    __base = _base_0,
    __name = "INPUT",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  INPUT = _class_0
end
local OUTPUT
do
  local _class_0
  local _parent_0 = PERIPHERAL
  local _base_0 = {
    update = function(self)
      self.state = self.inputpin.state
    end,
    drawMe = function(self)
      love.graphics.setColor(1, 1, 1)
      return printCentered("AUSGANG", self.pos.x + (self.__class:getWidth() / 2), self.pos.y + (self.__class:getHeight() / 2))
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, x, y)
      _class_0.__parent.__init(self, x, y, 1, 0)
      self.name = "OUTPUT"
    end,
    __base = _base_0,
    __name = "OUTPUT",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  OUTPUT = _class_0
end
local BUFFER
do
  local _class_0
  local _parent_0 = PERIPHERAL
  local _base_0 = {
    update = function(self)
      if self.isBuffering then
        if self.tickcount > 0 then
          self.tickcount = self.tickcount - 1
        else
          self.state = self.inputpin.state
          self.outputpin.state = self.state
          self.isBuffering = false
        end
      else
        if self.inputpin.state ~= self.state then
          self.isBuffering = true
          self.tickcount = self.ticks
        end
      end
    end,
    getHeight = function(self)
      return self.__class.size.space * 6
    end,
    drawMe = function(self)
      love.graphics.setColor(1, 1, 1)
      return printCentered("PUFFER \n" .. tostring(self.ticks) .. " tks", self.pos.x + (self.__class:getWidth() / 2), self.pos.y + (self.__class:getHeight() / 4), 2)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, x, y, ticks)
      _class_0.__parent.__init(self, x, y, 1, 1)
      self.name = "BUFFER"
      self.ticks = ticks or 5
      self.tickcount = 0
      self.isBuffering = false
    end,
    __base = _base_0,
    __name = "BUFFER",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  BUFFER = _class_0
end
local CLOCK
do
  local _class_0
  local _parent_0 = PERIPHERAL
  local _base_0 = {
    update = function(self)
      local now = love.timer.getTime()
      if now - self.lastMicroSec > 1 / self.tickspeed then
        self.state = not self.state
        self.lastMicroSec = now
      end
      self.outputpin.state = self.state
    end,
    getHeight = function(self)
      return self.__class.size.space * 6
    end,
    drawMe = function(self)
      love.graphics.setColor(1, 1, 1)
      return printCentered("CLOCK\n" .. tostring(self.tickspeed) .. " Hz", self.pos.x + (self.__class:getWidth() / 2), self.pos.y + (self.__class:getHeight() / 4), 2)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, x, y, tickspeed)
      _class_0.__parent.__init(self, x, y, 0, 1)
      self.name = "CLOCK"
      self.tickspeed = tickspeed or 1
      self.ticks = 1 / self.tickspeed
      self.lastMicroSec = love.timer.getTime()
    end,
    __base = _base_0,
    __name = "CLOCK",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  CLOCK = _class_0
end
local loadINPUTPIN
loadINPUTPIN = function(pin)
  local newpin = INPUTPIN(pin.parentID)
  newpin.id = pin.id
  newpin.state = pin.state
  newpin.pos = vec2(pin.pos.x, pin.pos.y)
  newpin.isConnected = pin.isConnected
  return newpin
end
local loadOUTPUTPIN
loadOUTPUTPIN = function(pin)
  local newpin = OUTPUTPIN(pin.parentID)
  newpin.id = pin.id
  newpin.state = pin.state
  newpin.pos = vec2(pin.pos.x, pin.pos.y)
  newpin.isConnected = pin.isConnected
  return newpin
end
local loadGATE
loadGATE = function(gatedata)
  local newgate = GATE(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
  if gatedata.name == "AND" then
    newgate = AND(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
  elseif gatedata.name == "NAND" then
    newgate = NAND(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
  elseif gatedata.name == "OR" then
    newgate = OR(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
  elseif gatedata.name == "NOR" then
    newgate = NOR(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
  elseif gatedata.name == "XOR" then
    newgate = XOR(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
  elseif gatedata.name == "XNOR" then
    newgate = XNOR(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
  elseif gatedata.name == "NOT" then
    newgate = NOT(gatedata.pos.x, gatedata.pos.y, gatedata.inputpincount)
  end
  newgate.id = gatedata.id
  newgate.state = gatedata.state
  newgate.inputpincount = gatedata.inputpincount
  newgate.inputpins = { }
  local _list_0 = gatedata.inputpins
  for _index_0 = 1, #_list_0 do
    local pin = _list_0[_index_0]
    table.insert(newgate.inputpins, loadINPUTPIN(pin))
  end
  newgate.outputpin = loadOUTPUTPIN(gatedata.outputpin)
  return newgate
end
local loadPERIPHERAL
loadPERIPHERAL = function(peripheraldata)
  local newperipheral = PERIPHERAL(peripheraldata.pos.x, peripheraldata.pos.y, peripheraldata.inputpincount)
  if peripheraldata.name == "INPUT" then
    newperipheral = INPUT(peripheraldata.pos.x, peripheraldata.pos.y, peripheraldata.inputpincount)
  elseif peripheraldata.name == "CLOCK" then
    newperipheral = CLOCK(peripheraldata.pos.x, peripheraldata.pos.y, peripheraldata.inputpincount)
    newperipheral.tickspeed = peripheraldata.tickspeed
    newperipheral.lastMicroSec = love.timer.getTime()
  elseif peripheraldata.name == "BUFFER" then
    newperipheral = BUFFER(peripheraldata.pos.x, peripheraldata.pos.y, peripheraldata.inputpincount)
    newperipheral.ticks = peripheraldata.ticks
    newperipheral.tickcounter = 0
    newperipheral.isBuffering = false
  elseif peripheraldata.name == "OUTPUT" then
    newperipheral = OUTPUT(peripheraldata.pos.x, peripheraldata.pos.y, peripheraldata.inputpincount)
  end
  newperipheral.id = peripheraldata.id
  newperipheral.state = peripheraldata.state
  if peripheraldata.hasinputpin then
    newperipheral.inputpin = loadINPUTPIN(peripheraldata.inputpin)
  end
  if peripheraldata.hasoutputpin then
    newperipheral.outputpin = loadOUTPUTPIN(peripheraldata.outputpin)
  end
  return newperipheral
end
return {
  PIN = PIN,
  INPUTPIN = INPUTPIN,
  OUTPUTPIN = OUTPUTPIN,
  GATE = GATE,
  AND = AND,
  OR = OR,
  NOT = NOT,
  NAND = NAND,
  NOR = NOR,
  XOR = XOR,
  XNOR = XNOR,
  PERIPHERAL = PERIPHERAL,
  INPUT = INPUT,
  OUTPUT = OUTPUT,
  BUFFER = BUFFER,
  CLOCK = CLOCK,
  loadGATE = loadGATE,
  loadPERIPHERAL = loadPERIPHERAL
}
