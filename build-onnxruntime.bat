:: build onnxruntime for windows by benjaminwan
:: x64 build_java, x86 Java is currently not supported on 32-bit x86 architecture
:: use in powershell
:: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
:: & 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Launch-VsDevShell.ps1' -SkipAutomaticLocation -HostArch amd64 -Arch amd64
@ECHO OFF
chcp 65001
cls
SETLOCAL EnableDelayedExpansion

IF "%1"=="" (
    ECHO input VS_VER none, use v143
    set VS_VER="v143"
) ^
ELSE (
    ECHO input VS_VER:%1
    set VS_VER="%1"
)

IF "%2"=="" (
    ECHO input CRT none, use mt
    set CRT="mt"
) ^
ELSE (
    ECHO input CRT:%2
    set CRT="%2"
)

call :cmakeParams "x64" %VS_VER% %CRT%
::call :cmakeParams "Win32" %VS_VER% %CRT%
GOTO:EOF

:getFileName
call set "libs=%%libs%% %~n1"
GOTO:EOF

:getFullPathAndName
call set "libs=%%libs%% %~1"
GOTO:EOF

:check_libexe_exists
::powershell -Command "if(Get-Command lib.exe -errorAction SilentlyContinue) {'true'} else {'false'}"
set pscmdline='powershell -Command "if(Get-Command lib.exe -errorAction SilentlyContinue) {'true'} else {'false'}"'
for /f %%a in (%pscmdline%) do (
    set libexe_exists=%%a
)
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
::del /s/q install\*test*.exe
copy install\include\onnxruntime\* install\include
rd /S /Q install\include\onnxruntime
ECHO set(OnnxRuntime_INCLUDE_DIRS "${CMAKE_CURRENT_LIST_DIR}/include") > install/OnnxRuntimeConfig.cmake
ECHO include_directories(${OnnxRuntime_INCLUDE_DIRS}) >> install/OnnxRuntimeConfig.cmake
ECHO link_directories(${CMAKE_CURRENT_LIST_DIR}/lib) >> install/OnnxRuntimeConfig.cmake
ECHO set(OnnxRuntime_LIBS onnxruntime) >> install/OnnxRuntimeConfig.cmake

mkdir install-static\lib
xcopy install\include install-static\include /s /y /i
call :getLibsList

call :check_libexe_exists

IF "%libexe_exists%" == "true" (
    ECHO "libexe_exists=%libexe_exists%"
    set libs=
    for /f "Delims=" %%a in (libs_list.txt) do (
        call :getFullPathAndName %%a
    )
) ELSE (
    ECHO "libexe_exists=%libexe_exists%"
    set libs=
    for /f "Delims=" %%a in (libs_list.txt) do (
        copy %%a install-static\lib
        call :getFileName %%a
    )
)

copy onnxruntime.dir\Release\onnxruntime.tlog\link.read.1.tlog install-static\link.log
ECHO set(OnnxRuntime_INCLUDE_DIRS "${CMAKE_CURRENT_LIST_DIR}/include")>install-static\OnnxRuntimeConfig.cmake
ECHO include_directories(${OnnxRuntime_INCLUDE_DIRS})>>install-static\OnnxRuntimeConfig.cmake
ECHO link_directories(${CMAKE_CURRENT_LIST_DIR}/lib)>>install-static\OnnxRuntimeConfig.cmake

IF "%libexe_exists%" == "true" (
ECHO set(OnnxRuntime_LIBS onnxruntime.lib)>>install-static\OnnxRuntimeConfig.cmake
) ELSE (
ECHO set(OnnxRuntime_LIBS %libs%)>>install-static\OnnxRuntimeConfig.cmake
)

::IF "%libexe_exists%" == "true" (
::    lib.exe /OUT:install-static\lib\onnxruntime.lib %libs%
::)

GOTO:EOF

:cmakeParams
if "%~1" == "Win32" (
    set MACHINE_FLAG="--x86"
)^
else (
    set MACHINE_FLAG="--build_java"
)
IF "%~2" == "v142" (
    set VS_FLAG=--cmake_generator "Visual Studio 16 2019"
) ^
ELSE (
    set VS_FLAG=--cmake_generator "Visual Studio 17 2022"
)
IF "%~3" == "mt" (
    set STATIC_CRT_FLAG="--enable_msvc_static_runtime"
) ^
ELSE (
    set STATIC_CRT_FLAG=
)
python %~dp0\tools\ci_build\build.py --build_dir %~dp0\build-%~1-%~2-%~3 ^
    --config Release ^
	--parallel ^
	--skip_tests ^
	--build_shared_lib ^
	%MACHINE_FLAG% ^
	%VS_FLAG% ^
	%STATIC_CRT_FLAG% ^
	--cmake_extra_defines CMAKE_INSTALL_PREFIX=./install onnxruntime_BUILD_UNIT_TESTS=OFF
pushd "build-%~1-%~2-%~3"\Release
cmake --build . --config Release -j %NUMBER_OF_PROCESSORS%
call :collectLibs
popd
GOTO:EOF