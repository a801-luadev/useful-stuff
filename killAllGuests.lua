local killAllGuests
do
	local guests = { }
	local free = { }

	local currentTime = os.time()
	local fiveDays = 1000 * 60 * 60 * 24 * 5 -- ms * s * m * h * d

	local sub = string.sub

	local isGuest = function(playerName, playerData)
		return
			sub(playerName, 1, 1) == '*' or
			(currentTime - playerData.registrationDate) < fiveDays
	end

	local killPlayer = tfm.exec.killPlayer
	local tfmRoom = tfm.get.room

	killAllGuests = function()
		for playerName, playerData in next, tfmRoom.playerList do
			if guests[playerName] then
				killPlayer(playerName)
			elseif not free[playerName] then
				if isGuest(playerName, playerData) then
					guests[playerName] = true
					killPlayer(playerName)
				else
					free[playerName] = true
				end
			end
		end

		return free, guests
	end
end

eventNewGame = function()
	killAllGuests()

	-- TODO
end
