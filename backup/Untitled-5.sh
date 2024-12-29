#!/bin/bash

# 检查 bc 命令
check_bc_installed() {
    if ! command -v bc &> /dev/null; then
        echo "bc 命令未安装，正在尝试安装..."

        # 检查操作系统并选择安装命令
        if [ -f /etc/debian_version ]; then
            sudo apt update && sudo apt install -y bc
        else
            echo "不支持的操作系统，请手动安装 bc 后重试。"
            exit 1
        fi

        # 再次检查 bc 是否安装成功
        if ! command -v bc &> /dev/null; then
            echo "安装 bc 失败，请检查网络或包管理器配置。"
            exit 1
        fi

        echo "bc 已成功安装。"
    else
        echo "bc 已安装，继续执行脚本。"
    fi
}

# 精确检查代码块是否存在（忽略空白和换行）
check_code_exists() {
    local normalized_file=$(grep -v '^\s*$' /etc/profile | tr -d '[:space:]')
    local normalized_code=$(echo "$1" | tr -d '[:space:]')

    if [[ "$normalized_file" == *"$normalized_code"* ]]; then
        return 0  # 找到完全匹配
    else
        return 1  # 未找到匹配
    fi
}

# 清理空的 SSH_CONNECTION 判断块
clean_empty_ssh_blocks() {
    echo "检查并清理空的 SSH_CONNECTION 判断块..."
    
    # 创建临时文件
    local temp_file=$(mktemp)
    
    # 使用 awk 删除空的 if [ -n "$SSH_CONNECTION" ]; then...fi 块
    awk '
    BEGIN { empty_block = 0; block_start = 0; buffer = "" }
    /if \[ -n "\$SSH_CONNECTION" \]; then/ { 
        empty_block = 1
        block_start = NR
        buffer = $0 "\n"
        next 
    }
    empty_block == 1 { 
        buffer = buffer $0 "\n"
        if ($0 ~ /^[[:space:]]*fi[[:space:]]*$/) {
            if (buffer !~ /run-parts/) {
                print "发现空块，行号:", block_start, "-", NR
                empty_block = 0
                buffer = ""
            } else {
                printf "%s", buffer
                empty_block = 0
                buffer = ""
            }
        } else if ($0 !~ /^[[:space:]]*$/) {
            printf "%s", buffer
            empty_block = 0
            buffer = ""
        }
        next
    }
    { print }
    ' /etc/profile > "$temp_file"

    # 检查是否有变化
    if ! cmp -s "$temp_file" /etc/profile; then
        echo "检测到空的 SSH_CONNECTION 判断块，正在清理..."
        sudo cp "$temp_file" /etc/profile
        echo "清理完成"
    else
        echo "未发现空的 SSH_CONNECTION 判断块"
    fi

    # 清理临时文件
    rm -f "$temp_file"
}

# 下载并设置 MOTD 脚本
download_motd_script() {
    # 选择操作系统类型：Debian 或 Armbian
    read -p "请选择操作系统类型 (输入debian/armbian/回车退出): " os_type
    os_type=${os_type,,} # 转换为小写

    # 根据操作系统类型选择下载的文件
    if [ "$os_type" == "debian" ]; then
        # 删除已有文件
        for file_name in "20-debian-sysinfo" "00-debian-heads"; do
            file_dest="/etc/update-motd.d/$file_name"
            if [ -f "$file_dest" ]; then
                echo "文件 $file_name 已存在，删除旧文件..."
                sudo rm -f "$file_dest"
            fi
        done
        
        # 下载两个文件
        file_url_1="https://ghproxy.net/https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/sysinfo/20-debian-sysinfo"
        file_url_2="https://ghproxy.net/https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/sysinfo/00-debian-heads"
        
        echo "正在下载 20-debian-sysinfo 文件..."
        curl -s -o "/etc/update-motd.d/20-debian-sysinfo" "$file_url_1"
        
        echo "正在下载 00-debian-heads 文件..."
        curl -s -o "/etc/update-motd.d/00-debian-heads" "$file_url_2"
        
        # 检查下载是否成功
        if [ $? -eq 0 ]; then
            chmod 755 /etc/update-motd.d/{20-debian-sysinfo,00-debian-heads}
            echo "Debian 文件已成功下载并设置权限为 755。"
        else
            echo "文件下载失败! 错误信息：$?"
            exit 1
        fi
    elif [ "$os_type" == "armbian" ]; then
        file_url="https://ghproxy.net/https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/sysinfo/20-armbian-sysinfo2"
        file_name="20-armbian-sysinfo2"

        # 删除已有文件并下载新的文件
        file_dest="/etc/update-motd.d/$file_name"
        if [ -f "$file_dest" ]; then
            echo "文件 $file_name 已存在，删除旧文件..."
            sudo rm -f "$file_dest"
        fi
        
        echo "正在从 GitHub 下载 Armbian 文件..."
        curl -s -o "$file_dest" "$file_url"

        # 检查下载是否成功
        if [ $? -eq 0 ]; then
            chmod 755 "$file_dest"
            echo "Armbian 文件已成功下载并设置权限为 755。"
        else
            echo "文件下载失败! 错误信息：$?"
            exit 1
        fi
    else
        echo "无效的操作系统类型，退出脚本。"
        exit 1
    fi

    # 检查下载的脚本是否依赖 bc
    if grep -q "bc" "$file_dest"; then
        echo "检测到 MOTD 脚本使用了 bc，确保其已正确安装..."
        check_bc_installed
    fi
}

