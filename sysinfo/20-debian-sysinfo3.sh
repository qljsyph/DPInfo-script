#!/bin/bash

RESET="\033[0m"
PURPLE="\033[1;35m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"

echo -e "${PURPLE}欢迎来到 私人服务 系统！${RESET}"
echo -e "${BLUE}当前时间：$(date '+%Y-%m-%d %H:%M:%S')${RESET}"
echo -e "${BLUE}系统内核版本：$(uname -r)${RESET}"
echo -e "${BLUE}系统已运行：$(uptime -p)${RESET}"

check_mihomo_service() {
    echo -e "\n${CYAN}检查 mihomo 服务状态：${RESET}"
    # shellcheck disable=SC2317
    if systemctl is-active --quiet mihomo; then
        echo -e "${GREEN}mihomo 服务正在运行${RESET}"
    else
        echo -e "${RED}mihomo 服务未运行${RESET}"
    fi
}


export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export TERM=xterm

CPU=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5); printf "%.2f", usage}')
echo -e "${YELLOW}CPU 使用率：${RESET}${CPU}%, 空闲: $(echo "100 - $CPU" | bc)%"

mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_free=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
mem_used=$((mem_total - mem_free))
mem_usage=$(awk -v used=$mem_used -v total=$mem_total 'BEGIN {printf "%.2f", (used/total)*100}')
echo -e "${YELLOW}当前内存使用情况：${RESET}$((mem_used / 1024))/$((mem_total / 1024)) MB (${mem_usage}%)"

disk_usage=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}')
echo -e "${YELLOW}当前磁盘使用情况：${RESET}${disk_usage}"

if [[ -f /run/systemd/resolve/resolv.conf ]]; then
    DNS_SERVERS=$(grep '^nameserver' /run/systemd/resolve/resolv.conf | awk '{print $2}')
else
    DNS_SERVERS=$(grep '^nameserver' /etc/resolv.conf | awk '{print $2}')
fi

echo -n -e "${YELLOW}DNS 服务器地址:${RESET} "
if [[ -n "$DNS_SERVERS" ]]; then
    for dns in $DNS_SERVERS; do
        echo -n "  $dns"
    done
    echo
else
    echo -e "${RED}未找到 DNS 服务器信息！${RESET}"
fi

DEFAULT_GATEWAY=$(ip route | awk '/default/ {print $3}')
echo -n -e "${YELLOW}默认网关:${RESET} "
[[ -n "$DEFAULT_GATEWAY" ]] && echo "$DEFAULT_GATEWAY" || echo -e "${RED}未找到默认网关信息！${RESET}"

GATEWAY_INTERFACE=$(ip route | awk '/default/ {print $5}')
echo -n -e "${YELLOW}网关接口:${RESET} "
[[ -n "$GATEWAY_INTERFACE" ]] && echo "$GATEWAY_INTERFACE" || echo -e "${RED}未找到网关接口信息！${RESET}"

echo -e "${BLUE}网络接口信息：${RESET}"
for interface in $(ip -o -4 addr show | awk '{print $2}' | sort | uniq); do
    [[ "$interface" =~ ^(lo|docker0|br0)$ ]] && continue
    MAC_ADDRESS=$(cat /sys/class/net/"$interface"/address 2>/dev/null)
    IP_ADDRESS=$(ip -o -4 addr show "$interface" | awk '{print $4}' | cut -d'/' -f1)
    IS_DHCP=$(grep -qE "iface\s+$interface\s+inet\s+dhcp" /etc/network/interfaces 2>/dev/null && echo "DHCP 分配" || echo "静态 IP")
    echo -e "${YELLOW}接口:${RESET} $interface"
    echo -e "  ${BLUE}MAC 地址:${RESET} $MAC_ADDRESS"
    echo -e "  ${BLUE}IP 地址:${RESET} ${IP_ADDRESS:-未分配}"
    echo -e "  ${BLUE}IP 类型:${RESET} $IS_DHCP"
done

check_mihomo_service

exit