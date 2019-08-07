do
  --[[
      You should NOT save module data in player's data (such as rankings,
    leaderboards...). Not because you can't, but because if the player is
    offline, even tho system.loadPlayerData will return true,
    eventPlayerDataLoaded won't ever be called.
  ]]
  local INSTA_SAVE = false --[[
      You can change this boolean value. Here is a little explanation:
      Transformice's Lua system is asynchronous. This means that nothing
    is really called "right now", it is mostly like a "call soon" system,
    so whenever you call system.loadPlayerData, the returned value is
    whether the player's data has started to load, not whether it was loaded.
      When the value is set to false, you must call to system.runAsyncTasks()
    in your eventLoop.
      If you change this to true, it will call the function, call
    eventPlayerDataLoaded and then leave the function. Otherwise, it will work
    as it does in Transformice, call the function, leave it and when the current
    event ends it will then call eventPlayerDataLoaded. An example is here:

    function eventPlayerDataLoaded(player, data)
      print("[eventPlayerDataLoaded] Loaded!")
    end

    function eventChatCommand(player, strcommand)
      local arguments, pointer, command = {}, 0, ""
      for argument in string.gmatch(strcommand, "%S+") do
        if pointer == 0 then
          command = string.lower(argument)
        else
          arguments[pointer] = argument
        end
        pointer = pointer + 1
      end

      if command == "load" then
        print("[eventChatCommand] Loading...")
        system.loadPlayerData(player)
        print("[eventChatCommand] Loaded!")
      end
    end

    function eventLoop()
      system.runAsyncTasks()
    end

    Output with INSTA_SAVE set to false (as it works in transformice):
    [eventChatCommand] Loading...
    [eventChatCommand] Loaded!
    [eventPlayerDataLoaded] Loaded!

    Output with INSTA_SAVE set to true:
    [eventChatCommand] Loading...
    [eventPlayerDataLoaded] Loaded!
    [eventChatCommand] Loaded!
  ]]
  local saveFileCooldown = 0
  local loadFileCooldown = 0
  local tasksPointer = 0
  local playerData = {}
  local files = {}
  local tasks = {}

  local tostring = tostring
  local unpack = table.unpack
  local type = type
  local time = os.time

  local function callSoon(fnc, ...)
    if INSTA_SAVE then
      return fnc(...)
    else
      tasksPointer = tasksPointer + 1
      tasks[tasksPointer] = {fnc=fnc, args={...}}
    end
  end

  function system.runAsyncTasks()
    if not INSTA_SAVE then
      for index = 1, #tasks do
        local task = tasks[index]

        task.fnc(unpack(task.args))
      end

      tasks = {}
      tasksPointer = 0
    end
  end

  function system.savePlayerData(player, data)
    playerData[tostring(player)] = tostring(data)
  end

  function system.loadPlayerData(player)
    local evt = _G["eventPlayerDataLoaded"]
    if type(evt) == "function" then
      local player = tostring(player)
      callSoon(evt, player, playerData[player] or "")
    end
    return true
  end

  function system.saveFile(data, file)
    local now = time()

    if now < saveFileCooldown then
      print("You can't call this function [system.saveFile] more than once per 1 minute.")
      return
    end

    saveFileCooldown = now + 60000
    local file = tonumber(file) or 0
    files[file] = tostring(data)
    local evt = _G["eventFileSaved"]
    if type(evt) == "function" then
      callSoon(evt, tostring(file))
    end
  end

  function system.loadFile(file)
    local now = time()

    if now < loadFileCooldown then
      print("You can't call this function [system.loadFile] more than once per 1 minute.")
      return
    end

    loadFileCooldown = now + 60000
    local evt = _G["eventFileLoaded"]
    if type(evt) == "function" then
      local file = tonumber(file) or 0
      callSoon(evt, tostring(file), files[file] or "")
    end
    return true
  end
end
