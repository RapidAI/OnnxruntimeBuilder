#!/usr/bin/env bash
# build onnxruntime by benjaminwan
# CMakeFiles/onnxruntime.dir/link.txt/link/lib*.a

function collectLibs() {
  # shared lib
  cmake --build . --config Release --target install
  rm -r -f install/bin
  echo "set(OnnxRuntime_INCLUDE_DIRS \"\${CMAKE_CURRENT_LIST_DIR}/include\")" > install/OnnxRuntimeConfig.cmake
  echo "include_directories(\${OnnxRuntime_INCLUDE_DIRS})" >> install/OnnxRuntimeConfig.cmake
  echo "link_directories(\${CMAKE_CURRENT_LIST_DIR}/lib)" >> install/OnnxRuntimeConfig.cmake
  echo "set(OnnxRuntime_LIBS onnxruntime)" >> install/OnnxRuntimeConfig.cmake

  # static lib
  mkdir -p install-static/lib
  cp -r install/include install-static
  link=$(cat CMakeFiles/onnxruntime.dir/link.txt)
  regex="lib.*.a$"
  libs=""
  for var in $link; do
    if [[ ${var} =~ ${regex} ]]; then
      echo cp ${var} install-static/lib
      cp ${var} install-static/lib
      name=$(echo $var | grep -E ${regex} -o)
      name=${name#lib}
      name=${name%.a}
      libs="${libs} ${name}"
    fi
  done
  echo "set(OnnxRuntime_INCLUDE_DIRS \"\${CMAKE_CURRENT_LIST_DIR}/include\")" > install-static/OnnxRuntimeConfig.cmake
  echo "include_directories(\${OnnxRuntime_INCLUDE_DIRS})" >> install-static/OnnxRuntimeConfig.cmake
  echo "link_directories(\${CMAKE_CURRENT_LIST_DIR}/lib)" >> install-static/OnnxRuntimeConfig.cmake
  echo "set(OnnxRuntime_LIBS $libs)" >> install-static/OnnxRuntimeConfig.cmake
}

function cmakeBuild() {
  mkdir -p "build-$1"
  pushd "build-$1"
  cmake -DCMAKE_BUILD_TYPE=$1 \
    -DCMAKE_CONFIGURATION_TYPES=$1 \
    -DCMAKE_INSTALL_PREFIX=install \
    $(cat ../onnxruntime_cmake_options.txt) \
    ../cmake
  cmake --build . -j $NUM_THREADS
  cmake --build . --target install
  collectLibs
  popd
}

function cmakeCrossBuild() {
  mkdir -p "build-$1"
  pushd "build-$1"
  cmake -DCMAKE_C_FLAGS="-pthread" -DCMAKE_CXX_FLAGS="-pthread" \
    -DCMAKE_TOOLCHAIN_FILE=../musl-cross.toolchain.cmake \
    -DCMAKE_BUILD_TYPE=$1 \
    -DCMAKE_CONFIGURATION_TYPES=$1 \
    -DCMAKE_INSTALL_PREFIX=install \
    $(cat ../onnxruntime_cmake_options.txt) \
    ../cmake
  cmake --build . -j $NUM_THREADS
  cmake --build . --target install
  collectLibs
  popd
}

sysOS=$(uname -s)
NUM_THREADS=1

if [ $sysOS == "Darwin" ]; then
  #echo "I'm MacOS"
  NUM_THREADS=$(sysctl -n hw.ncpu)
  cmakeBuild "Release"
elif [ $sysOS == "Linux" ]; then
  #echo "I'm Linux"
  NUM_THREADS=$(grep ^processor /proc/cpuinfo | wc -l)
  if [ "$1" ] && [ "$2" ]; then
    echo "TOOLCHAIN_NAME=$1"
    echo "TOOLCHAIN_PATH=$2"
    export TOOLCHAIN_NAME="$1"
    export TOOLCHAIN_PATH="$2"
    echo "cross build"
    cmakeCrossBuild "Release"
  else
    echo "native build"
    cmakeBuild "Release"
  fi
else
  echo "Other OS: $sysOS"
fi