# AutoDL GPU闲置监控

监控AutoDL服务器的GPU是否处于空闲状态。若GPU闲置超过一定时间后，通知微信，并自动关机，防止因忘关机导致浪费钱。

# 使用方式

```
# 配置AutoDL学术加速
source /etc/network_turbo
# 拉取配置脚本 gpu_monitor.sh
wget https://raw.githubusercontent.com/iioSnail/autodl_idle_gpu_monitor/main/gpu_monitor.sh
# 运行 gpu_monitor.sh 进行自动配置
sh gpu_monitor.sh
```

输出：
```

```
