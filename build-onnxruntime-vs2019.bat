:: build opencv 4.5.x for windows by benjaminwan
@ECHO OFF
chcp 65001
cls
SETLOCAL EnableDelayedExpansion

for /f "Delims=" %%x in (onnxruntime_cmake_options.txt) do set OPTIONS=!OPTIONS!%%x 

call :cmakeParamsX64 "Visual Studio 16 2019"
call :cmakeParamsX86 "Visual Studio 16 2019"
::call :cmakeParamsX64 "Visual Studio 15 2017"
GOTO:EOF

:collectLibs
cmake --build . --config Release --target install
del /s/q install\*test*.exe
mkdir -p install-static\lib
xcopy install\include install-static\include /s /y /i
copy RELEASE\ONNXRUNTIME_SESSION.LIB install-static\lib
copy RELEASE\ONNXRUNTIME_OPTIMIZER.LIB install-static\lib
copy RELEASE\ONNXRUNTIME_PROVIDERS.LIB install-static\lib
copy RELEASE\ONNXRUNTIME_UTIL.LIB install-static\lib
copy RELEASE\ONNXRUNTIME_FRAMEWORK.LIB install-static\lib
copy RELEASE\ONNXRUNTIME_GRAPH.LIB install-static\lib
copy RELEASE\ONNXRUNTIME_COMMON.LIB install-static\lib
copy RELEASE\ONNXRUNTIME_MLAS.LIB install-static\lib
copy RELEASE\ONNXRUNTIME_FLATBUFFERS.LIB install-static\lib
copy EXTERNAL\ONNX\RELEASE\ONNX.LIB install-static\lib
copy EXTERNAL\ONNX\RELEASE\ONNX_PROTO.LIB install-static\lib
copy "EXTERNAL\PROTOBUF\CMAKE\RELEASE\LIBPROTOBUF-LITE.LIB" install-static\lib
copy EXTERNAL\RE2\RELEASE\RE2.LIB install-static\lib
copy EXTERNAL\FLATBUFFERS\RELEASE\FLATBUFFERS.LIB install-static\lib
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