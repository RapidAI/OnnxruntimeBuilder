#!/bin/bash
# build onnxruntime 1.11 by benjaminwan
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
