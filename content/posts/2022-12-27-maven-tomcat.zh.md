---
title: 记录一次java web项目部署的过程
ZHtags: 
  - maven
key: maven-tomcat
date: '2022-12-27'
lastmod: '2022-12-27'
---
# 从其他机器上导入的maven项目构建失败
```bash
mvn clean
```
之后应该就可以正常编译了
# 配置github actions
- 使用maven编译
```yaml
- name: Build with Maven
      run: mvn -B package --file CSMS/pom.xml
```
- 上传release文件
```yaml
- name: Create Draft Release
      id: create_release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} # 验证token
      with:
        tag_name: ver-${{ github.sha }} # 触发工作流的提交 SHA。此提交 SHA 的值取决于触发工作流的事件。
        release_name: 配件库存管理系统
        draft: true
        prerelease: true # 是否为prerelease

    - uses: actions/upload-release-asset@v1.0.1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        upload_url: ${{ steps.create_release.outputs.upload_url }}
        asset_path: ./CSMS/target/CSMS.war # 编译输出文件的路径
        asset_name: CSMS.war
        asset_content_type: application/war # 文件拓展名

    - uses: eregon/publish-release@v1 # 上传release文件
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        release_id: ${{ steps.create_release.outputs.id }}
```
# 服务器tomcat版本过高遇到的问题
- tomcat配置ssl
```xml
<Connector port="8443" protocol="org.apache.coyote.http11.Http11AprProtocol"
               maxThreads="150" SSLEnabled="true" server="yourservername">
        <UpgradeProtocol className="org.apache.coyote.http2.Http2Protocol" />
        <SSLHostConfig>
		<Certificate certificateKeyFile="/etc/letsencrypt/live/courage.cf/privkey.pem"
                         certificateFile="/etc/letsencrypt/live/courage.cf/fullchain.pem"
                         certificateChainFile="/etc/letsencrypt/live/courage.cf/fullchain.pem"
                         type="RSA" />
        </SSLHostConfig>
    </Connector>
```
- 配置nginx转发
```conf
  map $ssl_preread_server_name $backend_name { 
    yourdomain web;
    warehouse.yourdomain warehouse;
    default web; 
  } 
# web，配置转发详情 
  upstream web { 
    server 127.0.0.1:10010;
  }
  upstream warehouse {
    server 127.0.0.1:8443;
  }
  server { 
    listen 443 reuseport; 
    listen [::]:443 reuseport;
    proxy_pass $backend_name; 
    ssl_preread on; 
  }
```
*部署到服务器后无法跳转到欢迎页面并报出500错误*  
- 降级tomcat版本
```bash
wget https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.99/bin/apache-tomcat-7.0.99.tar.gz
tar -xvf apache-tomcat-7.0.99.tar.gz
mv apache-tomcat-7.0.99 tomcat-7
```
*tomcat低版本配置ssl时出现错误*
- 使用nginx反代
```conf
server {

	root /var/www/html;

	# Add index.php to the list if you are using PHP
	index index.html index.htm index.nginx-debian.html;
    server_name warehouse.courage.cf; # managed by Certbot

	location / {
            proxy_ssl_server_name on;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;
            proxy_pass http://localhost:8080/;
        }

    listen [::]:10012 ssl ipv6only=on; # managed by Certbot
    listen 10012 ssl; # managed by Certbot
    add_header Strict-Transport-Security "max-age=31536000;includeSubDomains;preload" always;
    ssl_certificate /etc/letsencrypt/live/courage.cf/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/courage.cf/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}
```
*测试ssl正常，网页可以跳转到欢迎页面*
