-- Simple code to detect whether a player is touching an object
local pythag = function(x1, y1, x2, y2, range)
	return (x1 - x2) ^ 2 + (y1 - y2) ^ 2 <= (range ^ 2)
end

local checkCollision = function()
	local onCollision, index = { }, 0

	for playerName, playerData in next, tfm.get.room.playerList do
		for objectId, objectData in next, tfm.get.room.objectList do
			if pythag(playerData.x, playerData.y, objectData.x, objectData.y, 30) then  -- 30px of range
				index = index + 1
				onCollision[index] = playerData
				index = index + 1
				onCollision[index] = objectData
			end
		end
	end

	for i = 1, index, 2 do
		eventOnPlayerAndObjectCollision(onCollision[i], onCollision[i + 1])
	end
end

eventLoop = function()
	checkCollision()
	-- TODO
end

eventOnPlayerAndObjectCollision = function(playerDataa, objectData) -- Use this event to handle the collisions
	-- Example:
	-- print("The player '" .. playerDataa.playerName .. "' has touched an object of type '" .. objectData.type .. "'")
end
