local lume = require "lume"
local g = love.graphics
local lm = love.mouse
local Camera = {}

function Camera.new(cx, cy)
	local self = {}

	local x,y = cx or 0, cy or 0
	local scale = 1
	local active = false

	function self:set()
		if active then
			active = false
			g.pop()
		else
			g.push("transform")
			g.translate(x,y)
			g.scale(scale)
			active = true
		end
	end

	function self:getScreenPos(mx, my)
		return (mx-x)/scale, (my-y)/scale
	end	

	function self:applyScale(dx, dy)
		return dx/scale, dy/scale
	end

	function self:move(dx, dy)
		x = x + dx
		y = y + dy
	end

	function self:zoom(val)
		local factor = 0.8
		if val > 0 then
			factor = 1/factor
			-- if self.scale == self.maxZoom then return end
		else
			-- if self.scale == self.minZoom then return end
		end
		
		-- self.scale = clamp(round(self.scale*factor, 0.001), self.minZoom, self.maxZoom)
		scale = scale*factor

		local dx = (lm.getX()-x) * (factor-1)
		local dy = (lm.getY()-y) * (factor-1)

		x = x - dx
		y = y - dy
	end

	function self:center()
		x = 0
		y = 0
	end

	function self:reset()
		scale = 1
	end

	return self
end

function Camera.newSmooth(speed, minZoom, maxZoom)
	local self = {}

	local x, y = 0, 0
	local scale = 1
	local tx, ty, ts = x, y, scale
	local active = false
	local speed = speed or 1
	local minZoom = minZoom or 0.1
	local maxZoom = maxZoom or 10

	function self:set()
		if active then
			active = false
			g.pop()
		else
			g.push("transform")
			g.translate(x,y)
			g.scale(scale)
			active = true
		end
	end

	function self:getScreenPos(mx, my)
		return (mx-tx)/scale, (my-ty)/scale
	end

	function self:applyScale(dx, dy)
		return dx/scale, dy/scale
	end

	function self:move(dx, dy)
		tx = tx + dx
		ty = ty + dy
	end

	function self:zoom(val)
		local factor = 0.8
		if val > 0 then
			factor = 1/factor
		end
		
		ts = ts*factor

		if ts > minZoom*1.2 and ts < maxZoom*0.8 then
			local dx = (lm.getX()-tx) * (factor-1)
			local dy = (lm.getY()-ty) * (factor-1)

			tx = tx - dx
			ty = ty - dy
		end

		ts = lume.clamp(ts, minZoom, maxZoom)

	end

	function self:update(dt, cubic)
		if cubic then
			x = lume.smooth(x, tx, speed*dt)
			y = lume.smooth(y, ty, speed*dt)
			scale = lume.smooth(scale, ts, speed*dt)
		else
			x = lume.lerp(x, tx, (speed*0.3)*dt)
			y = lume.lerp(y, ty, (speed*0.3)*dt)
			scale = lume.lerp(scale, ts, (speed*0.3)*dt)
		end
	end

	function self:center()
		tx = 0
		ty = 0
	end

	function self:reset()
		ts = 1
	end

	return self
end

function Camera.newSmoothWithTransform(transformObj, speed, minZoom, maxZoom)
	local self = {}

	local x, y = 0, 0
	local scale = 1
	local tx, ty, ts = x, y, scale
	local active = false
	local speed = speed or 1
	local minZoom = minZoom or 0.1
	local maxZoom = maxZoom or 10

	function self:set()
		if active then
			active = false
			love.graphics.pop()
		else
			love.graphics.push("transform")
			love.graphics.applyTransform(transformObj)
			active = true
		end
	end

	function self:getScreenPos(mx, my)
		return (mx-tx)/scale, (my-ty)/scale
	end

	function self:applyScale(dx, dy)
		return dx/scale, dy/scale
	end

	function self:move(dx, dy)
		tx = tx + dx
		ty = ty + dy
	end

	function self:zoom(val)
		local factor = 0.8
		if val > 0 then
			factor = 1/factor
		end
		
		ts = ts*factor

		if ts > minZoom*1.2 and ts < maxZoom*0.8 then
			local dx = (lm.getX()-tx) * (factor-1)
			local dy = (lm.getY()-ty) * (factor-1)

			tx = tx - dx
			ty = ty - dy
		end

		ts = lume.clamp(ts, minZoom, maxZoom)

	end

	function self:update(dt, cubic)
		if cubic then
			x = lume.smooth(x, tx, speed*dt)
			y = lume.smooth(y, ty, speed*dt)
			scale = lume.smooth(scale, ts, speed*dt)
		else
			x = lume.lerp(x, tx, (speed*0.3)*dt)
			y = lume.lerp(y, ty, (speed*0.3)*dt)
			scale = lume.lerp(scale, ts, (speed*0.3)*dt)
		end
		transformObj:setTransformation(x, y, 0, scale)
	end

	function self:center()
		tx = 0
		ty = 0
	end

	function self:reset()
		ts = 1
	end

	return self
end

return Camera