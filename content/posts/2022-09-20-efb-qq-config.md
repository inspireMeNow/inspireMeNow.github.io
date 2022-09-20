---
title: 用Telegram收发qq消息
tags: 
  - qq
key: efb-qq-config
date: '2022-09-19'
lastmod: '2022-09-20'
---
# 所需条件
#### Tegeram帐号一个
#### VPS一台
#### Linux操作系统
# 开始
## 安装依赖
```bash
sudo apt-get install python3 libopus0 ffmpeg libmagic1 python3-pip git nano libssl-dev
```
### pip安装
```bash
pip3 install setuptools wheel

pip3 install ehforwarderbot
```
### 配置EFB
#### 创建配置文件目录
```bash
mkdir -p ~/.ehforwarderbot/profiles/default/
mkdir -p ~/.ehforwarderbot/profiles/default/blueset.telegram
mkdir -p ~/.ehforwarderbot/profiles/default/milkice.qq
```
### 创建配置文件~/.ehforwarderbot/profiles/default/config.yaml并编辑
```yaml
master_channel: blueset.telegram
slave_channels:
- milkice.qq
```
### 配置ETM
#### 创建bot
*向@BotFather发送/newbot启动向导*  
**注意：牢记bot的token**
#### 对bot进行配置 
发送 /setprivacy 到 @BotFather，选择刚刚创建好的 Bot 用户名，然后选择 “Disable”.  
发送 /setjoingroups 到 @BotFather，选择刚刚创建好的 Bot 用户名，然后选择 “Enable”.  
发送 /setcommands 到 @BotFather，选择刚刚创建好的 Bot 用户名，然后发送如下内容：
```yaml
link - 将会话绑定到 Telegram 群组
chat - 生成会话头
recog - 回复语音消息以进行识别
extra - 获取更多功能
```
#### 获取Telegram ID
*通过Bot查询，以下Bot可以查询，不行的话自己找Bot查询*  
@get_id_bot 发送 /start  
@XYMbot 发送 /whois  
@mokubot 发送 /whoami  
@GroupButler_Bot 发送 /id  
@jackbot 发送 /me  
@userinfobot 发送任意文字  
@orzdigbot 发送 /user  
#### 安装ETM
```bash
pip3 install efb-telegram-master
```
### 配置ETM
#### 创建配置文件~/.ehforwarderbot/profiles/default/blueset.telegram/config.yaml
```yaml
token: "12345678:bot-token" #换成自己的bot token
admins:
- 123456789 #填写Telegram ID

```
### 配置EQS
#### 安装EQS
```bash
pip3 install efb-qq-slave
```
#### 配置QQ客户端   
~~由于使用Mirai-http-api会遇到Telegram无法接收QQ消息的问题，故弃用，可能是兼容性问题~~
##### 使用go-cqhttp
*配置文件*  
```yaml
   account:         # 账号相关
     uin:           # QQ 账号
     password: ''   # QQ 密码，为空时使用扫码登录

   message:
     # 上报数据类型
     # efb-qq-plugin-go-cqhttp 仅支持 array 类型
     post-format: array
     # 为Reply附加更多信息
     extra-reply-data: true

   # 默认中间件锚点
   default-middlewares: &default
     # 访问密钥，强烈推荐在公网的服务器设置
     access-token: ''

   servers:
     # HTTP 通信设置
     - http:
         # 是否关闭正向 HTTP 服务器
         disabled: false
         # 服务端监听地址
         host: 127.0.0.1
         # 服务端监听端口
         port: 5700
         # 反向 HTTP 超时时间, 单位秒
         # 最小值为 5，小于 5 将会忽略本项设置
         timeout: 5
         middlewares:
           <<: *default # 引用默认中间件
         # 反向 HTTP POST 地址列表
         post:
           - url: 'http://127.0.0.1:8000' # 地址
             secret: ''                   # 密钥保持为空
```
*安装 efb-qq-plugin-go-cqhttp*  
```bash
pip install git+https://github.com/XYenon/efb-qq-plugin-go-cqhttp
```
*创建~/.ehforwarderbot/profiles/default/milkice.qq/config.yaml配置文件*
```yaml
Client: GoCQHttp                      # 指定要使用的 QQ 客户端
GoCQHttp:
    type: HTTP                        # 指定通信方式，现阶段仅支持 HTTP
    access_token:
    api_root: http://127.0.0.1:5700/  # GoCQHttp API接口地址/端口
    host: 127.0.0.1                   # efb-qq-slave 所监听的地址用于接收消息
    port: 8000                        # 同go-cqhttp配置文件中的端口
```
### 启动EFB
```bash
ehforwarderbot
```
### 使用Telegram
*搜索之前创建的Bot用户名，输入/start即可收发QQ消息*
