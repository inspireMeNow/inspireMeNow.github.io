---
title: rclone挂载云端网盘
ZHtags: 
  - webdav
key: rclone-config
date: '2023-02-19'
lastmod: '2023-02-19'
---
# 安装rclone
## Debian
```
sudo apt install rclone
```
# 配置云端网盘
```bash
rclone config
```
*提示：支持Amazon Drive、Dropbox、Google Drive、Google Photos、OpenDrive、SFTP、Webdav等众多网盘。*
# 新建挂载点
```bash
mkdir /path/to/mountpoint
```
# 挂载云端网盘
```bash
rclone mount remote_name:remote_path /path/to/mountpoint --daemon
```
# 进入挂载点目录
```bash
cd /path/to/mountpoint
```
**不要忘记卸载云端网盘！**
```bash
fusermount -u /path/to/mountpoint
```
# 更多用法
- 复制
```bash
rclone copy
```
- 同步到目标目录
```bash
rclone sync
```
- 双向同步
```bash
rclone bisync
```
- 移动
```bash
rclone move
```
- 删除路径下的内容
```bash
rclone delete
```
- 删除路径及所有内容
```bash
rclone purge
```
- 检查目标与源是否匹配
```bash
rclone check
```
- 列出路径中所有对象的大小和路径
```bash
rclone ls
```
- 列出路径中的所有目录
```bash
rclone lsd
```
- 列出远程目录中所有对象的总大小和数量
```bash
rclone size
```
# 选项配置