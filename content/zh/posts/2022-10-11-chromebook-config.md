---
title: chromebook配置
tags: 
  - chromebook
key: chromebook-config
date: '2022-10-10'
lastmod: '2022-10-28'
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
~~我没有使用crouton或者chromebrew~~  
*我是用了crostini和chromebrew，一个做包管理器，一个运行gui软件。*
## chromebrew
*chromebrew会将在chromeos中唯一的可执行目录/usr/local/写入rootfs并修改rootfs权限，从而使普通用户可读可执行文件。*
### 安装
```bash
curl -Ls git.io/vddgY | bash
```
### 使用
#### 安装软件包
```bash
crew install packagename
```
#### 搜索软件包
```bash
crew search packagename
```
#### 删除软件包
```bash
crew remove packagename
```
#### 重新安装软件包
```bash
crew reinstall packagename
```
### 遇到的问题
*安装rust后提示permission denied，发现home目录被设置了noexec标签导致无法运行可执行文件，故重新挂载home目录。*
```bash
sudo mount -i -o remount,rw,exec /home/chronos/user/
```
*此时重新运行cargo发现可以正常执行。*
```bash
cargo --version
```
## crostini
*打开chromebook设置中的linux支持即可，本质是一个lxc容器，相当于虚拟机。*
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
# 刷bios
**注意：刷bios之前需要拆下写保护螺丝并备份好BIOS！！！**
```bash
cd; curl -LO mrchromebox.tech/firmware-util.sh
sudo install -Dt /usr/local/bin -m 755 firmware-util.sh
sudo firmware-util.sh
```
*由于国内网络问题，建议使用软路由等建立热点连接，或者为root用户指定http_proxy变量。*
```bash
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
```
*之后按照提示进行操作即可，重启后进入bios较慢，耐心等待即可。*
# 使用windows
## 声卡驱动
**注意：需要提前安装intel智音驱动！！！**  
*使用@coolstar的sklkblsst驱动即可，但是该驱动有个问题就是开机后设备管理器一切正常但不发出声音，可以使用chromebook研究院群里的脚本解决，但是每次开机都需要执行该脚本。*
```powershell
pnputil /remove-device "ACPI\INT343B\0" 
pnputil /scan-devices 
pnputil /remove-device "ACPI\INT343B\1" 
pnputil /scan-devices 
exit
```
## 触摸板驱动
*使用@coolstar的sklkblsst驱动即可*
## 键盘映射驱动
*使用@coolstar的驱动即可*
## 其他驱动
*使用windows更新安装即可。*
# 使用linux
*触摸板，蓝牙，wifi均工作正常，只有声卡不工作，正在寻找解决方法。*  
**更新：intel已经重写了avs驱动，驱动目前已经进入5.19内核，但是仍在初始阶段，不久可能会修复声卡不工作的问题。**
# 恢复出厂系统时遇到的问题
*一直提示更新错误，按ctrl+alt+refresh键查看tty控制台输出发现bios固件更新失败，然后查资料发现需要装回写保护螺丝才可以正常刷入固件，故重新装入写保护螺丝，第二次恢复出厂系统成功。*  
**注意：成功后需要重置gbb标志才可以退出开发者模式，完全恢复官方系统！**
# windows下使用电池时屏幕闪烁
*在核心显卡控制面板“电源管理”中禁用”显示器节电技术“此功能即可，可能是win10的bug。*