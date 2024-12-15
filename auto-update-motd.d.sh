#!/bin/bash

# 定义要检查的代码块
check_code='if [ -n "$SSH_CONNECTION" ]; then
    run-parts /etc/update-motd.d
fi'

# 检查 /etc/profile 是否已经包含要添加的代码块
echo "正在检查 /etc/profile 是否已经包含所需的代码块..."
if ! grep -qF -- "$check_code" /etc/profile; then
    # 如果没有找到，则将代码追加到 /etc/profile 的末尾
    echo -e "$check_code" | sudo tee -a /etc/profile > /dev/null
    echo "内容已添加到 /etc/profile"
else
    echo "所需内容已存在于 /etc/profile"
fi

# 下载并放入 /etc/update-motd.d 目录
file_url="https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/20-debian-sysinfo"
file_dest="/etc/update-motd.d/20-debian-sysinfo"

# 检查文件是否已存在
if [ -f "$file_dest" ]; then
    # 文件已存在，修改文件名（添加时间戳）
    timestamp=$(date +%Y%m%d%H%M%S)
    new_file_dest="/etc/update-motd.d/20-debian-sysinfo-$timestamp"
    echo "文件已存在，新的文件名为：$new_file_dest"
    file_dest="$new_file_dest"
fi

# 下载文件
echo "正在从 GitHub 下载文件..."
curl -s -o "$file_dest" "$file_url"

# 检查下载是否成功
if [ $? -eq 0 ]; then
    # 设置文件权限为 755
    chmod 755 "$file_dest"
    echo "文件已下载并设置权限为 755: $file_dest"
else
    echo "文件下载失败! 错误信息：$?"
fi
