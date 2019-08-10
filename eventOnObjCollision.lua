-- Simple code to detect whether a player is touching an object
local pythag = function(x1, y1, x2, y2, range)
	return (x1 - x2) ^ 2 + (y1 - y2) ^ 2 <= (range ^ 2)
end

eventLoop = function()
	for playerName, playerData in next, tfm.get.room.playerList do
		for objectId, objectData in next, tfm.get.room.objectList do
			if pythag(playerData.x, playerData.y, objectData.x, objectData.y, 30) then  -- 30px of range
				eventOnObjCollision(playerData, objectData)
			end
		end
	end
end

eventOnObjCollision = function(player, object) -- Use this event to handle the collisions
	-- Example:
	-- print("The player '" .. player.playerName .. "' has touched an object of type '" .. object.type .. "'")
end
