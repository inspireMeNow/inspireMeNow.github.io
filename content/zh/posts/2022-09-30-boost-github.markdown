---
title: 自签证书解决github访问问题
tags: 
  - network
key: servlet-post
date: '2022-09-14'
lastmod: '2022-09-17'
---
*由于众所周知的原因，国内github时常连不上，tcpping查看github的ip可以访问，但就是通过域名旧无法访问，这类问题是sni阻断造成的，本文的方法类似中间人攻击，在本地反向代理github网站，由于得不到github的证书，浏览器会直接报ssl错误，阻止连接，此时我们需要信任证书，然后你就可以通过本地的域名访问github了，此过程没有发送github的sni，即避免了sni阻断。*
# 配置证书
**注：根据提示添加github.com,*.github.com,githubusercontent.com,*.githubusercontent.com这些域名到CN**
```bash
openssl genrsa 2048 > ca.key # 创建ca证书

# CA证书的公钥，用于信任CA证书
# 生成不通的CA
export SUBJ="/C=CN/ST=ST$RANDOM/O=O$RANDOM/OU=OU$RANDOM/CN=CN$RANDOM/emailAddress=$RANDOM@localhost"
# CN写0CN是为了让证书好找（会排到最前面）,20231231为证书过期日期
openssl req -new -x509 -days `expr \( \`date -d 20231231 +%s\` - \`date +%s\` \) / 86400 + 1` -key ca.key -out ca.pem -subj $SUBJ
# date为证书有效期


# 生成nginx使用的证书
openssl genrsa 1024 > nginx.key # 密钥
openssl req -new -nodes -key nginx.key -out nginx.csr -subj $SUBJ

# CA签名，写github对应域名
openssl x509 -req -days `expr \( \`date -d 99991231 +%s\` - \`date +%s\` \) / 86400 + 1` \
 -in nginx.csr -out nginx.pem -CA ca.pem -CAkey ca.key -set_serial 0 -extensions CUSTOM_STRING_LIKE_SAN_KU\
 -extfile <( cat << EOF
[CUSTOM_STRING_LIKE_SAN_KU]
subjectAltName=IP:127.0.0.1, IP: ::1 ,DNS:github.com, DNS:*.github.com, DNS:githubusercontent.com, DNS:*.githubusercontent.com
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
EOF
)
```
# 检查证书
```bash
openssl x509 -text -noout -in ca.pem
```
**注意：Windows用户需要将密钥和证书组合在 PKCS#12 (P12) 捆绑软件中并导出到p12文件，Linux用户不用导出证书**
# 导出证书
```bash
openssl pkcs12 -inkey ca.key -in ca.pem -export -out certificate.p12
```
# 检查p12文件
```bash
openssl pkcs12 -in certificate.p12 -noout -info
```
# 安装nginx
## fedora
```bash
sudo dnf install nginx 
```
## ubuntu
```bash
sudo apt install nginx
```
## windows
[下载链接](http://nginx.org/download/nginx-1.23.1.zip)
# 配置nginx
```bash
sudo vim /etc/nginx/nginx.conf
```
```conf
    upstream github-com { # 转发到对应ip
        server 140.82.112.3:443;
        server 140.82.112.4:443;
        server 140.82.113.3:443;
        server 140.82.113.4:443;
    }
    upstream githubusercontent-com {
        server 185.199.108.133:443;
        server 185.199.109.133:443;
        server 185.199.110.133:443;
        server 185.199.111.133:443;
    }
    upstream cloudflare {
        server 1.0.0.1:443;
    }

    map $host $default_http_host { # 匹配sni
        hostnames; # 不写这个会让你什么都匹配不出来
        default                     cloudflare; # 默认转发到cloudflare
        .github.com                 github-com;
        .githubusercontent.com      githubusercontent-com;
    }
    
     server {
        listen 443 ssl;

        ssl_certificate ca/nginx.pem; # 证书路径
        ssl_certificate_key ca/nginx.key;

        allow 127.0.0.0/8;
        deny all;

        location / {
            proxy_pass https://$default_http_host; # 反代域名
            proxy_set_header Host $http_host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Real_IP $remote_addr;
            proxy_set_header User-Agent $http_user_agent;
            proxy_set_header Accept-Encoding '';
            proxy_buffering off;
        }
    }

    server {
        listen 80 default_server;
        allow 127.0.0.0/8;
        deny all;
        rewrite ^(.*) https://$host$1 permanent; # 强制跳转https
    }
}
```
# 配置hosts
```conf
127.0.0.1 raw.github.com 
127.0.0.1 githubusercontent.com
127.0.0.1 cloud.githubusercontent.com
127.0.0.1 camo.githubusercontent.com
127.0.0.1 www.github.com 
127.0.0.1 gist.github.com
127.0.0.1 github.com 
127.0.0.1 raw.githubusercontent.com
127.0.0.1 user-images.githubusercontent.com
127.0.0.1 avatars3.githubusercontent.com 
127.0.0.1 avatars2.githubusercontent.com 
127.0.0.1 avatars1.githubusercontent.com 
127.0.0.1 avatars0.githubusercontent.com 
127.0.0.1 avatars.githubusercontent.com
```
# 配置nginx自动启动
```bash
sudo systemctl enable --now nginx
```
# 安装证书
## Linux
```bash
cat certificate.pem >> /etc/pki/tls/certs/ca-bundle.crt
```
## Windows
*参照网上的方法即可。*
# 测试网站
## curl测试
```bash
curl https://www.github.com
```
## 浏览器测试
*查看证书是否与自己安装的对应。*
# 注意事项
**证书用于解密https流，默认在服务端加密，在客户端解密，如果证书不安全（被别人知晓），那么你在该网站输入的所有内容相当于明文传输，一定不要泄漏自己的证书，也不要使用别人的证书！！！**