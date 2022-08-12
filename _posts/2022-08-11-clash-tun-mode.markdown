---
title: clash tun模式配置
tags: web
key: clash-tun-mode

---

# 1. 劫持系统dns

## 安装dnsmasq并启动dnsmasq

```
sudo dnf install dnsmasq
sudo systemctl start dnsmasq
```

## 删除系统自己的resolv.conf,并新建resolv.conf指定dns服务器ip

*注：systemd-resolved的dns服务器ip为127.0.0.53，dnsmasq为127.0.0.1*

```
sudo rm /etc/resolv.conf
sudo vim /etc/resolv.conf
```

```
nameserver 127.0.0.1
options edns0 trust-ad
search .
```

**注意：需要关闭networkmanager的dns服务器防止dns服务器ip被替换**

```
sudo vim /etc/NetworkManager/NetworkManager.conf
```

```
[main]
dns = none
```

*重启networkmanager*

```
sudo systemctl restart NetworkManager
```

*编辑dnsmasq配置文件*

```
sudo vim /etc/dnsmasq.d/clash.conf
```

```
no-hosts
no-resolv
server=127.0.0.1#1053 //将dns请求全部转发到clash
```

*重新启动dnsmasq*

```
sudo systemctl restart dnsmasq
```

*clash的dns服务器配置*  

*config.yaml*

```
dns:
  enable: true
  ipv6: true
  listen: :1053
  enhanced-mode: fake-ip      # redir-host or fake-ip
  fake-ip-range: 198.18.0.1/16    # Fake IP addresses pool CIDR
  use-hosts: true                 # lookup hosts and return IP record
  nameserver:
    - 223.5.5.5         # 阿里 19ms
    - 119.29.29.29      # DNSpod DNS 17ms
  # 提供 fallback 时，如果GEOIP非 CN 中国时使用 fallback 解析
  fallback:
    - tls://8.8.8.8:53         # Google DNS over TLS 50ms
    - tls://8.8.4.4:53         # cloudflare DNS over TLS 50ms
    - https://1.1.1.1/dns-query # cloudflare DNS over HTTPS
    - https://dns.google/dns-query # Google DNS over HTTPS

  # 强制DNS解析使用`fallback`配置
  fallback-filter:
    # true: CN使用nameserver解析，非CN使用fallback
    geoip: true
    # geoip设置为false时有效： 不匹配`ipcidr`地址时会使用`nameserver`结果，匹配`ipcidr`地址时使用`fallback`结果。
    ipcidr:
      - 240.0.0.0/4

```



*验证dns是否被劫持成功*

```
nslookup www.google.com
```

*出现应答结果即为劫持成功*

# 2.clash tun网卡配置

*注：clash需要root权限创建网卡*

```
tun:
  enable: true
  stack: system
  auto-route: true
  auto-detect-interface: true
```

最后重启clash

```
sudo systemctl restart clash
```

查看clash运行状态

```
sudo systemctl status clash
```
