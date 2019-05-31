#!/bin/sh
set -e
error () {
    echo "ERROR: $1"
    virsh domblklist $2 | tail -n+3 | cut -d' ' -f2
}

if [ $# -lt 1 ]; then error "Missing vm argument!"; exit 1; fi
vm=$1
if [ $# -lt 2 ]; then error "Missing device_path argument!" ${vm}; exit 1; fi
device_name=$2

virsh vol-delete \
      --pool default \
      --vol disk-${vm}-${device_name}.img || true

virsh vol-create-as \
      --pool default \
      --format qcow2 \
      --name disk-${vm}-${device_name}.img \
      --prealloc-metadata \
      --capacity 10G

volume_path=$(virsh vol-path --pool default disk-${vm}-${device_name}.img)


virsh attach-disk --domain ${vm} \
      --source ${volume_path} \
      --target ${device_name} \
      --driver qemu \
      --subdriver qcow2 \
      --targetbus virtio \
      --cache none --live --persistent || error "${device_name} is already taken!" ${vm}
