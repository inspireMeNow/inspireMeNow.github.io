---
title: Fedora 切换到 UKI 内核并启用安全启动
ZHtags: 
  - fedora
key: fedora
date: '2025-05-29'
lastmod: '2024-05-29'
---
# 生成 UKI 镜像
**这部分需要先去 BIOS 关闭安全启动！！**
## 删除 GRUB 引导程序
```bash
sudo rm -rf /boot/efi/*
sudo dnf remove grub2\* --setopt=protected_packages=
```
## 配置 kernel-install
~~这里也可以使用 ukify~~
```bash
sudo vim /etc/kernel/install.conf
```
```conf
layout=uki
uki_generator=dracut
```
*由于默认生成的 efi 文件包含随机字符，不利于 Direct Boot，这里需要固定 efi 文件名称*
```bash
sudo cp /usr/lib/kernel/install.d/90-uki-copy.install /etc/kernel/install.d/
sudo vim /etc/kernel/install.d/90-uki-copy.install
```
*这里添加了 `UKI_FALLBACK_FILE`， 留一份原来的内核备用*
```sh
#!/usr/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
# SPDX-License-Identifier: LGPL-2.1-or-later
#
# This file is part of systemd.
#
# systemd is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 2.1 of the License, or
# (at your option) any later version.
#
# systemd is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with systemd; If not, see <https://www.gnu.org/licenses/>.

set -e

COMMAND="${1:?}"
KERNEL_VERSION="${2:?}"
# shellcheck disable=SC2034
ENTRY_DIR_ABS="$3"
KERNEL_IMAGE="$4"

BOOT_ROOT="$KERNEL_INSTALL_BOOT_ROOT"

UKI_DIR="$BOOT_ROOT/EFI/Linux"

UKI_FILE="$UKI_DIR/fedora-linux.efi"
UKI_FALLBACK_FILE="$UKI_DIR/fedora-linux-fallback.efi"

# If there is a UKI named uki.efi on the staging area use that, if not use what
# was passed in as $KERNEL_IMAGE but insist it has a .efi extension
if [ -f "$KERNEL_INSTALL_STAGING_AREA/uki.efi" ]; then
    install -m 0644 "$UKI_FILE" "$UKI_FALLBACK_FILE"
    [ "$KERNEL_INSTALL_VERBOSE" -gt 0 ] && echo "Installing $KERNEL_INSTALL_STAGING_AREA/uki.efi as $UKI_FILE"
    install -m 0644 "$KERNEL_INSTALL_STAGING_AREA/uki.efi" "$UKI_FILE" || {
        echo "Error: could not copy '$KERNEL_INSTALL_STAGING_AREA/uki.efi' to '$UKI_FILE'." >&2
        exit 1
    }
elif [ -n "$KERNEL_IMAGE" ]; then
    [ -f "$KERNEL_IMAGE" ] || {
        echo "Error: UKI '$KERNEL_IMAGE' not a file." >&2
        exit 1
    }
    [ "$KERNEL_IMAGE" != "${KERNEL_IMAGE%*.efi}.efi" ] && {
        echo "Error: $KERNEL_IMAGE is missing .efi suffix." >&2
        exit 1
    }
    [ "$KERNEL_INSTALL_VERBOSE" -gt 0 ] && echo "Installing $KERNEL_IMAGE as $UKI_FILE"
    install -m 0644 "$KERNEL_IMAGE" "$UKI_FILE" || {
        echo "Error: could not copy '$KERNEL_IMAGE' to '$UKI_FILE'." >&2
        exit 1
    }
else
    [ "$KERNEL_INSTALL_VERBOSE" -gt 0 ] && echo "No UKI available. Nothing to do."
    exit 0
fi

chown root:root "$UKI_FILE" || :

exit 0

```
## 更改 dracut 配置
*由于 dracut 默认并不会读取 `/etc/kernel/cmdline` 中的内核参数，这里需要修改，保证 dracut 能读取到内核参数*
```bash
sudo vim /etc/dracut.conf
```
```conf
kernel_cmdline="$(cat /etc/kernel/cmdline)"
```
## 生成 UKI 镜像
```bash
sudo kernel-install add-all -v
```
~~如果没报错应该就成功了~~
## 设置启动项
```bash
sudo efibootmgr --create --disk /dev/sdX --part partition_number --label "Fedora" --loader '\EFI\Linux\fedora-linux.efi' --unicode
```
# 启用安全启动
## 安装 [sbctl](https://github.com/Foxboron/sbctl)
```bash
sudo dnf copr enable chenxiaolong/sbctl
sudo dnf install sbctl
```
## 创建密钥
```bash
sudo sbctl create-keys
```
## 将密钥导入BIOS
**这部分的操作可能导致设备变砖！！**   
    
