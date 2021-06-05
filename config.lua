local module = {}

print("Config is started!")

module.chipid = node.chipid()
module.SSID = {}  
module.SSID[wifi_ssid] = wifi_pass
module.AUTHUSERID = auth_id
module.ID = module.chipid
module.BROKER = broker_location
module.UN = broker_user
module.PS = broker_password
module.PORT = broker_port
module.RECONNECT = 0
module.QOS = 0
module.KEEPALIVE = 10 --10
module.SUBPOINT = module.chipid .."/SWITCH"
module.PUBPOINT = module.chipid .."/STATE"
module.LWT = module.chipid .."/lwt"
module.STATUS = module.chipid .."/RES"
module.PING = module.chipid .."/GET"
module.GETTIME = "gettime"
module.PRINTTIME = "printtime"
module.RETAIN = 0
module.RETAIN_TRUE = 1
module.BROKERSTATUS = "BROKERSTATUS"

module.isInternet = 0

return module  
