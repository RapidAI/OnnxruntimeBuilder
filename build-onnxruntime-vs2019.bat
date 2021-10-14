:: build onnxruntime for windows by benjaminwan
@ECHO OFF
chcp 65001
cls
SETLOCAL EnableDelayedExpansion

for /f "Delims=" %%x in (onnxruntime_cmake_options.txt) do set OPTIONS=!OPTIONS!%%x 

call :cmakeParamsX64 "Visual Studio 16 2019"
call :cmakeParamsX86 "Visual Studio 16 2019"
GOTO:EOF

:collectLibs
cmake --build . --config Release --target install
del /s/q install\*test*.exe
mkdir install-static\lib
xcopy install\include install-static\include /s /y /i
copy Release\onnxruntime_session.lib install-static\lib
copy Release\onnxruntime_optimizer.lib install-static\lib
copy Release\onnxruntime_providers.lib install-static\lib
copy Release\onnxruntime_util.lib install-static\lib
copy Release\onnxruntime_framework.lib install-static\lib
copy Release\onnxruntime_graph.lib install-static\lib
copy Release\onnxruntime_common.lib install-static\lib
copy Release\onnxruntime_mlas.lib install-static\lib
copy Release\onnxruntime_flatbuffers.lib install-static\lib
copy external\onnx\Release\onnx.lib install-static\lib
copy external\onnx\Release\onnx_proto.lib install-static\lib
copy external\protobuf\cmake\Release\libprotobuf-lite.lib install-static\lib
copy external\re2\Release\re2.lib install-static\lib
copy external\flatbuffers\Release\flatbuffers.lib install-static\lib
copy external\pytorch_cpuinfo\Release\cpuinfo.lib install-static\lib
copy external\pytorch_cpuinfo\deps\clog\Release\clog.lib install-static\lib
GOTO:EOF

:cmakeParamsX64
call build.bat --cmake_generator "%~1" --build_dir build-x64 --update ^
	--cmake_extra_defines CMAKE_INSTALL_PREFIX=./install onnxruntime_BUILD_UNIT_TESTS=OFF ^
    --config Release ^
    %OPTIONS%
pushd build-x64\Release
call :collectLibs
popd
GOTO:EOF

:cmakeParamsX86
call build.bat --cmake_generator "%~1" --build_dir build-x86 --x86 --update ^
	--cmake_extra_defines CMAKE_INSTALL_PREFIX=./install onnxruntime_BUILD_UNIT_TESTS=OFF ^
    --config Release ^
    %OPTIONS%
pushd build-x86\Release
call :collectLibs
popd
GOTO:EOF