---
title: 实现校园网自动认证的功能
tags: 
  - web
key: campus-problem
date: '2023-02-26'
lastmod: '2023-02-26'
---
*由于校园网认证总是自己断掉，于是想到使用bash或python脚本认证校园网的方法，配合linux的cron可以方便的进行自动认证。*  
# 抓取登录时使用的get/post请求
- 打开chrome开发者工具，选择网络，勾选保留日志选项  
![development-tool](/images/development-tool.png)
- 输入用户名和密码并登录，找到对应的登录请求
- 以cURL格式复制值  
![chrome-curl](/images/chrome-curl.png)  
*我的校园网使用的是get请求*
# 使用shell脚本认证
## 获取本机ip地址
```bash
ifconfig interface |grep inet|awk '{print $(NF)}'|head -n 1 # 替换为自己的网络接口
```
## 获取本机mac地址
```bash
ifconfig interface | grep ether| awk '{print $(NF-3)}' # 替换为自己的网络接口
```
## 编写认证脚本
```bash
CURRENT_IP=$(ifconfig interface|grep inet|awk '{print $(NF)}'|head -n 1)
MAC_ADDRESS=$(ifconfig interface | grep ether| awk '{print $(NF-3)}')
curl "http://192.168.251.75/quickauth.do?userid=userid&passwd=passwd&wlanuserip=${CURRENT_IP}&wlanacname=NFV-BASE&wlanacIp=202.206.32.195&ssid=&vlan=0&mac=${MAC_ADDRESS}&version=0&portalpageid=1&timestamp=1677389084992&uuid=d149ad07-e027-4f8b-aef3-206b5a4acf8e&portaltype=&hostname=" \
  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7" \
  -H "Accept-Language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7" \
  -H "Cache-Control: max-age=0" \
  -H "Connection: keep-alive" \
  -H "Cookie: macAuth=1f:78:63:0a:00:00||2b:7d:63:0a:00:00; ABMS=dbed4e41-6917-4d4e-8cce-f3c654b1e83c" \
  -H "DNT: 1" \
  -H "Upgrade-Insecure-Requests: 1" \
  -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36" \
  --compressed \
  --insecure
```
### 遇到的问题
*总是提示ip会话认证失败，使用具体值便认证成功，curl没有正确读取变量的值，查阅资料发现时url中的“&”字符引起的问题，需要对url进行编码*
### 解决方法
*使用urlencode命令将变量的值编码为url格式*
```bash
urlencode "${MAC_ADDRESS}"
```
*修改后的脚本如下*
```bash
CURRENT_IP=$(ifconfig interface |grep inet|awk '{print $(NF-4)}'|head -n 1)
MAC_ADDRESS=$(ifconfig interface | grep ether| awk '{print $(NF-3)}')
curl "http://192.168.251.75/quickauth.do?userid=userid&passwd=passwd&wlanuserip=$(urlencode "${CURRENT_IP}")&wlanacname=NFV-BASE&wlanacIp=202.206.32.195&ssid=&vlan=0&mac=$(urlencode "${MAC_ADDRESS}")&version=0&portalpageid=1&timestamp=1677389084992&uuid=d149ad07-e027-4f8b-aef3-206b5a4acf8e&portaltype=&hostname=" \
  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7" \
  -H "Accept-Language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7" \
  -H "Cache-Control: max-age=0" \
  -H "Connection: keep-alive" \
  -H "Cookie: macAuth=1f:78:63:0a:00:00||2b:7d:63:0a:00:00; ABMS=dbed4e41-6917-4d4e-8cce-f3c654b1e83c" \
  -H "DNT: 1" \
  -H "Upgrade-Insecure-Requests: 1" \
  -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36" \
  --compressed \
  --insecure
```
### 将脚本加入cron文件，定期运行脚本
*我设置的时每晚18时执行认证脚本*
```conf
0 18 * * * /path/to/auth
```
# 使用python脚本认证
## 使用netifaces包获取本机ip和mac地址
### 获取本机的所有网络接口
```python
import netifaces
netifaces.interfaces()
```
### 找到自己的wifi接口名称并获取ip和mac地址
```python
mac = netifaces.ifaddresses('interface')[netifaces.AF_LINK][0]['addr']
ip = netifaces.ifaddresses('interface')[netifaces.AF_INET][0]['addr']
```
## 使用request库模拟curl的get请求
```python
r = requests.get('http://192.168.251.75/quickauth.do?userid=userid&passwd=passwd&wlanuserip='+ip+'&wlanacname=NFV-BASE&wlanacIp=202.206.32.195&ssid=&vlan=0&mac='+mac+'&version=0&portalpageid=1&timestamp=1677389084992&uuid=d149ad07-e027-4f8b-aef3-206b5a4acf8e&portaltype=&hostname=')
print(r.json())
```