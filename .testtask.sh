#!/bin/bash

# ==========================================
# Скрипт для мониторинга процесса "test"
# Проверяет:
#   - Запущен ли процесс
#   - Был ли он перезапущен (сравнение PID)
#   - Доступен ли HTTPS-ресурс https://test.com/monitoring/test/api
# При недоступности сервера или перезапуске процесса
# пишет запись в /var/log/monitoring.log
# ==========================================

name_process="test"
log_file="/run/pid.txt"
api="https://test.com/monitoring/test/api"
monitoring_log="/var/log/monitoring.log"
# Получаем PID процесса "test" (берем только последний запущенный)
test_pid="$(pgrep -nx "$name_process")"

# Проверяем, найден ли процесс
if [[ -n "$test_pid" ]]; then
	# Если файла с PID ещё нет — создаем его
	if [[ ! -f "$log_file" ]]; then
    		echo "$test_pid" > "$log_file"
	fi

	if [[ "$test_pid" == "$(cat "$log_file")" ]]; then
        	# Выполняем HTTPS-запрос
        	# -s   тихий режим
        	# -k   игнорировать SSL-ошибки
        	# -L   следовать редиректам
        	# --fail  возвращать ошибку при кодах 4xx/5xx
        	# --connect-timeout 2  ждать подключения не более 2 секунд
        	# --max-time 3  общий лимит 3 секунды
        	# -o /dev/null  не выводить тело ответа
		if ! curl -s -k -L --fail --connect-timeout 2 --max-time 3 -o /dev/null "$api"; then
			echo "$(date +"%Y-%m-%d %H:%M:%S") -- сервер недоступен" >> "$monitoring_log"
		fi
	else
		echo "$(date +"%Y-%m-%d %H:%M:%S") -- процесс был перезапущен -- Старый PID: $(tail -n 1 "$log_file") -- Новый PID: "$test_pid"" >> "$monitoring_log"
		echo "$test_pid" > "$log_file"
	fi
else
	:
fi