# 备份并显示现有代码块
backup_and_show_existing_code() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="/tmp/profile_backup_${timestamp}"
    
    # 创建备份
    sudo cp /etc/profile "$backup_file"
    echo "已创建备份文件：$backup_file"
    
    # 查找并显示现有代码块
    echo "现有的相似代码块及其位置："
    echo "----------------------------------------"
    grep -n "run-parts /etc/update-motd.d" /etc/profile | while IFS=: read -r line_num content; do
        echo "行号: $line_num"
        echo "内容: $content"
        # 显示上下文（各显示1行）
        echo "上下文:"
        sed -n "$((line_num-1)),$((line_num+1))p" /etc/profile
        echo "----------------------------------------"
    done
    
    echo "请注意：如需手动恢复，可以使用以下命令："
    echo "sudo cp $backup_file /etc/profile"
    
    # 询问是否继续
    read -p "是否确认删除现有代码块并继续？(y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo "操作已取消"
        exit 1
    fi
    
    # 删除现有代码块
    sudo sed -i '/run-parts.*\/etc\/update-motd.d/d' /etc/profile
    echo "已删除现有代码块"
}

# 检查并添加代码块到 /etc/profile
handle_profile_modification() {
    local tool_choice=$1
    local check_code=""
    
    # 首先清理空的 SSH_CONNECTION 判断块
    clean_empty_ssh_blocks
    
    if [ "$tool_choice" == "1" ]; then
        # FinalShell/MobaXterm 的代码块
        check_code='if [ -n "$SSH_CONNECTION" ] && [ -z "$MOTD_SHOWN" ]; then
    export MOTD_SHOWN=1
    run-parts /etc/update-motd.d
fi'
        # 清空 /etc/motd 文件
        echo "清空 /etc/motd 文件..."
        sudo truncate -s 0 /etc/motd
        echo "/etc/motd 已清空"
    else
        # 原有的代码块
        check_code='if [ -n "$SSH_CONNECTION" ]; then
    run-parts /etc/update-motd.d
fi'
    fi

    if ! check_code_exists "$check_code"; then
        echo "检查是否存在类似的代码块..."
        
        # 检查是否存在相似的代码块
        existing_count=$(grep -c "run-parts /etc/update-motd.d" /etc/profile)

        if [ "$existing_count" -gt 0 ]; then
            echo "警告：已存在类似的代码块（$existing_count 处）"
            backup_and_show_existing_code
        fi

        # 确保文件以换行结尾
        sudo sed -i -e '$a\\' /etc/profile

        # 追加新的代码块
        echo "$check_code" | sudo tee -a /etc/profile > /dev/null

        echo "新的代码块已成功添加到模块"
    else
        echo "完整的代码块已存在于模块，跳过添加"
    fi
}

# 主脚本逻辑
main() {
    # 检查是否安装了 bc
    check_bc_installed

    # 选择工具类型
    echo "请选择使用的工具类型："
    echo "1. FinalShell/MobaXterm"
    echo "2. 其他工具(ServerBox等)"
    read -p "请输入选项 (1 或 2): " tool_choice

    # 验证输入
    if [[ ! "$tool_choice" =~ ^[12]$ ]]; then
        echo "无效的选项，请输入 1 或 2"
        exit 1
    fi

    # 处理 profile 修改
    handle_profile_modification "$tool_choice"

    # 执行下载 MOTD 脚本
    download_motd_script
}

# 运行主脚本
main