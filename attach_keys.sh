#!/usr/bin/env bash
# {{{ source ../vendor/std/src/log/error.sh
#!/usr/bin/env bash
# {{{ source ../vendor/std/src/runtime/stack_trace.sh
#!/usr/bin/env bash
function runtime::stack_trace() {
    local i=${1:-0}
    while caller $i; do
        ((i++))
    done | awk '{print  "[" NR "] " $3 ":" $1 " " $2}'
}
# }}} source ../vendor/std/src/runtime/stack_trace.sh
# Print error message and stack trace to stderr with timestamp
function log::error() {
    echo "[$(date +%Y-%m-%dT%H:%M:%S%z)] ERROR ${*}" >&2
    runtime::stack_trace 1 >&2
}
# }}} source ../vendor/std/src/log/error.sh
# {{{ source ../vendor/std/src/log/info.sh
#!/usr/bin/env bash
# {{{ source ../vendor/std/src/log/is_output.sh
#!/usr/bin/env bash
# {{{ source ../vendor/std/src/log/verbose.sh
#!/usr/bin/env bash
# get verbose level
function log::verbose() {
    echo "${LOG_VERBOSE:-0}"
}
# }}} source ../vendor/std/src/log/verbose.sh
# whether to output
function log::is_output() {
    local v="${1}"
    if [[ "${v}" -gt "$(log::verbose)" ]]; then
        return 1
    fi
}
# }}} source ../vendor/std/src/log/is_output.sh
# Print message to stderr with timestamp
function log::info() {
    local v="0"
    local key
    if [[ $# -gt 1 ]]; then
        key="${1}"
        case ${key} in
        -v | -v=*)
            [[ "${key#*=}" != "$key" ]] && v="${key#*=}" || { v="${2}" && shift; }
            if ! log::is_output "${v}" ; then
                return
            fi
            shift
            ;;
        *) ;;
        esac
    fi
    if [[ "${v}" -gt 0 ]]; then
        echo "[$(date +%Y-%m-%dT%H:%M:%S%z)] INFO(${v}) ${*}" >&2
        return
    fi
    echo "[$(date +%Y-%m-%dT%H:%M:%S%z)] INFO ${*}" >&2
}
# }}} source ../vendor/std/src/log/info.sh
# {{{ source ../vendor/std/src/runtime/command_exist.sh
#!/usr/bin/env bash
# Check a command exist
function runtime::command_exist() {
  local command="${1}"
  type "${command}" >/dev/null 2>&1
}
# }}} source ../vendor/std/src/runtime/command_exist.sh
# {{{ source ../vendor/std/src/http/cat.sh
#!/usr/bin/env bash
# source ../vendor/std/src/runtime/command_exist.sh # Embed file already embedded by attach_keys.sh
# source ../vendor/std/src/log/error.sh # Embed file already embedded by attach_keys.sh
# source ../vendor/std/src/log/info.sh # Embed file already embedded by attach_keys.sh
# source ../vendor/std/src/log/is_output.sh # Embed file already embedded by ../vendor/std/src/log/info.sh
# Cat a file from http url to stdout
# like unix cat command
function http::cat() {
    local url="${1}"
    log::info -v=1 "Cat from url ${url}"
    if runtime::command_exist curl; then
        if log::is_output 4; then
            curl -L "${url}"
        else
            curl -sSL "${url}"
        fi
    elif runtime::command_exist wget; then
        if log::is_output 4; then
            wget -q -O - "${url}"
        else
            wget -O - "${url}"
        fi
    else
        log::error "Neither curl nor wget are available"
        exit 1
    fi
}
# }}} source ../vendor/std/src/http/cat.sh
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

#
# ../vendor/std/src/log/verbose.sh is quoted by ../vendor/std/src/log/is_output.sh
# ../vendor/std/src/http/cat.sh is quoted by attach_keys.sh
# ../vendor/std/src/runtime/command_exist.sh is quoted by attach_keys.sh ../vendor/std/src/http/cat.sh
# ../vendor/std/src/log/is_output.sh is quoted by ../vendor/std/src/log/info.sh ../vendor/std/src/http/cat.sh
# ../vendor/std/src/runtime/stack_trace.sh is quoted by ../vendor/std/src/log/error.sh
# ../vendor/std/src/log/error.sh is quoted by attach_keys.sh ../vendor/std/src/http/cat.sh
# ../vendor/std/src/log/info.sh is quoted by attach_keys.sh ../vendor/std/src/http/cat.sh
