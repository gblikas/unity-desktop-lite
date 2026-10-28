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

set -uo pipefail
# Lifecycle commands can run with umask 0000; keep everything this script creates private.
umask 077

UNITY="${UNITY_INSTALL_DIR:-/opt/unity}/Editor/Unity"
LOG_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/unity-license"
SERIAL_LICENSE="${HOME}/.local/share/unity3d/Unity/Unity_lic.ulf"
NAMED_USER_LICENSES="${HOME}/.config/unity3d/Unity/licenses"
VNC_PASSWD_FILE=/usr/local/etc/vscode-dev-containers/vnc-passwd

log() {
    echo "[unity-license] $*"
}

# Use sudo to run as root when required
sudoIf() {
    if [ "$(id -u)" -ne 0 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

has_license() {
    [ -s "${SERIAL_LICENSE}" ] || compgen -G "${NAMED_USER_LICENSES}/*.xml" > /dev/null
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
    log "Add them at https://github.com/settings/codespaces with access to this repository, then restart the codespace."
    log "Run unity-license from a VS Code terminal: terminals in the noVNC desktop don't receive Codespaces secrets."
}

# run_unity <log file> <arguments...>: runs the Editor in batch mode with a private log.
run_unity() {
    local log_file="$1"
    shift
    mkdir -p "${LOG_DIR}"
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

activate() {
    set_vnc_password
    if has_license; then
        log "A Unity license is already active."
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
    # Unity expects the license folders to exist and be writable.
    mkdir -p "$(dirname "${SERIAL_LICENSE}")" "${NAMED_USER_LICENSES}"
    local args=(-serial)
    # Without a serial key, -serial activates a named-user (assigned) license.
    [ -n "${UNITY_SERIAL:-}" ] && args+=("${UNITY_SERIAL}")
    args+=(-username "${UNITY_USERNAME}" -password "${UNITY_PASSWORD}")
    log "Activating the Unity license (this can take a minute)..."
    if run_unity "${LOG_DIR}/activate.log" "${args[@]}" && has_license; then
        # Unity's log lists its command-line arguments; don't keep it around.
        rm -f "${LOG_DIR}/activate.log"
        log "Unity license activated. Run 'unity-license return' before deleting this codespace to free the seat."
    else
        log "Unity license activation failed; see ${LOG_DIR}/activate.log (delete it when done, it may contain your account details)."
    fi
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
    if run_unity "${LOG_DIR}/return.log" -returnlicense -username "${UNITY_USERNAME}" -password "${UNITY_PASSWORD}"; then
        rm -f "${LOG_DIR}/return.log"
        log "Unity license returned."
    else
        log "Returning the license failed; see ${LOG_DIR}/return.log"
        log "You can also remove the activation at https://id.unity.com (My Account > My Seats)."
        return 1
    fi
}

status() {
    if has_license; then
        log "A Unity license is active."
    else
        log "No Unity license is active."
    fi
}

case "${1:-activate}" in
    activate) activate ;;
    return) return_license ;;
    status) status ;;
    *)
        echo "usage: unity-license [activate|return|status]" >&2
        exit 2
        ;;
esac
