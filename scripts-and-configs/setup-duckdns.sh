#!/bin/bash

# DuckDNS自动更新脚本
# 将YOUR_DOMAIN和YOUR_TOKEN替换为实际值

DOMAIN="itwords"  # 您的DuckDNS域名（不包括.duckdns.org）
TOKEN="YOUR_TOKEN"  # 从DuckDNS获取的token

# 创建更新脚本
cat > /home/ec2-user/duckdns-update.sh << EOF
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=${DOMAIN}&token=${TOKEN}&ip=" | curl -k -o /tmp/duck.log -K -
EOF

chmod +x /home/ec2-user/duckdns-update.sh

# 设置cron任务，每5分钟更新一次
echo "*/5 * * * * /home/ec2-user/duckdns-update.sh >/dev/null 2>&1" | crontab -

# 立即运行一次
/home/ec2-user/duckdns-update.sh

echo "DuckDNS配置完成！"
echo "您的域名: ${DOMAIN}.duckdns.org"
echo "请确保已将TOKEN替换为您从DuckDNS获取的实际token" 