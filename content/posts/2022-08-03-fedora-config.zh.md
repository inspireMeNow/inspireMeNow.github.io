---
title: fedora基本配置
ZHtags: 
  - linux
key: fedora-setting 
date: '2022-08-03'
lastmod: '2024-03-05'
---

# 1.软件包管理工具

## dnf命令
*建立软件包缓存*  
```bash
sudo dnf makecache
```
*进行软件包更新*
```bash
sudo dnf upgrade
```
*更新单个软件包*
```bash
sudo dnf upgrade package_name
```
*搜索软件包*
```bash
dnf search package_name
```
*查找软件包，使用通配符*
```bash
dnf list kernel-*
```
*列出所有软件包*
```bash
dnf list all
```
*列出已安装软件包*
```bash
dnf list installed package_nam
```
*列出所有包组*
```bash
dnf group list
```
*列出已启用的软件仓库*
```bash
dnf repolist
```
*列出来自单个软件仓库的软件包*
```bash
dnf repository-packages fedora list
```
*显示单个软件包的信息*
```bash
dnf info package_name
```
*列出具体软件包的所有信息*
```bash
dnf repoquery package_name --info
```
*列出哪个软件包提供了该二进制文件*
```bash
dnf provides "*bin/named"
```
*列出某个软件包组的详细信息*
```bash
dnf -v group list group_name
```
*安装单个软件包*
```bash
sudo dnf install package_name
```
*不知道包名的情况下使用*
```bash
sudo dnf install /usr/sbin/named
```
*安装软件包组*
```bash
sudo dnf groupinstall group_nane
```
*卸载软件包*
```bash
sudo dnf remove package _name
```
*卸载软件包组*
```bash
sudo dnf group remove group_name
```
*列出所有事务*
```bash
dnf history list
```

# 2.驱动安装

## 显卡
*查看显卡型号*
```bash
lspci -k | grep -EA3 'VGA|3D|Display' 
```

### AMD, Intel显卡免驱
*查看模块加载情况*
```bash
lsmod|grep amdgpu
```

### NVIDIA 显卡驱动安装

#### 1.进行软件包更新

```bash
sudo dnf update  --refresh
```

#### 2. 安装驱动程序及其依赖

```bash
sudo dnf install gcc kernel-headers kernel-devel akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-libs xorg-x11-drv-nvidia-libs.i686
```

#### 3.等待驱动模块加载，过程需要5~10分钟

```bash
ps -e | grep akmods # 执行命令无输出说明模块安装完成
```

#### 4.强制从更新的内核模块中读取配置

```bash
sudo akmods --force

sudo dracut --force
```

#### 5.命令完成后重新启动系统

```bash
sudo reboot
```

```bash
lsmod | grep nvidia # 查看模块加载情况
```
## 网卡
### intel
*fedora预置了iwlwifi驱动模块，故可以即插即用。*  
*若其他系统比如debian默认没有预置需要添加non-free源并安装firmware-nonfree包,~~也可以将固件下载下来复制到/lib/firmware~~*    
*近期我将预置的我将预置的wpa_supplicant换成了iwd，fedora提供了iwd的包*  
#### 安装
```bash
sudo dnf install iwd
```
#### 停止并屏蔽wpa_supplicant
```bash
sudo systemctl stop wpa_supplicant

sudo systemctl mask wpa_supplicant
```
#### 设置自动启动
```bash
sudo systemctl enable --now iwd
```
### 设置NetworkManager
*由于NetworkManager默认以wpa_supplicant为后端，因此需要更改后端为iwd*  
```bash
sudo vim /etc/NetworkManager/conf.d/iwd.conf
```
```conf
[device]
wifi.backend=iwd
wifi.iwd.autoconnect=yes
```
### 重启NetworkManager  
```bash
sudo systemctl restart NetworkManager
```
# realtek
*你可能需要自己编译驱动，源码请自行寻找。*
# 3. systemd服务
*启动服务*
```bash
systemctl start service_name
```
*重启服务*
```bash
systemctl restart service_name
```
*服务自动启动*
```bash
systemctl enable service_name
```
*服务取消自动启动*
```bash
systemctl disable service_name
```
*屏蔽服务*
```bash
systemctl mask service_name
```
*查看服务是否自动启动*
```bash
systemctl is-enabled service_name
```
*编辑服务*
```bash
systemctl edit httpd.service
```
*新建服务*
```bash
vim /etc/systemd/system/foo.service
```

