--local module = {}

print("Get available APs")
available_aps = ""
aray_wifi = {}
wifi.setmode(wifi.STATION)
wifi.sta.getap(function(t)
   if t then
      for k,v in pairs(t) do
         ap = string.format("%-10s",k)
         ap = trim(ap)
         print(ap)
         available_aps = available_aps .. "<li>".. ap .."</li>"
         table.insert(aray_wifi,ap)
      end
      --print(available_aps)
      print("Starting Alarm!")
      print("Searching for available wifi...")
      tmr.alarm(2,5000,1, function() setup_server(available_aps) end )
   end
end)

local unescape = function (s)
   s = string.gsub(s, "+", " ")
   s = string.gsub(s, "%%(%x%x)", function (h)
         return string.char(tonumber(h, 16))
      end)
   return s
end

-- Indicator wifi AP state for wifi and broker configuration
local pinConfig = 6  --> GPIO12 -->D6
gpio.mode(pinConfig, gpio.OUTPUT)
gpio.write(pinConfig, gpio.LOW)

function setup_server(aps)
   print("Setting up Wifi AP server..")
   wifi.setmode(wifi.SOFTAP)
	 cfg={}
	 cfg.ssid="ESP8266_SWITCH"
	 cfg.pwd="YOUR_HARDCODED_PASSWORD_HERE" 
   wifi.ap.config(cfg)  
   wifi.ap.setip({ip="192.168.4.1",netmask="255.255.255.0",gateway="192.168.4.1"})
   print("IP Address:",wifi.ap.getip())

   --web server
   srv = nil
   --srv:close()
   srv=net.createServer(net.TCP)
   srv:listen(80,function(conn)
       conn:on("receive", function(client,request)
           print("Receive!")
           local buf = ""
           local show_form = "Y"
           local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
           if (method == nil) then
               _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP")
           end
           local _GET = {}
           if (vars ~= nil)then
               for k, v in string.gmatch(vars, "(%w+)=([^%&]+)&*") do
                   _GET[k] = unescape(v)
               end
           end

           if (_GET.psw ~= nil and _GET.ap ~= nil) then
                show_form = "N"
                print("Saving data..")
                client:send("Saving data..")
                file.open("wifi_config.lua", "w")
                file.writeline('ssid = "' .. _GET.ap .. '"')
                file.writeline('password = "' .. _GET.psw .. '"')
                file.close()
                node.compile("wifi_config.lua")
                file.remove("wifi_config.lua")
                --
                if (_GET.broker ~= nil and _GET.brokeruser ~= nil and _GET.brokerpass ~= nil and _GET.brokerport ~= nil and _GET.generaluserid ~= nil) then
                    file.remove("mqtt_config.lc")
                    file.open("mqtt_config.lua", "w")
                    file.writeline('broker = "' .. _GET.broker .. '"')
                    file.writeline('brokeruser = "' .. _GET.brokeruser .. '"')
                    file.writeline('brokerpass = "' .. _GET.brokerpass .. '"')
                    file.writeline('brokerport = "' .. _GET.brokerport .. '"')
                    file.writeline('generaluserid = "' .. _GET.generaluserid .. '"')
                    file.close()
                    node.compile("mqtt_config.lua")
                    file.remove("mqtt_config.lua")
                end
                -- AP indicator OFF
                gpio.write(pinConfig, gpio.LOW)
                client:send("Successfully done, congratulations! ")
                client:send("Restarting, please wait...")
                print("Restarting node, please wait..")
                -- TODO put diode state to OFF
                tmr.alarm(0,10000,0,function() node.restart() end)
                --node.restart()
           --else
           --   print("POST is not send or GET parameters are empty!")
           end

           if (show_form == "Y") then
             buf = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n"
             buf = buf .. "<!DOCTYPE HTML>\r\n"
             buf = buf .. "<html><body>"
             buf = buf .. "<h3>Configure WiFi</h3><br>"
             buf = buf .. "<form method='get' action='http://" .. wifi.ap.getip() .."'>"
             buf = buf .. "Available APs:<br>"
             buf = buf .. "Pick wifi SSID from list: <input name='ap' list='networks'><br>"
             buf = buf .. "<datalist id='networks'><br>"
             local wifi_list = ""
             for k,v in ipairs(aray_wifi) do
                wifi_list = wifi_list .. "<option value='" .. v .. "'><br>"
             end
             buf = buf .. wifi_list
             buf = buf .. "</datalist><br>"
             buf = buf .. "Enter wifi password: <input type='password' name='psw'></input><br>"
             buf = buf .. "<input type='text' name='ip' value='".. wifi.ap.getip() .. "' hidden></input><br>"
						 buf = buf .. "Enter Broker: <input type='text' name='broker'></input><br>"
						 buf = buf .. "Enter Broker user: <input type='text' name='brokeruser'></input><br>"
						 buf = buf .. "Enter Broker password: <input type='password' name='brokerpass'></input><br>"
                         buf = buf .. "Enter Broker port: <input type='text' name='brokerport'></input><br>"
                         buf = buf .. "Enter auth. ID: <input type='text' name='generaluserid'></input><br>"
             buf = buf .. "<br><button type='submit'>Save</button>"                   
             buf = buf .. "</form></body></html>"

             client:send(buf)
             --client:close()
             -- AP indicator ON
			 gpio.write(pinConfig, gpio.HIGH)
           end
           collectgarbage()
       end)
       conn:on("sent",function(client)
            client:close()
            collectgarbage()
        end)
   end)
   if (wifi.ap.getip() ~= nil) then
        print("Please connect to: " .. wifi.ap.getip() .. " to set wifi configuration!")
   else
        print("Can't get IP")
        -- red led on
   end
   --tmr.stop(0)
   tmr.stop(2)
end
 
function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--return module
