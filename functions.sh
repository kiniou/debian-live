CRESET="\\e[0m"
CERROR="\\e[31m"
CINFO="\\e[34m"
CWARN="\\e[33m"

log () {
    echo "$*"
}

log_info () {
    echo "${CINFO}INFO: $*${CRESET}"
}
log_error () {
    echo "${CERROR}ERROR: $*${CRESET}"
}
log_warn () {
    echo "${CWARN}WARN: $*${CRESET}"
}

get_loop_device () {
    local LOOP_DEVICE=""
    if [ -f "${1}" ]; then
        LOOP_DEVICE=$(losetup -j "${1}" | awk -F : -- '{ print $1 }')
    fi
    echo "${LOOP_DEVICE}"
    return 0
}

wait_for_part () {
    set +e
    local trial=5;
    while test ${trial} -gt 0;do
        if test -e "$1" -a -b "$1";then
            return 0
        fi
        log_info "Waiting for $1 block device..."
        sleep 0.01
        trial=$(("${trial}" - 1))
    done
    set -e
    return 1
}

mount_or_remount () {
    local source="${1}"; local target="${2}"
    if [ -z "${source}" ] || [ -z "${target}" ]
    then
        log_error "Remount failed missing argument: source='${source}' target='${target}'"
        return 1
    fi
    log_info "Mounting ${source} on ${target}"
    mkdir -vp "${target}"
    if findmnt -P "${target}"
    then
        umount "${target}"
    fi
    mount "${source}" "${target}"
    log_info "${source} mounted on ${target} 🙌"

}
