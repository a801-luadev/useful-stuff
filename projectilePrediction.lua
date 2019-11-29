--[[
Object trajectory prediction.

Basically, this creates two objects: Prediction1D and Prediction2D.
The first object predicts a movement on a single dimension, the second one, on two.
Apart from Prediction1D:limit, both objects share the same functions.
]]

math.round = function(x)
	return math.floor(x + 0.5)
end

local Prediction1D
--[[
	Represents a single-dimension trajectory prediction.
]]
do
	Prediction1D = {x=nil, v=nil, a=nil}
	Prediction1D.__index = Prediction1D

	local nan = 0/0

	Prediction1D.new = function(x, v, a, raw)
		--[[
			Creates a Prediction1D object.
			@x (int) -> initial position (mostly as an offset)
			@v (int) -> initial velocity
			@a (int) -> constant acceleration
			@raw (bool) -> whether to apply or not a conversion filter.
			If you set @raw to false, you can give @a values from map editor's gravity and/or wind.

			Returns: Prediction1D object.
		]]
		return setmetatable({
			x = x,
			v = v,
			a = raw and a or a * 0.033 -- so you can give it map editor gravity/wind
		}, Prediction1D)
	end

	Prediction1D:limit = function()
		--[[
			Gets the "limit" of the :where function.
			If you draw it, it is either the maximum or minimum point.

			Returns:
				@zero_start (bool) -> whether the limit is at the start of the trajectory
				@grows (int) -> whether the function grows, decreases or stays the same after the limit
				@limit (int) -> the limit (given in frames)

			Note that if @grows is 1, it will grow after the limit.
			If it is 0, it will stay the same, and if it is -1 it will decrease.
		]]
		if not self._limit then
			if self.a == 0 then -- no limit
				return nan, nan, nan
			end

			if (self.v > 0 and self.a < 0) or (self.v < 0 and self.a > 0) then
				-- V_0 > 0; a < 0 is the only case where there is a maximum
				-- V_0 < 0; a > 0 is the only case where there is a minimum

				-- Time when the derived function is 0 (slope = 0)
				self._limit = -self.v / self.a
				local next_value = self.v + self.a * (self._limit + 1)

				-- v != 0; a != 0, the next value can't be the same, it either grows or decreases.
				self._grows = next_value > 0 and 1 or -1
				self._zero_start = false
			else
				-- Otherwise, the limit is always gonna be 0.
				local next_value = self.v + self.a
				self._grows = next_value > 0 and 1 or (next_value < 0 and -1 or 0)
				self._limit = 0
				self._zero_start = true
			end
		end

		return self._zero_start, self._grows, self._limit
	end

	Prediction1D:when = function(x, after_limit)
		--[[
			Gets the frame when the projectile reaches the position.

			@x (int) -> the position
			@after_limit (bool) -> whether to get the frame before or after the "limit"

			Returns:
				@time (int) -> the frame when the projectile reaches the position (can be nan if it never reaches the position)
				@speed (int) -> the speed of the projectile when the position is reached (can be nan if it never reaches the position)

			Note: If one of the returned values is nan, the other is nan too.
		]]

		if self.a == 0 then
			return (x - self.x) / self.v, self.v
		end

		local speed = (2 * (x - self.x) * self.a + self.v ^ 2) ^ 0.5
		local time = (speed - self.v) / self.a

		if speed ~= speed then -- it is nan
			return nan, nan
		end

		if after_limit then
			local zero_start, grows, limit = self:limit()

			if not zero_start then
				speed = -speed
				time = limit * 2 - time
			end
		end

		return time, speed
	end

	Prediction1D:when_range = function(x1, x2)
		--[[
			Gets the frames when the projectile enters and/or leaves a range.

			@x1 (int) -> a limit of the range
			@x2 (int) -> another limit of the range

			Returns:
				@enter (int) -> the frame when the projectile enters the range (can be nan if it spawns in the range or never reaches it)
				@leave (int) -> the frame when the projectile leaves the range (can be nan if it never reaches the range)
		]]

		local t1, t2 = (self:when(x1)), (self:when(x2))
		if t1 ~= t1 then
			if t2 ~= t2 then
				return nan, nan
			end

			t1, t2 = t2, t1
			x1, x2 = x2, x1
		elseif t1 > t2 then
			t1, t2 = t2, t1
			x1, x2 = x2, x1
		end

		if t2 ~= t2 then
			-- Limit is in the range.
			return t1, (self:when(x1, true))
		end

		return t1, t2
	end

	Prediction1D:where = function(t)
		--[[
			Gets the position and speed of the projectile at the given frame.

			@frame (int) -> the frame

			Returns:
				@position (int) -> the position
				@speed (int) -> the speed
		]]
		return self.x + self.v * t + (self.a * t^2) / 2, self.a * t + self.v
	end
