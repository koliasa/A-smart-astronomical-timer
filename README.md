# Розумний астрономічний таймер
Проект "Розумний астрономічний таймер" є програмою на мові LUA для NodeMCU V3 ESP8266, яка використовує модуль реле 5V для Arduino PIC ARM AVR для управління зовнішнім освітленням. Програма використовує Wi-Fi для синхронізації часу, а також можливість ручного налаштування часу. Вона також отримує дані про погоду та астрономічні дані з Інтернету для аналізу та автоматичного включення світла під час потемніння. Крім того, програма підтримує вмикання/вимикання світла через мережу з допомогою команд.

## Вимоги
Для виконання програми потрібно:
* NodeMCU V3 ESP8266
* 2-канальний модуль реле 5V для Arduino PIC ARM AVR
* Інтернет-підключення

## Інструкція по встановленню
1. Підключіть NodeMCU V3 ESP8266 та модуль реле до комп'ютера.
2. Встановіть програму Arduino IDE на свій комп'ютер.
3. Відкрийте Arduino IDE та перейдіть до меню "Файл" -> "Налаштування".
4. У вікні "Налаштування" у полі "Додаткові дошки URL" введіть наступне значення: `http://arduino.esp8266.com/stable/package_esp8266com_index.json`
5. Натисніть кнопку "OK" та закрийте вікно "Налаштування".
6. Перейдіть до меню "Інструменти" -> "Плата" та оберіть "NodeMCU 1.0 (ESP-12E Module)".
7. Перейдіть до меню "Інструменти" -> "Версія" та оберіть "Latest".
8. Перейдіть до меню "Інструменти" -> "Завантажити бібліотеки" та завантажте наступні бібліотеки: "WiFiManager", "Time", "NTPClient", "ArduinoJson".
9. Відкрийте файл "smart_astronomical_timer.lua" в Arduino IDE та завантажте програму на NodeMCU V3 ESP8266.

## Використання
1. Підключіть NodeMCU V3 ESP8266 та модуль реле до джерела живлення.
2. Підключіть зовнішнє освітлення до модуля реле.
3. Підключіть NodeMCU V3 ESP8266 до Wi-Fi мережі.
4. Після підключення до Wi-Fi мережі програма автоматично синхронізує час з Інтернету.
5. Якщо потрібно, можна налаштувати час вручну за допомогою команди "/settime HH:MM:SS".
6. Програма автоматично отримує дані про погоду та астрономічні дані з Інтернету та вмикатиме світло під час потемніння.
7. Якщо потрібно, можна вмикати/вимикати світло через мережу з допомогою команд "/on" та "/off".

## Команди
Програма підтримує наступні команди через Wi-Fi:
- /settime HH:MM:SS - налаштувати час вручну.
- /on - вмикнути світло.
- /off - вимкнути світло.

## Автор
Ігор Коляса

Приклад коду на мові LUA для проекту 
`Розумний астрономічний таймер`
```lua
-- Завантаження модулів для роботи з Wi-Fi, HTTP та часом
wifi = require("wifi")
http = require("http")
sntp = require("sntp")

-- Налаштування змінних для зберігання конфігурації
ssid = "mywifi"
password = "mypassword"
server = "api.openweathermap.org"
path = "/data/2.5/weather"
city = "Kyiv"
appid = "myappid"

-- Налаштування змінних для зберігання астрономічних даних та налаштувань
lat = 50.43
lon = 30.52
offset = 2
sunset = 0
sunrise = 0

-- Налаштування пінів для керування реле
pin_relay_1 = 1
pin_relay_2 = 2
gpio.mode(pin_relay_1, gpio.OUTPUT)
gpio.mode(pin_relay_2, gpio.OUTPUT)

-- Функція для вмикання світла
function switch_on()
  gpio.write(pin_relay_1, gpio.HIGH)
  gpio.write(pin_relay_2, gpio.HIGH)
  print("Light turned on")
end

-- Функція для вимикання світла
function switch_off()
  gpio.write(pin_relay_1, gpio.LOW)
  gpio.write(pin_relay_2, gpio.LOW)
  print("Light turned off")
end

-- Функція для отримання погодних даних з сервера
function get_weather_data()
  http.get("http://" .. server .. path .. "?q=" .. city .. "&appid=" .. appid, nil, function(code, data)
    if (code < 0) then
      print("HTTP request failed")
    else
      print("HTTP request successful")
      weather_data = sjson.decode(data)
    end
  end)
end

-- Функція для отримання астрономічних даних
function get_astronomical_data()
  http.get("http://api.sunrise-sunset.org/json?lat=" .. lat .. "&lng=" .. lon .. "&formatted=0", nil, function(code, data)
    if (code < 0) then
      print("HTTP request failed")
    else
      print("HTTP request successful")
      astronomical_data = sjson.decode(data)
      sunset = astronomical_data.results.sunset
      sunrise = astronomical_data.results.sunrise
    end
  end)
end

-- Функція для визначення поточного часу
function get_current_time()
  sntp.sync(nil, function(sec, usec, server, info)
    print("Time synchronized")
  end, nil, 1)
end

-- Функція для визначення, чи настав час вмикання світла
function isTimeToTurnOnLight(astronomicalData, currentTime, timeZone)
  local sunriseTime = astronomicalData.sunrise
  local sunsetTime = astronomicalData.sunset
  local twilightBegin = astronomicalData.twilight_begin
  local twilightEnd = astronomicalData.twilight_end
  
  -- Перевірка, чи поточний час після заходу сонця та перед ранком
  if currentTime >= sunsetTime and currentTime < sunriseTime then
    return true
  end
  
  -- Перевірка, чи поточний час в межах світла
  if currentTime >= twilightBegin and currentTime < twilightEnd then
    return true
  end
  
  return false
end
```
Функція отримує три параметри: `astronomicalData`, `currentTime` та `timeZone`. `astronomicalData` - це таблиця, що містить дані про сходи/заходи сонця та інші астрономічні події для поточного дня. currentTime - поточний час, в мілісекундах з початку доби, який отримується з функції `getTimeOfDay(). timeZone` - часовий пояс, в якому працює пристрій, який можна задати в коді.

Функція спочатку отримує значення часу заходу/сходу сонця та початку/кінця світла з `astronomicalData`. Потім перевіряє, чи поточний час після заходу сонця та перед ранком, або чи поточний час в межах світла. Якщо так, то функція повертає true, що означає, що настав час вмикання світла.

Наступна частина коду містить функцію для вимкнення світла:
```lua
-- Функція для вимкнення світла
function turnOffLight()
  gpio.write(lightPin, gpio.HIGH)
  lightOn = false
end
```
Ця функція просто встановлює вихідний сигнал на піні, до якого підключене реле, в значення "високий рівень" (HIGH), що призводить до вмикання світла.

Код функції:
```lua
function switchLightsOn()
  gpio.write(relayPin, gpio.HIGH)
  print("Lights turned on")
end
```
Тут gpio.write(relayPin, gpio.HIGH) встановлює пін у високий рівень. Функція також виводить повідомлення "Lights turned on" у консоль.