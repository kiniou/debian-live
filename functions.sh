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
    LOOP_DEVICE=""
    if [ -f "${1}" ]; then
        LOOP_DEVICE=$(losetup -j "${1}" | awk -F : -- '{ print $1 }')
    fi
    echo "${LOOP_DEVICE}"
    return 0
}

wait_for_part () {
    set +e
    trial=5
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
