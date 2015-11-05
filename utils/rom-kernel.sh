#!/bin/bash

# Get current paths
: ${DIR:="$(cd `dirname $0`; pwd)"}

OUT="$(readlink ${DIR}/out)"
[ -z "${OUT}" ] && OUT="${DIR}/out"
OUT="$(cd ${OUT}; pwd)"

CCACHE_DIR="$(readlink ${DIR}/ccache)"
[ -z "${CCACHE_DIR}" ] && CCACHE_DIR="${DIR}/ccache"
CCACHE_DIR="$(cd ${CCACHE_DIR}; pwd)"

: ${ARCH:="arm"}
: ${VENDOR:="lge"}
: ${DEVICE:="hammerhead"}
: ${GCC:="prebuilts/gcc/linux-x86/${ARCH}/${ARCH}-eabi-4.8/bin/${ARCH}-eabi-"}
: ${THREADS:="$(($(cat /proc/cpuinfo | grep "^processor" | wc -l) / 4 * 3 + 1))"}

[ -n "${1}" ] || echo "Use ${0} [hammerhead_defconfig] or ${0} [zImage-dtb]"

mkdir -p ${OUT}/kernel/${VENDOR}/${DEVICE}

CCACHE_DIR="${CCACHE_DIR}" make ARCH=${ARCH} \
	CROSS_COMPILE="ccache ${DIR}/${GCC}" \
	-C ${DIR}/kernel/${VENDOR}/${DEVICE} \
	O=${OUT}/kernel/${VENDOR}/${DEVICE} \
	-j${THREADS} ${@}
