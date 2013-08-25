#!/bin/sh

# Author: chang.biao
# Move this script to ffmpeg src dir;
# exec this file in Terminal;

##########################################
#gas-preprocessor.pl
function preset_env(){
echo "编译使用内核类型-> ${1}"

#if
if [ ${1} == "i386" ]
then
CCPlatform="iPhoneSimulator"
elif [ ${1} == "armv6" ]; then
CCPlatform="iPhoneOS"
else
CCPlatform="iPhoneOS"
fi
#
echo "编译使用平台-> ${CCPlatform}"
#

CCGasPreCpu=/usr/local/bin/gas-preprocessor.pl
CCVersion="6.1"
DEVRoot=/Applications/Xcode.app/Contents/Developer/Platforms/${CCPlatform}.platform/Developer
SDKRoot=$DEVRoot/SDKs/${CCPlatform}${CCVersion}.sdk

#case 
case $1 in
"i386")
#printit; echo $1 | tr 'a-z' 'A-Z'  # 将参数做大小写转换！
CC=$DEVRoot/usr/bin/llvm-gcc
;;
"armv6")
#printit; echo $1 | tr 'a-z' 'A-Z'
#CC=$DEVRoot/usr/bin/arm-apple-darwin10-llvm-gcc-4.2
CC=$DEVRoot/usr/bin/llvm-gcc-4.2
#CC=$DEVRoot/usr/bin/llvm-gcc
#CC=/usr/bin/gcc
;;
"armv7")
#printit; echo $1 | tr 'a-z' 'A-Z'
CC=$DEVRoot/usr/bin/llvm-gcc
;;
*)
echo "输出参数$0 $1"
CC=$DEVRoot/usr/bin/llvm-gcc
;;
esac


echo "使用SDK:${CCVersion}-> ${SDKRoot}"
echo "使用编译器-> ${CC}"
#CC=$DEVRoot//usr/bin/gcc
}


################# configure ####################
#下面语句中别含'\n'和'\'
#可以下载yasm去掉--disable-asm参数,但还会error
#--disable-gpl | --enable-gpl
#--enable-nonfree
#--disable-ffprobe
#--disable-debug
#--disable-ffmpeg
#--disable-doc
#--disable-swscale-alpha
#--disable-armv5te
#--prefix=安装路径
################# i386 ####################
#ARCH-TYPE #for iPhoneSimulator
function configure_i386(){
    CCArch="i386"
    preset_env ${CCArch}
    ./configure --cc=${CC} --as="${CCGasPreCpu} ${CC}" --sysroot=${SDKRoot} --enable-cross-compile --target-os=darwin --arch=${CCArch} --cpu=${CCArch} --extra-cflags="-arch ${CCArch}" --extra-ldflags="-arch ${CCArch} -isysroot ${SDKRoot}" --enable-pic --disable-doc --disable-ffplay --disable-ffserver --disable-gpl --disable-shared --enable-static --disable-mmx --disable-debug --enable-decoder=h264 --disable-asm --prefix=compiled/${CCArch} --disable-armv5te --disable-swscale-alpha --enable-nonfree
}

################# armv6 ####################
#ARCH-TYPE #最新的编译器已经不适用与armv6的编译了;
function configure_armv6(){
    CCArch="armv6"
    preset_env ${CCArch}
    ./configure --cc=${CC} --as='gas-preprocessor.pl ${CC}' --sysroot=${SDKRoot} --enable-cross-compile --target-os=darwin --arch=arm --cpu=arm1176jzf-s --extra-cflags="-arch ${CCArch}" --extra-ldflags="-arch ${CCArch} -isysroot ${SDKRoot}" --enable-pic --disable-doc --disable-ffplay --disable-ffserver --enable-gpl --disable-shared --enable-static --disable-mmx --disable-debug --enable-decoder=h264 --disable-asm --prefix=compiled/${CCArch}
}

################# armv7 ####################
#ARCH-TYPE
function configure_armv7(){
    CCArch="armv7"
    preset_env ${CCArch}
    ./configure --cc=${CC} --as='gas-preprocessor.pl ${CC}' --sysroot=${SDKRoot} --enable-cross-compile --target-os=darwin --arch=arm --cpu=cortex-a8 --extra-cflags="-arch ${CCArch}" --extra-ldflags="-arch ${CCArch} -isysroot ${SDKRoot}" --enable-pic --disable-doc --disable-ffplay --disable-ffserver --disable-gpl --disable-shared --enable-static --disable-mmx --disable-debug --enable-decoder=h264 --disable-asm --prefix=compiled/${CCArch}
}

################# armv7s ####################
#ARCH-TYPE
function configure_armv7s(){
CCArch="armv7s"
preset_env ${CCArch}
./configure --cc=${CC} --as='gas-preprocessor.pl ${CC}' --sysroot=${SDKRoot} --enable-cross-compile --target-os=darwin --arch=arm --cpu=AppleSwift --extra-cflags="-arch ${CCArch}" --extra-ldflags="-arch ${CCArch} -isysroot ${SDKRoot}" --enable-pic --disable-doc --disable-ffplay --disable-ffserver --disable-gpl --disable-shared --enable-static --disable-mmx --disable-debug --enable-decoder=h264 --disable-asm --prefix=compiled/${CCArch}
}

################# Make & INSTALL ####################
#clean & make & install
function clean_make_install (){
    sudo make clean
    sudo make && make install
}
 

################# 合并静态库 ##################
#universal (using one *.a files for all platforms)
function lipo_all_arch_libs(){

    CCLipoCMD=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/lipo
#    CCLipoCMD=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/lipo
#    CCLipoCMD=/usr/bin/lipo

    CCLibSrcI386=./compiled/i386/lib
    CCLibArmv6=./compiled/armv6/lib
    CCLibSrcArmv7=./compiled/armv7/lib
    CCLibArmv7s=./compiled/armv7s/lib
    #目标
    CCLibDest=./compiled/fat/lib

    sudo mkdir -p ${CCLibDest}

    for libn in \
        libavcodec.a \
        libavdevice.a \
        libavformat.a \
        libavutil.a \
        libswresample.a \
        libpostproc.a \
        libswscale.a \
        libavfilter.a
    do
        _tmp_cmd_="lipo -output ${CCLibDest}/${libn} -create -arch i386 ${CCLibSrcI386}/${libn} -arch armv7 ${CCLibSrcArmv7}/${libn}"
        echo "合并lib命令：${_tmp_cmd_}"
        $_tmp_cmd_
    done
}

#编译产生库
#libavcodec.a
#libavdevice.a
#libavformat.a
#libavutil.a
#libswresample.a
#libpostproc.a
#libswscale.a
#libavfilter.a

#lipo -output ./compiled/fat/lib/libavcodec.a -create -arch armv6 ./compiled/armv6/lib/libavcodec.a -arch armv7 ./compiled/armv7/lib/libavcodec.a -arch i386 ./compiled/i386/lib/libavcodec.a



###################################
###---------- Main -------------###
#configure_i386
#configure_armv6
#configure_armv7
#configure_armv7s
#clean_make_install
lipo_all_arch_libs
###################################
