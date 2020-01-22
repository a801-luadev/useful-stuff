local find, gmatch = string.find, string.gmatch

local split = function(str, delimiter, f, isPlain)
	local out, index = { }, 0

	local n, i, j = 1
	while true do
		i, j = find(str, delimiter, n, isPlain)
		if not i then break end

		index = index + 1
		out[index] = sub(str, n, i - 1)
		if f then
			out[index] = f(out[index])
		end

		n = j + 1
	end

	index = index + 1
	out[index] = sub(str, n)
	if f then
		out[index] = f(out[index])
	end

	return out
end

local getValue = function(value)
	if value == '' then
		return 0
	end
	return tonumber(value) or value
end

local grounds = { }
eventNewGame = function()
	grounds = { }

	local xml = tfm.get.room.xmlMapInfo
	if xml then
		xml = xml.xml

		local groundIndex = 0
		for groundData in gmatch(xml, "<S (.-)/>") do
			groundIndex = groundIndex + 1
			grounds[groundIndex] = { }
			for attributeName, _, value in gmatch(groundData, "([%w-_]+)=([\"'])(.-)%2") do
				grounds[groundIndex][attributeName] = (tonumber(value) or (find(value, ',', 1, true) and split(value, ',', getValue, true)) or value)
			end
		end
	end
end

--[[ Table 'grounds' gets updated on every new game

Ex:

grounds[1].X -- Horizontal position (X) of the first ground (z-index: 0)
grounds[1].P[5] -- Angle of the first ground

]]
