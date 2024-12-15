#!/bin/bash

# 定义要检查的代码块
check_code='if [ -n "$SSH_CONNECTION" ]; then
    run-parts /etc/update-motd.d
fi'

# 检查 /etc/profile 是否已经包含要添加的代码块
if ! grep -qF -- "$check_code" /etc/profile; then
    # 将代码追加到 /etc/profile 的末尾
    echo -e "$check_code" >> /etc/profile
    echo "内容已添加到 /etc/profile"
else
    echo "所需内容已存在于 /etc/profile"
fi
