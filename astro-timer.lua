-- Налаштування підключення до WiFi мережі
wifi.setmode(wifi.STATION)
wifi.sta.config({ssid="назва_мережі", pwd="пароль"})
print(wifi.sta.getip())

-- Налаштування підключення до сервера NTP
sntp.sync("0.ua.pool.ntp.org",
  function(sec, usec, server, info)
    print('NTP sync', sec, usec, server)
  end,
  function()
    print('NTP sync failed!')
  end
)

-- Налаштування параметрів управління світлом
local LIGHT_PIN = 1     -- GPIO пін для управління світлом
local LIGHT_ON = 0      -- Рівень GPIO піну для увімкнення світла
local LIGHT_OFF = 1     -- Рівень GPIO піну для вимкнення світла

-- Налаштування параметрів управління часом
local TIMEZONE = 2      -- Часовий пояс (зсув в годинах відносно UTC)
local ON_HOUR = 20      -- Година ввімкнення світла
local OFF_HOUR = 6      -- Година вимкнення світла

-- Функція для отримання стану освітлення на основі астрономічного календаря
function get_light_state()
  local latitude = 50.45       -- Широта (для міста Київ)
  local longitude = 30.52      -- Довгота (для міста Київ)
  local sunrise = astro.sunrise(os.time(), latitude, longitude)
  local sunset = astro.sunset(os.time(), latitude, longitude)
  local current_time = os.time() + TIMEZONE * 3600
  if current_time >= sunrise and current_time <= sunset then
    return LIGHT_ON
  else
    return LIGHT_OFF
  end
end

-- Функція для управління світлом
function set_light_state(state)
  gpio.write(LIGHT_PIN, state)
end

-- Функція для автоматичного перемикання на літній / зимовий час
function check_dst()
  local now = os.time() + TIMEZONE * 3600
  local year = os.date('%Y', now)
  local dst_start = os.time({year=year, month=3, day=1, hour=2})
  local dst_end = os.time({year=year, month=11, day=1, hour=2})
  local is_dst = false
  if now >= dst_start and now < dst_end then
    is_dst = true
  end
  if is_dst then
    TIMEZONE = 3     -- Зсув для літнього часу
else
    TIMEZONE = 2     -- Зсув для зимового часу
end

-- Функція для отримання стану освітлення на основі астрономічного календаря
function getSunState()
    local latitude = 50.45  -- Широта для м. Київ
    local longitude = 30.52  -- Довгота для м. Київ
    local sunState = {}
    sunState.sunrise = astro.getSunrise(latitude, longitude, os.date("*t").year, os.date("*t").month, os.date("*t").day, TIMEZONE, 0)
    sunState.sunset = astro.getSunset(latitude, longitude, os.date("*t").year, os.date("*t").month, os.date("*t").day, TIMEZONE, 0)
    return sunState
end

-- Функція для отримання стану освітлення на основі поточного часу
function getTimeState()
    local timeState = {}
    local currentTime = os.date("*t")
    timeState.currentTime = os.time()
    timeState.currentHour = tonumber(currentTime.hour)
    timeState.isWeekend = (currentTime.wday == 1 or currentTime.wday == 7) -- 1 - Неділя, 7 - Субота
    timeState.isSummerTime = (currentTime.month > 3 and currentTime.month < 10) -- В Україні літній час діє з 4 березня по 28 жовтня
    return timeState
end

-- Функція для вимикання освітлення
function turnOffLights()
    gpio.write(LIGHT_PIN, gpio.HIGH) -- Вимикаємо освітлення
    LIGHT_STATE = 0
    print("Lights turned off")
end

-- Функція для ввімкнення освітлення
function turnOnLights()
    gpio.write(LIGHT_PIN, gpio.LOW) -- Вмикаємо освітлення
    LIGHT_STATE = 1
    print("Lights turned on")
end

-- Функція для автоматичного перемикання на літній / зимовий час
function checkTimeChange()
    local timeState = getTimeState()
    if timeState.isSummerTime and not SUMMER_TIME then
        SUMMER_TIME = true
        TIMEZONE = 3
        print("Switched to summer time")
    elseif not timeState.isSummerTime and SUMMER_TIME then
        SUMMER_TIME = false
        TIMEZONE = 2
        print("Switched to winter time")
    end
end

-- Функція для режиму роботи для вихідних днів
function checkWeekendMode()
    local timeState = getTimeState()
    if timeState.isWeekend and not WEEKEND_MODE then
        WEEKEND_MODE = true
        turnOffLights()
        print("Switched to weekend mode")
    elseif not timeState.isWeekend and WEEKEND_MODE then
        WEEKEND_MODE = false
        print("Switched to normal mode")
    end
end

