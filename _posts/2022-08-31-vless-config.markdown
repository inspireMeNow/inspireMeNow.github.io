---
title: vless配置
tags: network
key: vless-config 
---
**
# vless+websocket+tls配置
## server端
*config.json*
```conf
{
    "log": {
        "loglevel": "warning" //日志级别
    },
    "inbounds": [
        {
            "port": 10016,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "youruuid", // 填写你的 UUID
                        "level": 0,
                        "email": "youremail"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": 80 //回落到nginx的80端口
                    },
                    {
                        "path": "/path", // 必须换成自定义的 PATH
                        "dest": 1234,
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "tls",
                "tlsSettings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "/path/to/fullchain.pem", // 换成你的证书，绝对路径
                            "keyFile": "/path/to/privkey.pem" // 换成你的私钥，绝对路径
                        }
                    ]
                }
            }
        },
        {
            "port": 1234,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "youruuid", // 填写你的 UUID
                        "level": 0,
                        "email": "youremail"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": true, // 若使用 Nginx/Caddy 等反代 WS，需要删掉这行
                    "path": "/path" // 必须换成自定义的 PATH，需要和上面的一致
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
```
*由于nginx占用443端口。故使用nginx根据sni进行流量转发*  
*nginx.conf*
```conf
stream {
# 这里就是 SNI 识别，将域名映射成一个配置名，请修改自己的一级域名
  map $ssl_preread_server_name $backend_name {
    cl.example.com web;
    blog.example.com xray;
    default web;
  }
# web，配置转发详情
  upstream web {
    server 127.0.0.1:10001;
  }
# 转发到xray
  upstream xray {
    server 127.0.0.1:10016;
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
## client端
*我使用的clash meta核，以下为clash配置*   
```yaml
- name: "vless"
      type: vless
      server: yourdomain
      port: 443
      uuid: youruuid
      tls: true
      udp: true
      network: ws
      servername: yourdomain # priority over wss host
      ws-opts:
        path: /path
        headers: { Host: yourdomain }
```
