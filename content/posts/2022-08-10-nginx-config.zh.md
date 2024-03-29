---
title: nginx配置
ZHtags: 
  - web
key: nginx-config
date: '2022-08-10'
lastmod: '2022-08-10' 
---
*测试系统：Debian11*

# 1.安装升级系统
```bash
sudo apt update
```
# 2.安装nginx
```bash
sudo apt install nginx
```
# 3.申请域名
*github学生包或者freenom免费域名，添加域名解析，使用nslookup命令查看是否解析成功，注意先不要使用cdn*  

# 4.申请证书
*zerossl或者letsencrypt即可*  
## 80端口验证
```bash
sudo apt install python3-certbot-nginx
```
安装完成后：
```bash
sudo certbot –nginx
```
## 邮箱系统验证

## dns验证
### 泛域名申请  
*以cloudflare为例：*  
  
*创建cloudflare api密钥，记下token*  

*创建cloudflare.ini配置文件并放入指定位置*  
```conf
dns_cloudflare_api_token = your_token
```
*申请证书*
```bash
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini \
  -d example.com \
  -d www.example.com
```
### 二级域名申请
```bash
sudo certbot -d my.example.com --manual --preferred-challenges dns certonly
```
*注：根据提示添加txt域名映射记录，待域名生效后即可回车*
# 5.编辑nginx配置文件
编辑/etc/nginx/sites-enabled/default文件
```conf
server {

	# SSL configuration
	#
	# listen 443 ssl default_server;
	# listen [::]:443 ssl default_server;
	#
	# Note: You should disable gzip for SSL traffic.
	# See: https://bugs.debian.org/773332
	#
	# Read up on ssl_ciphers to ensure a secure configuration.
	# See: https://bugs.debian.org/765782
	#
	# Self signed certs generated by the ssl-cert package
	# Don't use them in a production server!
	#
	# include snippets/snakeoil.conf;

	root /var/www/html;

	# Add index.php to the list if you are using PHP
	index index.html index.htm index.nginx-debian.html index.php;
    server_name yourdomain;
        
        location / {
                try_files $uri $uri/ =404;
        }
	# pass PHP scripts to FastCGI server
	#
	location ~ \.php$ {
		include snippets/fastcgi-php.conf;
	
		# With php-fpm (or other unix sockets):
		fastcgi_pass unix:/run/php/php7.4-fpm.sock;
		# With php-cgi (or other tcp sockets):
		# fastcgi_pass 127.0.0.1:9000;
	}

	# deny access to .htaccess files, if Apache's document root
	# concurs with nginx's one
	#
	#location ~ /\.ht {
	#	deny all;
	#}

    listen [::]:10005 ssl ipv6only=on; # managed by Certbot
    listen 10005 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/yourdomain/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/yourdomain/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}
server {
    if ($host = yourdomain ) { //http强制跳转至https
        return 301 https://$host$request_uri;
    } # managed by Certbot


	listen 80 ;
	listen [::]:80 ;
    server_name yourdomain;
    return 404; # managed by Certbot


}
```
6.启用nginx服务
```bash
sudo systemctl enable –now nginx
```

7.浏览器查看网页