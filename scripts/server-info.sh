#!/bin/bash

# Скрипт диагностики сервера
# Использование: ./server-info.sh [URL1] [URL2] ... [--help]

LOG_FILE="/var/log/server-diagnostics.log"

# Функция вывода справки
show_help(){
  cat << EOF
Usage: $0 [URL1] [URL2] ...

Скрипт собирает информацию о сервере и проверяет доступность сервисов.

Опции:
  --help        Показать эту справку

Аргументы:
  URL           URL сервисов для проверки доступности (опционально)

Примеры:
    $0
    $0 http://localhost:5000/health http://localhost:8080/health
    $0 --help

Функции:
  - Информация о системе (hostname, ОС, uptime, kernel)
  - Использование CPU, RAM и дисков
  - Список запущенных Docker-контейнеров (если Docker установлен)
  - Проверка доступности сервисов по HTTP
  - Запись результата в лог-файл с timestamp
EOF
}

# Функция проверки зависимостей
check_dependencies(){
  local deps=("curl" "docker")
  local missing=()

  for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
        echo "Ошибка: отсутствуют зависимости: ${missing[*]}"
        return 1
    fi
    return 0
}

# Функция сбора информации о системе
get_system_info() {
    echo "=== Server Diagnostics ==="
    echo "Date:     $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Hostname: $(hostname)"
    echo "OS:       $(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || echo 'Unknown')"
    echo "Kernel:   $(uname -r)"
    echo "Uptime:   $(uptime -p | sed 's/up //')"
    echo
}

# Функция сбора информации о ресурсах
get_resource_usage() {
    echo "=== Resources ==="

    # CPU
    local cpu_cores
    cpu_cores=$(nproc)
    local load_avg
    load_avg=$(uptime | grep -oE 'load average: [0-9.]+, [0-9.]+, [0-9.]+' | sed 's/load average: //')
    echo "CPU:      ${cpu_cores} cores, load average: ${load_avg}"

    # RAM
    local total_ram_kb
    total_ram_kb=$(free | awk '/^Mem:/ {print $2}')
    local used_ram_kb
    used_ram_kb=$(free | awk '/^Mem:/ {print $3}')
    local ram_usage_percent
    ram_usage_percent=$(awk "BEGIN {printf \"%.0f\", ($used_ram_kb/$total_ram_kb)*100}")
    local total_ram_gb
    total_ram_gb=$(awk "BEGIN {printf \"%.1fG\", $total_ram_kb/1024/1024}")
    local used_ram_gb
    used_ram_gb=$(awk "BEGIN {printf \"%.1fG\", $used_ram_kb/1024/1024}")
    echo "RAM:      ${used_ram_gb} / ${total_ram_gb} (${ram_usage_percent}%)"

    # Disk
    local disk_total_kb
    disk_total_kb=$(df -k / | tail -1 | awk '{print $2}')
    local disk_used_kb
    disk_used_kb=$(df -k / | tail -1 | awk '{print $3}')
    local disk_usage_percent
    disk_usage_percent=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
    local total_disk_gb
    total_disk_gb=$(awk "BEGIN {printf \"%.1fG\", $disk_total_kb/1024/1024}")
    local used_disk_gb
    used_disk_gb=$(awk "BEGIN {printf \"%.1fG\", $disk_used_kb/1024/1024}")
    echo "Disk /:   ${used_disk_gb} / ${total_disk_gb} (${disk_usage_percent}%)"
    echo
}

# Функция получения информации о Docker
get_docker_info() {
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        echo "=== Docker ==="
        docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}" 2>/dev/null
        echo
    else
        echo "=== Docker ==="
        echo "Docker не установлен или недоступен"
        echo
    fi
}


# Функция проверки доступности сервисов
check_services() {
    local urls=("$@")
    local total_services=${#urls[@]}
    local healthy_count=0

    if [ "$total_services" -eq 0 ]; then
        return 0
    fi

    echo "=== Service Health Checks ==="

    for url in "${urls[@]}"; do
        if curl -f -s -o /dev/null -w "%{http_code}" "$url" -m 5; then
            # local status_code=$(curl -f -s -o /dev/null -w "%{http_code}" "$url")
            local status_code
            status_code=$(curl -f -s -o /dev/null -w "%{http_code}" "$url" -m 5)
            if [ "$status_code" -eq 200 ] 2>/dev/null; then
              local response_time
              response_time=$(curl -f -s -o /dev/null -w "%{time_total}" "$url" -m 5)
              printf "[OK]   %s (%s, %.0fms)\n" "$url" "$status_code" "$(echo "$response_time * 1000" | bc -l 2>/dev/null || echo 0)"
            ((healthy_count++))
            else
            #printf "[FAIL] %s (connection refused)\n" "$url"
              printf "[FAIL] %s (HTTP %s or connection error)\n" "$url" "${status_code:-unknown}"
            fi
        fi
    done

    printf "\nResult: %d/%d services healthy\n" "$healthy_count" "$total_services"

    if [ "$healthy_count" -ne "$total_services" ]; then
        return 1
    else
        return 0
    fi
}

# Основная функция
main() {
    # Обработка аргумента --help
    if [[ "$*" == *"--help"* ]] || [[ "$1" == "--help" ]]; then
        show_help
        exit 0
    fi

    # Проверка зависимостей
    if ! check_dependencies; then
        exit 1
    fi

    # Создаём лог-файл, если его нет, и проверяем права
    if [ ! -f "$LOG_FILE" ]; then
        sudo touch "$LOG_FILE" 2>/dev/null || LOG_FILE="$HOME/server-diagnostics.log"
    fi

    if [ ! -w "$LOG_FILE" ]; then
        LOG_FILE="$HOME/server-diagnostics.log"
        echo "Предупреждение: нет прав на запись в /var/log. Используем $LOG_FILE"
    fi

#    # Сбор всех данных
#    {
#        get_system_info
#        get_resource_usage
#        get_docker_info
#
#        # Проверка сервисов, если переданы URL
#        if [ $# -gt 0 ] && [[ $1 != --* ]]; then
#            check_services "$@"
#            local service_result=$?
#        else
#            service_result=0
#        fi
#    } | tee -a "$LOG_FILE"
#
#    # Возврат кода ошибки, если какой‑то сервис недоступен
#    exit "$service_result"


    if [ $# -gt 0 ] && [[ $1 != --* ]]; then
      check_services "$@"
      service_result=$?
    else
      service_result=0
    fi

    {
      get_system_info
      get_resource_usage
      get_docker_info
    } | tee -a "$LOG_FILE"

    exit "$service_result"
}

# Запуск основной функции с передачей всех аргументов
main "$@"