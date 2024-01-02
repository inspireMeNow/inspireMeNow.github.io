---
title: webdav解决局域网之间的文件传输问题
ZHtags: 
  - webdav
key: webdav-solution
date: '2023-01-12'
lastmod: '2023-01-12'
---
# webdav方法说明
|方法名称|	文件权限|	方法说明|
| :--- | :--- | :--- |
|OPTIONS|--|	支持 WebDAV 的检索服务方法|
|GET|	读|	获取文件|
|PUT、POST|	写|	上传文件|
|DELETE|	删除|	删除文件或集合|
|COPY|	读、写|	复制文件|
|MOVE|	删除、写|	移动文件|
|MKCOL|	写|	创建由一个或多个文件 URI 组成的新集合|
|PROPFIND|	读|	获取一个或多个文件的特性，实现文件的查找与管理|
|LOCK、UNLOCK|	写|	添加、删除文件锁，实现写操作保护|
# 使用的服务端
## nginx
**注意：需要第三方模块nginx-dav-ext-module！**  
### 配置webdav目录权限
```bash
chown -R nobody:nobody /var/www/dav
chmod -R 700 /var/www/dav
```
### 配置nginx服务器
```conf
dav_ext_lock_zone zone=davlock:10m;                   # DAV文件锁内存共享区

server {
    listen 443 ssl http2;                             # 启用HTTPS及HTTP/2
    server_name  yourservername;
    access_log  logs/webdav.access.log  main;         #网站日志文件
    root    /var/www/dav;
   
    ssl_certificate yourpath/fullchain.pem;           # 网站证书文件
    ssl_certificate_key yourpath/privkey.pem;         # 网站证书密钥文件
    ssl_session_cache shared:SSL:10m;                 # 会话缓存存储大小为10MB
    ssl_session_timeout  20m;                         # 会话缓存超时时间为20分钟

    client_max_body_size 20G;                         # 最大允许上传的文件大小

    location / {
        autoindex on;
        autoindex_localtime on;

        set $dest $http_destination;
        if (-d $request_filename) {                   # 对目录请求、对URI自动添加“/”
            rewrite ^(.*[^/])$ $1/;
            set $dest $dest/;
        }

        if ($request_method ~ (MOVE|COPY)) {          # 对MOVE|COPY方法强制添加Destination请求头
            more_set_input_headers 'Destination: $dest';
        }

        if ($request_method ~ MKCOL) {
            rewrite ^(.*[^/])$ $1/ break;
        }

        dav_methods PUT DELETE MKCOL COPY MOVE;       # DAV支持的请求方法
        dav_ext_methods PROPFIND OPTIONS LOCK UNLOCK; # DAV扩展支持的请求方法
        dav_ext_lock zone=davlock;                    # DAV扩展锁绑定的内存区域
        create_full_put_path  on;                     # 启用创建目录支持
        dav_access user:rw group:r all:r;             # 设置创建的文件及目录的访问权限

        auth_basic "Authorized Users WebDAV";
        auth_basic_user_file /etc/nginx/conf/.davpasswd; # webdav密码文件
    }
}
```
*密码文件示例：*
```conf
admin:$(openssl passwd yourpassword)
```
## rclone
*待补充！*
## dufs
*项目地址：[dufs](https://github.com/sigoden/dufs)*  
*常用命令行参数：*
|选项|说明|
| :--- | :--- |
| -b, --bind <addrs> | 监听地址 |
| -p, --port <port> | 监听端口，默认为5000 |
| --hidden <value> | 隐藏目录，用 `,`分隔 |
| -a, --auth <rules> | 添加授权规则 |
| --auth-method <value> | 授权方法，默认为: digest，可用选项为basic, digest，格式为/@username:password |
| -A, --allow-all | 允许所有操作 |
| --allow-upload | 允许上传 |
| --allow-delete |允许删除 |
| --allow-search | 允许搜索 |
| --render-index | 使用index.html提供网站界面 |
| --render-spa | 使用spa提供网站界面 |
| --tls-cert <path> | 证书文件 |
| --tls-key <path> | 证书密钥文件 |
| --log-format <format> | 日志格式 |
# 使用的客户端
## 客户端软件
- windows平台： winscp
- linux平台： nautilus、rclone
- macos平台： 访达
## 使用curl
*上传文件*
```bash
curl -T path-to-file http://127.0.0.1:5000/new-path/path-to-file
```
*下载文件*
```bash
curl http://127.0.0.1:5000/path-to-file
```
*将文件夹下载为压缩文件*
```bash
curl -o path-to-folder.zip http://127.0.0.1:5000/path-to-folder?zip
```
*删除文件、文件夹*
```bash
curl -X DELETE http://127.0.0.1:5000/path-to-file-or-folder
```