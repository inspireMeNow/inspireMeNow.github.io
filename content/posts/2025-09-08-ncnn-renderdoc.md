---
title: 为 NCNN 添加 RenderDoc 支持
ZHtags:
  - fedora
key: fedora
date: '2025-09-08'
lastmod: '2025-09-08'
---
## 平台检测宏定义

```cpp
#define PLATFORM_WINDOWS 0
#define PLATFORM_LINUX   0
#define PLATFORM_APPLE   0
#define PLATFORM_IOS     0
#define PLATFORM_ANDROID 0
```

查阅文档发现各个平台的 RenderDoc 库名称不同，因此需要用宏来检测各个平台，这里我定义了这几个宏，分别代表 Windows、Linux 等

```cpp
#if defined(WIN32) || defined(__WIN32__) || defined(_WIN32) || defined(_MSC_VER)
    #undef  PLATFORM_WINDOWS
    #define PLATFORM_WINDOWS 1

#elif defined(__APPLE__)
    #undef  PLATFORM_APPLE
    #define PLATFORM_APPLE 1
// 其他平台检测
```
Windows 的话，可以通过 `__WIN32__` 或者检测是否有 `MSVC` 就行；Android 用 `__ANDROID__`； Apple 平台用 `__APPLE__`；剩下的识别为 Linux

## RenderDoc API 初始化

```cpp
#define RENDERDOC_API_LATEST RENDERDOC_API_1_6_0
#define eRENDERDOC_API_Version_LATEST eRENDERDOC_API_Version_1_6_0
```
这里定义 LATEST 宏可以方便后续更新 RenderDoc 版本

*Windows 平台*
```cpp
HMODULE mod = GetModuleHandleA("renderdoc.dll")
```
- `GetModuleHandleA()` 获取已加载模块的句柄，不加载新模块
- **这里的话，RenderDoc 必须已经注入进程中，否则会导致 RenderDoc 加载失败**

```cpp
RENDERDOC_GetAPI = (pRENDERDOC_GetAPI)GetProcAddress(mod, "RENDERDOC_GetAPI");
```
- 获取 `RENDERDOC_GetAPI` 函数的地址
- RenderDoc API 的入口函数

*Linux/Android/macOS 平台*
```cpp
void *mod = dlopen("librenderdoc.so", RTLD_NOW | RTLD_LAZY);
```
- `dlopen()` 动态加载共享库
- `RTLD_NOW | RTLD_LAZY` 立即解析符号但延迟绑定

```cpp
RENDERDOC_GetAPI = (pRENDERDOC_GetAPI)dlsym(mod, "RENDERDOC_GetAPI");
```
`dlsym()` 获取符号地址

*API 初始化*
```cpp
if(RENDERDOC_GetAPI)
{
    RENDERDOC_API_LATEST* rdoc_api = NULL;
    int ret = RENDERDOC_GetAPI(eRENDERDOC_API_Version_LATEST, (void **)&rdoc_api);
    if(ret == 1 && rdoc_api) {
        rdoc_api->SetCaptureOptionU32(eRENDERDOC_Option_DebugOutputMute, 0);
        NCNN_LOGE("RenderDoc API initialized successfully");
        return rdoc_api;
    }
}
```

- `RENDERDOC_GetAPI()` 获取 API， 返回 1 表示成功
- `eRENDERDOC_API_Version_LATEST` 是先前定义的宏，代表 API 版本
- `SetCaptureOptionU32(eRENDERDOC_Option_DebugOutputMute, 0)` 启用调试输出

## 捕获控制

```cpp
static void ncnn_vulkan_begin_renderdoc_capture(
    RENDERDOC_API_LATEST* renderdoc_api, VkInstance instance) {
    if (!renderdoc_api) {
        NCNN_LOGE("RenderDoc API is NULL, cannot begin capture");
        return;
    }

    NCNN_LOGE("Starting RenderDoc capture...");
    renderdoc_api->StartFrameCapture(
        RENDERDOC_DEVICEPOINTER_FROM_VKINSTANCE(instance), NULL);
}
```

- `RENDERDOC_DEVICEPOINTER_FROM_VKINSTANCE(instance)` 是一个宏，它可以将 Vulkan 实例转换为 RenderDoc 设备指针
- 第二个参数 `NULL` 表示使用默认窗口，对于计算着色器来说可以为空
- `StartFrameCapture()` 开始捕获

```cpp
static void ncnn_vulkan_end_renderdoc_capture(
    RENDERDOC_API_LATEST* renderdoc_api, VkInstance instance) {
    // ...
    renderdoc_api->EndFrameCapture(
        RENDERDOC_DEVICEPOINTER_FROM_VKINSTANCE(instance), NULL);
}
```
`EndFrameCapture()` 停止捕获

