---
title: 在RK3588平台上运行ncnn并测试
ZHtags: 
  - ncnn
key: ncnn
date: '2024-06-30'
lastmod: '2024-06-30'
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
wget https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/_toolchain/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu.tar.xz
mkdir aarch64-orangepi
tar -xvf gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu.tar.xz -C aarch64-orangepi/
export PATH=$(pwd)/aarch64-orangepi/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu/bin:$PATH
```
## 设置cmake
```bash
cd ncnn
mkdir build-orangepi/
cd build-orangepi
```
*改一下编译器名称*
```bash
vim ../toolchains/aarch64-linux-gnu.toolchain.cmake
```
```cmake
set(CMAKE_C_COMPILER "aarch64-none-linux-gnu-gcc")
set(CMAKE_CXX_COMPILER "aarch64-none-linux-gnu-g++")
```
*设置cmake*
```bash
cmake -DCMAKE_TOOLCHAIN_FILE=../toolchains/aarch64-linux-gnu.toolchain.cmake -DNCNN_BUILD_TESTS=ON ..
```
![](/images/config-ncnn-cmake.png)
*设置完cmake就可以编译ncnn了*
## 编译ncnn
```bash
make -j8
```
![](/images/compile-ncnn.png)
## 将文件传送到OrangePi 5 Plus开发版
*开发版上是linux系统，这里我使用rsync传送,将my_ip和/path/to/替换成自己的*
```bash
make install
scp duan@my_ip:/path/to/ncnn/build-orangepi/benchmark/benchncnn .
scp duan@my_ip:/path/to/ncnn/benchmark/*.param .
```
# 测试ncnn
### 单元测试
*将build-orangepi、examples和tests目录、run_test.cmake文件上传至开发板*
```bash
mkdir ncnn
cd ncnn
rsync -a -v duan@my_ip:/path/to/ncnn/build-orangepi .
rsync -a -v duan@my_ip:/path/to/ncnn/examples .
rsync -a -v duan@my_ip:/path/to/ncnn/tests .
mkdir cmake
rsync -a -v duan@my_ip:/path/to/ncnn/cmake/run_test.cmake cmake/
```
*修改开发版上的/path/to/ncnn/build-orangepi/tests/CTestfile.cmake文件*
*将/home/orangepi/ncnn/这里更改为开发版上的路径*
```cmake
# CMake generated Testfile for
# Source directory: /home/orangepi/ncnn/tests
# Build directory: /home/orangepi/ncnn/build-orangepi/tests
#
# This file includes the relevant testing commands required for
# testing this directory and lists subdirectories to be tested as well.
add_test(test_mat_pixel_affine "/usr/bin/cmake" "-DTEST_EXECUTABLE=/home/orangepi/ncnn/build-orangepi/tests/test_mat_pixel_affine" "-P" "/home/orangepi/ncnn/tests/../cmake/run_test.cmake")
set_tests_properties(test_mat_pixel_affine PROPERTIES  _BACKTRACE_TRIPLES "/home/orangepi/ncnn/tests/CMakeLists.txt;14;add_test;/home/orangepi/ncnn/tests/CMakeLists.txt;44;ncnn_add_test;/home/orangepi/ncnn/tests/CMakeLists.txt;0;")
add_test(test_mat_pixel_drawing "/usr/bin/cmake" "-DTEST_EXECUTABLE=/home/orangepi/ncnn/build-orangepi/tests/test_mat_pixel_drawing" "-P" "/home/orangepi/ncnn/tests/../cmake/run_test.cmake")
set_tests_properties(test_mat_pixel_drawing PROPERTIES  _BACKTRACE_TRIPLES "/home/orangepi/ncnn/tests/CMakeLists.txt;14;add_test;/home/orangepi/ncnn/tests/CMakeLists.txt;48;ncnn_add_test;/home/orangepi/ncnn/tests/CMakeLists.txt;0;")
add_test(test_mat_pixel_rotate "/usr/bin/cmake" "-DTEST_EXECUTABLE=/home/orangepi/ncnn/build-orangepi/tests/test_mat_pixel_rotate" "-P" "/home/orangepi/ncnn/tests/../cmake/run_test.cmake")
set_tests_properties(test_mat_pixel_rotate PROPERTIES  _BACKTRACE_TRIPLES "/home/orangepi/ncnn/tests/CMakeLists.txt;14;add_test;/home/orangepi/ncnn/tests/CMakeLists.txt;52;ncnn_add_test;/home/orangepi/ncnn/tests/CMakeLists.txt;0;")
```
*运行单元测试*
```bash
ctest
```
![](/images/ncnn-test.png)
### cpu跑分测试
```bash
chmod +x benchncnn
./benchncnn 8 4 2 -1 1
```
*图为OrangePi 5 Plus RK3588平台跑分*
![](/images/ncnn-benchmark-cpu.png)