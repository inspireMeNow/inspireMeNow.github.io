---
title: Linux远程桌面配置
tags: 
  - remote
key: linux-remote
date: '2022-01-06'
lastmod: '2022-01-06`
---
# Linux下的远程客户端
trigervnc、xrdp、gnome-remote-desktop、spice
# vnc配置
## 添加用户
```bash
sudo vim /etc/tigervnc/vncserver.users
```
```conf
# TigerVNC User assignment
#
# This file assigns users to specific VNC display numbers.
# The syntax is <display>=<username>. E.g.:
#
# :2=andrew
# :3=lisa

# 添加自己用户，注意，不要与现有DISPLAY环境变量冲突
:2=user

```
## 编辑systemd文件
```bash
sudo vim /usr/lib/systemd/system/vncserver@.service
```
```conf
[Unit]
Description=Remote desktop service (VNC)
After=syslog.target network.target

[Service]
Type=forking
ExecStartPre=+/usr/libexec/vncsession-restore %i
ExecStart=/usr/libexec/vncsession-start %i
PIDFile=/run/vncsession-%i.pid
SELinuxContext=system_u:system_r:vnc_session_t:s0

[Install]
WantedBy=multi-user.target

```
## 设置systemd服务自动启动
*这里记得填写用户对应的display_number*
```bash
sudo systemctl enable --now vncserver@display_number
```
## 使用vnc客户端测试连接
# gnome-remote-desktop配置
*由于gnome-remote-desktop限制只能已登录用户使用，需要设置自动登录*
## 设置自动登录
```bash
sudo vim /etc/gdm/custom.conf
```
```conf
[daemon]
AutomaticLoginEnable=True
AutomaticLogin=username
```
*虽然自动登录成功，但登录后keyring未解锁，导致远程不可用，需要解锁keyring*
## 解锁keyring
*注：使用的是别人的脚本*
```bash
wget https://codeberg.org/umglurf/gnome-keyring-unlock/raw/branch/main/unlock.py

chmod +x unlock.py

./unlock.py <<< yourpassword
```
## 使用rdp客户端测试连接
# spice配置
*待补充*