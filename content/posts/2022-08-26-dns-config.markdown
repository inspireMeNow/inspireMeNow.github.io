---
title: 解决dns污染问题
tags: 
  - network
key: dns-config
date: '2022-08-26'
lastmod: '2022-08-26'
---
# 起因
由于近期dns污染严重，域名解析不正常，故设置doh，dns分流进行dns解析。
# 配置
## dnsmasq
*通过[dnsmasq-china-list](https://github.com/felixonmars/dnsmasq-china-list)进行dns分流*
### 安装
```bash
git clone https://github.com/felixonmars/dnsmasq-china-list

cd dnsmasq-china-list&&bash install.sh

sudo systemctl restart dnsmasq //重启dnsmasq
```
### 效果
*重启dnsmasq太慢，且解析速度下降*
## mosdns+dnsmasq
### 安装
#### mosdns
```bash
wget https://github.com/IrineSistiana/mosdns/releases/download/v4.1.9/mosdns-linux-amd64.zip

unzip mosdns-linux-amd64.zip

sudo mkdir /etc/mosdns

sudo cp mosdns /usr/bin

sudo cp config.yaml /etc/mosdns //配置文件

wget --no-check-certificate https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O /etc/mosdns/geosite.dat 

wget --no-check-certificate https://raw.githubusercontent.com/Loyalsoldier/geoip/release/geoip-only-cn-private.dat -O /etc/mosdns/geoip-only-cn-private.dat //中国ip名单

```
*配置文件*
```conf
log:
  level: warn
  file: "mosdns.log"

data_providers:
- tag: geosite
  file: ./geosite.dat
  auto_reload: true
- tag: geoip
  file: ./geoip-only-cn-private.dat
  auto_reload: true

plugins:
# 缓存
- tag: cache
  type: cache
  args:
    size: 4096
    lazy_cache_ttl: 172800

# 转发至本地服务器的插件
- tag: forward_local
  type: fast_forward
  args:
    upstream:
      - addr: tls://223.6.6.6:853 #alidns
        enable_pipeline: true

      - addr: tls://119.29.29.29:853 #dnspod
        idle_timeout: 8
        trusted: true

# 转发至远程服务器的插件
- tag: forward_remote
  type: fast_forward
  args:
    upstream:
      - addr: https://1.1.1.1/dns-query #cloudflare
        enable_pipeline: true

      - addr: https://dns.google/dns-query #google
        enable_pipeline: true
        trusted: true


# 匹配本地域名的插件
- tag: query_is_local_domain
  type: query_matcher
  args:
    domain:
      - 'provider:geosite:apple-cn'
      - 'provider:geosite:cn'

# 匹配非本地域名的插件
- tag: query_is_non_local_domain
  type: query_matcher
  args:
    domain:
      - 'provider:geosite:geolocation-!cn'

# 匹配广告域名的插件
- tag: query_is_ad_domain
  type: query_matcher
  args:
    domain:
      - 'provider:geosite:category-ads-all'

# 匹配本地 IP 的插件
- tag: response_has_local_ip
  type: response_matcher
  args:
    ip:
      - 'provider:geoip:cn'

# 主要的运行逻辑插件
# sequence 插件中调用的插件 tag 必须在 sequence 前定义，
# 否则 sequence 找不到对应插件。
- tag: main_sequence
  type: sequence
  args:
    exec:
      # 缓存
      - cache

      # 屏蔽广告域名
      - if: query_is_ad_domain
        exec:
          - _new_nxdomain_response
          - _return

      # 已知的本地域名用本地服务器解析
      - if: query_is_local_domain
        exec:
          - forward_local
          - _return

      # 已知的非本地域名用远程服务器解析
      - if: query_is_non_local_domain
        exec:
          - forward_remote
          - _return

        # 剩下的未知域名用 IP 分流。
        # primary 从本地服务器获取应答，丢弃非本地 IP 的结果。
      - primary:
          - forward_local
          - if: "(! response_has_local_ip) && [_response_valid_answer]"
            exec:
              - _drop_response
        # secondary 从远程服务器获取应答。
        secondary:
          - forward_remote
        # 这里建议设置成 local 服务器正常延时的 2~5 倍。
        # 这个延时保证了 local 延时偶尔变高时，其结果不会被 remote 抢答。
        # 如果 local 超过这个延时还没响应，可以假设 local 出现了问题。
        # 这时用就采用 remote 的应答。单位: 毫秒。
        fast_fallback: 200

servers:
- exec: main_sequence
  listeners:
    - protocol: udp
      addr: 127.0.0.1:1053 #监听1053端口
    - protocol: tcp
      addr: 127.0.0.1:1053
```
*新建systemd服务*
```conf
[Unit]
Description=mosdns Service
Documentation=https://irine-sistiana.gitbook.io/mosdns-wiki/
After=network.target

[Service]
NoNewPrivileges=true
ExecStart=/usr/bin/mosdns start -c /etc/mosdns/config.yaml -d /etc/mosdns/
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
#### dnsmasq
*配置文件*
```bash
sudo vim /etc/dnsmasq.d/local.conf
```
```conf
no-hosts
no-resolv
server=127.0.0.1#1053 #将dns请求转发到1053端口
```
*重启dnsmasq*
```bash
sudo systemctl restart dnsmasq
```
### 效果
*还行，过一段时间试试*