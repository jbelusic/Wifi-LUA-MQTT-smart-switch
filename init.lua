-- ESP8266

wifi_ssid       = nil
wifi_pass       = nil
broker_location = nil
broker_user     = nil
broker_password = nil
broker_port     = nil
init_status     = nil
auth_id         = nil

if pcall(
    function ()
        print("Open wifi config")
        dofile("wifi_config.lc")
		print("Wifi config is open.")					   
    end) 
then

    print("ESP8266_SWITCH module start, please wait...")
    print("SSID: "..ssid)

	-- Wifi
    wifi_ssid = ssid
    wifi_pass = password
		
	-- MQTT
	if pcall(
		function ()
			print("Open MQTT config")
			dofile("mqtt_config.lc")
			print("MQTT config is open.")					
		end) 
	then
		broker_location = broker
		broker_user     = brokeruser
		broker_password = brokerpass
        broker_port     = brokerport
        auth_id         = generaluserid
	else
		print("Problem with MQTT settings")
		print("Going to read new available APs")
		dofile("wifi_setup.lua")
	end
	
	-- Init State relay
	if pcall(
		function ()
			print("Open state file")
			dofile("status.lua")
		end) 
	then
		init_status = status
	else
		print("Problem with init status, set status to OFF")
		init_status = "OFF"
	end

    config = require("config") 
    app = require("application")
    setup = require("setup")

    reset_pin = 5 --> GPIO14 -->D5
    gpio.mode(reset_pin, gpio.INT, gpio.PULLUP)

    function startup()
        --print("Starting on startup...")
        gpio_read = gpio.read(reset_pin)
        is_pressed = 0
        if (gpio_read == 0) then
            is_pressed = 1
        else
            is_pressed = 0
        end
        print("Pin " ..reset_pin .. " - state is: " .. is_pressed)
        if (is_pressed == 1) then
            print("Restarting...")
            file.remove("wifi_config.lc")
            node.restart()
        end
        setup.start()
    end
    tmr.alarm(0,5000,0,startup)

else
   print("Enter configuration mode")
   dofile("wifi_setup.lua")
end
