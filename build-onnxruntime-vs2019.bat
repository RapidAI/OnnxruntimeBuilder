:: build onnxruntime 1.11.0 for windows by benjaminwan
@ECHO OFF
chcp 65001
cls
SETLOCAL EnableDelayedExpansion

for /f "Delims=" %%x in (onnxruntime_cmake_options.txt) do set OPTIONS=!OPTIONS!%%x 

call :cmakeParamsX64 "Visual Studio 16 2019"
call :cmakeParamsX86 "Visual Studio 16 2019"
GOTO:EOF

:getFileName
call set "libs=%%libs%% %~n1"
GOTO:EOF

:getLibsList
set "InFile=onnxruntime.dir\Release\onnxruntime.tlog\link.read.1.tlog"
set "OutFile=libs_list.txt"
set "LikeLine=RELEASE\*.LIB"
powershell -Command "$data = foreach($line in gc %InFile%){ $line.split(" ")} $data | Out-File %OutFile%"
powershell -Command "$data = foreach($line in gc %OutFile%){ if($line -like '*%LikeLine%*') {$line}} $data | Out-File -Encoding ascii %OutFile%"
GOTO:EOF

:collectLibs
cmake --build . --config Release --target install
del /s/q install\*test*.exe
echo set(OnnxRuntime_INCLUDE_DIRS "${CMAKE_CURRENT_LIST_DIR}/include") > install/OnnxRuntimeConfig.cmake
echo include_directories(${OnnxRuntime_INCLUDE_DIRS}) >> install/OnnxRuntimeConfig.cmake
echo link_directories(${CMAKE_CURRENT_LIST_DIR}/lib) >> install/OnnxRuntimeConfig.cmake
echo set(OnnxRuntime_LIBS onnxruntime) >> install/OnnxRuntimeConfig.cmake

mkdir install-static\lib
xcopy install\include install-static\include /s /y /i
call :getLibsList

set libs=
for /f "Delims=" %%a in (libs_list.txt) do (
copy %%a install-static\lib
call :getFileName %%a
)

echo set(OnnxRuntime_INCLUDE_DIRS "${CMAKE_CURRENT_LIST_DIR}/include") > install-static\OnnxRuntimeConfig.cmake
echo include_directories(${OnnxRuntime_INCLUDE_DIRS}) >> install-static\OnnxRuntimeConfig.cmake
echo link_directories(${CMAKE_CURRENT_LIST_DIR}/lib) >> install-static\OnnxRuntimeConfig.cmake
echo set(OnnxRuntime_LIBS %libs%) >> install-static\OnnxRuntimeConfig.cmake
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