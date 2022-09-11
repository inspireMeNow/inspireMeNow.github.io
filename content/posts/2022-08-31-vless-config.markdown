---
title: vless配置
tags: 
  - network
key: vless-config 
date: '2022-08-31'
lastmod: '2022-08-31'
enableComment: true
---
# xray安装
*注：我使用的是xray内核，v2ray内核应该也可以*  
```bash
wget https://github.com/XTLS/Xray-core/releases/download/v1.5.10/Xray-linux-64.zip

unzip Xray-linux-64.zip

cp xray /usr/bin

mkdir /etc/xray

cp *.dat /etc/xray
```
# xray systemd服务
```conf
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target
[Service]
ExecStart=/usr/bin/xray run -config /etc/xray/config.json
Environment="XRAY_LOCATION_ASSET=/etc/xray"
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000
[Install]
WantedBy=multi-user.target
```
**注意：若xray所在目录和geosite.dat所在目录不一致，需要设置环境变量XRAY_LOCATION_ASSET，不设置此环境变量会导致默认将geosite.dat定位至/use/bin，此目录无geosite.dat，因此服务会报错无法启动**  
  
*设置systemd服务自动启动*
```bash
sudo systemctl enable --now xray
```
# vless+websocket+tls配置
## server端
### xray配置
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
### nginx配置
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
# vless+nginx+grpc+tls配置
## server端
### xray配置
```conf
{
  "log": {
    "loglevel": "warning" //日志级别
  },
  "inbounds": [
    {
      "listen": "/dev/shm/Xray-VLESS-gRPC.socket,0666", //监听socket
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "youruuid" // 填写你的 UUID
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "yourservicename" // 填写你的 ServiceName
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {}
    },
    {
      "tag": "blocked",
      "protocol": "blackhole",
      "settings": {}
    }
  ],
  "routing": {
    "domainStrategy": "AsIs", //域名匹配
    "rules": [
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "blocked"
      }
    ]
  }
}
```
### nginx配置
```conf
server {
	listen 10013 ssl http2 so_keepalive=on;
	server_name yourdomain;

	index index.html;
	root /var/www/html;

	ssl_certificate /path/to/fullchain.pem;
	ssl_certificate_key /path/to/privkey.pem;
	ssl_protocols TLSv1.2 TLSv1.3;
	ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
	
	client_header_timeout 52w;
        keepalive_timeout 52w;
	# 在 location 后填写 /你的 ServiceName
	location /yourservicename {
		if ($content_type !~ "application/grpc") {
			return 404;
		}
		client_max_body_size 0;
		client_body_buffer_size 512k;
		grpc_set_header X-Real-IP $remote_addr;
		client_body_timeout 52w;
		grpc_read_timeout 52w;
		grpc_pass unix:/dev/shm/Xray-VLESS-gRPC.socket; #监听socket
	}
}
server {
    if ($host = yourdomain) {
        return 301 https://$host$request_uri;
    } # managed by Certbot
        listen 80 ;
        listen [::]:80 ;
    server_name yourdomain;
    return 404; # managed by Certbot
}
```
*注：nginx端口转发可参照websocket中的配置*  
## client端
*clash meta配置*  
```yaml
- name: "vless"
      type: vless
      server: yourdomain
      port: 443
      uuid: youruuid
      tls: true
      udp: true
      network: grpc
      servername: yourdomain # priority over wss host
      # skip-cert-verify: true
      grpc-opts: 
        grpc-service-name: yourservicename
```
