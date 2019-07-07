#!/bin/sh

set -e

cd "$(dirname "${0}")"

. ./functions.sh

if [ "$(id -u)" -ne 0 ]; then
    log_error "Must execute the script as root!"
    exit 1;
fi

# set -x

USB_FILE="$(realpath ./usb.img)"
if [ -f "${USB_FILE}" ]; then
    LOOPED="$(get_loop_device "${USB_FILE}")"

    if [ ! -z "${LOOPED}" ]; then
        log_info "${USB_FILE} already looped on ${LOOPED}."
        losetup -d "${LOOPED}";
        log_info "${USB_FILE} unlooped."
    fi
    rm "${USB_FILE}"
    log_warn "${USB_FILE} already created."
fi
log_info "creating ${USB_FILE}..."
fallocate -l 4G "${USB_FILE}"
log_info "${USB_FILE} created."


LOOP="$(get_loop_device "${USB_FILE}")"
if [ ! -z "$LOOP" ]; then
    losetup -d "${LOOP}"
fi
LOOP=$(losetup --show -f -P "${USB_FILE}")
log_info "${USB_FILE} has been successfully looped on ${LOOP}"

NUMPARTS=$(parted -s -m "${LOOP}" print 2>/dev/null | tail -n+3 | wc -l)
if [ "${NUMPARTS}" -gt 0 ]; then
    for i in $(seq 1 "$NUMPARTS");do
        parted -s "${LOOP}" rm "$i"
    done
fi


PARTED="parted -a optimal -s -m ${LOOP}"
log_info "creating GPT table on ${LOOP}"
${PARTED} mktable gpt

log_info "creating lbu-efi on ${LOOP}p1"
${PARTED} mkpart primary fat32 2048s 512MB
${PARTED} name 1 lbu-efi toggle 1 boot
${PARTED} print
wait_for_part "${LOOP}p1"
mkfs.vfat -n LBU_EFI "${LOOP}p1"

START_FREE_SECTOR="$(${PARTED} unit s print free | grep -E 'free;$' | tail -n1 | awk -F : -- '{print $2}')"
log_info "creating lbu-root on ${LOOP}p2"
${PARTED} mkpart primary ext4 "${START_FREE_SECTOR}" 2048MB
${PARTED} name 2 lbu-root
${PARTED} print
wait_for_part "${LOOP}p2"
mkfs.ext4 "${LOOP}p2"
tune2fs -L lbu-root "${LOOP}p2"


START_FREE_SECTOR="$(${PARTED} unit s print free | grep -E 'free;$' | tail -n1 | awk -F : -- '{print $2}')"
log_info "creating lbu-root on ${LOOP}p3"
${PARTED} mkpart primary ext4 "${START_FREE_SECTOR}" 100%
${PARTED} name 3 lbu-persistence
${PARTED} print
wait_for_part "${LOOP}p3"
mkfs.ext4 "${LOOP}p3"
tune2fs -L lbu-persistence "${LOOP}p3"
