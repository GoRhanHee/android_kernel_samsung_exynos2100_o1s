#!/bin/bash

# Import Submodule
git submodule init && git submodule update --remote

# Import Cross Compiler
git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9  \
 toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9

# Import clang-r383902
git clone https://github.com/UniversalX-devs/prebuilts_clang_host_linux-x86_clang-r383902.git \
 toolchain/clang/host/linux-x86/clang-r383902

# Setting 
export ANDROID_BUILD_TOP=$(pwd)
export OPTION=$1

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

if [ "${OPTION}" == "stock" ]; then
    make ${MAKE_ARGS} -j24 exynos2100-o1sksx_defconfig gorhanhee.config || exit 1
elif [ "${OPTION}" == "kernelsu" ]; then
    make ${MAKE_ARGS} -j24 exynos2100-o1sksx_defconfig gorhanhee.config kernelsu.config || exit 1
elif [ "${OPTION}" == "recovery" ]; then
    make ${MAKE_ARGS} -j24 exynos2100-o1sksx_defconfig gorhanhee.config recovery.config  || exit 1
fi

make ${MAKE_ARGS} -j24 || exit 1

# Cooking Kernel module
export MODULE_DIR=${ANDROID_BUILD_TOP}/out/modules_out
make ${MAKE_ARGS} -j24 INSTALL_MOD_PATH=${MODULE_DIR} INSTALL_MOD_STRIP=1 modules_install || exit 1

mkdir prebuilts/output

# Cooking dtb.img
# Idea from @xfwdrev exynos2100 kernel source (https://github.com/xfwdrev/android_kernel_samsung_ex2100/blob/12-upstream/build.sh)
./prebuilts/mkdtimg cfg_create ${ANDROID_BUILD_TOP}/prebuilts/output/dtb.img ${ANDROID_BUILD_TOP}/prebuilts/dt_configs/exynos2100.cfg -d ${ANDROID_BUILD_TOP}/out/arch/arm64/boot/dts/exynos

# Cooking dtbo.img
# Idea from @xfwdrev exynos2100 kernel source (https://github.com/xfwdrev/android_kernel_samsung_ex2100/blob/12-upstream/build.sh)
./prebuilts/mkdtimg cfg_create ${ANDROID_BUILD_TOP}/prebuilts/output/dtbo.img ${ANDROID_BUILD_TOP}/prebuilts/dt_configs/o1s.cfg -d ${ANDROID_BUILD_TOP}/out/arch/arm64/boot/dts/samsung/o1s

# Cooking flashable file & Finishing job
# ** Galaxy S21 required cooked vendor_boot.img when we use cooked kernel, So this script will cook valid boot.img and vendor_boot.img
# ** 5.4 Kernel is very weird kernel... So, If you watch this scripts, i recommend copy this scripts.. (this scripts from many smart developers..)
# If this option is "recovery", this script doesnt build boot.img and vendor_boot.img
if [ "${OPTION}" == "recovery" ]; then
    mkdir prebuilts/output/modules
    find out/modules_out/ -name "*.ko" -exec cp {} prebuilts/output/modules/ \;
    cp ${ANDROID_BUILD_TOP}/out/arch/arm64/boot/Image ${ANDROID_BUILD_TOP}/prebuilts/output/kernel
else
    # Cooking boot.img
        cp ${ANDROID_BUILD_TOP}/out/arch/arm64/boot/Image ${ANDROID_BUILD_TOP}/prebuilts/boot/build/unzip_boot/kernel
        cp ${ANDROID_BUILD_TOP}/out/kernel/config_data ${ANDROID_BUILD_TOP}/prebuilts/boot/build/unzip_boot/kernel_configs.txt
        cd prebuilts/boot && ./gradlew pack || exit 1
        cp boot.img.signed ${ANDROID_BUILD_TOP}/prebuilts/output/boot.img
        cd ${ANDROID_BUILD_TOP}
    # Cooking vendor_boot.img
        mkdir prebuilts/output/modules
        find out/modules_out/ -name "*.ko" -exec cp {} prebuilts/output/modules/ \;
        cp ${ANDROID_BUILD_TOP}/prebuilts/output/modules/* ${ANDROID_BUILD_TOP}/prebuilts/vendor_boot/build/unzip_boot/root/lib/modules/
        cd prebuilts/vendor_boot && ./gradlew pack || exit 1
        cp vendor_boot.img.signed ${ANDROID_BUILD_TOP}/prebuilts/output/vendor_boot.img
        cd ${ANDROID_BUILD_TOP}/prebuilts/output
    # Cooking flashable tar file    
        tar -cvf "Galaxy_S21_${OPTION}.tar" boot.img dtbo.img vendor_boot.img vbmeta.img
fi