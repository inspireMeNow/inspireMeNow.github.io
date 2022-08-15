---
title: gpg加密解密
tags: gpg
key: gpg-encrypt
---
# 生成密钥
*gpg生成私钥*
gpg --gen-key
*导出密钥*
```bash
gpg --export --armor keyID > gpgkey.pub.asc
```
*导入公钥*
```bash
gpg --import gpgkey.pub.asc
```
*从服务器导入*
```bash
gpg --keyserver servername --recv-keys keyID
```
# 非对称加密解密
*加密文件*
```bash
gpg -e -r username filename
```
*解密文件*
```bash
gpg -d filename
```
# 对称加密解密
*加密文件*
gpg --symmetric filename