## 配置 RenderDoc

```cpp
static void configure_renderdoc_headless(RENDERDOC_API_LATEST* rdoc_api) {
    if (!rdoc_api) return;

    // 设置捕获选项
    rdoc_api->SetCaptureOptionU32(eRENDERDOC_Option_AllowVSync, 0);
    rdoc_api->SetCaptureOptionU32(eRENDERDOC_Option_AllowFullscreen, 0);
    rdoc_api->SetCaptureOptionU32(eRENDERDOC_Option_APIValidation, 1);
    rdoc_api->SetCaptureOptionU32(eRENDERDOC_Option_CaptureCallstacks, 1);
    rdoc_api->SetCaptureOptionU32(eRENDERDOC_Option_DebugOutputMute, 0);

    // 捕获文件路径
    const char* capture_path = getenv("NCNN_RENDERDOC_CAPTURE_PATH");
    if (!capture_path) {
        capture_path = "./ncnn_capture";
    }
    rdoc_api->SetCaptureFilePathTemplate(capture_path);
}
```
这里我定义了一个`NCNN_RENDERDOC_CAPTURE_PATH` 环境变量用来指定 `rdc` 文件路径，默认在当前文件夹，文件名为 `ncnn_capture.rdc`

## 添加成员
```cpp
class __ncnn_vulkan_instance_holder
{
public:
    // 现有成员
    #if NCNN_ENABLE_RENDERDOC_PROFILING
    RENDERDOC_API_LATEST* renderdoc_api;
    #endif
};
```
在全局 Vulkan 实例中添加 RenderDoc API 指针

## 队列选择

```cpp
static uint32_t find_device_compute_queue(const std::vector<VkQueueFamilyProperties>& queueFamilyProperties, bool prefer_graphics_for_renderdoc = false)
{
    if (prefer_graphics_for_renderdoc) {
        for (uint32_t i = 0; i < queueFamilyProperties.size(); i++)
        {
            const VkQueueFamilyProperties& queueFamilyProperty = queueFamilyProperties[i];

            if ((queueFamilyProperty.queueFlags & VK_QUEUE_COMPUTE_BIT)
                    && (queueFamilyProperty.queueFlags & VK_QUEUE_GRAPHICS_BIT))
            {
                return i;
            }
        }
    }
    // 原有的查找逻辑
```
当 `prefer_graphics_for_renderdoc` 为 true 时，优先寻找同时支持图形和计算的队列，`VK_QUEUE_COMPUTE_BIT` 和 `VK_QUEUE_GRAPHICS_BIT` 都被设置

## 修改 CMakeLists.txt

```cmake
option(NCNN_ENABLE_RENDERDOC_PROFILING "Enables profiling with the RenderDoc tool." OFF)

if(NCNN_ENABLE_RENDERDOC_PROFILING)
    add_definitions(-DNCNN_ENABLE_RENDERDOC_PROFILING=1)
endif()
```

添加 CMake 构建选项，可以通过 `-DNCNN_ENABLE_RENDERDOC_PROFILING=ON` 启用 RenderDoc 支持

## 公共 API

```cpp
#if NCNN_ENABLE_RENDERDOC_PROFILING
void start_renderdoc_capture() {
    if (g_instance.renderdoc_api && g_instance.instance) {
        configure_renderdoc_headless(g_instance.renderdoc_api);
        ncnn_vulkan_begin_renderdoc_capture(g_instance.renderdoc_api, g_instance.instance);
    }
}

void end_renderdoc_capture() {
    if (g_instance.renderdoc_api && g_instance.instance) {
        ncnn_vulkan_end_renderdoc_capture(g_instance.renderdoc_api, g_instance.instance);
    }
}
#endif
```
用户需要捕获调用细节时直接使用这两个函数就行了

## 构建
这里需要启用 NCNN_VULKAN 并关掉 NCNN_SIMPLEVK，这样 validation layer 才会生效
```
mkdir -p build
cd build
cmake -DNCNN_VULKAN=ON -DNCNN_SIMPLEVK=OFF -DNCNN_ENABLE_RENDERDOC_PROFILING=ON ..
make -j$(nproc)
```
## 使用
在程序中添加捕获调用
```cpp
int main()
{
    // 开始RenderDoc捕获
    ncnn::start_renderdoc_capture();

    // ... 推理操作 ...

    // 结束RenderDoc捕获
    ncnn::end_renderdoc_capture();
    return 0;
}
```
捕获 GPU 操作
```bash
NCNN_RENDERDOC_CAPTURE_PATH="/path/to/capture_file" renderdoccmd capture your_ncnn_application
```

