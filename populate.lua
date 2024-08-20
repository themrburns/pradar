local args = {...}
-- args:
-- blacklist (add/remove) (username)
-- blacklist (list)
-- mcalert (add/remove) (username)
-- mcalert (list)
-- webhook (url)
-- help
local function argError() error("Invalid argument. Run 'populate help' for more information", 2) end
if #args < 1 then argError() end
local function readAll(path) local h = fs.open(path, "r") local ret = h.readAll() h.close() return ret end
local function writePath(path, obj) local h = fs.open(path, "w") h.write(obj) h.close() end


if args[1] == "blacklist" and #args > 1 then
    if args[2] == "add" or args[2] == "remove" and #args > 2 then
        local tabl = textutils.unserialise(readAll(".blacklist.list"))
        local user = tostring(args[3])
        tabl[user] = (args[2] == "add")
        writePath(".blacklist.list", textutils.serialise(tabl))
        print(tabl[user])
    elseif args[2] == "list" then
        local tabl = textutils.unserialise(readAll(".blacklist.list"))
        for player, _ in pairs(tabl) do
            write(player..", ")
        end
    else
        argError()
    end
elseif args[1] == "mcalert" and #args > 1 then
    if args[2] == "add" or args[2] == "remove" and #args > 2 then
        local tabl = textutils.unserialise(readAll(".mcAlert.list"))
        local user = tostring(args[3])
        if args[2] == "add" then table.insert(tabl, user) else for k, v in ipairs(tabl) do if v == user then tabl[k] = nil end end end
        writePath(".mcAlert.list", textutils.serialise(tabl))
    elseif args[2] == "list" then
        local tabl = textutils.unserialise(readAll(".mcAlert.list"))
        for _, player in pairs(tabl) do
            write(player..", ")
        end
    else
        argError()
    end
elseif args[1] == "webhook" and args[2] ~= nil then
    writePath("webhook.txt", tostring(args[2]))
elseif args[1] == "help" then
    print("() - marks required args, [] - marks optional args")
    print("populate blacklist (add/remove/list) [username]")
    print("         --- adds, removes or lists players in the blacklist file")
    print("populate mcalert (add/remove/list) [username]")
    print("         --- adds, removes or lists players in the mcalert file")
    print("populate webhook (url)")
    print("         --- add a webhook url to the webhook file. NOTE: this deletes the previous url, entered in the file")
    print("populate help")
    print("         --- show this interface")
else
    argError()
end
