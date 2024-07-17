#!/bin/bash
# build onnxruntime by benjaminwan

function is_cmd_exist() {
    retval=""
    if ! command -v $1 >/dev/null 2>&1; then
        retval="false"
    else
        retval="true"
    fi
    echo "$retval"
}

function collect_shared_lib() {
    if [ -d "install/bin" ]; then
        rm -r -f install/bin
    fi

    if [ -d "install/include/onnxruntime" ]; then
        mv install/include/onnxruntime/* install/include
        rm -rf install/include/onnxruntime
    fi

    echo "set(OnnxRuntime_INCLUDE_DIRS \"\${CMAKE_CURRENT_LIST_DIR}/include\")" >install/OnnxRuntimeConfig.cmake
    echo "include_directories(\${OnnxRuntime_INCLUDE_DIRS})" >>install/OnnxRuntimeConfig.cmake
    echo "link_directories(\${CMAKE_CURRENT_LIST_DIR}/lib)" >>install/OnnxRuntimeConfig.cmake
    echo "set(OnnxRuntime_LIBS onnxruntime)" >>install/OnnxRuntimeConfig.cmake
}

function copy_libs() {
    all_link=$(cat CMakeFiles/onnxruntime.dir/link.txt)
    link=${all_link#*onnxruntime.dir}
    regex="lib.*.a$"
    libs=""
    for var in $link; do
        if [[ ${var} =~ ${regex} ]]; then
            #echo cp ${var} install-static/lib
            cp ${var} install-static/lib
            name=$(echo $var | grep -E ${regex} -o)
            name=${name#lib}
            name=${name%.a}
            libs="${libs} ${name}"
        fi
    done
    echo "$libs"
}

function combine_libs_linux() {
    all_link=$(cat CMakeFiles/onnxruntime.dir/link.txt)
    link=${all_link#*onnxruntime.dir}
    regex="lib.*.a$"
    root_path="${PWD}"
    static_path="${PWD}/install-static"
    lib_path="${PWD}/install-static/lib"
    mkdir -p $lib_path
    echo "create ${lib_path}/libonnxruntime.a" >${static_path}/libonnxruntime.mri
    for var in $link; do
        if [[ ${var} =~ ${regex} ]]; then
            echo "addlib ${root_path}/${var}" >>${static_path}/libonnxruntime.mri
        fi
    done
    echo "save" >>${static_path}/libonnxruntime.mri
    echo "end" >>${static_path}/libonnxruntime.mri
    $TOOLCHAIN_NAME-ar -M <${static_path}/libonnxruntime.mri
}

function collect_static_libs() {
    if [ -d "install-static" ]; then
        rm -r -f install-static
    fi
    mkdir -p install-static/lib

    if [ -d "install/include" ]; then
        cp -r install/include install-static
    fi

    if [ ! -f "CMakeFiles/onnxruntime.dir/link.txt" ]; then
        echo "link.txt is not exist, collect static libs error."
        exit 0
    fi

    ar_exist=$(is_cmd_exist $TOOLCHAIN_NAME-ar)
    if [ "$ar_exist" == "true" ]; then
        echo "combine_libs_linux"
        combine_libs_linux
        libs="onnxruntime"
    else
        echo "copy_libs"
        libs=$(copy_libs)
    fi

    echo "set(OnnxRuntime_INCLUDE_DIRS \"\${CMAKE_CURRENT_LIST_DIR}/include\")" >install-static/OnnxRuntimeConfig.cmake
    echo "include_directories(\${OnnxRuntime_INCLUDE_DIRS})" >>install-static/OnnxRuntimeConfig.cmake
    echo "link_directories(\${CMAKE_CURRENT_LIST_DIR}/lib)" >>install-static/OnnxRuntimeConfig.cmake
    echo "set(OnnxRuntime_LIBS $libs)" >>install-static/OnnxRuntimeConfig.cmake

    cp CMakeFiles/onnxruntime.dir/link.txt install-static/link.log
}

HOST_OS=$(uname -s)
NUM_THREADS=1
BUILD_TYPE=Release

if [ $HOST_OS == "Linux" ]; then
    NUM_THREADS=$(nproc)
else
    echo "Unsupport OS: $HOST_OS"
    exit 0
fi

while getopts "n:p:" arg; do
    case $arg in
    n)
        echo "n's arg:$OPTARG"
        export TOOLCHAIN_NAME="$OPTARG"
        ;;
    p)
        echo "p's arg:$OPTARG"
        export TOOLCHAIN_PATH="$OPTARG"
        ;;
    ?)
        echo -e "unkonw argument."
        exit 1
        ;;
    esac
done
echo "TOOLCHAIN_NAME=$TOOLCHAIN_NAME, TOOLCHAIN_PATH=$TOOLCHAIN_PATH"

if [ -z "$TOOLCHAIN_NAME" ] || [ -z "$TOOLCHAIN_PATH" ]; then
    echo -e "empty TOOLCHAIN_NAME or TOOLCHAIN_PATH."
    echo -e "usage: ./build-onnxruntime-musl.sh -n 'aarch64-linux-musl' -p '/opt/aarch64-linux-musl'"
    exit 1
fi

export PATH=$TOOLCHAIN_PATH/bin:$PATH

mkdir -p "build-$BUILD_TYPE-$TOOLCHAIN_NAME"
pushd "build-$BUILD_TYPE-$TOOLCHAIN_NAME" || exit
cmake ../cmake \
    $(cat ../onnxruntime_cmake_options.txt) \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DCMAKE_INSTALL_PREFIX=install \
    -DCMAKE_TOOLCHAIN_FILE=../musl-cross.toolchain.cmake
patch -p0 -i ../patches/onnxruntime-1.18.0-musl.patch
cmake --build . --config $BUILD_TYPE -j $NUM_THREADS
cmake --build . --config $BUILD_TYPE --target install

if [ ! -d "install" ]; then
    echo "Cmake install  error!"
    exit 0
fi
collect_shared_lib
collect_static_libs
popd
