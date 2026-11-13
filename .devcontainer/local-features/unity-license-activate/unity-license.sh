#!/bin/bash
#
# unity-license: activates, returns or reports the Unity Editor license inside the
# running container. The feature runs `unity-license activate` as its postStartCommand.
#
# Credentials are read from the environment, where Codespaces puts your secrets once
# the codespace is running (lifecycle scripts and VS Code terminals; terminals opened
# inside the noVNC desktop do not get them):
#   UNITY_USERNAME, UNITY_PASSWORD   Unity ID used for activation (required)
#   UNITY_SERIAL                     serial key; leave unset for named-user seats
#   VNC_PASSWORD                     optional password for the noVNC desktop
#
# Never enable xtrace (set -x) in this script: it would print the credentials.
set +x

set -uo pipefail
# Lifecycle commands can run with umask 0000; keep everything this script creates private.
umask 077

UNITY="${UNITY_INSTALL_DIR:-/opt/unity}/Editor/Unity"
LOG_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/unity-license"
# Where Unity's licensing client keeps serial and named-user licenses.
SERIAL_LICENSE="${XDG_DATA_HOME:-${HOME}/.local/share}/unity3d/Unity/Unity_lic.ulf"
NAMED_USER_LICENSES="${XDG_CONFIG_HOME:-${HOME}/.config}/unity3d/Unity/licenses"
VNC_PASSWD_FILE=/usr/local/etc/vscode-dev-containers/vnc-passwd

log() {
    echo "[unity-license] $*"
}

usage() {
    echo "usage: unity-license [activate [--force]|return|status]" >&2
    exit 2
}

# The license and the desktop belong to the container's user. Under sudo both would become root's.
if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    echo "unity-license: run this as ${SUDO_USER}, without sudo." >&2
    exit 2
fi

