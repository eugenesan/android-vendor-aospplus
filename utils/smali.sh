#!/bin/sh

: ${OUT:="../../../out"}

git clone https://github.com/JesusFreke/smali.git ${OUT}/smali
cd ${OUT}/smali
./gradlew proguard
cd -

cp -vf ${OUT}/smali/baksmali/build/libs/baksmali-*-small.jar baksmali.jar
cp -vf ${OUT}/smali/smali/build/libs/smali-*-small.jar smali.jar
