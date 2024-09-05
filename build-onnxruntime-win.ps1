<#
.SYNOPSIS build onnxruntime for windows by benjaminwan
.DESCRIPTION
This is a powershell script for builid onnxruntime in windows.
Put this script to onnxruntime root path, and then run .\build-onnxruntime.ps1
attentions:
  1) Set ExecutionPolicy before run this script: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  2) Setup Developer PowerShell: & 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Launch-VsDevShell.ps1' -SkipAutomaticLocation -HostArch amd64 -Arch amd64
  3) x86 Java is currently not supported on 32-bit x86 architecture
  4) onnxruntime v1.18 is only support VS2022(v143)

.PARAMETER VsArch 
By default, we run this script on 64 bits Windows, this param is always x64.
Other options are for cross-compiling.
  a) .\build-onnxruntime.ps1 -VsArch x64
  b) .\build-onnxruntime.ps1 -VsArch x86
  c) .\build-onnxruntime.ps1 -VsArch arm64
  d) .\build-onnxruntime.ps1 -VsArch arm64ec
.PARAMETER VsVer
By default, this param of onnxruntime v1.18 is always v143
  a) .\build-onnxruntime.ps1 -VsVer v140 = VS2015
  b) .\build-onnxruntime.ps1 -VsVer v141 = VS2017
  c) .\build-onnxruntime.ps1 -VsVer v142 = VS2019
  d) .\build-onnxruntime.ps1 -VsVer v143 = VS2022
.PARAMETER VsCRT
  a) .\build-onnxruntime.ps1 -VsCRT md
  b) .\build-onnxruntime.ps1 -VsCRT mt
.PARAMETER BuildJava
By default, this param is set to False.
.\build-onnxruntime.ps1 -BuildJava
.PARAMETER BuildType
  a) .\build-onnxruntime.ps1 -BuildType Release
  b) .\build-onnxruntime.ps1 -BuildType Debug
  c) .\build-onnxruntime.ps1 -BuildType MinSizeRel
  d) .\build-onnxruntime.ps1 -BuildType RelWithDebInfo
#>

param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('x64', 'x86', 'arm64', 'arm64ec')]
    [string] $VsArch = "x64",

    [Parameter(Mandatory = $false)]
    [ValidateSet('v140', 'v141', 'v142', 'v143')]
    [string] $VsVer = 'v143',

    [Parameter(Mandatory = $false)]
    [ValidateSet('mt', 'md')]
    [string] $VsCRT = 'md',

    [Parameter(Mandatory = $false)]
    [switch] $BuildJava = $false,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Release', 'Debug', 'MinSizeRel', 'RelWithDebInfo')]
    [string] $BuildType = 'Release'
)


# 返回文件的名称
function GetFileName
{
    param ([string]$filePath)
    return [System.IO.Path]::GetFileName($filePath)
}

#调用这个函数来检查 lib.exe 是否存在
function CheckLibexeExists
{
    if (Get-Command lib.exe -errorAction SilentlyContinue)
    {
        return $True
    }
    else
    {
        return $False
    }
}

function GetLibsList
{
    $InFile = "onnxruntime.dir\Release\onnxruntime.tlog\link.read.1.tlog"
    $OutFile = "install-static\libs_list.txt"
    $LikeLine = "RELEASE\*.LIB"

    $data = Get-Content $InFile | ForEach-Object { $_.split(" ") }
    $data | Out-File $OutFile

    $data = Get-Content $OutFile | Where-Object { $_ -like "*$LikeLine*" }
    $data | Out-File -Encoding ascii $OutFile
}

