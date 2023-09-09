#!/bin/bash

echo "配置GPU空闲监控..."

rm -rf /tmp/autodl_idle_gpu_monitor
cd /tmp
git clone https://github.com/iioSnail/autodl_idle_gpu_monitor.git

cd autodl_idle_gpu_monitor

pip install -r requirements.txt

cp /tmp/autodl_idle_gpu_monitor/gpu_monitor.py /usr/local/bin/gpu_monitor

chmod +x /usr/local/bin/gpu_monitor

echo "请输入Token（用于微信通知配置，参考文档：https://www.autodl.com/docs/msg/）:"
read token

while true; do
  echo -n "请输入最大闲置时长（分钟）:"
  read max_idle

  if [[ "$max_idle" =~ ^[0-9]+$ ]]; then
    break
  else
    echo "max_idle只能为数字，请重新输入!"
  fi
done


echo "#!/bin/bash" > /etc/profile.d/gpu_monitor.sh
echo -n "nohup gpu_monitor -c -m $max_idle" >> /etc/profile.d/gpu_monitor.sh

echo -n "是否自动关机(y/n): "
read shutdown

if [ "$shutdown" = "y" ]; then

    while true; do
      echo -n "请输入等待时长（分钟）。通知微信后，等待一定时间后关机:"
      read wait_time

      if [[ "$wait_time" =~ ^[0-9]+$ ]]; then
        break
      else
        echo "wait_time只能为数字，请重新输入!"
      fi
    done

    echo -n " -s -w $wait_time" >> /etc/profile.d/gpu_monitor.sh
else
    echo "不设置自动关机"
fi

echo -n " -t $token" >> /etc/profile.d/gpu_monitor.sh

echo -n " &" >> /etc/profile.d/gpu_monitor.sh

echo "配置完成！"
echo "当GPU空闲超过 $max_idle 分钟后通知微信"

if [ "$shutdown" = "y" ]; then
   echo "当通知微信后，再过 $wait_time 分钟后自动关机"
fi

echo "你可通过”/etc/profile.d/gpu_monitor.sh“文件查看或修改开机启动脚本"

echo "你可通过”tail -f /tmp/gpu_monitor.log“查看日志"

bash /etc/profile.d/gpu_monitor.sh
echo "程序后台启动成功！以下是输出日志（可以ctrl-c，不影响程序继续运行）"
tail -f /tmp/gpu_monitor.log