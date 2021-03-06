#!/bin/sh
#
# Jailhouse, a Linux-based partitioning hypervisor
#
# Copyright (c) Siemens AG, 2018
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: GPL-2.0
#

usage()
{
	echo "Usage: $0 ARCHITECTURE [QEMU_OPTIONS]"
	echo -e "\nSet QEMU_PATH environment variable to use a locally " \
		"built QEMU version"
	exit 1
}

if [ -n "${QEMU_PATH}" ]; then
	QEMU_PATH="${QEMU_PATH}/"
fi

case "$1" in
	x86|x86_64|amd64)
		DISTRO_ARCH=amd64
		QEMU=qemu-system-x86_64
		;;
	""|--help)
		usage
		;;
	*)
		echo "Unsupported architecture: $1"
		exit 1
		;;
esac

IMAGE_BUILD_DIR="$(dirname $0)/out/"

shift 1

${QEMU_PATH}${QEMU} \
	-drive file=${IMAGE_BUILD_DIR}/build/tmp/deploy/images/demo-image-debian-stretch-qemu${DISTRO_ARCH}.ext4.img,discard=unmap,if=none,id=disk,format=raw \
	-device ide-hd,drive=disk -m 1G -enable-kvm -smp 4 \
	-serial mon:stdio -serial vc \
	-cpu kvm64,-kvm_pv_eoi,-kvm_steal_time,-kvm_asyncpf,-kvmclock,+vmx,+arat \
	-machine q35,kernel_irqchip=split \
	-device intel-iommu,intremap=on,x-buggy-eim=on \
	-device intel-hda,addr=1b.0 -device hda-duplex \
	-netdev user,id=net -device e1000e,addr=2.0,netdev=net \
	-kernel ${IMAGE_BUILD_DIR}/build/tmp/deploy/images/vmlinuz* \
	-append "intel_iommu=off memmap=66M\$0x3b000000 root=/dev/sda" \
	-initrd ${IMAGE_BUILD_DIR}/build/tmp/deploy/images/initrd.img* \
	"$@"
