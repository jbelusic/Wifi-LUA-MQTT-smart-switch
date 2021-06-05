local module = {}

local function isOnline()
    http.get("http://httpbin.org/ip", nil, function(code, data, result)
    print("code: " .. code)
		print("data: " .. data)
		temporary_ip = 0
		local t = sjson.decode(data)
        for k,v in pairs(t) do 
		  print(k,v) 
			print("test ip:")
			print(v)
			if (v ~= nil) then
				temporary_ip = 1
			end
		end
		print(result)
		--if (code < 0) then
		if (temporary_ip == 0) then
            print("HTTP request failed...")
        else
            --print(code, data)
            print("ping success")
            tmr.stop(6)
            print("Starting application..")
            app.start()
        end
    end)
end

module.timeout = 0;
local function wifi_wait_ip()
  if wifi.sta.getip()== nil then
    print("IP setup unavailable, Waiting..."..module.timeout)
    module.timeout = module.timeout + 1
    --if(module.timeout >= 180) then
    --    --file.remove('wifi_config.lc')
    --    node.restart()
    --end
  else
    tmr.stop(1)
	print("Finaly!")
    print("\n====================================")
    print("ESP8266 mode is: " .. wifi.getmode())
    print("MAC address is: " .. wifi.ap.getmac())
    print("IP is "..wifi.sta.getip())
    print("====================================")
    -- Connecting to DNS - ping ip from http://httpbin.org/ip
    --print("Ping http://httpbin.org/ip...")
	
    tmr.alarm(6, 10000, 1, isOnline)
	
    --http_request = require "http.request"
    --headers, stream = assert(http_request.new_from_uri("http://example.com"):go())
    --body = assert(stream:get_body_as_string())
    --if headers:get ":status" ~= "200" then
    --    error(body)
    --end
    --print(body)
    --print("Starting application..")
    --app.start()
  end
end

local function wifi_start(list_aps)
	print("wifi start listing aps ...")
    restart = 1
    show_more = 0
	local cfg_tbl = {}
    if list_aps then
        for key,value in pairs(list_aps) do
            if show_more == 0 then
                if config.SSID and config.SSID[key] then
                    print("Listing and getting key " .. key .. " ...")
        				print("Key is found!")
                        wifi.setmode(wifi.STATION);
        				print("Trying to connect...")
        				cfg_tbl = {}
        				cfg_tbl.ssid = key
        				cfg_tbl.pwd = config.SSID[key]
                        --wifi.sta.config(key,config.SSID[key])
        				wifi.sta.config(cfg_tbl)
                        wifi.sta.connect()
                        print("Connecting to " .. key .. " ...")
                        --config.SSID = nil  -- can save memory
                        tmr.alarm(1, 2500, 1, 
        					wifi_wait_ip
        				)
        				print("Connected!")
                        show_more = 1
        				cfg_tbl = nil
                        restart = 0
    			--else
    			--	print("Not connected to " .. key .. " ...")
                end
            end
        end
        -- Restarting if not found our network (maybe it is not started, it needs more time to start, restarting...)
        if restart == 1 then
            tmr.alarm(2, 10000, 1, function () restart = 0 end)
            node.restart()
        end
    else
        print("Error getting AP list")
        --file.remove('wifi_config.lc')
        node.restart()
    end
end

function module.start()
    print("Configuring Wifi ...")
    wifi.setmode(wifi.STATION)
    wifi.sta.getap(wifi_start)
end

return module 
