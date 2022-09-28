---
title: docker容器配置
tags: 
  - docker
key: docker-container
date: '2022-09-27'
lastmod: '2022-09-27'
---
*由于编译debian方便一点，故pull了一个debian镜像，设置过程参考了[docker文档](https://docs.docker.com/)。*
# docker安装
- 设置软件仓库
  ```bash
  sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

  sudo dnf makecache
  ```
- 安装docker引擎
  ```bash
  sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin
  ```
- 安装特定版本的docker
  - 查看可用版本
    ```bash
     dnf list docker-ce  --showduplicates | sort -r
    ```
  - 安装docker
    ```bash
    sudo dnf -y install docker-ce-<VERSION_STRING> docker-ce-cli-<VERSION_STRING> containerd.io docker-compose-plugin
    ```
- 设置docker自动启动
  ```bash
  sudo systemctl enable --now docker
  ```
- 将用户加入docker用户组（可选）  
  
  *这样打开docker时不需要授权*
  ```bash
  sudo usermod -a -G docker username
  ```
  **注意：需要重启系统才能生效**
# 运行GUI程序
*加上-e DISPLAY=${DISPLAY} -v /tmp/.X11-unix:/tmp/.X11-unix:Z参数即可，但是不要使用root账户运行gui程序会打不开窗口*
# 设置debian参数
*-e用于设置环境变量，-v用于设置挂载的volume，可以挂载实际文件夹，也可以挂载docker的volume，后者需要为volume命名，如果系统启用了selinux，则需要加上:Z参数*
```bash
docker run --name debian -e LANG=C.UTF-8 -e DISPLAY=${DISPLAY} -v /tmp/.X11-unix:/tmp/.X11-unix:Z -v /pathto/github:/pathto/github:Z -it debian:unstable /bin/bash -l
```
**注意：debian镜像中需要先安装好X11**
# 平时启动debian
```bash
docker start debian

docker exec -it debian bash
```
# 删除镜像
```bash
docker rm debian
```
