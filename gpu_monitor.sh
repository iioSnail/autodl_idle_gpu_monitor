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

echo 'pid=$(pgrep -f "python /usr/local/bin/gpu_monitor")' >> /etc/profile.d/gpu_monitor.sh
echo 'if [ -z "$pid" ]; then' >> /etc/profile.d/gpu_monitor.sh
echo '  echo "启动GPU限制监控程序"' >> /etc/profile.d/gpu_monitor.sh

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

    echo " -s -w $wait_time \\" >> /etc/profile.d/gpu_monitor.sh

    nohup sh gpu_monitor -c -m $max_idle -s -w $wait_time -t $token &
else
    echo "不设置自动关机"
    nohup sh gpu_monitor -c -m $max_idle -t $token &
fi

echo " -t $token \\" >> /etc/profile.d/gpu_monitor.sh

echo " &" >> /etc/profile.d/gpu_monitor.sh
echo 'else' >> /etc/profile.d/gpu_monitor.sh
echo '  echo "GPU限制程序已启动"' >> /etc/profile.d/gpu_monitor.sh
echo 'fi' >> /etc/profile.d/gpu_monitor.sh

echo "配置完成！"

sleep 1

echo "当GPU空闲超过 $max_idle 分钟后通知微信"

if [ "$shutdown" = "y" ]; then
   echo "当通知微信后，再过 $wait_time 分钟后自动关机"
fi

sleep 1

echo "你可通过”/etc/profile.d/gpu_monitor.sh“文件查看或修改开机启动脚本"

sleep 1

echo "你可通过”tail -f /tmp/gpu_monitor.log“查看日志"

sleep 1

echo "程序后台启动成功！以下是输出日志（可以ctrl-c，不影响程序继续运行）"

sleep 1

tail -f /tmp/gpu_monitor.log