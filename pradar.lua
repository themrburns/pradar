local DiscordHook = require("DiscordHook")

logo = [[   ___  ___          __
  / _ \/ _ \___ ____/ /__ _____
 / ___/ , _/ _ `/ _  / _ `/ __/
/_/  /_/|_|\_,_/\_,_/\_,_/_/
]]
print(logo)

local function readList(path)
    local r = fs.open(path, "r")
    local tbl = r.readAll()
    r.close()
    return tbl
end

if not fs.exists(".mcAlert.list") then
    print("EXCEPTION: Elevated Permissions List has not been identified on your system. If you believe this to be a mistake, please contact the system administrator.")
    print("PRadar is configured to automatically generate this file. To populate it, use the populate command line utility.")

    local h = fs.open(".mcAlert.list", "w")
    h.write(textutils.serialise({}))
    h.close()

    if fs.exists(".mcAlert.list") then print("Successfully created .mcAlert.list (empty)") else error("Could not create .mcAlert.list, create manually.") end
end


if not fs.exists(".blacklist.list") then
    print("EXCEPTION: Blacklist file has not been identified on your system. If you believe this to be a mistake, please contact the system administrator.")
    print("PRadar is configured to automatically generate this file. To populate it, use the populate command line utility")

    local h = fs.open(".blacklist.list", "w")
    h.write(textutils.serialise({}))
    h.close()

    if fs.exists(".blacklist.list") then print("Successfully created .blacklist.list (empty)") else error("Could not create .blacklist.list, create manually.") end
end

if not fs.exists("webhook.txt") then
    print("WARN: Webhook.txt file has not been identified on your system. If you believe this to be a mistake, please contact the system administrator.")
    print("PRadar is configured to automatically generate this file. To populate it, use the populate command line utility")
    local h = fs.open("webhook.txt", "w")
    h.write("PLACEHOLDER")
    h.close()

    if fs.exists("webhook.txt") then print("Successfully created webhook.txt (empty)") else error("Could not create webhook.txt, create manually.") end
end

local function contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

local function announceMount(wanted)
    term.write("Successfully mounted "..wanted.."...")
    local mount = peripheral.find(wanted)
    mount = mount or nil
    print(not not mount)
    if not not mount then return mount else return false end
end

print("Reading Lists")
local mcalert = textutils.unserialise(readList(".mcAlert.list"))
local blacklist = textutils.unserialise(readList(".blacklist.list"))

print("Mounting peripherals")
local pd = announceMount("playerDetector")
local cb = announceMount("chatBox")

print("Reading and configuring webhook")
local webhookAddress = readList("webhook.txt")
local success, hook = DiscordHook.createWebhook(webhookAddress)
if not success then error("Webhook connection failed, reason: "..hook) end


t = {}   -- original table (created somewhere)

-- keep a private access to original table
local _t = t

-- create proxy
t = {}

-- create metatable
local mt = {
    __index = function (t,k)
    return _t[k]   -- access the original table
    end,
    __newindex = function (t,k,v)
    print("*update of element " .. tostring(k) ..
                              " to " .. tostring(v))

    if not not v then
        hook.sendEmbed("", "Enemy Found", "An intruder has been detected! User **"..tostring(v).."** has entered the radar's perimeter", nil, 0xFF0000, nil, nil, "PRadar", nil)
        local message = {
            { text = "An intruder has been detected entering the radar's perimeter: "},
            { text = v, color = "red"}
        }
        local messageJSON = textutils.serialiseJSON(message)
        for _, player in ipairs(mcalert) do
            local successful, error = cb.sendFormattedMessageToPlayer(messageJSON, player, "PRADAR", "[]")
        end
    elseif v == nil then
        hook.sendEmbed("", "Enemy Found", "An intruder has been detected! User **"..tostring(_t[k]).."** has exited the radar's perimeter", nil, 0xFF0000, nil, nil, "PRadar", nil)
        local messageFail = {
            { text = "An intruder has been detected exiting the radar's perimeter: "},
            { text = _t[k], color = "red"}
        }
        local messageFailJSON = textutils.serialiseJSON(messageFail)
        for _, player in ipairs(mcalert) do
            local successful, error = cb.sendFormattedMessageToPlayer(messageFailJSON, player, "PRADAR", "[]")
        end
    end
    _t[k] = v   -- update original table
    end
}
setmetatable(t, mt)
-- t[2] = "hello"
-- t[2] = nil

while true do
    sleep(0)
    local list = pd.getPlayersInRange(100)
    for _, accessor in pairs(_t) do
        if not contains(list, accessor) then t[accessor] = nil end
    end
    for _, player in ipairs(list) do
        if not not not blacklist[player] and t[player] ~= player then t[player] = player end
    end
end

