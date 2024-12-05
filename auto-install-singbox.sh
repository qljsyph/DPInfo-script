#!/bin/bash

# 更新软件包
echo "正在更新软件包..."
sudo apt update -y

# 更新系统
echo "正在更新系统..."
sudo apt upgrade -y

# 检查 curl 是否已安装，如果没有安装则自动安装
if ! command -v curl &> /dev/null; then
    echo "curl 未安装，正在安装..."
    sudo apt update -y
    sudo apt install curl -y
else
    echo "curl 已安装。"
fi

# 检查是否已安装 sing-box
if ! command -v sing-box &> /dev/null; then
    echo "sing-box 未安装，开始安装..."
    sudo curl -fsSL https://sing-box.app/gpg.key -o /etc/apt/keyrings/sagernet.asc
    sudo chmod a+r /etc/apt/keyrings/sagernet.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/sagernet.asc] https://deb.sagernet.org/ * *" | \
    sudo tee /etc/apt/sources.list.d/sagernet.list > /dev/null
    sudo apt-get update
    sudo apt-get install sing-box -y
else
    echo "sing-box 已安装，当前版本信息如下："
    sing-box version
    echo "是否更新 sing-box？"
    echo "1 更新安装稳定版"
    echo "2 更新安装 beta 版"
    echo "3 不更新"
    read -p "请输入选择 (1/2/3): " choice
    case $choice in
        1)
            echo "正在安装稳定版..."
            sudo apt-get install sing-box -y
            ;;
        2)
            echo "正在安装 beta 版..."
            # 若有beta版的安装命令，可以在这里添加
            sudo apt-get install sing-box-beta -y
            ;;
        3)
            echo "不进行更新。"
            ;;
        *)
            echo "无效选择。"
            exit 1
            ;;
    esac
fi

# 检查 nftables 防火墙
if ! dpkg -l | grep -q nftables; then
    echo "nftables 防火墙未安装，正在安装..."
    sudo apt-get install nftables -y
else
    echo "nftables 防火墙已安装。"
fi

# 下载必要的脚本
echo "正在下载脚本..."
sudo curl -o /root/debian_tproxy.sh https://ghp.ci/https://raw.githubusercontent.com/qljsyph/EasySingbox/master/Linux/debian_tproxy.sh
sudo curl -o /root/tun_debian.sh https://ghp.ci/https://raw.githubusercontent.com/qljsyph/EasySingbox/master/Linux/tun_debian.sh
sudo curl -o /root/stop_debian_tproxy.sh https://ghp.ci/https://raw.githubusercontent.com/qljsyph/EasySingbox/master/Linux/stop_debian_tproxy.sh


# 赋予脚本执行权限
echo "正在赋予脚本执行权限..."
sudo chmod +x /root/debian_tproxy.sh /root/stop_debian_tproxy.sh /root/tun_debian.sh

# 提示输入后端地址
read -p "请输入后端地址 (例如 http://192.168.10.12:5000): " backend_address

# 替换脚本中的 BACKEND_URL
echo "正在替换脚本中的后端地址..."
sed -i "s|BACKEND_URL=\"http://192.168.10.12:5000\"|BACKEND_URL=\"$backend_address\"|g" /root/debian_tproxy.sh /root/tun_debian.sh

# 提示输入订阅链接
read -p "请输入订阅链接: " subscription_url
sed -i "s|SUBSCRIPTION_URL=\"\"|SUBSCRIPTION_URL=\"$subscription_url\"|g" /root/debian_tproxy.sh /root/tun_debian.sh

# 提示是否执行脚本
echo "脚本配置完成，选择是否执行："
echo "1 执行 debian_tproxy.sh"
echo "2 执行 tun_debian.sh"
echo "3 退出"
read -p "请输入选择 (1/2/3): " execute_choice

case $execute_choice in
    1)
        echo "正在执行 debian_tproxy.sh..."
        sudo /root/debian_tproxy.sh
        ;;
    2)
        echo "正在执行 tun_debian.sh..."
        sudo /root/tun_debian.sh
        ;;
    3)
        echo "退出。"
        exit 0
        ;;
    *)
        echo "无效选择。"
        exit 1
        ;;
esac