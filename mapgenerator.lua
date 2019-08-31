local MapFactory
do
	local tag_to_xml

	tag_to_xml = function(tag)
		local xml = "<" .. tag.name

		for aname, avalue in next, tag.attributes do
			xml = xml .. " " .. aname .. "=\"" .. avalue .. "\""
		end

		if not tag.tags[1] then
			return xml .. " />"
		end
		xml = xml .. (tag.attributes[1] and " >" or ">")

		for _, itag in next, tag.tags do
			xml = xml .. tag_to_xml(itag)
		end

		return xml .. "</" .. tag.name .. ">"
	end

	MapFactory = function()
		local self = {}
		local policy = nil
		local C = {
			name = "C",
			tags = {
				{
					name = "P",
					tags = {},
					attributes = {}
				},
				{
					name = "Z",
					tags = {
						{
							name = "S",
							tags = {},
							attributes = {}
						},
						{
							name = "D",
							tags = {},
							attributes = {}
						},
						{
							name = "O",
							tags = {},
							attributes = {}
						}
					},
					attributes = {}
				}
			},
			attributes = {}
		}

		self.set_policy = function(_policy)
			policy = _policy

			policy.length = policy.length or 800
			policy.height = policy.height or 400

			policy.grounds = policy.grounds or 0
			policy.holes = policy.holes or 0
			policy.cheese = policy.cheese or 0

			policy.separationCheck = policy.separationCheck or function() return true end
			policy.afterDone = policy.afterDone or function() end

			return self
		end

		self.generate = function()
			local count = 0
			local Z = C.tags[2].tags
			local grounds = Z[1].tags
			local deco = Z[2].tags

			for index = 1, policy.grounds do
				local ground = {
					name = "S",
					tags = {},
					attributes = {
						X = nil,
						Y = nil,
						L = math.random(policy.groundMinLength or 10, policy.groundMaxLength or 10),
						H = math.random(policy.groundMinHeight or 10, policy.groundMaxHeight or 10),
						T = "0",
						-- P = "dynamic,mass,friction,restitution,rotation,fixed_rotation,lineal_amortiguation,angular_amortiguation"
						P = "0,0,0.3,0.2,0,0,0,0"
					}
				}
				while true do
					ground.attributes.X = math.random(0, policy.length)
					ground.attributes.Y = math.random(0, policy.height)
					local collides = false

					for _, _ground in next, grounds do
						count = count + 1
						if not policy.separationCheck(ground, _ground) then
							collides = true
							break
						end
					end

					if not collides then
						if index == 1 then
							count = count + 1
							if policy.separationCheck(ground, nil) then
								break
							end
						else
							break
						end
					end
				end
				grounds[index] = ground
			end

			for index = 1, policy.holes do
				local x, y, halfWidth, halfHeight, collides

				local hole = {
					name = "T",
					tags = {},
					attributes = {
						X = nil,
						Y = nil
					}
				}
				while true do
					hole.attributes.X = math.random(0, policy.length)
					hole.attributes.Y = math.random(0, policy.height)
					collides = false

					for _, ground in next, grounds do
						count = count + 1
						if not policy.separationCheck(hole, ground) then
							collides = true
							break
						end
					end

					if not collides then
						for _, dec in next, deco do
							count = count + 1
							if not policy.separationCheck(hole, dec) then
								collides = true
								break
							end
						end

						if not collides then
							if #grounds == 0 and #deco == 0 then
								count = count + 1
								if policy.separationCheck(hole, nil) then
									break
								end
							else
								break
							end
						end
					end
				end

				deco[index] = hole
			end

			for _ = 1, policy.cheese do
				local x, y, halfWidth, halfHeight, collides
				local cheese = {
					name = "F",
					tags = {},
					attributes = {
						X = nil,
						Y = nil
					}
				}
				while true do
					cheese.attributes.X = math.random(0, policy.length)
					cheese.attributes.Y = math.random(0, policy.height)
					collides = false

					for _, ground in next, grounds do
						count = count + 1
						if not policy.separationCheck(cheese, ground) then
							collides = true
							break
						end
					end

					if not collides then
						for _, dec in next, deco do
							count = count + 1
							if not policy.separationCheck(cheese, dec) then
								collides = true
								break
							end
						end

						if not collides then
							if #grounds == 0 and #deco == 0 then
								count = count + 1
								if policy.separationCheck(cheese, nil) then
									break
								end
							else
								break
							end
						end
					end
				end

				deco[#deco + 1] = cheese
			end

			policy.afterDone(C)
			return self, count
		end

		self.clean = function()
			C = {
				name = "C",
				tags = {
					{
						name = "P",
						tags = {},
						attributes = {}
					},
					{
						name = "Z",
						tags = {
							{
								name = "S",
								tags = {},
								attributes = {}
							},
							{
								name = "D",
								tags = {},
								attributes = {}
							},
							{
								name = "O",
								tags = {},
								attributes = {}
							}
						},
						attributes = {}
					}
				},
				attributes = {}
			}
			return self
		end

		self.as_xml = function()
			local attr = C.tags[1].attributes
			attr.L = policy.length
			attr.H = policy.height
			return tag_to_xml(C, "C")
		end
		return self
	end
end

local function AlmostRandomGenerator(self, other)
	if self.name == "S" then -- ground
		if not other then
			return true

		elseif other.name == "S" then
			local halfWidth = other.attributes.L / 2 + 60
			local halfHeight = other.attributes.H / 2 + 60
			local _halfWidth = self.attributes.L / 2 + 60
			local _halfHeight = self.attributes.H / 2 + 60
			if (other.attributes.X + halfWidth > self.attributes.X - _halfWidth and self.attributes.X + _halfWidth > other.attributes.X - halfWidth and
				other.attributes.Y + halfHeight > self.attributes.Y - _halfHeight and self.attributes.Y + _halfHeight > other.attributes.Y - halfHeight) then
				return false
			end
		end

	elseif self.name == "T" then -- hole
		if not other then
			return true

		elseif other.name == "S" then
			local halfWidth = other.attributes.L / 2 + 60
			local halfHeight = other.attributes.H / 2 + 60
			if (other.attributes.X + halfWidth > self.attributes.X and self.attributes.X > other.attributes.X - halfWidth and
				other.attributes.Y + halfHeight > self.attributes.Y and self.attributes.Y > other.attributes.Y - halfHeight) then
				return false
			end

		elseif other.name == "T" then
			if (other.attributes.X + 60 > self.attributes.X and self.attributes.X > other.attributes.X - 60 and
				other.attributes.Y + 60 > self.attributes.Y and self.attributes.Y > other.attributes.Y - 60) then
				return false
			end
		end

	elseif self.name == "F" then -- cheese
		if not other then
			return true

		elseif other.name == "S" then
			local halfWidth = other.attributes.L / 2 + 60
			local halfHeight = other.attributes.H / 2 + 60
			if (other.attributes.X + halfWidth > self.attributes.X and self.attributes.X > other.attributes.X - halfWidth and
				other.attributes.Y + halfHeight > self.attributes.Y and self.attributes.Y > other.attributes.Y - halfHeight) then
				return false
			end

		elseif other.name == "T" then
			if (other.attributes.X + 60 > self.attributes.X and self.attributes.X > other.attributes.X - 60 and
				other.attributes.Y + 60 > self.attributes.Y and self.attributes.Y > other.attributes.Y - 60) then
				return false
			end

		elseif other.name == "F" then
			if (other.attributes.X + 60 > self.attributes.X and self.attributes.X > other.attributes.X - 60 and
				other.attributes.Y + 60 > self.attributes.Y and self.attributes.Y > other.attributes.Y - 60) then
				return false
			end
		end
	end

	return true -- evades infinite loops
end

local function NotRandomGenerator(self, other)
	if self.place then
		return true
	end

	if self.name == "S" then -- ground
		if not other then
			self.attributes.X = 400
			self.attributes.Y = 200
			return true

		elseif other.name == "S" then
			if other.checked_S then
				return true
			end

			other.checked_S = true
			self.attributes.X = other.attributes.X + other.attributes.L / 2 + self.attributes.L / 2
			self.attributes.Y = other.attributes.Y
			self.place = true
			return true
		end

	elseif self.name == "T" then -- hole
		if not other then
			self.attributes.X = 400
			self.attributes.Y = 200
			return true

		elseif other.name == "S" then
			if other.checked_T then
				return true
			end

			other.checked_T = true
			self.attributes.X = other.attributes.X
			self.attributes.Y = other.attributes.Y - other.attributes.H / 2
			self.place = true
			return true

		elseif other.name == "T" then
			if (other.attributes.X + 60 > self.attributes.X and self.attributes.X > other.attributes.X - 60 and
				other.attributes.Y + 60 > self.attributes.Y and self.attributes.Y > other.attributes.Y - 60) then
				return false
			end
		end

	elseif self.name == "F" then -- cheese
		if not other then
			self.attributes.X = 400
			self.attributes.Y = 200
			return true

		elseif other.name == "S" then
			if other.checked_F or other.checked_T then
				return true
			end

			other.checked_F = true
			self.attributes.X = other.attributes.X
			self.attributes.Y = other.attributes.Y - other.attributes.H / 2 - 5
			self.place = true
			return true

		elseif other.name == "T" then
			if (other.attributes.X + 60 > self.attributes.X and self.attributes.X > other.attributes.X - 60 and
				other.attributes.Y + 60 > self.attributes.Y and self.attributes.Y > other.attributes.Y - 60) then
				return false
			end

		elseif other.name == "F" then
			if (other.attributes.X + 60 > self.attributes.X and self.attributes.X > other.attributes.X - 60 and
				other.attributes.Y + 60 > self.attributes.Y and self.attributes.Y > other.attributes.Y - 60) then
				return false
			end
		end
	end

	return true -- evades infinite loops
end

local function TotallyRandomGenerator() return true end

local factory = MapFactory().set_policy({
	length = 800,
	height = 400,

	grounds = 5,
	groundMinLength = 100,
	groundMaxLength = 100,
	groundMinHeight = 40,
	groundMaxHeight = 40,
	holes = 0,
	cheese = 0,

	separationCheck = NotRandomGenerator,
	-- afterDone = function(C)
	-- 	C.tags[1].attributes.F = math.random(0, 10)
	-- end
})

function eventChatCommand()
	local start = os.time()
	local fac, count = factory.clean().generate()
	tfm.exec.newGame(fac.as_xml())
	print(os.time() - start)
	print(count)
end
tfm.exec.disableAutoNewGame(true)
