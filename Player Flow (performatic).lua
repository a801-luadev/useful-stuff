local copy = function(list)
	local out = { }
	for k, v in next, list do
		out[k] = v
	end
	return out
end

local players = {
	room  = { _count = 0 },
	alive = { _count = 0 },
	dead  = { _count = 0 }
}

local players_insert = function(where, playerName)
	if not where[playerName] then
		where._count = where._count + 1
		where[where._count] = playerName
		where[playerName] = where._count
	end
end

local players_remove = function(where, playerName)
	if where[playerName] then
		where._count = where._count - 1
		where[where[playerName]] = nil
		where[playerName] = nil
	end
end

eventNewPlayer = function(playerName)
	players_insert(players.room, playerName)
	players_insert(players.dead, playerName)
end
for playerName in next, tfm.get.room.playerList do
	eventNewPlayer(playerName)
end

eventPlayerLeft = function(playerName)
	players_remove(players.room, playerName)
end

eventPlayerDied = function(playerName)
	players_remove(players.alive, playerName)
	players_insert(players.dead, playerName)
end

eventPlayerRespawn = function(playerName)
	players_remove(players.dead, playerName)
	players_insert(players.alive, playerName)
end

eventNewGame = function()
	players.dead = { _count = 0 }
	players.alive = copy(players.room)
end
