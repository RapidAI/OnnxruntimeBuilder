#!/bin/bash
# build onnxruntime by benjaminwan
# CMakeFiles/onnxruntime.dir/link.txt/link/lib*.a

function collectLibs() {
  # shared lib
  cmake --build . --config Release --target install
  rm -r -f install/bin
  echo "set(OnnxRuntime_INCLUDE_DIRS \"\${CMAKE_CURRENT_LIST_DIR}/include\")" >install/OnnxRuntimeConfig.cmake
  echo "include_directories(\${OnnxRuntime_INCLUDE_DIRS})" >>install/OnnxRuntimeConfig.cmake
  echo "link_directories(\${CMAKE_CURRENT_LIST_DIR}/lib)" >>install/OnnxRuntimeConfig.cmake
  echo "set(OnnxRuntime_LIBS onnxruntime)" >>install/OnnxRuntimeConfig.cmake
  echo "add_library(\${OnnxRuntime_LIBS} SHARED IMPORTED)" >>install/OnnxRuntimeConfig.cmake
  echo "set_target_properties(\${OnnxRuntime_LIBS} PROPERTIES IMPORTED_LOCATION \${CMAKE_CURRENT_LIST_DIR}/lib/libonnxruntime.so)" >>install/OnnxRuntimeConfig.cmake
}

function cmakeParamsAndroid() {
  ./build.sh --build_dir "$1_$2_$3" --config $1 \
    $(cat ./onnxruntime_cmake_options.txt) \
    --cmake_extra_defines CMAKE_INSTALL_PREFIX=./install onnxruntime_BUILD_UNIT_TESTS=OFF \
    --android --android_sdk_path $ANDROID_HOME \
    --android_ndk_path $ANDROID_NDK_HOME \
    --android_abi $2 \
    --android_api $3

  pushd "$1_$2_$3"/Release
  collectLibs
  popd
}

cmakeParamsAndroid "Release" "armeabi-v7a" 19
cmakeParamsAndroid "Release" "arm64-v8a" 21
cmakeParamsAndroid "Release" "x86" 19
cmakeParamsAndroid "Release" "x86_64" 21

echo "message(\"OnnxRuntime Path: \${CMAKE_CURRENT_LIST_DIR}/\${ANDROID_ABI}\")" > OnnxRuntimeWrapper.cmake
echo "set(OnnxRuntime_DIR \"\${CMAKE_CURRENT_LIST_DIR}/\${ANDROID_ABI}\")" >> OnnxRuntimeWrapper.cmake
