---
title: xray reality配置
ZHtags: 
  - network
key: vless-config 
date: '2022-08-31'
lastmod: '2024-01-05'
---
# xray安装
```bash
wget https://github.com/XTLS/Xray-core/releases/download/v1.8.1/Xray-linux-64.zip

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
~~vless+websocket+tls和vless+nginx+grpc+tls容易被识别，不建议使用~~
# vless reality配置
*服务端*
```json
{
    "log": {
    	"loglevel": "info",
    	"access": "/var/log/xray/access.log",
    	"error": "/var/log/xray/error.log"
    },
    "inbounds": [ // 服务端入站配置
        {
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "UUID", // 必填，执行 ./xray uuid 生成，或 1-30 字节的字符串
                        "flow": "xtls-rprx-vision" // 选填，若有，客户端必须启用 XTLS
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,  // 选填，若为 true，输出调试信息
                    "dest": ":PORT", // 必填，格式同 VLESS fallbacks 的 dest，回退到Nginx监听端口
                    "xver": 0,  // 选填，格式同 VLESS fallbacks 的 xver
                    "serverNames": [ // 必填，客户端可用的 serverName 列表，暂不支持 * 通配符
                        "SNI"
                    ],
                    "privateKey": "privateKey", // 必填，执行 ./xray x25519 生成
                    "minClientVer": "", // 选填，客户端 Xray 最低版本，格式为 x.y.z
                    "maxClientVer": "", // 选填，客户端 Xray 最高版本，格式为 x.y.z
                    //"maxTimeDiff": 0, // 选填，允许的最大时间差，单位为毫秒
                    "shortIds": [ // 必填，客户端可用的 shortId 列表，可用于区分不同的客户端
                        "shortId" // 0 到 f，长度为 2 的倍数，长度上限为 16
                    ]
                }
            }
        }
    ],
    "outbounds": [
    {
      "protocol": "freedom",
      "settings" : {
	      "domainStrategy": "UseIPv6"
      },
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "domain": [
          "domain:iqiyi.com",
          "domain:video.qq.com",
          "domain:youku.com"
        ],
        "type": "field",
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "ip": [
          "geoip:cn",
          "geoip:private"
        ],
        "outboundTag": "blocked"
      },
      {
        "protocol": [
          "bittorrent"
        ],
        "type": "field",
        "outboundTag": "blocked"
      }
    ]
  }
}

```
*客户端*
```json
{
    "log": {
    	"loglevel": "info"
    },
    "inbounds": [
    // 4.2 有少数APP不兼容socks协议，需要用http协议做转发，则可以用下面的端口
    {
      "tag": "socks",
      "protocol": "socks",
      "listen": "127.0.0.1", // 这个是通过http协议做本地转发的地址
      "port": 1081 // 这个是通过http协议做本地转发的端口
    }
    ],
    "outbounds": [ // 客户端出站配置
        {
            "protocol": "vless",
            "settings": {
                "vnext": [
                    {
                        "address": "IP", // 服务端的域名或 IP
                        "port": 443,
                        "users": [
                            {
                                "id": "UUID", // 与服务端一致
                                "flow": "xtls-rprx-vision", // 与服务端一致
                                "encryption": "none"
                            }
                        ]
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false, // 选填，若为 true，输出调试信息
                    "fingerprint": "chrome", // 必填，使用 uTLS 库模拟客户端 TLS 指纹
                    "serverName": "SNI", // 服务端 serverNames 之一
                    "publicKey": "publicKey", // 服务端私钥对应的公钥
                    "shortId": "shortId", // 服务端 shortIds 之一
                    "spiderX": "/" // 爬虫初始路径与参数，建议每个客户端不同
                }
            }
        }
    ]
}

```
### nginx配置 
*nginx.conf*
```conf
stream {
# 监听 PORT 并开启 ssl_preread
  server {
    listen PORT reuseport;
    listen [::]:PORT reuseport;
    proxy_pass $backend_name;
    ssl_preread on;
  }
}
```