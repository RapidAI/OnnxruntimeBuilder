:: build onnxruntime 1.11.0 for windows by benjaminwan
@ECHO OFF
chcp 65001
cls
SETLOCAL EnableDelayedExpansion

for /f "Delims=" %%x in (onnxruntime_cmake_options.txt) do set OPTIONS=!OPTIONS!%%x 

call :cmakeParams "Visual Studio 16 2019" "x64" "md"
call :cmakeParams "Visual Studio 16 2019" "x86" "md"
call :cmakeParams "Visual Studio 16 2019" "x64" "mt"
call :cmakeParams "Visual Studio 16 2019" "x86" "mt"
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
if "%~2" == "x86" (
    set MACHINE_FLAG="--x86"
)^
else (
    set MACHINE_FLAG=
)
if "%~3" == "mt" (
    set STATIC_CRT_FLAG="--enable_msvc_static_runtime"
)^
else (
    set STATIC_CRT_FLAG=
)
call build.bat --cmake_generator "%~1" --build_dir "build-%~2-%~3" %MACHINE_FLAG% --update ^
	--cmake_extra_defines CMAKE_INSTALL_PREFIX=./install onnxruntime_BUILD_UNIT_TESTS=OFF ^
    --config Release ^
    %OPTIONS% %STATIC_CRT_FLAG%
pushd "build-%~2-%~3"\Release
call :collectLibs
popd
GOTO:EOF