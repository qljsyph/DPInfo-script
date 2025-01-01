#!/bin/bash
#v1.1.2

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
    local normalized_file normalized_code
    normalized_file=$(grep -v '^\s*$' /etc/profile | tr -d '[:space:]')
    normalized_code=$(echo "$1" | tr -d '[:space:]')
    [[ "$normalized_file" == *"$normalized_code"* ]]
}

download_motd_script() {
    read -r -p "请选择操作系统类型 (输入debian/armbian/回车退出): " os_type
    os_type=${os_type,,}
    case "$os_type" in
        debian)
            local file_dest_1="/etc/update-motd.d/00-debian-heads"
            local file_dest_2="/etc/update-motd.d/20-debian-sysinfo"
            local file_url_1="https://ghgo.xyz/https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/sysinfo/00-debian-heads"
            local file_url_2="https://ghgo.xyz/https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/sysinfo/20-debian-sysinfo"
            ;;
        armbian)
            local file_dest="/etc/update-motd.d/20-armbian-sysinfo2"
            local file_url="https://ghgo.xyz/https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/sysinfo/20-armbian-sysinfo2"
            ;;
        *)
            echo "无效的操作系统类型，退出脚本。"
            exit 1
            ;;
    esac

    if [ "$os_type" == "debian" ]; then
        for file in "$file_dest_1" "$file_dest_2"; do
            [ -f "$file" ] && sudo rm -f "$file"
        done
        curl -s -o "$file_dest_1" "$file_url_1" && curl -s -o "$file_dest_2" "$file_url_2"
        if [ $? -eq 0 ]; then
            chmod 755 "$file_dest_1" "$file_dest_2"
            echo "文件1和文件2已成功下载并设置权限为 755。"
        else
            echo "文件下载失败!"
            exit 1
        fi
    else
        [ -f "$file_dest" ] && sudo rm -f "$file_dest"
        curl -s -o "$file_dest" "$file_url"
        if [ $? -eq 0 ]; then
            chmod 755 "$file_dest"
            echo "Armbian 文件已成功下载并设置权限为 755。"
        else
            echo "文件下载失败!"
            exit 1
        fi
    fi

    if grep -q "bc" "$file_dest"; then
        echo "检测到脚本使用了 bc依赖，确保其已正确安装..."
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
        sudo truncate -s 0 /etc/motd
    else
        check_code="if [ -n \"\$SSH_CONNECTION\" ]; then
 run-parts /etc/update-motd.d
fi"
    fi

    if ! check_code_exists "$check_code"; then
        if grep -q "run-parts /etc/update-motd.d" /etc/profile; then
            echo "警告：已存在类似的代码块，请手动检查 /etc/profile 中包含update-motd.d的完整代码块，确认后手动删除重新执行脚本。"
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
    check_bc_installed
    echo "请选择使用的工具类型："
    echo "1. FinalShell/MobaXterm"
    echo "2. 其他工具(ServerBox等)"
    read -r -p "请输入选项 (1 或 2): " tool_choice
    if [[ ! "$tool_choice" =~ ^[12]$ ]]; then
        echo "无效的选项，请输入 1 或 2"
        exit 1
    fi
    handle_profile_modification "$tool_choice"
    download_motd_script
}

main
