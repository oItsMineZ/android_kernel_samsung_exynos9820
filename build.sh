#!/bin/bash

abort ()
{
    cd -
    echo "---------------------------------------------------------"
    echo "-- Kernel Compilation Failed! Exiting..."
    echo "---------------------------------------------------------"

    if [[ "$LOCAL" == "y" ]]; then
        clean
    fi

    exit -1
}

unset_flags ()
{
    cat << EOF
Usage: $(basename "$0") [options]
Options:
    -m, --model [value]    Specify the Model Code of the Phone (default: d2s)
    -k, --ksu [y/N]        Include KernelSU Next with SuSFS (default: y)
    -h, --help             List all Build Script Command
    -c, --clean [y/N]      Reset all Change to Latest Commit [!! Your Uncommit Change will Lost !!] (default: n)
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model|-m)
            MODEL="$2"
            shift 2
            ;;
        --ksu|-k)
            KSU_OPTION="$2"
            shift 2
            ;;
        --ver|-v)
            KERNEL_VERSION="$2"
            shift 2
            ;;
        --rel|-r)
            RELEASE="$2"
            shift 2
            ;;
        --help|-h)
            unset_flags
            exit 1
            ;;
        --clean|-c)
            CLEAN="$2"
            shift 2
            ;;
        *)\
            unset_flags
            exit 1
            ;;
    esac
done

detect_env ()
{
    DATE=`date +"%Y%m%d"`
    export KBUILD_BUILD_USER=oItsMineZ
    export KBUILD_BUILD_HOST=Stable

    echo "---------------------------------------------------------"

    if [ ! -z $RELEASE ]; then
        echo "-- Running on GitHub Actions..."
    else
        echo "-- Running on Local Machine..."
        LOCAL=y
    fi

    # Set Build Variable
    if [ -z $KERNEL_VERSION ]; then
        KERNEL_VERSION=Unofficial
    fi

    if [ -z $KSU ]; then
        KSU=y
    fi

    if [ -z $CLEAN ]; then
        CLEAN=n
    fi
}

DIR=$(pwd)

if [ -z $MODEL ]; then
    MODEL=d2s
fi

KERNEL_DEFCONFIG=oitsminez-"$MODEL"_defconfig
case $MODEL in
beyond0lte)
    SOC=9820
    BOARD=SRPRI28A014KU
;;
beyond1lte)
    SOC=9820
    BOARD=SRPRI28B014KU
;;
beyond2lte)
    SOC=9820
    BOARD=SRPRI17C014KU
;;
beyondx)
    SOC=9820
    BOARD=SRPSC04B011KU
;;
d1)
    SOC=9825
    BOARD=SRPSD26B007KU
;;
d1xks)
    SOC=9825
    BOARD=SRPSD23A002KU
;;
d2s)
    SOC=9825
    BOARD=SRPSC14B007KU
;;
d2x)
    SOC=9825
    BOARD=SRPSC14C007KU
;;
*)
    unset_flags
    exit
esac

kernelsu ()
{
    KSU_NEXT=ksu_next.config

    if test -d "$DIR/drivers/kernelsu" && grep -rnw 'fs/Makefile' -e 'CONFIG_KSU_SUSFS'; then
        echo "---------------------------------------------------------"
        echo "-- KernelSU-Next Directory Found!..."
        echo "---------------------------------------------------------"
    else
        echo "---------------------------------------------------------"
        echo "-- Checkout oItsMineZ's KernelSU-Next Repo..."
        echo "---------------------------------------------------------"

        git submodule add --force https://github.com/oItsMineZ/KernelSU-Next
        curl -LSs "https://raw.githubusercontent.com/oItsMineZ/KernelSU-Next/susfs-v1.5.5/kernel/setup.sh" | bash -

        if ! grep -rnw 'fs/Makefile' -e 'CONFIG_KSU_SUSFS'; then

            echo "---------------------------------------------------------"
            echo "-- Patch Kernel Tree with SuSFS..."
            echo "---------------------------------------------------------"

            curl -LOSs "https://raw.githubusercontent.com/oItsMineZKernel/Kernel-Patch/refs/heads/main/SuSFS.patch" && patch -p1 < SuSFS.patch && rm -rf *.patch
        fi
    fi
}

toolchain ()
{
    echo "---------------------------------------------------------"
    echo "-- Checkout Toolchain Repo..."
    echo "---------------------------------------------------------"

    git submodule add -f https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r433403b.git toolchain/clang-r433403b

    CLANG=$DIR/toolchain/clang-r433403b
    PATH=$CLANG/bin:$CLANG/lib:$PATH
    ARGS="
        ARCH=arm64 O=out \
        LLVM=1 LLVM_IAS=1 \
        CC=clang \
        READELF=$CLANG/bin/llvm-readelf \
    "
}

