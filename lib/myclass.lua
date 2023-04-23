-- define a class object
local class = {}

-- create a new class
function class:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

-- create a subclass
function class:subclass()
    local subclass = {}
    setmetatable(subclass, self)
    self.__index = self
    return subclass
end
