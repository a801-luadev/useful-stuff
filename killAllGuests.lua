local checkPlayer, killAllGuests
do
	local guests = { }
	local free = { }

	local currentTime = os.time()
	local fiveDays = 1000 * 60 * 60 * 24 * 5 -- ms * s * m * h * d

	local sub = string.sub
	local killPlayer = tfm.exec.killPlayer
	local tfmRoom = tfm.get.room

	local isGuest = function(playerName, playerData)
		return
			sub(playerName, 1, 1) == '*' or
			(currentTime - playerData.registrationDate) < fiveDays
	end

	checkPlayer = function(playerName)
		if guests[playerName] or free[playerName] then
			return free[playerName] -- False if guest. True otherwise.
		end

		if isGuest(playerName, tfmRoom[playerName]) then
			guests[playerName] = true
			return false
		else
			free[playerName] = true
			return true
		end
	end

	killAllGuests = function()
		for playerName in next, guests do
			killPlayer(playerName)
		end

		return free, guests
	end
end

eventNewPlayer = function(playerName)
	local isValidPlayer = checkPlayer(playerName)

	-- TODO
end

eventNewGame = function()
	killAllGuests()

	-- TODO
end
