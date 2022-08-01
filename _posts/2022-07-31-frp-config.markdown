---
title: frp内网穿透
tags: frp
key: frp-config
---
# 1.frp server端配置  
```
[common]
# frp监听的端口，默认是7000，可以改成其他的
bind_port = 14823
vhost_http_port = 12345
# 授权码，请改成更复杂的
token = 12345678

# frp管理后台端口，请按自己需求更改
dashboard_port = 7800 
# frp管理后台用户名和密码，请改成自己的
dashboard_user = admin
dashboard_pwd = admin
enable_prometheus = true

```

# 2.frp client端配置  
```
[common]
server_addr = yourdomain
server_port = 14823 #server端bind_port
token = 12345678  #授权码
[ssh]   #ssh远程链接
type = tcp
local_ip = 127.0.0.1
local_port = 22 #本地ssh端口
remote_port = 6000 #远程ssh连接端口
[web1]
type = http #http服务
local_port = 80
custom_domains = yourdomain

```
# 3.frp配置mariadb  
```
[mariadb]
type = tcp
local_ip = 127.0.0.1   #内网ip
local_port = 3306 # 内网mariadb端口
remote_port = 1006 # 公网mariadb端口
```
# 4.frp与nginx共用80、443端口  
## http  
### nginx配置  
```
location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to displaying a 404.
        # try_files $uri $uri/ =404;
        proxy_pass http://127.0.0.1:8081; #填写frpc的vhost端口
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header REMOTE-HOST $remote_addr;
    }

```
### frp server端配置  
```
vhost_http_port = 8081
```
### frp client配置  
```
[web1]
type = http
local_port = 80
custom_domains = yourdomain
```
## https  
### frp server配置  
```
vhost_https_port = 8082
```
### frp client配置  
```
#plugin = https2http
#plugin_local_addr = 127.0.0.1:1313 #本地服务器端口

# HTTPS证书的路径
#plugin_crt_path = /etc/frp/domain/yourdomain/fullchain1.pem
#plugin_key_path = /etc/frp/domain/yourdomain/privkey1.pem
#plugin_host_header_rewrite = 127.0.0.1
#plugin_header_X-From-Where = frp
```  
### nginx配置  
未完待续  