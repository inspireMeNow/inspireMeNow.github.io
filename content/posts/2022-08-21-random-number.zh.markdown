---
title: 随机数生成
ZHtags: 
  - linux
key: random-number
date: '2022-08-21'
lastmod: '2022-08-21'
---
# 通过系统变量生成
```bash
echo $RANDOM
```
*获取特定位数的随机字符,这里为10位*  
```bash
echo $RANDOM |md5sum |cut -c 1-10
```
*获取随机数字,这里为10位*
```bash
echo $RANDOM |cksum |cut -c 1-10
```
# 通过openssl生成
*base64编码*  
```bash
openssl rand -base64 10
```
**注：openssl产生的是指定长度个bytes的随机字符，也可使用cksum等命令生成随机数字**
# 通过系统uuid生成
```bash
cat /proc/sys/kernel/random/uuid 
```
# 通过程序实现
## C++实现
### 随机数
*生成1~100000之间的随机数，使用srand函数初始化保证每次的随机数不同*
```c++
# include <iostream>
#include<random>
#include<time.h>
int main(){
    srand((unsigned)time(NULL));
    int a=1;
    int b=100000;
    std::cout << (rand() % (b - a + 1)) + a << std::endl;
    return 0;
}
```
### 随机字符