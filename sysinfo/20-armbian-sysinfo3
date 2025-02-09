#!/bin/bash

RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
CYAN="\033[1;36m"
RESET="\033[0m"

echo -e "${CYAN}欢迎来到私人服务系统！${RESET}"
echo -e "${PURPLE}当前时间：$(date '+%Y-%m-%d %H:%M:%S')${RESET}"
echo -e "${BLUE}系统内核版本：$(uname -r)${RESET}"
echo -e "${GREEN}项目地址：https://github.com/qljsyph/bash-script 版本v1.2.5beta ${RESET}"

check_mihomo_service() {
    echo -e "\n${CYAN}检查 mihomo 服务状态：${RESET}"
    if systemctl is-active --quiet mihomo; then
        echo -e "${GREEN}mihomo 服务正在运行${RESET}"
    else
        echo -e "${RED}mihomo 服务未运行${RESET}"
    fi
}

check_system_resources() {
    echo -e "\n${CYAN}系统资源信息：${RESET}"
    CPU_INFO=$(top -bn1 | grep "Cpu(s)" | awk '{if (NF >= 8) printf "使用率: %.1f%%, 空闲: %.1f%%", $2, $8}')
    echo -e "${BLUE}CPU 状态：${RESET}${CPU_INFO}"
    MEM_INFO=$(free -h | awk '/^Mem/ {printf "%s/%s (%.1f%%)", $3, $2, $3/$2*100}')
    echo -e "${BLUE}内存使用：${RESET}${MEM_INFO}"
    DISK_INFO=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}')
    echo -e "${BLUE}磁盘使用：${RESET}${DISK_INFO}"
}

check_network() {
    echo -e "\n${CYAN}网络信息：${RESET}"
    DEFAULT_GATEWAY=$(ip route | awk '/default/ {print $3}')
    GATEWAY_INTERFACE=$(ip route | awk '/default/ {print $5}')
    [[ -n "$DEFAULT_GATEWAY" ]] && echo -e "${BLUE}默认网关：${RESET}${DEFAULT_GATEWAY}\n${BLUE}网关接口：${RESET}${GATEWAY_INTERFACE}" || echo -e "${RED}未找到默认网关信息！${RESET}"
    if [[ -f /run/systemd/resolve/resolv.conf ]]; then
        DNS_SERVERS=$(grep '^nameserver' /run/systemd/resolve/resolv.conf | awk '{print $2}')
    else
        DNS_SERVERS=$(grep '^nameserver' /etc/resolv.conf | awk '{print $2}')
    fi
    [[ -n "$DNS_SERVERS" ]] && echo -e "${BLUE}DNS 服务器：${RESET}\n$DNS_SERVERS" || echo -e "${RED}未找到 DNS 服务器信息！${RESET}"
}

check_mihomo_service
check_system_resources
check_network