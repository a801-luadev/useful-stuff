local ping
do
	local room = tfm.get.room -- this table is not changed by the API
	local time = os.time
	local print = print
	local movePlayer = tfm.exec.movePlayer
	local addPhysicObject = tfm.exec.addPhysicObject
	local players, pointer = {}, 0
	local real_range = 15
	local range2 = real_range * 2
	local cr = real_range ^ 2 + 1
	local cx, cy
	local ground_ids, ground_def
	local ping_evt, bot_evt
	local giveup

	local function set_grounds(i1, i2, i3, i4, bodyDef)
		ground_ids, ground_def = {i1, i2, i3, i4}, bodyDef
	end

	local function set_position(x, y, dont_print)
		cx, cy = x, y

		if (not dont_print) and (x ^ 2 + y ^ 2 < cr) then -- It is about the left corner
			print("[ping.setCheckPosition] The given position is too close to the left corner; \
				meaning that is_bot event won't work and bots will have a pretty low ping.")
			--[[
					Why this happens?
				This is pretty easy: by default, bots (at least with the transfromage APIs) don't
				send position packets, and the server sets their "Lua position"
				(tfm.get.room.playerList.x / y) to 0, 0. This system relies on the position, and
				if the bots are always at 0, 0 and you set a checking position that is close to it
				bots will have a pretty low ping (not meaning the real ping, but the one that is
				calculated using this library!)
			]]--
		end
	end

	local function set_evts(ping_recv, is_bot)
		ping_evt, bot_evt = ping_recv, is_bot
	end

	local function set_timeout(timeout)
		giveup = timeout
	end

	local function load_grounds()
		ground_def.width = 10
		ground_def.height = range2
		addPhysicObject(ground_ids[1], cx - real_range, cy, ground_def)
		addPhysicObject(ground_ids[2], cx + real_range, cy, ground_def)

		ground_def.width = range2
		ground_def.height = 10
		addPhysicObject(ground_ids[3], cx, cy - real_range, ground_def)
		addPhysicObject(ground_ids[4], cx, cy + real_range, ground_def)
	end

	local function check_pings()
		if pointer == 0 then return end

		local _players, _pointer = {}, 0
		local current = time()
		local player, pdata
		for index = 1, #players do
			player = players[index]
			pdata = room.playerList[player[1]]

			if pdata then
				local took = current - player[2]

				if (pdata.x - cx) ^ 2 + (pdata.y - cy) ^ 2 < cr then
					tfm.exec.movePlayer(player[1], player[3], player[4])
					if ping_evt then
						ping_evt(player[1], took)
					end
				elseif took >= giveup then
					if bot_evt then
						bot_evt(player[1])
					end
				else
					_pointer = _pointer + 1
					_players[_pointer] = player
				end
			end
		end

		pointer = _pointer
		players = _players
	end

	local function hook_player(player, dont_print)
		local pdata = room.playerList[player]
		if pdata then
			movePlayer(player, cx, cy)
			pointer = pointer + 1
			players[pointer] = {player, time(), pdata.x, pdata.y}
			return true
		elseif not dont_print then
			print("[ping.hookPlayer] The given parameter is not a room player.")
		end
		return false
	end

	set_grounds(1, 2, 3, 4, {type = tfm.enum.ground.invisible})
	set_position(400, 200)
	set_timeout(2000)
	ping = {
		hookPlayer = hook_player, --
		setGrounds = set_grounds, --
		setCheckPosition = set_position, --
		loadGrounds = load_grounds, --
		setEvents = set_evts, --
		checkPings = check_pings, --
		setTimeout = set_timeout --
	}
end

--[[ Example usage ]]--
ping.setEvents(function(player, ping)
	print(player .. "'s ping: " .. ping .. "ms.")
end, function(player)
	print(player .. " might be a bot.")
	-- You could check the player again and if it says that it might be a bot too then it is!
	-- Or you could set a greater timeout with ping.setTimeout, which is easier.
end)
ping.loadGrounds()

function eventLoop()
	ping.checkPings()
end

function eventChatCommand(player, cmd)
	print("Hooking player " .. cmd .. ": " .. (ping.hookPlayer(cmd) and "success" or "error"))
	-- Remember that the function could never result in calling one of the events: the player
	-- could leave the room before the system times out!
end
