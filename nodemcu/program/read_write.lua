pin_number = 1
gpio.mode (pin_number, gpio.OUTPUT) -- установка рабочего режима на выход
status = 0 -- выключен
print("status: "..status)

function switch_on()
  if status == 0 then
      print("swith_on"..status)
      gpio.write (pin_number, gpio.HIGH)
      status = 1
  end
end

function switch_off()
  if status == 1 then
      print("swith_off"..status)
      gpio.write (pin_number, gpio.LOW)
      status = 0
  end
end

mytimer = tmr.create()
mytimer:register(1000, tmr.ALARM_AUTO, function()
  local light = adc.read(0)
  -- print("ADC: "..light)
  
  client:publish("/topic", "hello", 0, 0, function(client) print("sent") end)
  if light > 700 and status == 0 then
     switch_on()
  elseif light < 700 and status == 1 then
     switch_off()
  end    
end)
mytimer:start()

--mytimer:stop()
--mytimer:unregister()
--mytimer = nill