---
title: chromebook配置
tags: 
  - chromebook
key: chromebook-config
date: '2022-09-30'
lastmod: '2022-10-01'
---
# 启用开发者模式
**注意：此操作会对chromebook进行powerwash操作！**  
*开机按esc+refresh+power键按提示进行操作即可。*
# 设置上网环境  
## 设置tuic
### 下载  
```bash
wget https://github.com/EAimTY/tuic/releases/download/0.8.4/tuic-client-0.8.4-x86_64-linux-gnu
```
### 安装  

**注意：chromeos的分区除了/usr/local/外所有路径均有noexec标签，即阻止任何二进制文件运行，所以只能安装到/usr/local路径下！**     
```bash
mv tuic-client-0.8.4-x86_64-linux-gnu tuic

sudo install -Dt /usr/local/bin -m 755 ~/Downloads/tuic
```
### 配置
```bash
mkdir -p /usr/local/etc/tuic

sudo vim /usr/local/etc/tuic/config.json
```
```json
{
    "relay": {
        "server": "servername",
        "port": yourport,
        "token": "yourtoken",

        "udp_relay_mode": "quic",
        "congestion_controller": "bbr",
        "heartbeat_interval": 10000,
        "alpn": ["h3"],
        "disable_sni": false,
        "reduce_rtt": false,
        "request_timeout": 8000,
        "max_udp_relay_packet_size": 1500
    },
    "local": {
        "port": yourlocalort,

        "ip": "127.0.0.1"
    },
    "log_level": "info"
}
```
### 启动
```
nohup tuic -c /usr/local/etc/tuic/config.json
```

## 设置clash
### 安装
```bash
sudo install -Dt /usr/local/bin -m 755 ~/Downloads/clash
```
### 启动
```bash
nohup clash &
```
## 设置代理
*进入设置选手动配置代理即可。*  

### 配置文件
*之前说过，不再赘述。*
# 设置linux环境
*我没有使用crouton或者chromebrew，我使用了官方的crostini，官方内置的是debian镜像，按debian系统的操作即可。* 
# 中文输入法
*linux环境中使用fcitx即可，chromeos的中文可以在设置中启用。*
# vscode-server使用
*过程中遇到了vscode中gpg签名失败的方法，查阅了资料，得到解决办法如下：*
```bash
export GPG_TTY=$(tty)
```
*之后应该可以在终端中验证gpg签名了。*
# 体验
*我这台是3k屏，观感比之前1080p的win本好了不少，写代码比之前舒服多了，就是chromebook的中文输入法比较残废。*