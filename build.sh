#!/bin/bash

# Import Submodule
git submodule init && git submodule update --remote

# Import Cross Compiler
git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9  \
 toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9

# Import clang-r383902
git clone https://github.com/UniversalX-devs/prebuilts_clang_host_linux-x86_clang-r383902.git \
 toolchain/clang/host/linux-x86/clang-r383902

# Setting path
export ANDROID_BUILD_TOP=$(pwd)

# OEM Setting
export ARCH=arm64
export PLATFORM_VERSION=11
export ANDROID_MAJOR_VERSION=r
export SEC_BUILD_CONF_VENDOR_BUILD_OS=13

# Setting toolchain path
CLANG_DIR=${ANDROID_BUILD_TOP}/toolchain/clang/host/linux-x86/clang-r383902
GCC_DIR=${ANDROID_BUILD_TOP}/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
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

make ${MAKE_ARGS} -j24 exynos2100-o1sksx_defconfig gorhanhee.config || exit 1
make ${MAKE_ARGS} -j24 || exit 1

# Cooking Kernel module
export MODULE_DIR=${ANDROID_BUILD_TOP}/out/modules_out
make ${MAKE_ARGS} -j24 INSTALL_MOD_PATH=${MODULE_DIR} INSTALL_MOD_STRIP=1 modules_install || exit 1

# Cooking boot.img
cp ${ANDROID_BUILD_TOP}/out/arch/arm64/boot/Image ${ANDROID_BUILD_TOP}/prebuilts/boot/build/unzip_boot/kernel
cp ${ANDROID_BUILD_TOP}/out/kernel/config_data ${ANDROID_BUILD_TOP}/prebuilts/boot/build/unzip_boot/kernel_configs.txt
cd prebuilts/boot
./gradlew pack || exit 1
cp boot.img.signed ${ANDROID_BUILD_TOP}/prebuilts/boot.img

cd ${ANDROID_BUILD_TOP}

# Cooking vendor_boot.img
mkdir prebuilts/modules
find out/modules_out/ -name "*.ko" -exec cp {} prebuilts/modules/ \;
cp ${ANDROID_BUILD_TOP}/prebuilts/modules/* ${ANDROID_BUILD_TOP}/prebuilts/vendor_boot/build/unzip_boot/root/lib/modules/
cd prebuilts/vendor_boot
./gradlew pack || exit 1
cp vendor_boot.img.signed ${ANDROID_BUILD_TOP}/prebuilts/vendor_boot.img

cd ${ANDROID_BUILD_TOP}/prebuilts

# Download fastbootD patched recovery
RECOVERY_URL="https://github.com/GoRhanHee/android_kernel_samsung_exynos2100_o1s/releases/download/fastbootD/recovery.img"
RECOVERY_FILE=$(basename "$RECOVERY_URL")
TARGET_PATH=${ANDROID_BUILD_TOP}/prebuilts/$RECOVERY_FILE
if [ ! -f "$TARGET_PATH" ]; then
    wget -q --show-progress --progress=dot:giga -O "$TARGET_PATH" "$RECOVERY_URL"
fi

# Cooking flashable tar file
tar -cvf "Galaxy S21 KernelSU.tar" boot.img recovery.img vendor_boot.img vbmeta.img