~~我已经在benchncnn中添加了 RenderDoc 支持，跑个 benchmark 看看~~
```bash
$ renderdoccmd capture ./benchncnn 8 4 0 0 1
Launching './benchncnn' with params: 8 4 0 0 1
Launched as ID 38920
RenderDoc API initialized successfully
validation layer: linux_read_sorted_physical_devices:
validation layer:      Original order:
validation layer:            [0] llvmpipe (LLVM 20.1.8, 256 bits)
validation layer:            [1] Intel(R) Iris(R) Xe Graphics (TGL GT2)
validation layer:      Sorted order:
validation layer:            [0] Intel(R) Iris(R) Xe Graphics (TGL GT2)
validation layer:            [1] llvmpipe (LLVM 20.1.8, 256 bits)
validation layer: Copying old device 0 into new device 0
validation layer: Copying old device 1 into new device 1
validation layer: linux_read_sorted_physical_devices:
validation layer:      Original order:
validation layer:            [0] llvmpipe (LLVM 20.1.8, 256 bits)
validation layer:            [1] Intel(R) Iris(R) Xe Graphics (TGL GT2)
validation layer:      Sorted order:
validation layer:            [0] Intel(R) Iris(R) Xe Graphics (TGL GT2)
validation layer:            [1] llvmpipe (LLVM 20.1.8, 256 bits)
validation layer: Copying old device 0 into new device 0
validation layer: Copying old device 1 into new device 1
validation layer: linux_read_sorted_physical_devices:
validation layer:      Original order:
validation layer:            [0] llvmpipe (LLVM 20.1.8, 256 bits)
validation layer:            [1] Intel(R) Iris(R) Xe Graphics (TGL GT2)
validation layer:      Sorted order:
validation layer:            [0] Intel(R) Iris(R) Xe Graphics (TGL GT2)
validation layer:            [1] llvmpipe (LLVM 20.1.8, 256 bits)
validation layer: Copying old device 0 into new device 0
validation layer: Copying old device 1 into new device 1
validation layer: linux_read_sorted_physical_devices:
validation layer:      Original order:
validation layer:            [0] llvmpipe (LLVM 20.1.8, 256 bits)
validation layer:            [1] Intel(R) Iris(R) Xe Graphics (TGL GT2)
validation layer:      Sorted order:
validation layer:            [0] Intel(R) Iris(R) Xe Graphics (TGL GT2)
validation layer:            [1] llvmpipe (LLVM 20.1.8, 256 bits)
validation layer: Copying old device 0 into new device 0
validation layer: Copying old device 1 into new device 1
validation layer: Removing driver /usr/lib64/libvulkan_asahi.so due to not having any physical devices
validation layer: Removing driver /usr/lib64/libvulkan_virtio.so due to not having any physical devices
validation layer: Removing driver /usr/lib64/libvulkan_radeon.so due to not having any physical devices
validation layer: Removing driver /usr/lib64/libvulkan_powervr_mesa.so due to not having any physical devices
validation layer: Removing driver /usr/lib64/libvulkan_panfrost.so due to not having any physical devices
validation layer: Removing driver /usr/lib64/libvulkan_nouveau.so due to not having any physical devices
validation layer: Removing driver /usr/lib64/libvulkan_intel_hasvk.so due to not having any physical devices
validation layer: Removing driver /usr/lib64/libvulkan_freedreno.so due to not having any physical devices
validation layer: Removing driver /usr/lib64/libvulkan_broadcom.so due to not having any physical devices
[0 Intel(R) Iris(R) Xe Graphics (TGL GT2)]  queueC=0[1]  queueT=0[1]
[0 Intel(R) Iris(R) Xe Graphics (TGL GT2)]  fp16-p/s/u/a=1/1/1/1  int8-p/s/u/a=1/1/1/1
[0 Intel(R) Iris(R) Xe Graphics (TGL GT2)]  subgroup=32(8~32)  ops=1/1/1/1/1/1/1/1/1/1
[0 Intel(R) Iris(R) Xe Graphics (TGL GT2)]  fp16-cm=0  int8-cm=0  bf16-cm=0  fp8-cm=0
[1 llvmpipe (LLVM 20.1.8, 256 bits)]  queueC=0[1]  queueT=0[1]
[1 llvmpipe (LLVM 20.1.8, 256 bits)]  fp16-p/s/u/a=1/1/1/1  int8-p/s/u/a=1/1/1/1
[1 llvmpipe (LLVM 20.1.8, 256 bits)]  subgroup=8(8~8)  ops=1/1/1/1/1/1/1/1/1/1
[1 llvmpipe (LLVM 20.1.8, 256 bits)]  fp16-cm=0  int8-cm=0  bf16-cm=0  fp8-cm=0
validation layer: Inserted device layer "VK_LAYER_KHRONOS_validation" (libVkLayer_khronos_validation.so)
validation layer: Inserted device layer "VK_LAYER_RENDERDOC_Capture" (/usr/lib64/renderdoc/librenderdoc.so)
validation layer: vkCreateDevice layer callstack setup to:
validation layer:    <Application>
validation layer:      ||
validation layer:    <Loader>
validation layer:      ||
validation layer:    VK_LAYER_RENDERDOC_Capture
validation layer:            Type: Implicit
validation layer:            Enabled By: Implicit Layer
validation layer:                Disable Env Var:  DISABLE_VULKAN_RENDERDOC_CAPTURE_1_39
validation layer:            Manifest: /usr/share/vulkan/implicit_layer.d/renderdoc_capture.json
validation layer:            Library:  /usr/lib64/renderdoc/librenderdoc.so
validation layer:      ||
validation layer:    VK_LAYER_KHRONOS_validation
validation layer:            Type: Explicit
validation layer:            Enabled By: By the Application
validation layer:            Manifest: /usr/share/vulkan/explicit_layer.d/VkLayer_khronos_validation.json
validation layer:            Library:  libVkLayer_khronos_validation.so
validation layer:      ||
validation layer:    <Device>
validation layer:        Using "Intel(R) Iris(R) Xe Graphics (TGL GT2)" with driver: "/usr/lib64/libvulkan_intel.so"
Starting RenderDoc capture...
loop_count = 8
num_threads = 4
powersave = 0
gpu_device = 0
cooling_down = 1
fopen squeezenet.param failed
network graph not ready
          squeezenet  min =    0.00  max =    0.00  avg =    0.00
           mobilenet  min =   18.00  max =   19.46  avg =   19.02
        mobilenet_v2  min =   17.87  max =   19.36  avg =   18.76
        mobilenet_v3  min =   20.07  max =   24.74  avg =   21.90
fopen shufflenet.param failed
network graph not ready
          shufflenet  min =    0.00  max =    0.00  avg =    0.00
fopen shufflenet_v2.param failed
network graph not ready
       shufflenet_v2  min =    0.00  max =    0.00  avg =    0.00
             mnasnet  min =   18.63  max =   24.55  avg =   20.79
     proxylessnasnet  min =   21.37  max =   27.65  avg =   24.58
     efficientnet_b0  min =   23.01  max =   23.75  avg =   23.36
   efficientnetv2_b0  min =  172.44  max =  260.64  avg =  188.77
        regnety_400m  min =   25.58  max =   27.10  avg =   26.13
           blazeface  min =   11.35  max =   11.62  avg =   11.44
           googlenet  min =   38.80  max =   43.13  avg =   40.21
fopen resnet18.param failed
network graph not ready
            resnet18  min =    0.00  max =    0.00  avg =    0.00
             alexnet  min =   39.59  max =   46.78  avg =   43.20
fopen vgg16.param failed
network graph not ready
               vgg16  min =    0.00  max =    0.00  avg =    0.00
fopen resnet50.param failed
network graph not ready
            resnet50  min =    0.00  max =    0.00  avg =    0.00
fopen squeezenet_ssd.param failed
network graph not ready
      squeezenet_ssd  min =    0.00  max =    0.00  avg =    0.00
       mobilenet_ssd  min =   24.16  max =   29.74  avg =   26.34
      mobilenet_yolo  min =   26.62  max =   32.16  avg =   29.69
  mobilenetv2_yolov3  min =   21.91  max =   25.67  avg =   23.68
fopen yolov4-tiny.param failed
network graph not ready
         yolov4-tiny  min =    0.00  max =    0.00  avg =    0.00
           nanodet_m  min =   45.24  max =   51.48  avg =   49.53
fopen yolo-fastest-1.1.param failed
network graph not ready
    yolo-fastest-1.1  min =    0.00  max =    0.00  avg =    0.00
fopen yolo-fastestv2.param failed
network graph not ready
      yolo-fastestv2  min =    0.00  max =    0.00  avg =    0.00
fopen vision_transformer.param failed
network graph not ready
  vision_transformer  min =    0.00  max =    0.00  avg =    0.00
          FastestDet  min =   15.22  max =   18.05  avg =   16.52
Ending RenderDoc capture...
```
使用 RenderDoc GUI 分析 rdc 文件
![](/images/renderdoc-capture.png)

## 参考
- [RenderDoc API文档](https://renderdoc.org/docs/in_application_api.html)
