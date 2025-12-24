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

# Cooking Kernel Source
make ARCH=arm64 -j16 exynos2100-o1sksx_defconfig gorhanhee.config || exit 1
make ARCH=arm64 -j16 || exit 1
