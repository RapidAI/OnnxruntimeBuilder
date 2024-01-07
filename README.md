# OnnxruntimeBuilder

Onnxruntime Builder

### 简介

编译onnxruntime 动态库和静态库。

- 文件名包含shared代表动态库(windows是onnxruntime.dll，linux是onnxruntime.so，macos是onnxruntime.dylib);
- 文件名包含static代表静态库(***.a);
- 包内添加了简单的cmake，用于cmake系统find_package.
- 仓库的Release的包不支持GPU，仅使用CPU。
- 文件名包含windows，linux，macos，android，代表这4种操作系统平台使用的库;
- 动态库在部署时也必须跟编译出来的可以执行文件一起部署，而静态库编译时会被包含到可执行文件里;
- 静态库部署起来更方便些，但可执行文件体积增大，各有优缺点，按需选择;
- linux版支持不同cpu架构，一般家用pc选择x86_64-linux-musl即可;
- linux版使用musl工具链编译，故最终项目最好也用musl工具链，musl工具链优点是支持静态链接libc，部署时不需要依赖系统的libc库;
- windows版文件名含md代表动态链接crt，文件名含mt代表静态链接crt，静态链接时不需要依赖标准c库，部署时更方便，但文件体积增大;

### windows版本特别说明

v1.6.0以下支持vs2017，从v1.7.0开始在windows环境下仅支持vs2019和vs2022版本。

### 关于OpenMP

- [官方v1.7.0版本说明](https://github.com/microsoft/onnxruntime/releases/tag/v1.7.0)
  Starting from this release, all ONNX Runtime CPU packages are now built without OpenMP.
- 官方仓库Release的从1.7.0开始，所有CPU版的包编译时没有启用OpenMP选项；
- 本仓库的初始版~1.8.0仍然启用了OpenMP选项，即使用本仓库的这些包时，编译环境要求安装OpenMP；
- 从1.9.0开始，本仓库移除OpenMP编译选项，保持与官方一致；

### 关于Windows静态链接CRT

如果使用官方仓库自带python编译脚本，需要添加--enable_msvc_static_runtime
本仓库使用的cmake编译选项添加

```
-DONNX_USE_MSVC_STATIC_RUNTIME=ON
-Dprotobuf_MSVC_STATIC_RUNTIME=ON
-Dgtest_force_shared_crt=OFF
-DCMAKE_MSVC_RUNTIME_LIBRARY="MultiThreaded$<$<CONFIG:Debug>:Debug>"
```

#### 20211011

- 从1.9.0开始，移除OpenMP编译选项，保持与官方一致

#### 20220521

- v1.9.1

#### 20220523

- v1.10.0

#### 20220524

- v1.11.0

#### 20220525

- v1.11.1

#### 20220928

- v1.12.0

#### 20220929

- v1.12.1

#### 20221013

- windows平台，更早版本的包均为md版，从此版增加链接静态CRT版本(mt)
- 后缀md: 无
- 后缀mt: --enable_msvc_static_runtime

#### 20221026

- v1.13.1

#### 20230213

- v1.14.0

#### 20230308

- v1.14.1

#### 20230623

- v1.15.0

#### 20240105

- v1.15.1
- 改用cmake 编译
- 使用musl toolchain编译交叉linux版
- windows版增加vs2022