-- Функція для режиму роботи для вихідних днів
function isWeekend()
    local dayOfWeek = tonumber(os.date("%w", time))
    return dayOfWeek == 0 or dayOfWeek == 6 -- 0 - неділя, 6 - субота
    end

    -- Функція для визначення стану світла на основі астрономічного календаря
    function getLightState()
    local sunRise, sunSet = sunRiseSet()
    local currentTime = os.time() + TIMEZONE * 3600 -- Відлік від UTC до локального часу
    if isWeekend() then
    -- Вихідні дні - весь час світло
    return true
    elseif currentTime >= sunRise and currentTime < sunSet then
    -- Сонце ще не заходить, або уже сходить
    return true
    else
    return false
    end
    end
    
    -- Функція для ручного вмикання / вимикання світла через мережу
    function setLightState(state)
    if state then
    gpio.write(LED_PIN, gpio.HIGH)
    else
    gpio.write(LED_PIN, gpio.LOW)
    end
    end
    
    -- Функція для виконання команд, отриманих через мережу
    function handleCommand(cmd)
    if cmd == "on" then
    setLightState(true)
    elseif cmd == "off" then
    setLightState(false)
    end
    end
    
    -- Функція для запуску веб-сервера для отримання команд через мережу
    function startServer()
    local srv = net.createServer(net.TCP)
    srv:listen(80, function(conn)
    conn:on("receive", function(conn, payload)
    local cmd = string.match(payload, "%w+")
    handleCommand(cmd)
    conn:send("OK")
    end)
    conn:on("sent", function(conn) conn:close() end)
    end)
    print("Web server started")
    end
end

-- Запуск основної програми
tmr.alarm(0, 1000, tmr.ALARM_AUTO, function()
    local h, m = getTime()
    local s = getSunset()
    local sr = getSunrise()
    local w = getWeekday()
    local holiday = isHoliday()
    local light_state = isLightOn()
    -- Перевіряємо, чи настав час для вимикання світла
if (h >= LIGHT_OFF_HOUR and h < LIGHT_ON_HOUR) or holiday then
    if light_state == true then
        switchLight(false)
    end
end

-- Перевіряємо, чи настав час для вмикання світла
if (h >= LIGHT_ON_HOUR and h < LIGHT_OFF_HOUR) and not holiday then
    if light_state == false then
        switchLight(true)
    end
end

-- Оновлюємо час у разі зміни хвилини
if m == 0 then
    setTime()
end

-- Перевіряємо, чи настав час для перемикання на літній / зимовий час
if (w == 7 and m == 3 and h == 2) then
    switchDaylightSavingTime()
elseif (w == 7 and m == 10 and h == 3) then
    switchDaylightSavingTime()
end
end

-- Функція для вимикання / вмикання світла
function switchLight(state)
if state == true then
gpio.write(LIGHT_PIN, gpio.HIGH)
else
gpio.write(LIGHT_PIN, gpio.LOW)
end
end

-- Функція для отримання стану освітлення на основі астрономічного календаря
function isLightOn()
local s = getSunset()
local sr = getSunrise()
local h, m = getTime()
-- Перевіряємо, чи настав час до заходу сонця або після сходу сонця
if (h < s.hour) or (h == s.hour and m < s.min) or (h > sr.hour) or (h == sr.hour and m >= sr.min) then
    return true
else
    return false
end
end

-- Функція для отримання часу з NTP-сервера
function getTime()
local tm = rtctime.epoch2cal(rtctime.get()+TIMEZONE6060)
return tm["hour"], tm["min"], tm["sec"], tm["day"], tm["month"], tm["year"], tm["wday"]
end

-- Функція для отримання часу за нашим часовим поясом з NTP-сервера
function getLocalTime()
local tm = rtctime.epoch2cal(rtctime.get()+TIMEZONE6060)
return tm
end
-- Функція для отримання часу сходу сонця за нашим часовим поясом
function get_sunrise_time()
    local url = "https://api.sunrise-sunset.org/json?lat=" .. LATITUDE .. "&lng=" .. LONGITUDE .. "&formatted=0"
    local response = http.get(url)
    local content = response.readAll()
    response.close()

    local data = json.decode(content)
    local sunrise_time = data.results.sunrise
    local sunrise_hour, sunrise_minute = sunrise_time:match("(%d+):(%d+)")
    sunrise_hour = tonumber(sunrise_hour) + TIMEZONE -- Додаємо зсув часового поясу
    if sunrise_hour > 23 then
        sunrise_hour = sunrise_hour - 24
    end
    return sunrise_hour, sunrise_minute
end

-- Функція для отримання часу заходу сонця за нашим часовим поясом
function get_sunset_time()
    local url = "https://api.sunrise-sunset.org/json?lat=" .. LATITUDE .. "&lng=" .. LONGITUDE .. "&formatted=0"
    local response = http.get(url)
    local content = response.readAll()
    response.close()

    local data = json.decode(content)
    local sunset_time = data.results.sunset
    local sunset_hour, sunset_minute = sunset_time:match("(%d+):(%d+)")
    sunset_hour = tonumber(sunset_hour) + TIMEZONE -- Додаємо зсув часового поясу
    if sunset_hour > 23 then
        sunset_hour = sunset_hour - 24
    end
    return sunset_hour, sunset_minute
end
-- Ці дві функції використовуються для отримання часу сходу і заходу сонця за нашим часовим поясом. Вони використовують API Sunrise-Sunset для отримання даних із Інтернету. Якщо ви звернетесь до цих функцій, вони повернуть час сходу або заходу сонця у вигляді годин і хвилин, з урахуванням часового поясу.