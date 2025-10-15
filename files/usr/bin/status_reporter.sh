#!/bin/ash

# 读取 UCI 配置
config_file="/etc/config/luci_mailreport"
. /lib/functions/uci-defaults.sh

# 检查是否启用
if [ "$(uci_get $config_file settings enabled 0)" != "1" ]; then
    exit 0
fi

# 获取邮件配置
SMTP_SERVER=$(uci_get $config_file settings smtp_server)
SMTP_PORT=$(uci_get $config_file settings smtp_port 465)
SMTP_USER=$(uci_get $config_file settings smtp_user)
SMTP_PASS=$(uci_get $config_file settings smtp_password)
RECIPIENT=$(uci_get $config_file settings recipient)
SENDER_EMAIL=$(uci_get $config_file settings sender_email "OpenWrt@$(uname -n)")
SENDER_HOST=$(uname -n)
AUTH_STR=$(echo -n "$SMTP_USER" | base64)
PASS_STR=$(echo -n "$SMTP_PASS" | base64)

# -----------------
# 状态信息收集 (最小化依赖，使用内置命令)
# -----------------
UPTIME=$(awk '{print $1}' /proc/uptime)
UPTIME_DAYS=$(($UPTIME / 86400))
UPTIME_HOURS=$((($UPTIME % 86400) / 3600))
LOAD=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')
MEMORY_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
MEMORY_FREE=$(awk '/MemFree/ {print $2}' /proc/meminfo)
MEMORY_AVAILABLE=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)

# 避免使用 jsonfilter，直接用 grep/sed 解析 ubus 输出的简单 JSON
# 查找 "address": "X.X.X.X", 并提取 X.X.X.X
WAN_IP=$(ubus call network.interface.wan status 2>/dev/null | \
         grep -o '"address": "[0-9.]*"' | \
         sed 's/"address": "//; s/"//')

if [ -z "$WAN_IP" ]; then
    WAN_IP="N/A (WAN not connected or configured)"
fi

# 格式化邮件内容 (RFC 822 头部和正文)
MAIL_DATE=$(date -R)
MAIL_SUBJECT="OpenWrt 状态报告 - $(date +%F)"

MAIL_BODY="OpenWrt 路由器运行状态：
--------------------------------
当前时间：$(date)
系统名称：${SENDER_HOST}
已运行时间：${UPTIME_DAYS} 天 ${UPTIME_HOURS} 小时
平均负载 (1/5/15 分钟)：${LOAD}
WAN IP 地址：${WAN_IP}

内存使用情况 (KB)：
  总内存：${MEMORY_TOTAL}
  可用：${MEMORY_AVAILABLE}
  剩余：${MEMORY_FREE}
--------------------------------"

# -----------------
# 使用 openssl 发送邮件 (SMTPS 模式，需要 openssl-client)
# -----------------

{
    echo "HELO ${SENDER_HOST}"
    sleep 1
    echo "AUTH LOGIN"
    sleep 1
    echo "${AUTH_STR}"
    sleep 1
    echo "${PASS_STR}"
    sleep 1
    echo "MAIL FROM: <${SENDER_EMAIL}>"
    sleep 1
    echo "RCPT TO: <${RECIPIENT}>"
    sleep 1
    echo "DATA"
    sleep 1
    echo "From: ${SENDER_EMAIL}"
    echo "To: ${RECIPIENT}"
    echo "Subject: ${MAIL_SUBJECT}"
    echo "Date: ${MAIL_DATE}"
    echo "MIME-Version: 1.0"
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    echo "${MAIL_BODY}"
    echo "."
    sleep 1
    echo "QUIT"
} | openssl s_client -quiet -crlf -connect "${SMTP_SERVER}":"${SMTP_PORT}" > /dev/null 2>&1

exit 0