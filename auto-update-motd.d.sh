#!/bin/bash

# 检查 /etc/profile 是否已经包含完整的代码块
grep -q 'if [ -n "$SSH_CONNECTION" ]; then' /etc/profile && \
grep -q 'run-parts /etc/update-motd.d' /etc/profile && \
grep -q 'fi' /etc/profile

if [ $? -ne 0 ]; then
    # 将代码追加到 /etc/profile 的末尾
    echo -e '\nif [ -n "$SSH_CONNECTION" ]; then\n    run-parts /etc/update-motd.d\nfi' >> /etc/profile
    echo "内容已添加到 /etc/profile"
else
    echo "所需内容已存在于 /etc/profile"
fi