kernel ()
{
    if [[ "$SOC" == "9825" ]]; then
        DEVICE=Note10
    else
        DEVICE=S10
    fi

    # Build Kernel Image
    echo "---------------------------------------------------------"
    echo "-- Device: $DEVICE ("$MODEL")"
    echo "-- SOC: Exynos$SOC"
    echo "-- Defconfig: $KERNEL_DEFCONFIG"
    echo "-- Kernel Version: $KERNEL_VERSION"
    echo "-- Build Date: `date +"%Y-%m-%d"`"

    if [ -z $KSU_NEXT ]; then
        echo "-- KernelSU Next with SuSFS: Not Include"
    else
        echo "-- KernelSU Next with SuSFS: $KSU_NEXT"
    fi

    sed -i "s/CONFIG_LOCALVERSION=\"\"/CONFIG_LOCALVERSION=\"-oItsMineZKernel-$KERNEL_VERSION-$DEVICE-$MODEL\"/" $DIR/arch/arm64/configs/$KERNEL_DEFCONFIG
    sed -i "s/CONFIG_LOCALVERSION_AUTO=\"y\"/CONFIG_LOCALVERSION_AUTO=\"n\"/" $DIR/arch/arm64/configs/$KERNEL_DEFCONFIG

    if [ ! -z $RELEASE ]; then
        echo BUILD_DEVICE=$DEVICE >> $GITHUB_ENV
    fi

    DEFCONFIG="$KERNEL_DEFCONFIG oitsminez.config $KSU_NEXT"

    echo "---------------------------------------------------------"
    echo "-- Building Kernel Using "$KERNEL_DEFCONFIG""
    echo "-- Generating Configuration Files..."
    echo "---------------------------------------------------------"

    make -j$(nproc --all) $ARGS $DEFCONFIG || abort

    echo "---------------------------------------------------------"
    echo "-- Building Kernel..."
    echo "---------------------------------------------------------"

    make -j$(nproc --all) $ARGS || abort

    echo "---------------------------------------------------------"
    echo "-- Finished Kernel Build!"
    echo "---------------------------------------------------------"

    rm -rf $DIR/build/out/$MODEL
    mkdir -p $DIR/build/out/$MODEL
}

dtb ()
{
    # Build DTB Image
    echo "-- Building Device Tree Blob Image for exynos$SOC..."
    echo "---------------------------------------------------------"

    $DIR/build/mkdtimg cfg_create $DIR/build/out/$MODEL/dtb_exynos$SOC.img \
        $DIR/build/dtconfigs/exynos$SOC.cfg \
        -d $DIR/out/arch/arm64/boot/dts/exynos

    # Build DTBO Image
    echo "---------------------------------------------------------"
    echo "-- Building Device Tree Blob Image for $DEVICE ($MODEL)..."
    echo "---------------------------------------------------------"

    $DIR/build/mkdtimg cfg_create $DIR/build/out/$MODEL/dtbo_$MODEL.img \
        $DIR/build/dtconfigs/$MODEL.cfg \
        -d $DIR/out/arch/arm64/boot/dts/samsung
}

ramdisk ()
{
    # Build Ramdisk
    echo "---------------------------------------------------------"
    echo "-- Building Ramdisk..."
    echo "---------------------------------------------------------"

    rm -rf $DIR/build/AIK/s*
    mkdir -p $DIR/build/AIK/split_img
    cp $DIR/out/arch/arm64/boot/Image $DIR/build/AIK/split_img/boot.img-kernel
    echo -e "0x10000000" > build/AIK/split_img/boot.img-base
    echo -e $BOARD > build/AIK/split_img/boot.img-board
    echo -e "loop.max_part=7" > build/AIK/split_img/boot.img-cmdline
    echo -e "sha1" > build/AIK/split_img/boot.img-hashtype
    echo -e "1" > build/AIK/split_img/boot.img-header_version
    echo -e "AOSP" > build/AIK/split_img/boot.img-imgtype
    echo -e "0x00008000" > build/AIK/split_img/boot.img-kernel_offset
    echo -e "45285376" > build/AIK/split_img/boot.img-origsize
    echo -e "2023-04" > build/AIK/split_img/boot.img-os_patch_level
    echo -e "12.0.0" > build/AIK/split_img/boot.img-os_version
    echo -e "2048" > build/AIK/split_img/boot.img-pagesize
    echo -e "0x01000000" > build/AIK/split_img/boot.img-ramdisk_offset
    echo -e "gzip" > build/AIK/split_img/boot.img-ramdiskcomp
    echo -e "0xf0000000" > build/AIK/split_img/boot.img-second_offset
    echo -e "0x00000100" > build/AIK/split_img/boot.img-tags_offset

    # Create Boot Image
    echo "-- Creating Boot Image..."
    echo "---------------------------------------------------------"

    mkdir -p $DIR/build/AIK/ramdisk/debug_ramdisk
    mkdir -p $DIR/build/AIK/ramdisk/dev
    mkdir -p $DIR/build/AIK/ramdisk/mnt
    mkdir -p $DIR/build/AIK/ramdisk/proc
    mkdir -p $DIR/build/AIK/ramdisk/sys

    rm -rf $DIR/build/AIK/ramdisk/f*

    cp $DIR/build/AIK/fstab.exynos$SOC $DIR/build/AIK/ramdisk/

    cd $DIR/build/AIK && ./repackimg.sh --nosudo
}