```conf
#示例
[Unit]
Description=frpc #服务描述
After=network.target #在网络连接激活后启动

[Service]
Type=simple #服务类型
ExecStart=/usr/bin/frpc -c frp.ini #命令

[Install]
WantedBy=multi-user.target
```

```bash
systemctl status service_name #查看服务运行状态

journalctl -u service_name #查看服务运行日志

journalctl --vacuum-size=1M #清理运行日志
```
## 硬件解码
**注意：需要先启用rpmfusion仓库才能继续操作！**  
```bash
sudo dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel
```
```bash
sudo dnf install lame\* --exclude=lame-devel
```
```bash
sudo dnf group upgrade --with-optional Multimedia
```
### intel视频解码
```bash
sudo dnf install intel-media-driver libva libva-utils gstreamer1-vaapi ffmpeg intel-gpu-tools mesa-dri-drivers mpv
```
*编辑~/.bashrc*
```bash
export LIBVA_DRIVER_NAME=iHD
```
*十一代CPU及以后开启guc以及fbc*  
*编辑/etc/modprobe.d/i915.conf*
```conf
options i915 enable_guc=3
options i915 enable_fbc=1
```
*重新生成initramfs* 
```bash
sudo dracut --force
```
*重启查看guc以及huc是否启用*
```bash
sudo dmesg | grep -i guc
```
### 浏览器硬件解码
*chrome*  
**wayland下不可用**  
```conf
/usr/bin/google-chrome-stable --proxy-server=socks5://127.0.0.1:7890 --enable-gpu-rasterization --enable-zero-copy --disable-features=UseChromeOSDirectVideoDecoder --enable-features=VaapiVideoDecoder --enable-features=VaapiVideoEncoder --ignore-gpu-blocklist --ozone-platform-hint=auto --gtk-version=4 --enable-features=WebUIDarkMode --force-dark-mode %U
```
*firefox*  
*硬件解码应该开箱即用*  
# 4.vim命令

## 命令模式

i 进入编辑模式  
x 删除当前光标所在处的字符  
: 切换到底线命令模式  

## 输入模式

*回车键换行*  
*退格键删除光标前一个字符*  
*删除键删除光标后一个字符*    
*方向键在文本中移动光标*  
*HOME/END移动光标到行首/行尾*  
*Page Up/Page Down上/下翻页*  
*Insert切换光标为输入/替换模式，光标将变成竖线/下划线*  
*ESC退出输入模式，切换到命令模式*  

*输入“/”搜索字符串，回车后跳转到对应字符串位置*  

# 5.KVM虚拟化
*查看CPU是否支持虚拟化，有输出说明CPU支持虚拟化*
```bash
egrep '^flags.*(vmx|svm)' /proc/cpuinfo 
```
*安装虚拟化包组*
```bash
sudo dnf install @virtualization
```
*设置libvirtd自动启动并启动服务*
```bash
sudo systemctl enable --now libvirtd
```
*查看KVM内核模块是否加载*
```bash
lsmod | grep kvm
```

## 使用virsh-install配置

```bash
sudo virt-install --name Fedora \
--description 'Fedora' \
--ram 4096 \
--vcpus 4 \
--disk path=/var/lib/libvirt/images/linux.qcow2,size=20 \
--os-type linux \
--os-variant fedora36 \
--network bridge=virbr0 \
--graphics vnc,listen=127.0.0.1,port=5901 \
--cdrom Fedora-Workstation-Live-x86-64-36-1.1.iso \
--noautoconsole
```

## 使用virt-manager配置

### 根据gui界面管理

## 使用virsh配置
*创建虚拟机*
```bash
virsh create machine_name 
```
*列出所有虚拟机*
```bash
virsh list --all
```
*导出配置文件*
```bash
virsh dumpxml <virtual machine (name | id | uuid)
```
*虚拟机关机*
```bash
virsh shutdown machine_name
```
*虚拟机强制关机*
```bash
virsh destroy machine_name
```

# 6.启用第三方软件仓库
## 启用flathub仓库
*添加软件源*

```bash
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

*搜索软件包*

```bash
flatpak --user search package_name
```

*安装软件包*

```bash
flatpak --user install package_name
```

*删除软件包*

```bash
flatpak --user remove package_name
```
## 启用rpmfusion软件仓库
```bash
sudo dnf install https://mirrors.ustc.edu.cn/rpmfusion/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.ustc.edu.cn/rpmfusion/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```
*之后执行dnf makecache重新生成软件包缓存即可。*  
## 设置其他软件仓库
*依照软件官网的设置向导设置即可。*
# 7.中文输入法配置
```bash
sudo dnf install fcitx5-configtool fcitx5 fcitx5-rime
```
*配置输入法自动启动*  
```bash
sudo dnf install fcitx5-rime
```
*注销账户重新登录或者重启电脑后即可使用。*
# 8.端口被占用解决方法
## 查看占用端口的程序
*lsof命令*  
```bash
lsof -i:port_number
```
*netstat命令*
```bash
netstat -tunlp | grep port_number
```
## 杀死占用端口的程序
```bash
kill -9 PID
```
# 9.开启sysrq

