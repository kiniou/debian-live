#!/bin/sh
mount /dev/disk/by-partlabel/live_bios_efi /mnt/efi
mount /dev/disk/by-partlabel/live_data /mnt/data
mount -o loop live-image-amd64.iso /mnt/cdrom
