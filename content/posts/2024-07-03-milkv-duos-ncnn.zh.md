---
title: 在milkv duo s开发版上运行ncnn并测试
ZHtags: 
  - ncnn
key: ncnn
date: '2024-07-03'
lastmod: '2024-07-03'
---
# 编译安装ncnn
## 克隆ncnn仓库
*我的系统是fedora 40*
```bash
mkdir ncnn
cd ncnn
git clone https://github.com/Tencent/ncnn.git
git submodule update --init
```
## 设置交叉工具链
```bash
cd ..
wget https://sophon-file.sophon.cn/sophon-prod-s3/drive/23/03/07/16/host-tools.tar.gz
mkdir riscv-milkv
tar -zxvf host-tools.gz -C riscv-milkv/
export RISCV_ROOT_PATH=$(pwd)/riscv-milkv/host-tools/gcc/riscv64-linux-x86_64
```
## 设置cmake
```bash
cd ncnn
mkdir build-milkv/
cd build-milkv
cmake -DCMAKE_TOOLCHAIN_FILE=../toolchains/c906-v240.toolchain.cmake -DCMAKE_BUILD_TYPE=release -DNCNN_BUILD_TESTS=ON -DNCNN_OPENMP=OFF -DNCNN_THREADS=OFF -DNCNN_RUNTIME_CPU=OFF -DNCNN_RVV=ON -DNCNN_SIMPLEOCV=ON -DNCNN_BUILD_EXAMPLES=ON ..
```
![](/images/ncnn-milkv-cmake.png)
*设置完cmake就可以编译ncnn了*
## 编译ncnn
```bash
make -j$(nproc)
```
![](/images/ncnn-milkv-compile.png)
## 将benchncnn和param文件传送到milkv duo s开发版
*开发版上是linux系统，这里我使用scp传送,将my_ip和/path/to/替换成自己的*
```bash
make install
scp duan@my_ip:/path/to/ncnn/build-milkv/benchncnn .
scp duan@my_ip:/path/to/ncnn/benchmark/*.param .
```
![](/images/ncnn-milkv-push.png)
## 跑分测试
*milkv duo s的SG2000有一个ARM核（1 x Cortex-A53@1GHz）和一个RISCV核（1 x C906@1GHz + 1 x C906@700MHz)，有点难为这块开发板了x*
### riscv核跑分
```bash
chmod +x benchncnn
./benchncnn 4 1 2 -1 0
```
![](/images/milkv-ncnn-benchmark.png)
### arm核跑分
*明天在更*