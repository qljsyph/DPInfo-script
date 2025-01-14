#!/bin/bash
# v 1.2.2

check_bc_installed() {
    if ! command -v bc &> /dev/null; then
        echo "bc 命令未安装，正在尝试安装..."
        if [ -f /etc/debian_version ]; then
            sudo apt update && sudo apt install -y bc
        else
            echo "不支持的操作系统，请手动安装 bc 后重试。"
            exit 1
        fi
        if ! command -v bc &> /dev/null; then
            echo "安装 bc 失败，请检查网络或包管理器配置。"
            exit 1
        fi
        echo "bc 已成功安装。"
    else
        echo "bc 已安装，继续执行脚本。"
    fi
}

check_code_exists() {
    local normalized_file
    normalized_file=$(grep -v '^\s*$' /etc/profile | tr -d '[:space:]')
    local normalized_code
    normalized_code=$(echo "$1" | tr -d '[:space:]')
    if [[ "$normalized_file" == *"$normalized_code"* ]]; then
        return 0
    else
        return 1
    fi
}

remove_motd() {
    echo "正在执行删除操作..."

    sudo sed -i '/^if \[ -n "\$SSH_CONNECTION" \]; then/,/^fi$/ { /^if \[ -z "\$MOTD_SHOWN" \]; then/,/^fi$/d; /^fi$/d; }' /etc/profile
    sudo sed -i '/^if \[ -n "\$SSH_CONNECTION" \] && \[ -z "\$MOTD_SHOWN" \]; then/,/^fi$/d' /etc/profile
    sudo sed -i '/^if \[ -n "\$SSH_CONNECTION" \]; then/,/^fi$/d' /etc/profile
    
    for file in "00-debian-heads" "20-debian-sysinfo" "20-debian-sysinfo2" "20-armbian-sysinfo2"; do
        [ -f "/etc/update-motd.d/$file" ] && sudo rm -f "/etc/update-motd.d/$file" 2>/dev/null
    done
    
    echo "删除完成"
}

download_motd_script() {
    read -r -p "请选择操作系统类型（输入 debian/armbian/回车退出）: " os_type
    os_type=${os_type,,}
    if [ "$os_type" == "debian" ]; then
        read -r -p "选择 Debian 版本（输入 1: sing-box 版 2: 普通版）: " debian_choice
        case $debian_choice in
            1)
                file_url_1="https://ghproxy.cc/https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/sysinfo/00-debian-heads"
                file_url_2="https://ghproxy.cc/https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/sysinfo/20-debian-sysinfo"
                ;;
            2)
                file_url_1="https://ghproxy.cc/https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/sysinfo/00-debian-heads"
                file_url_2="https://ghproxy.cc/https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/sysinfo/20-debian-sysinfo2"
                ;;
            *)
                echo "无效选项，请输入 1 或 2"
                exit 1
                ;;
        esac

        for file_name in "00-debian-heads" "20-debian-sysinfo"; do
            file_dest="/etc/update-motd.d/$file_name"
            if [ -f "$file_dest" ]; then
                if [ "$file_name" == "00-debian-heads" ]; then
                    echo "文件 1 已存在，删除旧文件..."
                else
                    echo "文件 2 已存在，删除旧文件..."
                fi
                sudo rm -f "$file_dest"
            fi
        done
        echo "正在下载文件 1..."
        curl -s -o "/etc/update-motd.d/00-debian-heads" "$file_url_1"
        download_status_1=$?
        echo "正在下载文件 2..."
        curl -s -o "/etc/update-motd.d/20-debian-sysinfo" "$file_url_2"
        download_status_2=$?
        if [ $download_status_1 -eq 0 ] && [ $download_status_2 -eq 0 ]; then
            chmod 755 /etc/update-motd.d/{00-debian-heads,20-debian-sysinfo}
            echo "Debian 文件已成功下载并设置权限为 755。"
        else
            echo "文件下载失败! 错误信息：$download_status_2"
            exit 1
        fi
    elif [ "$os_type" == "armbian" ]; then
        file_url="https://ghproxy.cc/https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/sysinfo/20-armbian-sysinfo2"
        file_name="20-armbian-sysinfo2"
        file_dest="/etc/update-motd.d/$file_name"
        if [ -f "$file_dest" ]; then
            echo "文件已存在，删除旧文件..."
            sudo rm -f "$file_dest"
        fi
        echo "正在从 GitHub 下载文件..."
        curl -s -o "$file_dest" "$file_url"
        download_status=$?
        if [ $download_status -eq 0 ]; then
            chmod 755 "$file_dest"
            echo "Armbian 文件已成功下载并设置权限为 755。"
        else
            echo "文件下载失败! 错误信息：$download_status"
            exit 1
        fi
    else
        echo "无效的操作系统类型，退出脚本。"
        exit 1
    fi
    if grep -q "bc" "$file_dest"; then
        echo "检测到脚本使用了 bc，确保其已正确安装..."
        check_bc_installed
    fi
}

handle_profile_modification() {
    local tool_choice=$1
    local check_code=""
    if [ "$tool_choice" == "1" ]; then
        check_code="if [ -n \"\$SSH_CONNECTION\" ] && [ -z \"\$MOTD_SHOWN\" ]; then
    export MOTD_SHOWN=1
    run-parts /etc/update-motd.d
fi"
        echo "正在清空标志区文件..."
        sudo truncate -s 0 /etc/motd
        echo "标志区文件已清空。"
    else
        check_code="if [ -n \"\$SSH_CONNECTION\" ]; then
    if [ -z \"\$MOTD_SHOWN\" ]; then
        export MOTD_SHOWN=1
        run-parts /etc/update-motd.d
    fi
fi"
    fi
    if ! check_code_exists "$check_code"; then
        echo "未找到完全匹配的代码块，准备添加..."
        existing_count=$(grep -c "run-parts /etc/update-motd.d" /etc/profile)
        if [ "$existing_count" -gt 0 ]; then
            echo "警告：已存在类似的代码块（$existing_count 处）"
            echo "请手动检查 /etc/profile 中包含 update-motd.d 的完整代码块，确认后手动删除重新执行脚本。"
            exit 1
        fi
        sudo sed -i -e '$a\\' /etc/profile
        echo "$check_code" | sudo tee -a /etc/profile > /dev/null
        echo "代码块已成功添加到模块"
    else
        echo "完整的代码块已存在于模块，跳过添加"
    fi
}

main() {
    echo "请选择操作："
    echo "1. 安装"
    echo "2. 删除"
    read -r -p "请输入选项（1 或 2）: " operation_choice
    
    case $operation_choice in
        1)
            echo "开始安装..."
            check_bc_installed
            download_motd_script
            echo "请选择使用的工具类型（必看 wiki）："
            echo "1. FinalShell/MobaXterm"
            echo "2. 其他工具(ServerBox 等)"
            read -r -p "请输入选项（1 或 2）: " tool_choice
            if [[ ! "$tool_choice" =~ ^[12]$ ]]; then
                echo "无效的选项，请输入 1 或 2"
                exit 1
            fi
            handle_profile_modification "$tool_choice"
            ;;
        2)
            remove_motd
            ;;
        *)
            echo "无效的选项，请输入 1 或 2"
            exit 1
            ;;
    esac
}

main