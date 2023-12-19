#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/../vendor/std/src/log/error.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../vendor/std/src/log/info.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../vendor/std/src/runtime/command_exist.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../vendor/std/src/http/cat.sh"

# Attach ssh keys
function ssh::attach_keys() {
    local keys="${1}"
    local outfile="${2}"
    local outdir=""
    outdir="$(dirname "${outfile}")"

    if [ ! -d "${outdir}" ]; then
        log::info -v=1 "create directory ${outdir}"
        mkdir -p "$(dirname "${outfile}")"
    fi

    if [[ "${keys}" != *"/"* ]]; then
        keys="https://github.com/${keys}.keys"
    fi

    log::info -v=1 "get keys from ${keys}"
    newkeys="$(http::cat "${keys}")"
    if [ -z "${newkeys}" ]; then
        log::error "get keys failed"
        return 1
    fi

    if [ ! -f "${outfile}" ]; then
        log::info -v=1 "create file ${outfile} and add keys"
        echo "${newkeys}" >"${outfile}"
        return 0
    fi

    diffkeys="$(echo "${newkeys}" | grep -vxFf "${outfile}")"
    if [ -z "${diffkeys}" ]; then
        log::info -v=1 "no new keys"
        return 0
    fi

    log::info -v=1 "backup ${outfile}"
    cp "${outfile}" "${outfile}".bak

    log::info -v=1 "add new keys to ${outfile}"
    if [ -n "$(tail -c 1 "${outfile}")" ]; then
        echo >>"${outfile}"
    fi
    echo "${diffkeys}" >>"${outfile}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    function usage() {
        echo "Usage: $0 [keys] [authorized_keys_path]"
        echo
        echo "Options:"
        echo "  keys      The github id or keys url"
        echo "  outfile   The output to authorized_keys file"
        echo
        echo "Example:"
        echo "  $0 wzshiming"
        echo "  $0 wzshiming ~/.ssh/authorized_keys"
        echo "  $0 https://github.com/wzshiming.keys"
        echo "  $0 https://github.com/wzshiming.keys ~/.ssh/authorized_keys"
    }

    function main() {
        local keys="${1}"
        if [[ "${keys}" == "" ]]; then
            usage
            return 1
        fi
        local outfile="${2:-"${HOME}/.ssh/authorized_keys"}"
        ssh::attach_keys "${keys}" "${outfile}"
    }
    main "$@"
fi
