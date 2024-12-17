local State = {
  stopped = "stopped",
  running = "running"
}

local Action = {
  stop = "STOP",
  start = "START",
  refuel = "REFUEL",
  ping = "PING",
}

local STATE = State.stopped
local actionQueue = {}

local function rednet()
  local modem = peripheral.getName((peripheral.find("modem")))
  rednet.open(modem)

  while true do
    local id, message = rednet.receive("2nnel")
    if id == os.computerID() then goto skip_packet end
    if type(message) ~= "table" then goto skip_packet end
    if type(message.action) ~= "string" then goto skip_packet end
    message._id = id

    table.insert(actionQueue, message)

    ::skip_packet::
  end

  rednet.close()
end

local function retry(delay, f, ...)
  while true do
    local ok = f(...)
    if not ok then break end
    sleep(delay)
  end
end

local function mineForward()
  if turtle.detect() then
    assert(turtle.dig())
    return true
  end
  return false
end

local function mineUp()
  if turtle.detectUp() then
    assert(turtle.digUp())
    return true
  end
  return false
end

local function detectOre(inspector)
  local has_block, data = inspector()
  if not has_block then return false end

  return string.find(data.name, "_ore$")) ~= nil
end


local function digTunnel()
  turtle.placeDown()
  if detectOre(turtle.inspect) then
    return true
  end
  retry(0.5, mineForward)
  assert(turtle.forward())
  if detectOre(turtle.inspectUp) then
    return true
  end
  retry(0.5, mineUp)
  return false
end


local function refuel(limit)
  if turtle.getFuelLimit() == "unlimited" then return 0 end

  local sel = turtle.getSelectedSlot()
  local fuelLevel = turtle.getFuelLevel()

  for i=1,16 do
    if (limit and limit <= 0) or turtle.getFuelLevel() >= turtle.getFuelLimit() then break end

    local count = turtle.getItemCount(i)
    if count == 0 then goto skip_slot end

    turtle.select(i)
    assert(turtle.refuel(limit))

    if limit then
      limit = limit - (count - turtle.getItemCount())
    end

    ::skip_slot::
  end

  turtle.select(sel)

  return turtle.getFuelLevel() - fuelLevel
end

local function response(id, msg, kwargs)
  -- just in case :3
  print(msg)

  kwargs = kwargs or {}
  kwargs.message = msg
  rednet.send(id, kwargs, "2nnel-response")
end

local function stopAll(reason)
  STATE = State.stopped
  rednet.broadcast({ action = Action.STOP, reason = reason }, "2nnel")
end

local function miner()
  sleep(0.5)
  while true do
    if STATE == State.running then
      local ok, message = pcall(digTunnel)
      if not ok then
        print("Mining procedure failed: " .. message)
        stopAll("Mining error occured: " .. message)
      else
        local oreFound = message
        if oreFound then
          stopAll("Ore found")
        end
      end
    elseif STATE == State.stopped then
      sleep(1)
    end

    while #actionQueue ~= 0 do
      local p = table.remove(actionQueue, 1)
      local action = p.action
      local id = p._id

      if action == Action.start then
        STATE = State.running
      elseif action == Action.stop then
        STATE = State.stopped
      elseif action == Action.refuel then
        local ok, message = pcall(refuel, p.limit)
        if not ok then
          response(id, "Refuel failed: " .. message)
        else
          local refueled = message
          response(id, ("Refueled %d fuel units"):format(refueled))
        end
      elseif action == Action.ping then
        response(id, "Pong!")
      else
        response(id, "Unimplemented action: " .. action)
      end
    end
  end
end

parallel.waitForAny(rednet, miner)
