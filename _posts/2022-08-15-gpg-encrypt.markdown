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
```bash
gpg --symmetric filename
```
*解密文件*
```bash
gpg -d filename
```
# 对文件签名
*数字签名*
```bash
gpg -o filename.sig -s filename
```
*签名+加密*
```bash
gpg -o filename.sig -ser name filename
```
*文本签名*
```bash
gpg -o filename.sig --clearsign filename
```
*分离签名（原文件与签名分开）*
```bash
gpg -o filename.sig -ab filename
```
*验证签名*
```bash
gpg --verify filename.sig filename
```
# github使用gpg签名提交
*1.在Github的[SSH and GPG keys](https://github.com/settings/keys)中，新增一个GPG key。*  
  
*2.设置git使用的gpg key id。*  
```bash
git config --global user.signingkey {key_id}
```
*3.用gpg key id签名*
### 每次提交时加上-S参数
```bash
git commit -S -m "update blogs"
```
### 全局设置每次提交时使用签名
```bash
git config --global commit.gpgsign true
```
### 本地确认github web端提交的签名信息
*导入github的密钥*
```bash
curl https://github.com/web-flow.gpg | gpg --import
```
*用自己的密钥进行签名验证*
```bash
gpg --sign-key {key_id}
```