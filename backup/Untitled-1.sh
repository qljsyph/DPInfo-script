#!/bin/bash

# 欢迎界面和系统基本信息
echo -e "\033[1;35m欢迎来到 私人服务 系统！\033[0m"
echo -e "\033[1;34m当前时间：$(date '+%Y-%m-%d %H:%M:%S')\033[0m"
echo -e "\033[1;34m系统内核版本：$(uname -r)\033[0m"
echo -e "\033[1;34m系统已运行：$(uptime -p)\033[0m"

# Sing-box 状态检查
if command -v sing-box >/dev/null 2>&1; then
    SINGBOX_VERSION=$(sing-box version 2>/dev/null | head -n 1 || echo "未知版本")
    echo -e "\033[1;32m当前 sing-box 版本:\033[0m $SINGBOX_VERSION"
    if systemctl is-active --quiet sing-box; then
        echo -e "\033[1;32mSing-box 服务正在运行\033[0m"
        SINGBOX_MEMORY=$(ps -o rss= -C sing-box | awk '{total += $1} END {printf "%.2f", total/1024}')
        echo -e "\033[1;34mSing-box 内存占用:\033[0m ${SINGBOX_MEMORY:-未知} MB"
    else
        echo -e "\033[1;31mSing-box 服务未运行\033[0m"
    fi
else
    echo -e "\033[1;31mSing-box 未安装或不可用！\033[0m"
fi

# 检查防火墙状态
if command -v nft >/dev/null 2>&1; then
    if systemctl is-active --quiet nftables; then
        echo -e "\033[1;36mNftables 防火墙已启用\033[0m"
    else
        echo -e "\033[1;35mNftables 防火墙未运行\033[0m"
    fi
else
    echo -e "\033[1;31mNftables 防火墙未安装！\033[0m"
fi

# 系统资源使用情况
CPU=$(awk '/^cpu / {usage=($2+$4)*100/($2+$4+$5); printf "%.2f", usage}' /proc/stat)
mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_free=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
mem_used=$((mem_total - mem_free))
mem_usage=$(awk -v used=$mem_used -v total=$mem_total 'BEGIN {printf "%.2f", (used/total)*100}')
disk_usage=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}')
echo -e "\033[1;33mCPU 使用率：\033[0m${CPU}%, 空闲: $(echo "100 - $CPU" | bc)%"
echo -e "\033[1;33m内存使用：\033[0m$((mem_used / 1024))/$((mem_total / 1024)) MB (${mem_usage}%)"
echo -e "\033[1;33m磁盘使用：\033[0m${disk_usage}"

# 网络信息：默认网关和接口
DEFAULT_GATEWAY=$(ip route | awk '/default/ {print $3}')
GATEWAY_INTERFACE=$(ip route | awk '/default/ {print $5}')
if [[ -n "$DEFAULT_GATEWAY" ]]; then
    echo -e "\033[1;34m默认网关:\033[0m $DEFAULT_GATEWAY"
    echo -e "\033[1;34m网关接口:\033[0m $GATEWAY_INTERFACE"
else
    echo -e "\033[1;31m未找到默认网关信息！\033[0m"
fi

# DNS 信息
DNS_SERVERS=$(grep '^nameserver' /etc/resolv.conf 2>/dev/null | awk '!seen[$2]++ {print $2}')
if [[ -n "$DNS_SERVERS" ]]; then
    echo -e "\033[1;34mDNS 服务器地址:\033[0m"
    for dns in $DNS_SERVERS; do
        echo "  $dns"
    done
else
    echo -e "\033[1;31m未找到 DNS 服务器信息！\033[0m"
fi

# 网络接口详细信息
echo -e "\033[1;33m网络接口信息：\033[0m"
for interface in $(ls /sys/class/net); do
    [[ "$interface" == "lo" || "$interface" =~ ^(docker|br|veth) ]] && continue
    MAC_ADDRESS=$(cat /sys/class/net/"$interface"/address 2>/dev/null)
    IP_ADDRESS=$(ip -4 -o addr show "$interface" | awk '{print $4}' | cut -d'/' -f1)
    echo -e "\033[1;34m接口:\033[0m $interface"
    echo -e "  \033[1;34mMAC 地址:\033[0m ${MAC_ADDRESS:-未知}"
    echo -e "  \033[1;34mIP 地址:\033[0m ${IP_ADDRESS:-未分配}"
done

# 检查可用更新
if command -v apt >/dev/null 2>&1; then
    UPDATES=$(apt list --upgradable 2>/dev/null | wc -l)
    echo -e "\033[1;33m待更新的软件包数量：\033[0m $((UPDATES - 1))"
else
    echo -e "\033[1;31m无法检查更新状态（APT 未安装）！\033[0m"
fi
