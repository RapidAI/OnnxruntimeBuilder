#!/bin/bash
# build onnxruntime by benjaminwan
# CMakeFiles/onnxruntime.dir/link.txt/link/lib*.a

function collectLibs() {
  # shared lib
  cmake --build . --config Release --target install
#  rm -r -f install/bin
  mv install/include/onnxruntime/core/session/* install/include
  rm -rf install/include/onnxruntime
  echo "set(OnnxRuntime_INCLUDE_DIRS \"\${CMAKE_CURRENT_LIST_DIR}/include\")" > install/OnnxRuntimeConfig.cmake
  echo "include_directories(\${OnnxRuntime_INCLUDE_DIRS})" >> install/OnnxRuntimeConfig.cmake
  echo "link_directories(\${CMAKE_CURRENT_LIST_DIR}/lib)" >> install/OnnxRuntimeConfig.cmake
  echo "set(OnnxRuntime_LIBS onnxruntime)" >> install/OnnxRuntimeConfig.cmake

  # static lib
  mkdir -p install-static/lib
  cp -r install/include install-static
  all_link=$(cat CMakeFiles/onnxruntime.dir/link.txt)
  link=${all_link#*onnxruntime.dir}
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
  cp CMakeFiles/onnxruntime.dir/link.txt install-static/link.log
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
sysOS=$(uname -s)
NUM_THREADS=1

if [ $sysOS == "Darwin" ]; then
  NUM_THREADS=$(sysctl -n hw.ncpu)
elif [ $sysOS == "Linux" ]; then
  NUM_THREADS=$(nproc)
else
  echo "Other OS: $sysOS"
  exit 0
fi


python3 $DIR/tools/ci_build/build.py --build_dir $DIR/build-$sysOS \
    --allow_running_as_root \
    --config Release \
    --parallel \
    --skip_tests \
    --build_shared_lib \
    --build_java \
    --cmake_extra_defines CMAKE_INSTALL_PREFIX=./install onnxruntime_BUILD_UNIT_TESTS=OFF

pushd build-$sysOS/Release
cmake --build . --config Release -j $NUM_THREADS
collectLibs
popd
