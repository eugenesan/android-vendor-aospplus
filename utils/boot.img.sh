#!/bin/bash -ex

# RePack Android boot.img or system.img
# http://forum.xda-developers.com/google-nexus-5/orig-development/kernel-furnace-1-0-0-lg-nexus-5-t2679826
# Version 1.1

: ${OUT:="../../../out"}

if [ -z "$(which cpio)" ] || [ -z "$(which gzip)" ] || [ -z "$(which cc)" ] || [ -z "$(which fakeroot)" ]; then
	echo "Missing tools: cpio|gzip|cc|fakeroot, aborting..."
	exit 1
fi

if [ ! -x ${OUT}/mkbootimg ] || [ ! -x ${OUT}/unpackbootimg ] || [ ! -x ${OUT}/simg2img ] || [ ! -x ${OUT}/ext4fuse/ext4fuse ]; then
	echo "Preparing to compile simg2img,mkbootimg,unpackbootimg from source"
	[ -n `which gcc` ] || sudo apt-get install build-essential
	[ -n `which git` ] || sudo apt-get install git
	[ -r /usr/include/zlib.h ] || sudo apt-get install zlib1g-dev
	[ -r /usr/include/fuse/fuse.h ] || sudo apt-get install libfuse-dev

	[ -d ${OUT}/android_system_core ] || git clone --depth 1 --single-branch --branch cm-12.1 --single-branch https://github.com/CyanogenMod/android_system_core.git ${OUT}/android_system_core

	cc -o ${OUT}/mkbootimg ${OUT}/android_system_core/mkbootimg/mkbootimg.c \
		-I${OUT}/android_system_core/mkbootimg -I${OUT}/android_system_core/include \
		${OUT}/android_system_core/libmincrypt/{dsa_sig.c,p256.c,p256_ec.c,p256_ecdsa.c,rsa.c,sha256.c,sha.c}

	cc -o ${OUT}/unpackbootimg ${OUT}/android_system_core/mkbootimg/unpackbootimg.c \
		-I${OUT}/android_system_core/mkbootimg -I${OUT}/android_system_core/include \
		${OUT}/android_system_core/libmincrypt/{dsa_sig.c,p256.c,p256_ec.c,p256_ecdsa.c,rsa.c,sha256.c,sha.c}

	cc -o ${OUT}/simg2img ${OUT}/android_system_core/libsparse/simg2img.c \
		-I${OUT}/android_system_core/libsparse -I${OUT}/android_system_core/include -I${OUT}/android_system_core/libsparse/include \
		${OUT}/android_system_core/libsparse/{backed_block,output_file,sparse{,_crc32,_err,_read}}.c \
		-lz

	[ -d ${OUT}/ext4fuse ] || git clone --depth 1 --single-branch --branch master https://github.com/gerard/ext4fuse.git ${OUT}/ext4fuse
	make -C ${OUT}/ext4fuse
else
	echo "Tools are pre-built."
fi

if [ "${1}" == "unpack" ]; then
	mkdir -p output
	${OUT}/unpackbootimg -i ${OUT}/boot.img -o output

	if [ -s ${OUT}/boot.img-dt ]; then
		cat ${OUT}/boot.img-zImage ${OUT}/boot.img-dt > ${OUT}/boot.img-zImage-dtb
	else
		cat ${OUT}/boot.img-zImage > ${OUT}/boot.img-zImage-dtb
	fi
fi

if [ "${1}" == "unpack-rd" ]; then
	mkdir -p ${OUT}/ramdisk
	pushd ${OUT}/ramdisk
	$(which gzcat || which zcat) ../../${OUT}/boot.img-ramdisk.gz | fakeroot -s ../../${OUT}/boot.img-ramdisk.fkdb -- cpio -i
	popd
fi

if [ "${1}" == "pack-rd" ]; then
	mkdir -p ${OUT}/ramdisk
	pushd ${OUT}/ramdisk
	find . | fakeroot -i ../../${OUT}/boot.img-ramdisk.fkdb -- cpio -o -H newc | gzip > ../../${OUT}/boot.img-ramdisk.gz
	popd
fi

if [ "${1}" == "pack" ]; then
	${OUT}/mkbootimg --kernel ${OUT}/boot.img-zImage-dtb --ramdisk ${OUT}/boot.img-ramdisk.gz \
	--cmdline "$(cat ${OUT}/boot.img-cmdline)" \
	--base $(cat ${OUT}/boot.img-base) --pagesize $(cat ${OUT}/boot.img-pagesize) \
	--ramdisk_offset $(cat ${OUT}/boot.img-ramdisk_offset) --tags_offset $(cat ${OUT}/boot.img-tags_offset) \
	-o ${OUT}/boot.img
fi

if [ "${1}" == "convert" ]; then
	mkdir -p output
	echo "Converting system.img to ext4 format"
	${OUT}/simg2img ${OUT}/system.img ${OUT}/system.ext4
fi

if [ "${1}" == "mount" ]; then
	echo "Mounting system.img as ext4"
	mkdir -p ${OUT}/system
	fakeroot -s ${OUT}/system.img.fkdb -- ${OUT}/ext4fuse/ext4fuse ${OUT}/system.ext4 ${OUT}/system
fi

if [ "${1}" == "unmount" ]; then
	echo "Un-Mounting system.mnt"
	fakeroot -s ${OUT}/system.img.fkdb -- fusermount -u ${OUT}/system
	rmdir ${OUT}/system
	rm ${OUT}/system.img.fkdb
fi
