#!/bin/bash
# build onnxruntime by benjaminwan
# CMakeFiles/onnxruntime.dir/link.txt/link/lib*.a

function createConfig() {
  echo "set(OnnxRuntime_INCLUDE_DIRS \"\${CMAKE_CURRENT_LIST_DIR}/include\")" >install/OnnxRuntimeConfig.cmake
  echo "include_directories(\${OnnxRuntime_INCLUDE_DIRS})" >>install/OnnxRuntimeConfig.cmake
  echo "link_directories(\${CMAKE_CURRENT_LIST_DIR}/lib)" >>install/OnnxRuntimeConfig.cmake
  echo "set(OnnxRuntime_LIBS onnxruntime)" >>install/OnnxRuntimeConfig.cmake
  echo "add_library(\${OnnxRuntime_LIBS} SHARED IMPORTED)" >>install/OnnxRuntimeConfig.cmake
  echo "set_target_properties(\${OnnxRuntime_LIBS} PROPERTIES IMPORTED_LOCATION \${CMAKE_CURRENT_LIST_DIR}/lib/libonnxruntime.so)" >>install/OnnxRuntimeConfig.cmake
}

function cmakeParams() {
  mkdir -p "build-$1"
  pushd "build-$1"
  cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CONFIGURATION_TYPES=Release \
    -DCMAKE_INSTALL_PREFIX=install \
    -DANDROID_ABI=$1 -DANDROID_MIN_SDK=$2 -DANDROID_PLATFORM=android-$2\
    -DCMAKE_TOOLCHAIN_FILE="$3/build/cmake/android.toolchain.cmake" \
    $(cat ../onnxruntime_cmake_options.txt) \
    ../cmake
  cmake --build . --config Release -j $NUM_THREADS
  cmake --build . --config Release --target install
  createConfig
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
    echo "set ARCH_TYPE=$1"
    ARCH_TYPE="$1"
else
    echo "#1 ARCH_TYPE is empty("armeabi-v7a","arm64-v8a","x86","x86_64"), use armeabi-v7a"
    ARCH_TYPE="armeabi-v7a"
fi

if [ "$2" ]; then
    echo "set MIN_SDK=$2"
    MIN_SDK="$2"
else
    echo "#2 MIN_SDK is empty, use 21"
fi

if [ "$3" ]; then
    echo "set $NDK_PATH=$3"
    set NDK_PATH="$3"
else
    echo "#3 NDK_PATH is empty, use $ANDROID_NDK_HOME"
    set NDK_PATH=$ANDROID_NDK_HOME
fi

# build
cmakeParams $ARCH_TYPE $MIN_SDK $ANDROID_NDK_HOME

#echo "message(\"OnnxRuntime Path: \${CMAKE_CURRENT_LIST_DIR}/\${ANDROID_ABI}\")" > OnnxRuntimeWrapper.cmake
#echo "set(OnnxRuntime_DIR \"\${CMAKE_CURRENT_LIST_DIR}/\${ANDROID_ABI}\")" >> OnnxRuntimeWrapper.cmake