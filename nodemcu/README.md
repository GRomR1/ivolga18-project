------------------------------
* работа с прошивкой контроллера
------------------------------

Сборка прошивки для NodeMCU
```
git clone https://github.com/nodemcu/nodemcu-firmware.git
cd nodemcu-firmware
docker run --rm -ti -v `pwd`:/opt/nodemcu-firmware marcelstoer/nodemcu-build
```

Смотрим что вышло
```
ls -lh ./bin/
```

Устанавливаем утилиту за заливки прошивки в устройство
```
sudo pip install esptool
```

Прошивка
```
sudo esptool.py --port /dev/ttyUSB0 erase_flash
sudo esptool.py --port /dev/ttyUSB0 flash_id
sudo esptool.py --port /dev/ttyUSB0 --baud 115200 write_flash 0 ./bin/nodemcu_float_master_20180711-1230.bin
```

Инфо об устройстве
```
sudo esptool.py --port /dev/ttyUSB0 flash_id
esptool.py v2.4.1
Serial port /dev/ttyUSB0
Connecting....
Detecting chip type... ESP8266
Chip is ESP8266EX
Features: WiFi
MAC: 60:01:94:37:b2:e1
Uploading stub...
Running stub...
Stub running...
Manufacturer: c8
Device: 4016
Detected flash size: 4MB
Hard resetting via RTS pin...
```

Дальше запись [программы](nodemcu/program) в память котроллера с помощью [ESPlorer](nodemcu/ESPlorer).

Контроллер работает в режиме станции-клиента и подключается к WiFi точке `Rus:12345670` (см. файл [wifi.lua](nodemcu/program/wifi.lua)).
