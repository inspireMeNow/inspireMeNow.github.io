---
title: 在骁龙765平台上运行ncnn并测试
ZHtags: 
  - ncnn
key: ncnn
date: '2024-07-02'
lastmod: '2024-07-02'
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
## 设置Android NDK
```bash
cd ..
wget https://dl.google.com/android/repository/android-ndk-r26d-linux.zip
mkdir android-ndk
unzip android-ndk-r26d-linux.zip -d android-ndk/
export ANDROID_NDK=$(pwd)/android-ndk/android-ndk-r26d
```
*可选：去除debug标志*
```bash
vim $ANDROID_NDK/build/cmake/android-legacy.toolchain.cmak
```
*去掉这里的-g参数即可*
```cmake
list(APPEND ANDROID_COMPILER_FLAGS
  -g
  -DANDROID
```
## 设置cmake
*如果你的cmake版本大于等于3.21，ndk版本为r23或更高，可添加-DANDROID_USE_LEGACY_TOOLCHAIN_FILE=False选项以启用优化*
```bash
mkdir -p build-android
cd build-android

cmake -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake"\
    -DANDROID_ABI="arm64-v8a" \
    -DANDROID_PLATFORM=android-21 -DNCNN_VULKAN=ON \
    -DANDROID_USE_LEGACY_TOOLCHAIN_FILE=False ..
```
![](/images/config-ncnn-cmake-android.png)
*设置完cmake就可以编译ncnn了*
## 编译ncnn
```bash
make -j$(nproc)
make install
```
![](/images/compile-ncnn-android.png)
# 测试ncnn
## 将文件传送到手机
*这里我使用Pixel 4a 5g手机进行测试*
```bash
adb push build-android/benchmark/benchncnn /data/local/tmp/
adb push ../benchmark/*.param /data/local/tmp/
````
### cpu跑分测试
*SM7250平台*
```bash
chmod +x benchncnn
./benchncnn 8 4 2 -1 1
```
![](/images/ncnn-benchmark-android-cpu.png)
### gpu跑分测试
*Adreno 620平台*
```bash
./benchncnn 8 4 2 0 1
```
![](/images/ncnn-benchmark-android-gpu.png)
*看起来cpu性能和gpu差的有点多..*