function CollectLibs
{
    # 删除 install 目录下所有以 *test*.exe 结尾的文件
    Remove-Item -Path "install\*test*.exe" -Force -Recurse

    # 复制 install\include\onnxruntime 目录下的所有文件到 install\include
    Copy-Item -Path "install\include\onnxruntime\*" -Destination "install\include" -Force -Recurse

    # 删除 install\include\onnxruntime 目录
    Remove-Item -Path "install\include\onnxruntime" -Force -Recurse

    # 创建 install/OnnxRuntimeConfig.cmake 文件，并写入相关内容
    Set-Content -Path "install/OnnxRuntimeConfig.cmake" -Value "set(OnnxRuntime_INCLUDE_DIRS `${CMAKE_CURRENT_LIST_DIR}/include`)"
    Add-Content -Path "install/OnnxRuntimeConfig.cmake" -Value "include_directories(${OnnxRuntime_INCLUDE_DIRS})"
    Add-Content -Path "install/OnnxRuntimeConfig.cmake" -Value "link_directories(`${CMAKE_CURRENT_LIST_DIR}/lib`)"
    Add-Content -Path "install/OnnxRuntimeConfig.cmake" -Value "set(OnnxRuntime_LIBS onnxruntime)"

    # 创建 install-static\lib 目录
    if (Test-Path -Path "install-static\lib")
    {
        Remove-Item -Path "install-static\lib" -Force -Recurse
    }
    New-Item -Path "install-static\lib" -ItemType Directory

    # 复制 install\include 目录下的所有文件到 install-static\include
    if (Test-Path -Path "install-static\include")
    {
        Remove-Item -Path "install-static\include" -Force -Recurse
    }
    Copy-Item -Path "install\include" -Destination "install-static\include" -Recurse

    # 调用 GetLibsList 函数
    GetLibsList

    # 调用 CheckLibexeExists 函数
    $LibexeExists = CheckLibexeExists

    # 根据 lib exe 是否存在执行不同的操作
    if ($LibexeExists)
    {
        $libs = @()
        Get-Content -Path "install-static\libs_list.txt" | ForEach-Object {
            $libs += $_
        }
    }
    else
    {
        $libs = @()
        Get-Content -Path "install-static\libs_list.txt" | ForEach-Object {
            Copy-Item $_ "install-static\lib"
            $fileName = GetFileName $_
            $libs += "$fileName"
        }
    }

    # 复制 onnxruntime.dir\Release\onnxruntime.tlog\link.read.1.tlog 文件到 install-static\link.log
    Copy-Item -Path "onnxruntime.dir\Release\onnxruntime.tlog\link.read.1.tlog" -Destination "install-static\link.log"

    # 创建 install-static\OnnxRuntimeConfig.cmake 文件，并写入相关内容
    Set-Content -Path "install-static\OnnxRuntimeConfig.cmake" -Value "set(OnnxRuntime_INCLUDE_DIRS `${CMAKE_CURRENT_LIST_DIR}/include`)"
    Add-Content -Path "install-static\OnnxRuntimeConfig.cmake" -Value "include_directories(${OnnxRuntime_INCLUDE_DIRS})"
    Add-Content -Path "install-static\OnnxRuntimeConfig.cmake" -Value "link_directories(`${CMAKE_CURRENT_LIST_DIR}/lib`)"

    # 根据 lib exe 是否存在写入不同的 OnnxRuntime_LIBS 值, 如果 lib exe 存在，使用 lib.exe 工具生成 onnxruntime.lib 文件
    if ($LibexeExists)
    {
        Add-Content -Path "install-static\OnnxRuntimeConfig.cmake" -Value "set(OnnxRuntime_LIBS onnxruntime.lib)"
        lib.exe /OUT:"install-static\lib\onnxruntime.lib" $libs
    }
    else
    {
        Add-Content -Path "install-static\OnnxRuntimeConfig.cmake" -Value "set(OnnxRuntime_LIBS $libs)"
    }
}


#Set-PSDebug -Trace 1
Set-PSDebug -Trace 0

# 清屏
Clear-Host

Write-Host "Params: VsArch=$VsArch VsVer=$VsVer VsCRT=$VsCRT BuildJava=$BuildJava BuildType=$BuildType"

switch ($VsArch)
{
    x64 {
        $VsArchFlag = ''
    }
    x86 {
        $VsArchFlag = '--x86'
    }
    arm64 {
        $VsArchFlag = '--arm64'
    }
    arm64ec {
        $VsArchFlag = '--arm64ec'
    }
    default {
        exit
    }
}

switch ($VsArch)
{
    x64 {
        $ArmFlag = ''
    }
    x86 {
        $ArmFlag = ''
    }
    arm64 {
        $ArmFlag = '--buildasx'
    }
    arm64ec {
        $ArmFlag = '--buildasx'
    }
    default {
        exit
    }
}

if ($VsVer -eq "v143")
{
    $VsFlag = 'Visual Studio 17 2022'
}
else
{
    $VsFlag = 'Visual Studio 16 2019'
}

if ($VsCRT -eq "mt")
{
    $StaticCrtFlag = "--enable_msvc_static_runtime"
}
else
{
    $StaticCrtFlag = ""
}

if ($BuildJava)
{
    $JavaFlag = "--build_java"
}
else
{
    $JavaFlag = ""
}

$OutPutPath = "build-$VsArch-$VsVer-$VsCRT"

if (!(Test-Path -Path $OutPutPath\$BuildType))
{
    Write-Host "创建文件夹:$OutPutPath\$BuildType"
    New-Item -Path "$OutPutPath\$BuildType" -ItemType Directory
}

python $PSScriptRoot\tools\ci_build\build.py `
	$VsArchFlag `
	$ArmFlag `
	$JavaFlag `
	--build_shared_lib `
    --build_dir $PSScriptRoot\$OutPutPath `
	--config $BuildType `
	--parallel `
	--skip_tests `
	--compile_no_warning_as_error `
	--cmake_generator $VsFlag `
	$StaticCrtFlag `
	--cmake_extra_defines CMAKE_INSTALL_PREFIX=./install onnxruntime_BUILD_UNIT_TESTS=OFF

if (!(Test-Path -Path $OutPutPath\$BuildType\$BuildType))
{
    Write-Host "Build error!"
    exit
}

Push-Location "build-$VsArch-$VsVer-$VsCRT\$BuildType"

#$LogicalProcessorsNum=(Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
#cmake --build . --config $BuildType --parallel $LogicalProcessorsNum

cmake --install .
if (!(Test-Path -Path install))
{
    Write-Host "Cmake install error!"
    exit
}
CollectLibs

Pop-Location