**由于某个服务卡死或者kernel loop导致无法关机时使用**

```bash
sudo vim /etc/sysctl.d/90-sysrq.conf
```
```conf
kernel.sysrq = 1
```
*查看sysrq是否已启用*
```bash
cat /proc/sys/kernel/sysrq
```
**注：各数字代表功能：**  
- 0 - disable sysrq completely
- 1 - enable all functions of sysrq
- \>1 - bitmask of allowed sysrq functions (see below for detailed function description):
  - 2 - enable control of console logging level
  - 4 - enable control of keyboard (SAK, unraw)
  - 8 - enable debugging dumps of processes etc.
  - 16 - enable sync command
  - 32 - enable remount read-only
  - 64 - enable signalling of processes (term, kill, oom-kill)
  - 128 - allow reboot/poweroff
  - 256 - allow nicing of all RT tasks  

*临时启用sysrq*  
```bash
echo "number" >/proc/sys/kernel/sysrq 
```
注：需重启电脑或~~sysctl -p~~生效

# 10.迁移/var目录遇到的问题

*由于我的好多docker镜像存储在/var目录，导致根目录可用空间越来越小，于是考虑将/var目录迁移到新分区。*

## 迁移过程

###  备份

**注：若要备份整个系统，则需要排除目录/proc,/lost+found,/mnt,/sys,/run/media,/dev,/tmp，若备份输出的包本身在备份目录则还要排除包本身，可以使用--exclude命令进行排除**

#### pigz打包

```bash
sudo tar --use-compress-program=pigz -cvpf linux-backup.tgz /var
```

#### zstd打包

```bash
sudo tar -z -c -T0 -18 -v -p -f - linux-backup.zstd /var
```

### 恢复

#### 切换到LiveCD

*BIOS设置为LiveCD启动，然后重启电脑*

#### 挂载磁盘

```bash
sudo mount /dev/nvme0n1p3 /mnt/var
```

#### 解包备份文件

##### pigz解包

```bash
sudo tar -xvf linux-backup.tgz -C /mnt/
```

##### zstd解包

```bash
sudo tar -z -c -T0 -18 -v -p -f - linux-backup.zstd -C /mnt/
```

#### 重启电脑

## 遇到的问题

~~最初不知道为啥不开机，发现可进入shell，进入shell后发现/var/log/audit/audit.log中有大量denied字段，猜测可能是selinux问题，于是把selinux设置为disabled重启电脑发现正常，重新开启后就不开机，发现文件的label可能已经错乱。~~

*由于文件的selinux标识不正确导致无法开机，google了很多资料，重新标记文件标识才解决。*

## 解决方法

*设置开机后重新标记文件*

```bash
sudo fixfiles -F -B onboot
```

## 最终结果

*重启后selinux重新relabel有一堆警告，可以无视，重启后即可正常开机，log中也没有大量denied字段。*

# 11.无法执行二进制文件的解决方法
*systemd报错提示Permission Denied,怀疑是selinux的问题，于是setenforce 0，重启systemd服务，二进制文件可以正常执行，于是查资料发现需要selinux设置可执行文件标签才可以正常运行程序。*
```bash
sudo chcon -R -t bin_t /usr/bin/tuic
```
# 12.ssh远程登录机器时遇到的问题
*远程登录时遇到publickey permission denied报错，经过查阅资料发现ssh密钥不是立刻被导入电脑的，需要自己先行导入。*  
**注意：有时无法登录时可以kill掉ssh-agent进程并重新启动此进程。**
```bash
eval $(ssh-agent) > /dev/null
killall ssh-agent #kill掉ssh-agent进程
eval `ssh-agent`
ssh-add ~/.ssh/id_rsa #添加自己的密钥
```
*第一次登录可以使用-i选项指定密钥登录，此外也可以指定端口。*
```bash
ssh -i /path/to/yourkey username@host -p port
```
**重要：公钥放在服务器的authorized_keys文件中，私钥一定要自己拿好，不要给别人，服务器一定要禁用密码登录和root用户登录！**
```conf
PasswordAuthentication yes #禁止密码登录
PermitRootLogin no #禁止root用户登录
```