end

local Prediction2D
--[[
	Represents a bidimensional trajectory prediction.
]]
do
	Prediction2D = {x=nil, y=nil, w=nil, g=nil}
	Prediction2D.__index = Prediction2D

	local nan = 0/0

	Prediction2D.new = function(x, y, vx, vy, w, g, raw)
		--[[
			Creates a Prediction2D object.
			@x (int) -> initial X position (mostly as an offset)
			@y (int) -> initial Y position (mostly as an offset)
			@vx (int) -> initial X velocity
			@vy (int) -> initial Y velocity
			@w (int) -> constant X acceleration
			@g (int) -> constant Y acceleration
			@raw (bool) -> whether to apply or not a conversion filter.
			If you set @raw to false, you can give @w and @g values from map editor's gravity and/or wind.

			Returns: Prediction2D object.
		]]
		return setmetatable({
			x = Prediction1D.new(x, vx, w, raw),
			y = Prediction1D.new(y, vy, g, raw)
		}, Prediction2D)
	end

	Prediction2D:when = function(x, y, strict)
		--[[
			Gets the frame when the projectile reaches the position.

			@x (int) -> the X position
			@y (int) -> the Y position
			@stric (bool) -> if it is true it will strictly check if the Y positions are ==, otherwise it will round them both

			Returns:
				@time (int) -> the frame when the projectile reaches the position (can be nan if it never reaches the position)
				@xSpeed (int) -> the x speed of the projectile when the position is reached (can be nan if it never reaches the position)
				@ySpeed (int) -> the y speed of the projectile when the position is reached (can be nan if it never reaches the position)

			Note: If one of the returned values is nan, the other is nan too.
		]]
		local xTime, xSpeed = self.x:when(x)
		if xTime == xTime then -- it isn't nan
			local yPosition, ySpeed = self.y:where(xTime)

			if strict and (yPosition == y) or (math.round(yPosition) == math.round(y)) then
				return xTime, xSpeed, ySpeed
			end
		end
		return nan, nan, nan
	end

	Prediction2D:when_range = function(x1, y1, x2, y2)
		--[[
			Gets the frames when the projectile enters and/or leaves a range.

			@x1 (int) -> a X limit of the range
			@y1 (int) -> a Y limit of the range
			@x2 (int) -> another X limit of the range
			@y2 (int) -> another Y limit of the range

			Returns:
				@enter (int) -> the frame when the projectile enters the square (can be nan if it spawns in the range or never reaches it)
				@leave (int) -> the frame when the projectile leaves the square (can be nan if it never reaches the range)
		]]
		local enterX, leaveX = self.x:when_range(x1, x2)
		local enterY, leaveY = self.y:when_range(y1, y2)

		if enterY > leaveX or enterX > leaveY then
			return nan, nan
		end

		return enterX > enterY and enterX or enterY, leaveX > leaveY and leaveY or leaveX
	end

	Prediction2D:where = function(t)
		--[[
			Gets the position and speed of the projectile at the given frame.

			@frame (int) -> the frame

			Returns:
				@xPosition (int) -> the X position
				@yPosition (int) -> the Y position
				@xSpeed (int) -> the X speed
				@ySpeed (int) -> the Y speed
		]]
		local xPosition, xSpeed = self.x:where(t)
		local yPosition, ySpeed = self.y:where(t)
		return xPosition, yPosition, xSpeed, ySpeed
	end
end