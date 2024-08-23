# OnnxruntimeBuilder

### 简介

编译onnxruntime 动态库和静态库。

- 仓库的Release的包不支持GPU，仅使用CPU;
- 文件名包含shared代表动态库(windows是.dll，linux是.so，macos是.dylib);
- 文件名包含static代表静态库(***.a);
- 文件名包含windows，linux，macos，android，代表这4种操作系统平台使用的库;
- 文件名包含musl，使用musl工具链交叉编译;

### windows版本说明

- windows版文件名含md代表动态链接crt，文件名含mt代表静态链接crt，静态链接时不需要依赖标准c库，部署时更方便，但文件体积增大;
- 最好选择与你的vs版本一致的库;

### 关于老版本Linux系统
- 随着onnxruntime不断更新和升级，对gcc版本要求越来越高，对应的glibc版本要求也越来越高。
- 如果想在老系统如centos7或ubuntu14上使用，请下载v1.6.0版本的库。
- 需要注意的是gcc4不支持avx512指令集，性能可能受到一些影响。

### ubuntu CPU架构支持信息

| CPU架构   | 备注               |
|---------|------------------|
| amd64   | x86_64 一般家用PC    |
| arm     | arm/v7 armhf     |
| arm64   | arm64/v8 aarch64 |
| ppc64le | Power PC 64 LE   |

### ubuntu版本说明

| 操作系统         | gcc版本  | libc版本 | binutils版本 | 
|--------------|--------|--------|------------|
| ubuntu 14.04 | 4.8.4  | 2.19   | 2.24       |
| ubuntu 16.04 | 5.4.0  | 2.23   | 2.26.1     |
| ubuntu 18.04 | 7.5.0  | 2.27   | 2.30       |
| ubuntu 20.04 | 9.4.0  | 2.31   | 2.34       |
| ubuntu 22.04 | 11.4.0 | 2.35   | 2.38       |

- 最好选择与你的gcc一致的版本;
- 低版本gcc使用高版本工具编译出来的库会出错;
- onnxruntime 1.17.0以上 在ubuntu 20.04 arm64无法支持，编译出错信息:The compiler doesn't support BFLOAT16

### musl版本说明

- 必须选择一致的工具链版本来编译bin文件;
- 工具链可以从此处获得https://github.com/benjaminwan/musl-cross-builder

### 如果7z包解压出错
- 需要安装最新版的7zip工具，https://www.7-zip.org/download.html

### 关于OpenMP

- [官方v1.7.0版本说明](https://github.com/microsoft/onnxruntime/releases/tag/v1.7.0)
  Starting from this release, all ONNX Runtime CPU packages are now built without OpenMP.
- 官方仓库Release的从1.7.0开始，所有CPU版的包编译时没有启用OpenMP选项；
- 本仓库重新编译的v1.6.0没有启用OpenMP选项；
- 本仓库的初始版~1.8.0仍然启用了OpenMP选项，即使用本仓库的这些包时，编译环境要求安装OpenMP；