**导入前 BIOS 需要启用 Setup Mode，具体参考 [example enrollment](https://github.com/Foxboron/sbctl/blob/master/docs/workflow-example.md)**

### Option ROM

```bash
cp /sys/kernel/security/tpm0/binary_bios_measurements eventlog
tpm2_eventlog eventlog | grep "BOOT_SERVICES_DRIVER"
EventType: EV_EFI_BOOT_SERVICES_DRIVER
```
**输出包含 `BOOT_SERVICES_DRIVER` 表明电脑包含 Option ROM，不可以直接 enroll，否则会导致变砖**

*导入`Microsoft Corporation UEFI CA 2011` 证书*
```bash
sudo sbctl enroll-keys -m
```

*如果不想导入微软的证书可以使用 `TPM eventlog` 读取校验值后手动导入*
```bash
sudo sbctl enroll-keys -t
```

*没有 Option ROM 的电脑直接 enroll 即可*
```bash
sudo sbctl enroll-keys
```

## 修改 install 文件
*sbctl 默认会签名包含随机字符的 UKI 镜像，不修改会报 not exist 错误*
```bash
sudo cp /usr/lib/kernel/install.d/91-sbctl.install /etc/kernel/install.d/
sudo vim /etc/kernel/install.d/91-sbctl.install
```
*这里固定了 `IMAGE_FILE`，并删掉了 remove 部分，~~毕竟不需要清理内核了~~*
```sh
#!/usr/bin/sh
#  This file is part of sbctl.

COMMAND="$1"
KERNEL_VERSION="$2"
ENTRY_DIR_ABS="$3"
# shellcheck disable=SC2034  # Unused variables left for readability
KERNEL_IMAGE="$4"

IMAGE_FILE="$ENTRY_DIR_ABS/linux"
IMAGE_FALLBACK_FILE="$ENTRY_DIR_ABS/linux"

if [ "$KERNEL_INSTALL_LAYOUT" = "uki" ]; then
        UKI_DIR="$KERNEL_INSTALL_BOOT_ROOT/EFI/Linux"
        IMAGE_FILE="$UKI_DIR/fedora-linux.efi"
        IMAGE_FALLBACK_FILE="$UKI_DIR/fedora-linux-fallback.efi"
fi

case "$COMMAND" in
add)
        printf 'sbctl: Signing kernel %s\n' "$IMAGE_FILE"

        # exit without error if keys don't exist
        # https://github.com/Foxboron/sbctl/issues/187
        if ! [ "$(sbctl setup --print-state --json | awk '/installed/ { gsub(/,$/,"",$2); print $2 }')" = "true" ]; then
                echo "Secureboot key directory doesn't exist, not signing!"
                exit 0
        fi

        sbctl sign "$IMAGE_FILE" 1>/dev/null
        sbctl sign "$IMAGE_FALLBACK_FILE" 1>/dev/null
        ;;
esac
```
*之后每次内核更新都会重新签名*

## 重新生成 UKI 镜像并签名
```bash
sudo kernel-install add-all -v
```
# 参考
- [Unified kernel image - Gentoo Wiki](https://wiki.gentoo.org/wiki/Unified_kernel_image)
- [Unified kernel image - ArchWiki](https://wiki.archlinux.org/title/Unified_kernel_image)
- [FAQ Foxboron/sbctl Wiki](https://github.com/Foxboron/sbctl/wiki/FAQ)

