---
title: hysteria配置
tags: 
  - network
key: hysteria-config
date: '2022-08-29'
lastmod: '2022-08-29'
---
**由于hysteria用了udp协议，不受tcp阻断的影响，故尝试此项目。**
# server端
## 下载安装
### 下载
wget https://github.com/HyNetwork/hysteria/releases/download/v1.2.0/hysteria-linux-amd64
### 编辑配置文件config.json
```conf
{
  "listen": ":37658", #监听端口
  "protocol": "wechat-video", #流量类型，支持udp，faketcp，wechat-video
  "cert": "/path/to/fullchain.pem",
  "key": "/path/to/privkey.pem",
  "alpn": "h3",
  "auth": {
    "mode": "passwords",
    "config": ["yourpassword"] 
  },
  "up_mbps": 100, #限速，建议值不要过高，默认单位：Mbps
  "down_mbps": 100
}
```
### 启动hysteria
```bash
./hysteria -c config.json server
```
### 注册为systemd服务
```conf
[Unit]
Description=Hysteria, a feature-packed network utility optimized for networks of poor quality
Documentation=https://github.com/HyNetwork/hysteria/wiki
After=network.target
[Service]
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true
WorkingDirectory=/etc/hysteria
Environment=HYSTERIA_LOG_LEVEL=info
ExecStart=/usr/bin/hysteria -c /etc/hysteria/config.json server
Restart=on-failure
RestartPreventExitStatus=1
RestartSec=5
[Install]
WantedBy=multi-user.target
```
### 重载systemd服务
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now hysteria
```
# client端
*我是用的clash meta核心，它可以进行分流*  
```yaml
- name: "hysteria"
      type: hysteria
      server: yourdomain
      port: yourport
      auth_str: yourpassword
      #obfs: yourpassword
      alpn: h3
      protocol: wechat-video          #支持udp/wechat-video/faketcp
      up: '100 Mbps'          #若不写单位，默认为Mbps
      down: '100 Mbps'       #若不写单位，默认为Mbps
```
# 测试
*晚高峰时期确实稳定，过几天看看。*
