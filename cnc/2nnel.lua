local args = {...}

local modem = peripheral.getName((peripheral.find("modem")))
rednet.open(modem)

local action = args[1]

rednet.broadcast({action = action}, "2nnel")

while true do
  local id, response = rednet.receive("2nnel-response", 3)
  if not id then break end
  if type(response) ~= "table" then goto skip_packet end
  if type(response.message) ~= "string" then goto skip_packet end

  print(("%d: %s"):format(id, response.message))

  ::skip_packet::
end

rednet.close()
