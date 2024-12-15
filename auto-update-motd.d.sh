#!/bin/bash

##!/bin/bash

# 定义要检查的代码块
check_code='if [ -n "$SSH_CONNECTION" ]; then
 run-parts /etc/update-motd.d
fi'

# 使用更精确的检查方法
check_precise() {
    # 使用 awk 进行精确匹配，忽略可能的空白和缩进差异
    awk -v code="$1" 'BEGIN{found=0} 
    # 去除代码块中的所有空白字符
    function strip(s) {
        gsub(/[ \t\r\n]/, "", s)
        return s
    }
    # 将文件中的每一行和目标代码块进行比较
    {
        current = current $0
        if (strip(current) == strip(code)) {
            found=1
            exit
        }
        # 如果当前累积的行超过了代码块长度，就移除最前面的行
        if (split(current, arr, "\n") > split(code, carr, "\n")) {
            sub(/^[^\n]*\n/, "", current)
        }
    }
    END {
        exit (found ? 0 : 1)
    }' /etc/profile
}

# 执行精确检查
if ! check_precise "$check_code"; then
    # 如果未找到完全匹配的代码块
    echo "未找到完全匹配的代码块，准备添加..."
    
    # 确保文件以换行结尾
    sudo sed -i -e '$a\' /etc/profile
    
    # 追加代码块
    echo "$check_code" | sudo tee -a /etc/profile > /dev/null
    
    echo "代码块已成功添加到 /etc/profile"
else
    echo "精确匹配的代码块已存在于 /etc/profile"
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
