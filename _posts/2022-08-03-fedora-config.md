---
title: fedora基本配置
tags: linux
key: fedora-config
---
# 1.软件包管理工具
## dnf命令
```
sudo dnf makecache //建立软件包缓存
```
```
sudo dnf upgrade //进行软件包更新
```
```
sudo dnf upgrade package_name //更新单个软件包
```
```
sudo dnf install https://mirrors.ustc.edu.cn/rpmfusion/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.ustc.edu.cn/rpmfusion/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm //启用rpmfusion软件仓库
```
```
dnf search package_name //搜索软件包
```
```
dnf list kernel-* //查找软件包，使用通配符
```
```
dnf list all //列出所有软件包
```
```
dnf list installed package_name //列出已安装软件包
```
```
dnf group list //列出所有包组
```
```
dnf repolist //列出已启用的软件仓库
```
```
dnf repository-packages fedora list //列出来自单个软件仓库的软件包
```
```
dnf info package_name //显示单个软件包的信息
```
```
dnf repoquery package_name --info //列出具体软件包的所有信息
```
```
dnf provides "*bin/named" //列出哪个软件包提供了该二进制文件
```
```
dnf -v group list group_name //列出某个软件包组的详细信息
```
```
sudo dnf install package_name //安装单个软件包
```
```
sudo dnf install /usr/sbin/named //不知道包名的情况下使用
```
```
sudo dnf groupinstall group_nane //安装软件包组
```
```
sudo dnf remove package _name //卸载软件包
```
```
sudo dnf group remove group_name //卸载软件包组
```
```
dnf history list //列出所有事务
```
# 2.驱动安装
## 显卡
```
lspci -k | grep -EA3 'VGA|3D|Display' //查看显卡型号
```
### AMD, Intel显卡免驱
```
lsmod|grep amdgpu //查看模块加载情况
```
### NVIDIA 显卡驱动安装
#### 1.进行软件包更新
```
sudo dnf update  --refresh
```
#### 2. 安装驱动程序及其依赖
```
sudo dnf install gcc kernel-headers kernel-devel akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-libs xorg-x11-drv-nvidia-libs.i686
```
#### 3.等待驱动模块加载，过程需要5~10分钟
```
ps -e | grep akmods //执行命令无输出说明模块安装完成
```
#### 4.强制从更新的内核模块中读取配置
```
sudo akmods --force 
sudo dracut --force
```
#### 5.命令完成后重新启动系统
```
sudo reboot
```
```
lsmod | grep nvidia //查看模块加载情况
```