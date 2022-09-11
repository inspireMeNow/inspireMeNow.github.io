---
title: 自建gitlab
tags: 
  - git
key: gitlab-setup
date: '2022-08-28'
lastmod: '2022-08-28'
---
# 安装方式
*我选的docker镜像，方便管理*  
## 1.拉取docker镜像
```bash
docker pull gitlab/gitlab-ee:latest
```
## 2.设置gitlab存储位置
```bash
export GITLAB_HOME=/srv/gitlab #自己设置位置
```
## 3.运行docker镜像
```bash
sudo docker run --detach \
  --hostname gitlab.example.com \ #外部url，服务器域名
  --publish 443:443 --publish 80:80 --publish 22:22 \ #换成自己的端口
  --name gitlab \
  --restart always \ #设置自动启动
  --volume $GITLAB_HOME/config:/etc/gitlab:Z \ #相当于文件挂载点
  --volume $GITLAB_HOME/logs:/var/log/gitlab:Z \
  --volume $GITLAB_HOME/data:/var/opt/gitlab:Z \
  --shm-size 256m \
  gitlab/gitlab-ee:latest
```
## 4.查看gitlab运行日志
```bash
sudo docker logs -f gitlab
```
*注：成功后即可打开浏览器输入localhost进入登录界面*
## 5.获取管理员初始密码
```bash
sudo docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
```
**注：请在24小时内修改密码，否则密码将会失效**
## 6.gitlab配置
*由于我这台服务器有nginx，需要监听80端口，因此禁用gitlab的内建nginx*  
### 禁用内建nginx
```conf
nginx['enable'] = false
```
### 设置web服务器用户
```conf
web_server['external_users'] = ['www-data']
```
### 将web服务器添加到受信任的代理列表中
```conf
gitlab_rails['trusted_proxies'] = [ '192.168.1.0/24', '192.168.2.1', '2001:0db8::/32' ]
```
### 允许GitLab Workhorse监听TCP端口
```conf
gitlab_workhorse['listen_network'] = "tcp"
gitlab_workhorse['listen_addr'] = "127.0.0.1:8181"
```
### 外部nginx服务器设置反向代理
```conf
server {
  ## Either remove "default_server" from the listen line below,
  ## or delete the /etc/nginx/sites-enabled/default file. This will cause gitlab
  ## to be served if you visit any address that your server responds to, eg.
  ## the ip address of the server (http://x.x.x.x/)n 0.0.0.0:80 default_server;
  listen 0.0.0.0:80;
  listen [::]:80;
  server_name _; ## Replace this with something like gitlab.example.com
  server_tokens off; ## Don't show the nginx version number, a security best practice
  # root /opt/gitlab/embedded/service/gitlab-rails/public;

  ## See app/controllers/application_controller.rb for headers set

  ## Individual nginx logs for this GitLab vhost
  # access_log  /var/log/nginx/gitlab_access.log;
  # error_log   /var/log/nginx/gitlab_error.log;
  include /etc/nginx/default.d/*.conf;
  location / {
    client_max_body_size 0; #不限制上传大小
    gzip off;

    ## https://github.com/gitlabhq/gitlabhq/issues/694
    ## Some requests take more than 30 seconds.
    proxy_read_timeout      300;
    proxy_connect_timeout   300;
    proxy_redirect          off;

    proxy_http_version 1.1;

    proxy_set_header    Host                $http_host;
    proxy_set_header    X-Real-IP           $remote_addr;
    proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
    proxy_set_header    X-Forwarded-Proto   $scheme;

    proxy_pass http://127.0.0.1:8181/; # 转发到8181端口
  }
}
```
# 实际使用
*由于gitlab占用内存太大，故做以下调整*
```conf
puma['worker_processes'] = 2
postgresql['shared_buffers'] = "256MB"
```
*其他优化方式可查看[Running GitLab in a memory-constrained environment](https://docs.gitlab.com/omnibus/settings/memory_constrained_envs.html)*  
  
*效果：实际比之前少了一半内存占用，还行*
# gitlab runner配置
*我是用的是docker镜像*
## 拉取镜像
```bash
docker pull gitlab/gitlab-runner:latest
```
## 运行镜像
```bash
docker run -d --name gitlab-runner --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner:Z \
  gitlab/gitlab-runner:latest
```
## 设置与gitlab的连接
### 获取gitlab ci token
### 注册runner
```bash
docker exec -it gitlab-runner gitlab-runner register
```
**注：由于网络环境影响，下载依赖较慢，故为docker镜像配置代理**  
### 为docker配置代理
*编辑/etc/systemd/system/docker.service.d/http-proxy.conf文件*  
```conf
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:7890"
Environment="HTTPS_PROXY=http://127.0.0.1:7890"
Environment="NO_PROXY=localhost,127.0.0.0/8,::1" #局域网直连
```
*重载systemd服务*
```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```
### 为gitlab runner配置代理
编辑/srv/gitlab-runner/config/config.toml文件，在[[runners]]处加入以下内容  
```conf
pre_clone_script = "git config --global http.proxy $HTTP_PROXY; git config --global https.proxy $HTTPS_PROXY" #为git配置代理
environment = ["https_proxy=http://172.17.0.1:7890", "http_proxy=http://172.17.0.1:7890", "HTTPS_PROXY=172.17.0.1:7890", "HTTP_PROXY=172.17.0.1:7890"]
```
### 测试gitlab runner
*在项目根目录新建.gitlab-ci.yml文件，以下为示例*  
```yaml
image: ruby:latest

variables:
  JEKYLL_ENV: production
  LC_ALL: C.UTF-8

before_script:
  - gem install bundler #部署之前安装依赖
  - bundle install

test:
  stage: test
  script:
  - bundle exec jekyll build -d test #测试命令
  artifacts:
    paths:
    - test
  except:
  - master

pages:
  stage: deploy #部署命令
  script:
  - bundle exec jekyll build -d public
  artifacts:
    paths:
    - public
  only:
  - master
```
*在web界面查看部署情况*