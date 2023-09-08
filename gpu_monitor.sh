#!/bin/bash

echo "配置GPU空闲监控..."

rm -rf /tmp/autodl_idle_gpu_monitor
cd /tmp
git clone https://github.com/iioSnail/autodl_idle_gpu_monitor.git

cd autodl_idle_gpu_monitor

pip install -r requirements.txt

cp /tmp/autodl_idle_gpu_monitor/gpu_monitor.py /usr/local/bin/gpu_monitor

chmod +x /usr/local/bin/gpu_monitor

echo "请输入Token（用于微信通知配置，参考文档：https://www.autodl.com/docs/msg/）"
read token

echo "请输入最大闲置时长（分钟）"
read max_idle

echo "nohup sh gpu_monitor -c -m $max_idle" > /etc/profile.d/gpu_monitor.sh

echo "是否自动关机(y/n)"
read shutdown

if [ "$shutdown" == "y" ]; then
    echo "请输入等待时长（分钟）。通知微信后，等待一定时间后关机"
    read wait_time

    echo " -s -w $wait_time" >> /etc/profile.d/gpu_monitor.sh

    nohup sh gpu_monitor -c -m $max_idle -s -w $wait_time &
else
    echo "不设置自动关机"
    nohup sh gpu_monitor -c -m $max_idle &
fi

echo " &" >> /etc/profile.d/gpu_monitor.sh

echo "配置完成！"
echo "当GPU空闲超过$max_idle 分钟后通知微信"

if [ "$shutdown" == "y" ]; then
   echo "当通知微信后，再过$wait_time 分钟后自动关机"
fi

