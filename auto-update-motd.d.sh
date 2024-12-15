#!/bin/bash

# 定义要检查的代码块
check_code='if [ -n "$SSH_CONNECTION" ]; then
 run-parts /etc/update-motd.d
fi'

# 精确检查代码块是否存在的函数
check_code_exists() {
    # 使用更严格的正则表达式和多行匹配
    grep -Pzq "$(echo "$1" | sed 's/[]\[\/().^$*]/\\&/g')" /etc/profile
}

# 执行精确检查
if ! check_code_exists "$check_code"; then
    # 如果未找到完全匹配的代码块
    echo "未找到完全匹配的代码块，准备添加..."
    
    # 确保文件以换行结尾
    sudo sed -i -e '$a\' /etc/profile
    
    # 追加代码块
    echo "$check_code" | sudo tee -a /etc/profile > /dev/null
    
    echo "代码块已成功添加到 /etc/profile"
else
    echo "完整的代码块已存在于 /etc/profile，跳过添加"
    exit 0
fi

# 选择操作系统类型：Debian 或 Armbian
read -p "请选择操作系统类型 (输入debian/armbian): " os_type
os_type=${os_type,,}  # 转换为小写

# 根据操作系统类型选择下载的文件
if [ "$os_type" == "debian" ]; then
    file_url="https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/20-debian-sysinfo"
    file_name="20-debian-sysinfo"
elif [ "$os_type" == "armbian" ]; then
    file_url="https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/20-armbian-sysinfo2"
    file_name="20-armbian-sysinfo"
else
    echo "无效的操作系统类型，退出脚本。"
    exit 1
fi

# 设置文件目标路径
file_dest="/etc/update-motd.d/$file_name"

# 检查文件是否已存在
if [ -f "$file_dest" ]; then
    # 文件已存在，修改文件名（添加时间戳）
    timestamp=$(date +%Y%m%d%H%M%S)
    new_file_dest="/etc/update-motd.d/$file_name-$timestamp"
    echo "文件已存在，新的文件名为：$new_file_dest"
    file_dest="$new_file_dest"
fi

# 下载文件
echo "正在从 GitHub 下载 $os_type 的文件..."
curl -s -o "$file_dest" "$file_url"

# 检查下载是否成功
if [ $? -eq 0 ]; then
    # 设置文件权限为 755
    chmod 755 "$file_dest"
    echo "文件已下载并设置权限为 755: $file_dest"
else
    echo "文件下载失败! 错误信息：$?"
fi
