# 自动系统信息显示脚本
适合armbian和debian系统server模式显示系统信息的环境变量修改，当前网络环境下如果无法拉取请尝试删除镜像加速地址，armbian和debian显示内容略有区别已基本满足使用。
# 版本
版本: v1.0.2
## 一键脚本：
```
bash <(curl -sL https://ghp.ci/https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/auto-sysinfo.sh)
```
# 系统信息显示内容
- **当前时间**
- **系统内核版本**
- **当前singbox版本**
- **singbox运行状态**
- **singbox内存占用**
- **防火墙状态**
- **cpu使用率**
- **内存使用率**
- **存储状况**
- **网络设置信息**
- **网络接口信息**
如果信息显示不精准或需要刷新，请尝试运行 ``` run-parts /etc/update-motd.d  ```进行检查校正。
# 界面展示
![Image text](https://raw.githubusercontent.com/qljsyph/bash-script/refs/heads/main/picture/image.png)