---
title: trojan-go配置
tags: 
  - network
key: trojan-config
date: '2022-08-10'
lastmod: '2022-08-10' 
---
1.github下载trojan-go二进制文件
```bash
wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip
```
2.解压trojan-go并放至/usr/bin,赋予其执行权限
```bash
unzip trojan-go-linux-amd64.zip

cp trojan-go /usr/bin

chmod +x trojan-go
```
3.将剩余文件放至/etc/trojan-go
```bash
mkdir /etc/trojan-go

cp -r * /etc/trojan-go
```
4.申请trojan-go的证书
```bash
sudo certbot certonly –agree-tos –standalone –no-eff-email -m youremail -d yourdomain
```
将证书移至/etc/trojan-go中
```bash
sudo cp -r /etc/letsencrypt/archive/yourdomain /etc/trojan-go
```
5.编辑config.json  
*生成随机uuid*
```bash
cat /proc/sys/kernel/random/uuid
```
*config.json*
```json
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 10010, //与nginx共存时不可填写443端口
    "remote_addr": "127.0.0.1",
    "remote_port": 80, //默认返回网页
    "password": [
        "yourpassword" //填写自己密码
    ],
    "ssl": {
        "cert": "/etc/trojan-go/yourdomain/fullchain1.pem", //网站的证书
        "key": "/etc/trojan-go/yourdomain/privkey1.pem",
	"fallback": 10005, //回程默认网页
        "sni": "yourdomain"
    },
    "websocket": { //ws模式伪装path
	"enabled": true,
	"path": "/yourpath", //建议填写随机值
	"host": "yourdomain"
    }
}
```
6.设置端口转发
由于trojan与nginx都占用443端口，因此需设置端口转发  

*nginx.conf*
```conf
stream { 
# 这里就是 SNI 识别，将域名映射成一个配置名，请修改自己的一级域名 
  map $ssl_preread_server_name $backend_name { 
    yourdomain web;
    yourdomain trojan;
    default web; 
  } 
# web，配置转发详情 
  upstream web { 
    server 127.0.0.1:10005;
  }
  upstream trojan {
    server 127.0.0.1:10010;
  }
# 监听 443 并开启 ssl_preread
  server { 
    listen 443 reuseport; 
    listen [::]:443 reuseport;
    proxy_pass $backend_name; 
    ssl_preread on; 
  }
}
```
7.新建trojan用户
*用于安全原因，trojan-go需要以trojan用户的身份运行*  
```bash
sudo useradd -s /sbin/nologin trojan
```
*设置文件夹权限*  
```bash
sudo chown -R /etc/trojan-go
```
7.新建systemd服务
```bash
sudo vim /usr/lib/systemd/system/trojan-go.service
```
*trojan-go.service*
```conf
[Unit]
Description=Trojan-Go - An unidentifiable mechanism that helps you bypass GFW
Documentation=https://p4gefau1t.github.io/trojan-go/
After=network.target nss-lookup.target

[Service]
User=trojan
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/bin/trojan-go -config /etc/trojan-go/config.json
Restart=on-failure
RestartSec=10s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
sudo systemctl daemon-reload //重载systemd服务
```
8.重启nginx并设置trojan-go开机启动
```bash
sudo systemctl enable –now trojan-go

sudo systemctl restart nginx
```
9.（可选）启用tcp bbr加速
```bash
echo 'net.core.default_qdisc=fq' | sudo tee -a /etc/sysctl.conf

echo 'net.ipv4.tcp_congestion_control=bbr' | sudo tee -a /etc/sysctl.conf

sudo sysctl -p

init 6 //重启机器

lsmod|grep bbr //查看bbr模块是否加载
```
9.客户端设置（自选客户端）  
*设置clash*
```yaml
- name: 'trojan'
      type: trojan
      server: yourdomain
      port: '443'
      password: "yourwassword"
      sni: yoursni
      udp: true
      ws-opts:
        path: /yourpath
        headers:
          Host: yourdomain
```