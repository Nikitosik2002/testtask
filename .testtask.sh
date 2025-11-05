#!/bin/bash

name_process="test"
log_file="/run/pid.txt"
api="https://test.com/monitoring/test/api"
monitoring_log="/var/log/monitoring.log"

test_pid="$(pgrep -nx "$name_process")"


if [[ -n "$test_pid" ]]; then
	if [[ ! -f "$log_file" ]]; then
    		echo "$test_pid" > "$log_file"
	fi

	if [[ "$test_pid" == "$(cat "$log_file")" ]]; then
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

