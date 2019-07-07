#!/bin/sh

set -e

cd "$(dirname "${0}")"

. ./functions.sh

if [ "$(id -u)" -ne 0 ]; then
    log_error "Must execute the script as root!"
    exit 1;
fi

if [ -z "$1" ]; then
    log_error "Pass the live iso file as argument"
fi

if [ ! -f "$1" ]; then
    log_error "live iso is not a file 🤷"
fi
BASE="/mnt/live-build"
mkdir -vp "${BASE}"
ISO_MOUNT="${BASE}/iso"

log_info "Looping ${1}."
ISOLOOP="$(get_loop_device "${1}")"
if [ -z "${ISOLOOP}" ];then
    ISOLOOP="$(losetup --show -P -f "${1}")"
fi
log_info "${1} looped on ${ISOLOOP} 🙌"

log_info "Mounting ${ISOLOOP} on ${ISO_MOUNT}"
mkdir -vp "${ISO_MOUNT}"
mount -o loop "${ISOLOOP}" "${ISO_MOUNT}"
log_info "${ISOLOOP} mounted on ${ISO_MOUNT} 🙌"

USB_FILE="$(realpath ./usb.img)"
log_info "Looping ${USB_FILE}"
USBLOOP="$(get_loop_device "${USB_FILE}")"
if [ -z "${USBLOOP}" ]; then
    USBLOOP="$(losetup --show -P -f "${USB_FILE}")"
fi
log_info "${USB_FILE} looped on ${USBLOOP} 🙌"

parts=$(ls -1 "${USBLOOP}"p*)
for part in $parts; do
    PARTLABEL=$(blkid -o export "${part}" | grep -E "^PARTLABEL" | sed -e "s/^PARTLABEL=//")
    if [ ! -z "${PARTLABEL}" ];then
        dst="${BASE}/${PARTLABEL}"
        log_info "Mounting ${part} on ${dst}"
        mkdir -p "${dst}"
        mount -o loop "${part}" "${dst}"
        log_info "${part} mounted on ${dst} 🙌"
    else
        log_error "${part} does not have a PARTLABEL assigned! 😱"
    fi
done
