local GATE
do
  local _class_0
  local _base_0 = {
    getWidth = function(self)
      return print('no @ in first level')
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      local _ = {
        getWidth = function(self)
          return print('no @ in second level')
        end
      }
      return {
        [self.getWidth] = function(self)
          return print('1  @ in second level')
        end
      }
    end,
    __base = _base_0,
    __name = "GATE"
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
  self.getWidth = function(self)
    return print('1  @ in first level')
  end
  GATE = _class_0
end
local AND
do
  local _class_0
  local _parent_0 = GATE
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self)
      _class_0.__parent.__init(self)
      _class_0.__parent.getWidth()
      _class_0.__parent.getWidth(self)
      return self:getWidth()
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




print('GATE')
GATE.getWidth()
local gate = GATE()
gate.getWidth()
print('')
print('AND')
AND.getWidth()
print('==>>inside AND constructor')
local andgate = AND()
print('<<==outside AND constructor')
andgate.getWidth()
print('')