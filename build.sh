#!/bin/bash

# Import Submodule
git submodule init && git submodule update --remote

# Import Cross Compiler
git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9  \
 toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9

# Import clang-r383902
git clone https://github.com/UniversalX-devs/prebuilts_clang_host_linux-x86_clang-r383902.git \
 toolchain/clang/host/linux-x86/clang-r383902

# OEM Setting
export ARCH=arm64
export PLATFORM_VERSION=11
export ANDROID_MAJOR_VERSION=r
export SEC_BUILD_CONF_VENDOR_BUILD_OS=13

# Setting toolchain path
CLANG_DIR=$(pwd)/toolchain/clang/host/linux-x86/clang-r383902
GCC_DIR=$(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
PATH=$CLANG_DIR/bin:$CLANG_DIR/lib:$GCC_DIR/bin:$GCC_DIR/lib:$PATH

# Cooking Kernel Source
mkdir out

MAKE_ARGS="
LLVM=1 \
LLVM_IAS=1 \
ARCH=arm64 \
READELF=${CLANG_DIR}/bin/llvm-readelf \
CROSS_COMPILE=${GCC_DIR}/bin/aarch64-linux-gnu- \
O=out
"

make ${MAKE_ARGS} -j16 exynos2100-o1sksx_defconfig gorhanhee.config || exit 1
make ${MAKE_ARGS} -j16 || exit 1
