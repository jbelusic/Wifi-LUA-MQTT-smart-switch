local module = {}  

m = nil
setStatus = nil

-- Toggling LED
local pinOnOff = 2  --> GPIO4 -->D2
local state = gpio.LOW
gpio.mode(pinOnOff, gpio.OUTPUT)
local isMqttUnavailable = 0

-- Set relay from last known status in status file
if init_status ~= nil then
	if init_status == "ON" then
	  print("Init status from file: ON")
		gpio.write(pinOnOff, gpio.HIGH)
	elseif init_status == "OFF" then
		print("Init status from file: OFF")
		gpio.write(pinOnOff, gpio.LOW)
	else
		print("Can't read init status from file. Set to OFF")
		gpio.write(pinOnOff, gpio.LOW)
	end
end

local is_started = 0

function setStatus(pSt)
	file.open("status.lua", "w")
	file.write('status = "' .. pSt .. '"')
	file.close()
  if pSt ~= nil then
    init_status = pSt
  end
end

local function push(pState)
  if pState == "ON" then
    print("Switch On")
    gpio.write(pinOnOff, gpio.HIGH)
  end

  if pState == "OFF" then
    print("Switch Off")
    gpio.write(pinOnOff, gpio.LOW)
  end

  -- Publishing status
  m:publish(config.STATUS, pState, config.QOS, config.RETAIN_TRUE, function(conn) end)
	
	if pState ~= nil then
		setStatus(pState)
	end
end

-- Sends my id to the broker for registration
local function register_myself()  
  print("Subscribing...")
  m:subscribe({[config.SUBPOINT]=config.QOS, [config.PING]=config.QOS, [config.PRINTTIME]=config.QOS, nil})
  print("Subscribed on " .. config.SUBPOINT)
end

local function connack_string(connack_code)
    if connack_code == 0 then
        print("Connection Accepted.")
    elseif connack_code == -1 then
        print("Connection Refused: Timeout trying to send the Connect message.")
    elseif connack_code == -2 then
        print("Connection Refused: Timeout waiting for a CONNACK from the broker.")
    elseif connack_code == -3 then
        print("Connection Refused: DNS Lookup failed.")
    elseif connack_code == -4 then
        print("Connection Refused: The response from the broker was not a CONNACK as required by the protocol.")
    elseif connack_code == -5 then
        print("Connection Refused: There is no broker listening at the specified IP Address and Port.")
		elseif connack_code == 1 then
        print("Connection Refused: The broker is not a 3.1.1 MQTT broker.")
    elseif connack_code == 2 then
        print("Connection Refused: The specified ClientID was rejected by the broker. (See mqtt.Client()).")
    elseif connack_code == 3 then
        print("Connection Refused: The server is unavailable.")
    elseif connack_code == 4 then
        print("Connection Refused: The broker refused the specified username or password.")
    elseif connack_code == 5 then
        print("Connection Refused: The username is not authorized.")
    else
        print("Connection Refused: unknown reason.")
    end
end

function reconnect()
	print ("Reconnecting MQTT broker...")
	
	m:connect(config.BROKER, config.PORT, config.QOS, function(client) print("Connected to MQTT")
		register_myself()   --run the subscripion function 
	end)
end												 
local function mqtt_start()
  print("Connecting to broker...")

  is_started = 1
  -- Connect to broker
  m:connect(config.BROKER, config.PORT, config.QOS, config.RECONNECT, 
  function(con) 
    print("Connected!")
    if isMqttUnavailable > 0 then
      isMqttUnavailable = 0
      print("Sending information about MQTT Broket was down!")
      m:publish(config.STATUS, "Was Offline, now is Online", config.QOS, config.RETAIN, function(conn) end)
      tmr.stop(5)
      -- Print status of relay
      if init_status ~= nil then
        print("Init status: " .. init_status)
      end
    end
    register_myself()
    print("Publishing AVBL status on: " .. config.STATUS)
    m:publish(config.STATUS, "AVLB", config.QOS, config.RETAIN, function(conn) end)
    print("Done!")
    m:publish(config.STATUS, "ONLINE", config.QOS, config.RETAIN_TRUE, function(conn) end)

    -- Set switch to last known state
    if init_status ~= nil then
      if init_status == "ON" then
        m:publish(config.STATUS, init_status, config.QOS, config.RETAIN_TRUE, function(conn) end)
      elseif init_status == "OFF" then
        m:publish(config.STATUS, init_status, config.QOS, config.RETAIN_TRUE, function(conn) end)
      else
        m:publish(config.STATUS, "OFF", config.QOS, config.RETAIN_TRUE, function(conn) end)
      end
    end
  end,
  function(client, reason)
    print("failed reason: " .. reason)
    print(connack_string(reason))
	register_myself()
	m:publish(config.STATUS, "OFF", config.QOS, config.RETAIN_TRUE, function(conn) end)
  end)

  -- on receive message
  m:on("message", function(conn, topic, data)
    --print(topic .. ":" ..data)
    if data ~= nil then
      if is_started == 0 then
        if topic == node.chipid() .."/SWITCH" then
          if data == "ON" or data == "OFF" then
            push(data)
          end
        end
      end
      is_started = 0

      if topic == config.PING and data == "AVLB" then
        m:publish(config.STATUS, "AVLB", config.QOS, config.RETAIN, function(conn) end)
      end
    end
  end)

  m:on("offline", function(client) 
    print ("Offline " .. config.ID) 
		isMqttUnavailable = isMqttUnavailable + 1
		print("Restarting MQTT module...")
		m:lwt(config.STATUS, "OFFLINE", 0, 0)
        tmr.alarm(5, 10000, 1, mqtt_start)
	    register_myself()
  end)
  
end

module.timeout_restart = 0;
reset_pin = 5 --> GPIO14 -->D5
gpio.mode(reset_pin, gpio.INT, gpio.PULLUP)

function module.start()
    print("Starting MQTT module...")
    m = mqtt.Client(config.ID, config.KEEPALIVE, config.UN, config.PS)
    m:lwt(config.STATUS, "OFFLINE", 0, config.RETAIN_TRUE)
    mqtt_start()
end

return module  
