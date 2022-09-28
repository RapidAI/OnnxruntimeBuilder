# OnnxruntimeBuilder

Onnxruntime Builder

### 简介

编译onnxruntime 动态库和静态库。

动态库: onnxruntime-版本号-编译环境-shared.7z

静态库: onnxruntime-版本号-编译环境-static.7z

包内添加了简单的cmake，用于cmake系统find_package.

仓库的Release的包不支持GPU，仅使用CPU。

### windows版本特别说明
虽然v1.6.0支持vs2017，但是因为v1.7.0在vs2017下编译出错，所以windows环境下就仅保留了vs2019版本。

### 关于OpenMP
[官方v1.7.0版本说明](https://github.com/microsoft/onnxruntime/releases/tag/v1.7.0)

Starting from this release, all ONNX Runtime CPU packages are now built without OpenMP.

从1.7.0开始，官方Release的所有CPU版的包编译时没有启用OpenMP选项。

但是本仓库的编译脚本仍然启用了OpenMP选项，即使用本仓库的包时，编译环境要求安装OpenMP。

这是与官方Release不同的地方，敬请注意!

#### 20211011
从1.9.0开始，移除OpenMP编译选项，保持与官方一致

#### 20220521
1.9.1

#### 20220523
1.10.0

#### 20220524
1.11.0

#### 20220525
1.11.1

#### 20220928
1.12.0