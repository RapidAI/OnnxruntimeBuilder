:: build onnxruntime for windows by benjaminwan
@ECHO OFF
chcp 65001
cls
SETLOCAL EnableDelayedExpansion

IF "%1"=="" (
    echo input VS_VER none, use v142
	set VS_VER="v142"
)^
ELSE (
	echo input VS_VER:%1
    set VS_VER="%1"
)

IF "%2"=="" (
    echo input CRT none, use mt
	set CRT="mt"
)^
ELSE (
	echo input CRT:%2
    set CRT="%2"
)

for /f "Delims=" %%x in (onnxruntime_cmake_options.txt) do set OPTIONS=!OPTIONS!%%x

call :cmakeParams "x64" %VS_VER% %CRT%
call :cmakeParams "Win32" %VS_VER% %CRT%
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

:cmakeParams
mkdir "build-%~1-%~2-%~3"
pushd "build-%~1-%~2-%~3"
if "%~3" == "md" (
    set STATIC_CRT_ENABLED="OFF"
	set STATIC_CRT_DISABLED="ON"
	set STATIC_CRT_LIBRARY="MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
)^
else (
    set STATIC_CRT_ENABLED="ON"
	set STATIC_CRT_DISABLED="OFF"
	set STATIC_CRT_LIBRARY="MultiThreaded$<$<CONFIG:Debug>:Debug>"
)

cmake -A "%~1" -T "%~2,host=x64" -DCMAKE_INSTALL_PREFIX=install ^
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_CONFIGURATION_TYPES=Release ^
  %OPTIONS% ^
  -DONNX_USE_MSVC_STATIC_RUNTIME=%STATIC_CRT_ENABLED% ^
  -Dprotobuf_MSVC_STATIC_RUNTIME=%STATIC_CRT_ENABLED% ^
  -Dgtest_force_shared_crt=%STATIC_CRT_DISABLED% ^
  -DCMAKE_MSVC_RUNTIME_LIBRARY=%STATIC_CRT_LIBRARY% ^
  ../cmake
cmake --build . --config Release -j %NUMBER_OF_PROCESSORS%
cmake --build . --config Release --target install
call :collectLibs
popd
GOTO:EOF