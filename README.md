# OnnxruntimeBuilder

Onnxruntime Builder

### 简介

编译onnxruntime 动态库和静态库。

动态库: onnxruntime-版本号-编译环境-shared.7z

静态库: onnxruntime-版本号-编译环境-static.7z

包内添加了简单的cmake，用于cmake系统find_package.

### windows版本说明
虽然v1.6.0支持vs2017，但是因为v1.7.0在vs2017下编译出错，所以windows环境下就仅保留了vs2019版本。