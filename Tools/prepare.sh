#!/bin/bash
set -xe
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..


if hash cmake 2>/dev/null; then

python prepare.py -G Ninja -DENABLE_WEBRTC_AEC=ON -DENABLE_H263=YES -DENABLE_FFMPEG=YES -DENABLE_NON_FREE_CODECS=ON -DENABLE_GPL_THIRD_PARTIES=ON -DENABLE_AMRWB=NO -DENABLE_AMRNB=NO -DENABLE_OPENH264=YES -DENABLE_X264=NO -DENABLE_G729=NO -DENABLE_MPEG4=NO -DENABLE_H263P=NO -DENABLE_ILBC=NO -DENABLE_ISAC=NO -DENABLE_SILK=NO -DENABLE_VCARD=ON -DLINPHONE_BUILDER_LATEST=YES -DENABLE_RELATIVE_PREFIX=YES -DENABLE_GSM=YES -DENABLE_OPUS=YES -DENABLE_SILK=YES -DENABLE_BV16=YES -DENABLE_MKV=YES -DENABLE_SPEEX=YES -DLINPHONE_BUILDER_LATEST=NO -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -p

else

python prepare.py -G Ninja -DENABLE_WEBRTC_AEC=ON -DENABLE_H263=YES -DENABLE_FFMPEG=YES -DENABLE_NON_FREE_CODECS=ON -DENABLE_GPL_THIRD_PARTIES=ON -DENABLE_AMRWB=NO -DENABLE_AMRNB=NO -DENABLE_OPENH264=YES -DENABLE_X264=NO -DENABLE_G729=NO -DENABLE_MPEG4=NO -DENABLE_H263P=NO -DENABLE_ILBC=NO -DENABLE_ISAC=NO -DENABLE_SILK=NO -DENABLE_VCARD=ON -DLINPHONE_BUILDER_LATEST=YES -DENABLE_RELATIVE_PREFIX=YES -DENABLE_GSM=YES -DENABLE_OPUS=YES -DENABLE_SILK=YES -DENABLE_BV16=YES -DENABLE_MKV=YES -DENABLE_SPEEX=YES -DLINPHONE_BUILDER_LATEST=NO -p

fi