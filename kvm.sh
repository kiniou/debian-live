#!/bin/sh
set -e

if [ ! -f /tmp/kvm.vars.fd ];then
    cp -f /usr/share/OVMF/OVMF_VARS.fd /tmp/kvm.vars.fd
fi

kvm -serial stdio \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \
  -drive if=pflash,format=raw,readonly=on,file=/tmp/kvm.vars.fd \
  -drive if=ide,file="${1}" \
  -m 4096 -display gtk -enable-kvm -smp cpus=6 \