build_zip ()
{
    # Build Zip
    echo "---------------------------------------------------------"
    echo "-- Building Zip..."
    if [[ "$LOCAL" == "y" ]] || [[ "$RELEASE" == "y" ]]; then
        echo "---------------------------------------------------------"
    fi

    rm -rf $DIR/build/out/$MODEL/zip
    mkdir -p $DIR/build/export
    mkdir -p $DIR/build/out/$MODEL/zip
    mkdir -p $DIR/build/out/$MODEL/zip/module
    mkdir -p $DIR/build/out/$MODEL/zip/module/common/
    mkdir -p $DIR/build/out/$MODEL/zip/module/META-INF/com/google/android
    mkdir -p $DIR/build/out/$MODEL/zip/META-INF/com/google/android
    mv $DIR/build/AIK/image-new.img $DIR/build/out/$MODEL/boot-patched.img

    cp $DIR/build/out/$MODEL/boot-patched.img $DIR/build/out/$MODEL/zip/boot.img
    cp $DIR/build/out/$MODEL/dtb_exynos$SOC.img $DIR/build/out/$MODEL/zip/dtb.img
    cp $DIR/build/out/$MODEL/dtbo_$MODEL.img $DIR/build/out/$MODEL/zip/dtbo.img
    cp $DIR/build/update-binary $DIR/build/out/$MODEL/zip/META-INF/com/google/android/
    cp $DIR/build/updater-script $DIR/build/out/$MODEL/zip/META-INF/com/google/android/

    cp $DIR/build/module.prop $DIR/build/out/$MODEL/zip/module/
    cp $DIR/build/system.prop $DIR/build/out/$MODEL/zip/module/common/
    cp $DIR/build/module-binary $DIR/build/out/$MODEL/zip/module/META-INF/com/google/android/update-binary
    echo -e "#MAGISK" > $DIR/build/out/$MODEL/zip/module/META-INF/com/google/android/updater-script

    cd $DIR/build/out/$MODEL/zip/module
    zip -r ../module.zip .
    rm -rf $DIR/build/out/$MODEL/zip/module

    sed -i "s/ui_print(\" Kernel Version: \");/ui_print(\" Kernel Version: $KERNEL_VERSION\");/" $DIR/build/out/$MODEL/zip/META-INF/com/google/android/updater-script
    sed -i "s/ui_print(\" Kernel Device: \");/ui_print(\" Kernel Device: $DEVICE ($MODEL)\");/" $DIR/build/out/$MODEL/zip/META-INF/com/google/android/updater-script
    sed -i "s/CONFIG_LOCALVERSION=\"-oItsMineZKernel-$KERNEL_VERSION-"$DEVICE"-$MODEL\"/CONFIG_LOCALVERSION=\"-oItsMineZKernel-$KERNEL_VERSION-"$DATE"-"$DEVICE"-$MODEL\"/" $DIR/arch/arm64/configs/$KERNEL_DEFCONFIG

    NAME=$(grep -o 'CONFIG_LOCALVERSION="[^"]*"' $DIR/arch/arm64/configs/$KERNEL_DEFCONFIG | cut -d '"' -f 2)
    NAME=${NAME:1}.zip

    if [[ "$LOCAL" == "y" ]] || [[ "$RELEASE" == "y" ]]; then
        cd $DIR/build/out/$MODEL/zip
        zip -r ../"$NAME" .
        rm -rf $DIR/build/out/$MODEL/zip
        mv $DIR/build/out/$MODEL/"$NAME" $DIR/build/export/"$NAME"
        cd $DIR/build/export
    fi
}

clean ()
{
    echo "---------------------------------------------------------"
    echo "-- Cleanup Build Files..."
    echo "---------------------------------------------------------"

    cd $DIR && rm -rf o* .w* build/AIK/s* build/AIK/ramdisk/f* && git restore arch/arm64/configs/$KERNEL_DEFCONFIG build/u*

    if [[ "$CLEAN" == "y" ]]; then	
        rm -rf K* toolc* && git clean -df && git reset --hard HEAD
    fi
}

# Main Function
rm -rf ./build.log
(
    START=`date +%s`

    echo "---------------------------------------------------------"
    echo "-- Preparing the Build Environment..."

    detect_env

    if test -d "$DIR/toolchain"; then
        echo "---------------------------------------------------------"
        echo "-- Toolchain Directory Found!"
        echo "---------------------------------------------------------"
    else
        toolchain
    fi

    if [[ "$KSU" == "y" ]]; then
        kernelsu
    fi

    kernel
    dtb
    ramdisk
    build_zip

    if [[ "$LOCAL" == "y" ]]; then
        clean
    fi

    END=`date +%s`

    let "ELAPSED=$END-$START"

    echo "---------------------------------------------------------"
    echo "-- Total Compile Time was $(($ELAPSED / 60)) Minutes and $(($ELAPSED % 60)) Seconds"
    echo "---------------------------------------------------------"
) 2>&1	| tee -a ./build.log