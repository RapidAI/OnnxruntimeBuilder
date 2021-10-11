#!/bin/bash
# build onnxruntime 1.7 by benjaminwan
# CMakeFiles/onnxruntime.dir/link.txt/link/lib*.a

function collectLibs() {
  cmake --build . --config Release --target install
  rm -r -f install/bin
  mkdir -p install-static/lib
  cp -r install/include install-static
  cp libonnxruntime_session.a install-static/lib
  cp libonnxruntime_optimizer.a install-static/lib
  cp libonnxruntime_providers.a install-static/lib
  cp libonnxruntime_util.a install-static/lib
  cp libonnxruntime_framework.a install-static/lib
  cp libonnxruntime_graph.a install-static/lib
  cp libonnxruntime_common.a install-static/lib
  cp libonnxruntime_mlas.a install-static/lib
  cp libonnxruntime_flatbuffers.a install-static/lib
  cp external/onnx/libonnx.a install-static/lib
  cp external/onnx/libonnx_proto.a install-static/lib
  cp external/protobuf/cmake/libprotobuf-lite.a install-static/lib
  cp external/re2/libre2.a install-static/lib
  cp external/flatbuffers/libflatbuffers.a install-static/lib
  cp external/nsync/libnsync_cpp.a install-static/lib
}

function cmakeParamsMac() {
  ./build.sh --config $1 \
    $(cat ./onnxruntime_cmake_options.txt) \
    --cmake_extra_defines CMAKE_INSTALL_PREFIX=./install onnxruntime_BUILD_UNIT_TESTS=OFF

  pushd build/MacOS/Release
  collectLibs
  popd
}

function cmakeParamsLinux() {
  ./build.sh --config $1 \
    $(cat ./onnxruntime_cmake_options.txt) \
    --cmake_extra_defines CMAKE_INSTALL_PREFIX=./install onnxruntime_BUILD_UNIT_TESTS=OFF

  pushd build/Linux/Release
  collectLibs
  popd
}

sysOS=$(uname -s)
NUM_THREADS=1

if [ $sysOS == "Darwin" ]; then
  #echo "I'm MacOS"
  NUM_THREADS=$(sysctl -n hw.ncpu)
  cmakeParamsMac "Release"
elif [ $sysOS == "Linux" ]; then
  #echo "I'm Linux"
  NUM_THREADS=$(grep ^processor /proc/cpuinfo | wc -l)
  cmakeParamsLinux "Release"
else
  echo "Other OS: $sysOS"
fi
