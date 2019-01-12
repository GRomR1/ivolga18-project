------------------------------
* запуск сервисов в докер-контейнерах:
  * grafana
  * influxd
  * mosquitto
  * telegraf
------------------------------

## Запуск/остановка сервисов

```
./run.sh
./stop.sh
```

### До запуска grafana

Графана запускается нет от `root`, поэтому требуется настроить права доступа на каталоги.
И затем запускать контейнер с параметром `user`

Изменение прав на него для моего юзера
```
chown -R rg: /opt/grafana/data
chown -R rg: /opt/grafana/config
```

Получение id юзера и затем передача его в yml файл docker-compose
```
id -u rg
1000
```

### После запуска grafana

Авторизация в вебе графаны под учеткой `admin:admin` и изменение на `admin:ertdfg`.

Импорт [готового](docker-services/grafana-dashboard.json) дашбоарда по [инструкции](http://docs.grafana.org/reference/export_import/).

### До запуска influxdb

Генерируем конфиг файл для influxdb
```
docker run --rm influxdb influxd config > /opt/influxdb/config/influxdb.conf
```

### После запуска influxdb

InfluxDB - создаем пользователя и БД - `admin:ertdfg` и `db`
```
curl -G http://localhost:8087/query --data-urlencode "q=show databases"
curl -i -XPOST http://localhost:8087/query --data-urlencode "q=CREATE USER admin WITH PASSWORD 'ertdfg' WITH ALL PRIVILEGES"
curl -i -XPOST http://localhost:8087/query -u admin:ertdfg --data-urlencode "q=CREATE DATABASE db"
```

Получаем кое-какую информацию из БД (для тестов)
```
curl -XPOST 'http://localhost:8087/write?db=db' -u admin:ertdfg --data-binary 'sensors,var=light val=0i'
curl -XPOST 'http://localhost:8087/write?db=db' -u admin:ertdfg --data-binary 'sensors,var=light val=1i'
curl -G 'http://localhost:8087/query?pretty=true' -u admin:ertdfg --data-urlencode "db=db" --data-urlencode "q=SHOW MEASUREMENTS"
curl -G 'http://localhost:8087/query?pretty=true' -u admin:ertdfg --data-urlencode "db=db" --data-urlencode "q=SELECT * FROM sensors"
curl -G 'http://localhost:8087/query?pretty=true' -u admin:ertdfg --data-urlencode "db=db" --data-urlencode "q=SHOW TAG KEYS FROM sensors"
curl -G 'http://localhost:8087/query?pretty=true' -u admin:ertdfg --data-urlencode "db=db" --data-urlencode "q=SHOW FIELD KEYS FROM sensors"
curl -XPOST 'http://localhost:8087/query?pretty=true' -u admin:ertdfg --data-urlencode "db=db" --data-urlencode "q=DROP MEASUREMENT sensors"
curl -G 'http://localhost:8087/query?pretty=true' -u admin:ertdfg --data-urlencode "db=db" --data-urlencode "q=SELECT sum(value) FROM sensors WHERE topic = '/sensors/like'"
```

Запрос получения значения освещенности с датчика:
```
SELECT 867941.072 / pow(("value" -10), 1.5832)
FROM "sensors"
WHERE ("topic" = '/sensors/light' AND "user" = 'device') AND $timeFilter
GROUP BY "user" fill(null)
```

Запросы статуса лампы:
```
SELECT "value" FROM "sensors" WHERE ("topic" = '/sensors/lamp') AND $timeFilter
```


### Работа с mosquitto

И отправляем MQTT пакет с сообщением в Json формате `{"value":0, "command": "set", "user": "device"}`
на `/sensors/lamp`

Сообщение с лайками:
```
/sensors/like
{"value":1, "command": "add", "user": "mobile"}
```

Для дебага используем [mqtt-spy](https://github.com/eclipse/paho.mqtt-spy)
