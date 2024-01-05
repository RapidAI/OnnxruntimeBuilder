#!/bin/bash
# build onnxruntime by benjaminwan
# CMakeFiles/onnxruntime.dir/link.txt/link/lib*.a

function cmakeParams() {
  mkdir -p "build-$1"
  pushd "build-$1"
  cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CONFIGURATION_TYPES=Release \
    -DCMAKE_INSTALL_PREFIX=install \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=$1 -DANDROID_MIN_SDK=$2 -DANDROID_PLATFORM=android-$2\
    $(cat ../onnxruntime_cmake_options.txt) \
    ../cmake
  cmake --build . --config Release -j $NUM_THREADS
  cmake --build . --config Release --target install
  popd
}

sysOS=$(uname -s)
NUM_THREADS=1

if [ $sysOS == "Darwin" ]; then
  #echo "I'm MacOS"
  NUM_THREADS=$(sysctl -n hw.ncpu)
elif [ $sysOS == "Linux" ]; then
  #echo "I'm Linux"
  NUM_THREADS=$(grep ^processor /proc/cpuinfo | wc -l)
else
  echo "Other OS: $sysOS"
fi

if [ "$1" ]; then
 echo "set ANDROID_NDK=$1"
 export ANDROID_NDK="$1"
else
 echo "input ANDROID_NDK is empty, use default"
fi

# build
cmakeParams "armeabi-v7a" 19
cmakeParams "arm64-v8a" 21
cmakeParams "x86" 19
cmakeParams "x86_64" 21

echo "message(\"OnnxRuntime Path: \${CMAKE_CURRENT_LIST_DIR}/\${ANDROID_ABI}\")" > OnnxRuntimeWrapper.cmake
echo "set(OnnxRuntime_DIR \"\${CMAKE_CURRENT_LIST_DIR}/\${ANDROID_ABI}\")" >> OnnxRuntimeWrapper.cmake