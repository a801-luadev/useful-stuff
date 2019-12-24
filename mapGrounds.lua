local gsub = string.gsub

local grounds = { }
eventNewGame = function()
	grounds = { }

	local xml = tfm.get.room.xmlMapInfo
	if xml then
		xml = xml.xml

		local groundIndex = 0
		gsub(xml, "<S (.-)/>", function(groundData)
			groundIndex = groundIndex + 1
			grounds[groundIndex] = { }
			gsub(groundData, "([%w-_]+)=([\"'])(.-)%2", function(attributeName, _, value)
				grounds[groundIndex][attributeName] = (tonumber(value) or value)
			end)
		end)
	end
end