# Use sudo to run as root when required
sudoIf() {
    if [ "$(id -u)" -ne 0 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

# True when a license file is present. Unity only checks it against its servers when the
# Editor starts, so a file can outlive an activation removed at id.unity.com.
has_license() {
    [ -s "${SERIAL_LICENSE}" ] && return 0
    local file
    for file in "${NAMED_USER_LICENSES}"/*.xml; do
        [ -s "${file}" ] && return 0
    done
    return 1
}

# Prints the names (never the values) of required credentials that are not set.
missing_credentials() {
    local name missing=()
    for name in UNITY_USERNAME UNITY_PASSWORD; do
        [ -n "${!name:-}" ] || missing+=("${name}")
    done
    echo "${missing[*]}"
}

explain_missing_credentials() {
    log "In Codespaces, add them at https://github.com/settings/codespaces with access to this repository, then restart the codespace. GitHub passes secrets only to people with write access, and not on pull requests from forks."
    log "Elsewhere (local Dev Containers, or a terminal inside the noVNC desktop), export them in the terminal and run this command again."
}

# Unity stops reading a command-line value at a dash followed by a non-digit.
warn_about_password() {
    case "${UNITY_PASSWORD}" in
        -[!0-9]*) log "Warning: Unity cannot read a password that starts with '-' from its command line, so this will probably fail." ;;
    esac
}

# logged <log file> <pattern>: true when Unity's log has a line matching the pattern.
logged() {
    grep -q -E "$2" "$1" 2> /dev/null
}

# run_unity <log file> <arguments...>: runs the Editor in batch mode with a private log.
run_unity() {
    local log_file="$1"
    shift
    mkdir -p "${LOG_DIR}"
    # Start from an empty log: a run must never be judged by the log of an earlier one.
    : > "${log_file}"
    # A hung activation must not block the codespace from starting.
    timeout 600 "${UNITY}" -quit -batchmode -nographics "$@" -logFile "${log_file}" > /dev/null 2>&1
}

set_vnc_password() {
    [ -n "${VNC_PASSWORD:-}" ] || return 0
    if ! command -v vncpasswd > /dev/null; then
        log "VNC_PASSWORD is set, but vncpasswd is not installed; keeping the image's VNC password."
        return 0
    fi
    # The desktop's VNC server runs as the container's remote user (this script's user) and
    # re-reads the password file on every connection.
    local tmp
    tmp="$(mktemp)"
    if printf '%s\n' "${VNC_PASSWORD}" | vncpasswd -f > "${tmp}" \
        && sudoIf install -m 600 -o "$(id -u)" -g "$(id -g)" "${tmp}" "${VNC_PASSWD_FILE}"; then
        log "Desktop (VNC) password set from VNC_PASSWORD."
    else
        log "Could not set the desktop (VNC) password; keeping the image's VNC password."
    fi
    rm -f "${tmp}"
}

# activate [--force]: with --force, replaces the license files that are already present.
activate() {
    set_vnc_password
    if has_license && [ "${1:-}" != "--force" ]; then
        log "A Unity license file is already present; not activating again."
        log "If the Editor rejects it, run 'unity-license activate --force'."
        return 0
    fi
    local missing
    missing="$(missing_credentials)"
    if [ -n "${missing}" ]; then
        log "Unity license not activated: ${missing} not set."
        explain_missing_credentials
        return 0
    fi
    if [ ! -x "${UNITY}" ]; then
        log "Unity Editor not found at ${UNITY}."
        return 0
    fi
    warn_about_password
    # Unity expects the license folders to exist and be writable.
    mkdir -p "$(dirname "${SERIAL_LICENSE}")" "${NAMED_USER_LICENSES}" "${LOG_DIR}"
    # Only reached with a license file when --force was given. Start as a new container would,
    # but keep the old files until the new activation has worked.
    local replaced=""
    if has_license; then
        replaced="$(mktemp -d "${LOG_DIR}/replaced.XXXXXX")"
        mv -f "${SERIAL_LICENSE}" "${NAMED_USER_LICENSES}"/*.xml "${replaced}/" 2> /dev/null
    fi
    local args=(-serial)
    # Without a serial key, -serial activates a named-user (assigned) license.
    [ -n "${UNITY_SERIAL:-}" ] && args+=("${UNITY_SERIAL}")
    args+=(-username "${UNITY_USERNAME}" -password "${UNITY_PASSWORD}")
    log "Activating the Unity license (this can take a minute)..."
    # The Editor exits with 0 only after its license check has passed.
    if run_unity "${LOG_DIR}/activate.log" "${args[@]}" && has_license; then
        # Unity's log can contain account details; don't keep it around.
        rm -f "${LOG_DIR}/activate.log"
        log "Unity license activated. Run 'unity-license return' before deleting this codespace to free the seat."
    else
        log "Unity license activation failed; see ${LOG_DIR}/activate.log (delete it when done, it may contain your account details)."
        if [ -n "${replaced}" ]; then
            rm -f "${SERIAL_LICENSE}" "${NAMED_USER_LICENSES}"/*.xml
            [ -e "${replaced}/${SERIAL_LICENSE##*/}" ] && mv -f "${replaced}/${SERIAL_LICENSE##*/}" "${SERIAL_LICENSE}"
            mv -f "${replaced}"/*.xml "${NAMED_USER_LICENSES}/" 2> /dev/null
            log "The previous license files were put back."
        fi
    fi
    [ -n "${replaced}" ] && rm -rf "${replaced}"
    return 0
}

return_license() {
    local missing
    missing="$(missing_credentials)"
    if [ -n "${missing}" ]; then
        log "Cannot return the license: ${missing} not set."
        explain_missing_credentials
        return 1
    fi
    if [ ! -x "${UNITY}" ]; then
        log "Cannot return the license: Unity Editor not found at ${UNITY}."
        return 1
    fi
    warn_about_password
    local returned=""
    run_unity "${LOG_DIR}/return.log" -returnlicense -username "${UNITY_USERNAME}" -password "${UNITY_PASSWORD}"
    # Unity's exit status is not the result: after returning a named-user license it still exits
    # with an error, because it then looks for a serial license to return as well. So go by its
    # log, and remove the file of each license it returned (without it, the next start activates
    # again).
    if logged "${LOG_DIR}/return.log" "Successfully returned the entitlement license"; then
        rm -f "${NAMED_USER_LICENSES}"/*.xml
        returned=yes
    fi
    if logged "${LOG_DIR}/return.log" "Successfully returned ULF license"; then
        rm -f "${SERIAL_LICENSE}"
        returned=yes
    fi
    if has_license; then
        log "Returning the license failed; see ${LOG_DIR}/return.log (delete it when done, it may contain your account details)."
        log "You can also remove the activation at https://id.unity.com (My Account > My Seats)."
        return 1
    fi
    if [ -n "${returned}" ]; then
        rm -f "${LOG_DIR}/return.log"
        log "Unity license returned."
    else
        log "Unity did not report a returned license, and no license file is present here; see ${LOG_DIR}/return.log (delete it when done, it may contain your account details)."
        log "If a seat is still listed at https://id.unity.com (My Account > My Seats), remove it there."
    fi
    return 0
}

status() {
    if has_license; then
        log "A Unity license file is present."
    else
        log "No Unity license file is present."
    fi
}

[ "$#" -le 2 ] || usage
case "${1:-activate} ${2:-}" in
    "activate " | "activate --force") activate "${2:-}" ;;
    "return ") return_license ;;
    "status ") status ;;
    *) usage ;;
esac
