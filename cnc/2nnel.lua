local args = {...}

local modem = peripheral.getName((peripheral.find("modem")))
rednet.open(modem)

local action = args[1]:upper()
local packet = {action = action}

if action == "TURN" then
  packet.direction = args[2]
elseif action == "START" then
  packet.limit = tonumber(args[2])
end

rednet.broadcast(packet, "2nnel")

while true do
  local id, response = rednet.receive("2nnel-response", 3)
  if not id then break end
  if type(response) ~= "table" then goto skip_packet end
  if type(response.message) ~= "string" then goto skip_packet end

  print(("%d: %s"):format(id, response.message))

  ::skip_packet::
end

rednet.close()
