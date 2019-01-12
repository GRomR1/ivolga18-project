-- init mqtt client with keepalive timer 120sec
m = mqtt.Client("clientid", 120)

pin_number = 1 -- вход лампочки
gpio.mode (pin_number, gpio.OUTPUT) -- установка рабочего режима на выход
gpio.write (pin_number, gpio.LOW)

status = 0 -- выключен
disable_light = 0 

print("status: "..status)

-- setup Last Will and Testament (optional)
-- попытка отправить свой статус перед отключением
m:lwt("/sensors/power", 
     "{\"value\":0, \"command\": \"switch\", \"user\": \"device\"}", 0, 0)

m:on("connect", function(con) print ("connected") end)
m:on("offline", function(con) print ("offline") end)

function switch_on()
  if status == 0 then
      print("swith_on"..status)
      m:publish("/sensors/lamp", 
        "{\"value\":1, \"command\": \"set\", \"user\": \"device\"}",
        0, 0, function(client) print("Sent switch_on ") end)
      gpio.write (pin_number, gpio.HIGH)
      status = 1
  end
end

function switch_off()
  if status == 1 then
      print("swith_off"..status)
      m:publish("/sensors/lamp", 
        "{\"value\":0, \"command\": \"set\", \"user\": \"device\"}",
        0, 0, function(client) print("Sent switch_off ") end)
      gpio.write (pin_number, gpio.LOW)
      status = 0
  end
end

-- on publish message receive event
m:on("message", function(conn, topic, data) 
  print(topic .. ":" )
  if topic == "/sensors/button" then
    if data ~= nil then
      print(data)
    end
    if string.find(data, "{\"value\":1, \"command\": \"set\"") then
      switch_on()
    end
    if string.find(data, "{\"value\":0, \"command\": \"set\"") then
      switch_off()
    end
    if string.find(data, "{\"value\":1, \"command\": \"change\"") then
      if status == 1 then
        switch_off()
      else
        switch_on()
      end
    end
  end
  if topic == "/sensors/disable_light" then
    if string.find(data, "{\"value\":1, \"command\": \"set\"") then
      disable_light = 1
    end
    if string.find(data, "{\"value\":0, \"command\": \"set\"") then
      disable_light = 0
    end
  end
end)


m:connect("dev.s3t.club", 1884, 0, function(client)
  print("connected")
  -- Calling subscribe/publish only makes sense once the connection
  -- was successfully established. You can do that either here in the
  -- 'connect' callback or you need to otherwise make sure the
  -- connection was established (e.g. tracking connection status or in
  -- m:on("connect", function)).

  -- subscribe topic with qos = 0
  client:subscribe("/sensors/button", 0, function(client) print("subscribe 'button' success") end)
  client:subscribe("/sensors/disable_light", 0, function(client) print("subscribe 'disable_light' success") end)
  
  -- publish a message with data = hello, QoS = 0, retain = 0
  client:publish("/sensors/power", 
     "{\"value\":1, \"command\": \"switch\", \"user\": \"device\"}", 
     0, 0, function(client) print("sent power on") end)
     
  -- publish a message with data = hello, QoS = 0, retain = 0
  client:publish("/sensors/lamp", 
     "{\"value\":0, \"command\": \"set\", \"user\": \"device\"}",
     0, 0, function(client) print("sent switch_off ") end)
  
  mytimer = tmr.create()
  mytimer:register(1000, tmr.ALARM_AUTO, function()
    local light = adc.read(0)
    -- print("ADC: "..light)
  
    client:publish("/sensors/light", 
      "{\"value\":"..light..", \"command\": \"measure\", \"user\": \"device\"}",
      0, 0, function(client) print("Sent ADC: "..light) end)
    
    if disable_light == 0 and light > 800 and status == 0 then
       switch_on()
    elseif disable_light == 0 and light < 700 and status == 1 then
       switch_off()
    end
  end)
  mytimer:start()
end,
function(client, reason)
  print("failed reason: " .. reason)
end)
