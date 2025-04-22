shebang := if os() == 'windows' {
  'powershell.exe'
} else {
  '/usr/bin/env pwsh'
}

# Set shell for non-Windows OSs:
set shell := ["powershell", "-c"]

# Set shell for Windows OSs:
set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

onnx := "v1.21.1"
vs := "vs2022"

default:
  @just --list

# 编译opencv静态库
build_lib:
  just _build "x64" "v143" "mt"
  just _build "x64" "v143" "md"
  just _build "x86" "v143" "mt"
  just _build "x86" "v143" "md"
  just _build "arm64" "v143" "mt"
  just _build "arm64" "v143" "md"

_build arch ver crt:
  #!{{shebang}}
  if ("{{arch}}" -eq "x64") {
    .\Launch-VsDevShell.ps1 -VsInstallationPath 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise' -SkipAutomaticLocation -HostArch amd64 -Arch amd64
  } else {
    .\Launch-VsDevShell.ps1 -VsInstallationPath 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise' -SkipAutomaticLocation -HostArch amd64 -Arch "{{arch}}"
  }
  .\build-onnxruntime-win.ps1 -VsArch {{arch}} -VsVer {{ver}} -VsCRT {{crt}}
  cp -r build-{{arch}}-{{ver}}-{{crt}}/Release/install onnxruntime-{{onnx}}-windows-{{vs}}-{{arch}}-shared-{{crt}}
  7z a onnxruntime-{{onnx}}-windows-{{vs}}-{{arch}}-shared-{{crt}}.7z onnxruntime-{{onnx}}-windows-{{vs}}-{{arch}}-shared-{{crt}}
  rm onnxruntime-{{onnx}}-windows-{{vs}}-{{arch}}-shared-{{crt}} -r -fo
  cp -r build-{{arch}}-{{ver}}-{{crt}}/Release/install-static onnxruntime-{{onnx}}-windows-{{vs}}-{{arch}}-static-{{crt}}
  7z a onnxruntime-{{onnx}}-windows-{{vs}}-{{arch}}-static-{{crt}}.7z onnxruntime-{{onnx}}-windows-{{vs}}-{{arch}}-static-{{crt}}
  rm onnxruntime-{{onnx}}-windows-{{vs}}-{{arch}}-static-{{crt}} -r -fo

# 编译opencv java包
build_java:
  just _java "x64" "v143" "mt"
  just _java "x64" "v143" "md"
  just _java "arm64" "v143" "mt"
  just _java "arm64" "v143" "md"

_java arch ver crt:
  #!{{shebang}}
  if ("{{arch}}" -eq "x64") {
    .\Launch-VsDevShell.ps1 -VsInstallationPath 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise' -SkipAutomaticLocation -HostArch amd64 -Arch amd64
  } else {
    .\Launch-VsDevShell.ps1 -VsInstallationPath 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise' -SkipAutomaticLocation -HostArch amd64 -Arch "{{arch}}"
  }
  .\build-onnxruntime-win.ps1 -VsArch {{arch}} -VsVer {{ver}} -VsCRT {{crt}} -BuildJava
  cp -r build-{{arch}}-{{ver}}-{{crt}}/Release/java/build/libs onnxruntime-{{onnx}}-windows-{{vs}}-java-{{arch}}-{{crt}}
  7z a onnxruntime-{{onnx}}-windows-{{vs}}-java-{{arch}}-{{crt}}.7z onnxruntime-{{onnx}}-windows-{{vs}}-java-{{arch}}-{{crt}}
  rm onnxruntime-{{onnx}}-windows-{{vs}}-java-{{arch}}-{{crt}} -r -fo
