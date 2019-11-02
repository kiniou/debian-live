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
ISO_LOOP="$(get_loop_device "${1}")"
if [ -z "${ISO_LOOP}" ];then
    ISO_LOOP="$(losetup --show -P -f "${1}")"
    log_info "${1} looped on ${ISO_LOOP} 🙌"
else
    log_warn "${1} already looped on ${ISO_LOOP} 🤷"
fi

mount_or_remount "${ISO_LOOP}" "${ISO_MOUNT}"

USB_FILE="$(realpath ./usb.img)"
log_info "Looping ${USB_FILE}"
USB_LOOP="$(get_loop_device "${USB_FILE}")"
if [ -z "${USB_LOOP}" ]; then
    USB_LOOP="$(losetup --show -P -f "${USB_FILE}")"
fi
log_info "${USB_FILE} looped on ${USB_LOOP} 🙌"

persistence_configuration () {
    cat <<EOF
/ union
EOF
}

copy_files () {
    case $1 in
        *lbu-efi)
            USB_EFI="${1}"
            log_info "copying EFI files..."
            rsync --info=progress2 -a "${ISO_MOUNT}/EFI" "${USB_EFI}/"
            ;;
        *lbu-root)
            USB_ROOT="${1}"
            log_info "copying Live USB files..."
            rsync --info=progress2 -a -f "- EFI" "${ISO_MOUNT}/" "${USB_ROOT}/"
            ;;
        *lbu-persistence)
            log_info "prepare persistence files ..."
            persistence_configuration > "${1}/persistence.conf"
            log_info "persistence configuration:"
            cat "${1}/persistence.conf"
            ;;
        *)
            echo "${1}"
            ;;
    esac
}

parts=$(ls -1 "${USB_LOOP}"p*)
for part in $parts; do
    PARTLABEL=$(blkid -o export "${part}" | grep -E "^PARTLABEL" | sed -e "s/^PARTLABEL=//")
    if [ ! -z "${PARTLABEL}" ];then
        dst="${BASE}/${PARTLABEL}"
        mount_or_remount "${part}" "${dst}"
        copy_files "${dst}"
    else
        log_error "${part} does not have a PARTLABEL assigned! 😱"
    fi
done

echo "USB_EFI:  ${USB_EFI}"
echo "USB_ROOT: ${USB_ROOT}"

grub-install --no-uefi-secure-boot --removable --target=x86_64-efi \
             --boot-directory="${USB_ROOT}/boot" \
             --efi-directory="${USB_EFI}" \
             "${USB_LOOP}"
