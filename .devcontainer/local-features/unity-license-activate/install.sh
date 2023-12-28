#!/bin/bash

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

if [ -z "${VNC_PASSWORD}" ]; then
    echo "VNC_PASSWORD is not set"
    exit 1
fi

echo "${VNC_PASSWORD}" | vncpasswd -f > /usr/local/etc/vscode-dev-containers/vnc-passwd

if [ -z "${UNITY_USERNAME}" ]; then
    echo "UNITY_USERNAME is not set"
    exit 1
fi

if [ -z "${UNITY_PASSWORD}" ]; then
    echo "UNITY_PASSWORD is not set"
    exit 1
fi

if [ -z "${UNITY_SERIAL}" ]; then
    echo "UNITY_SERIAL is not set"
    exit 1
fi

if [ -z "${UNITY_INSTALL_DIR}" ]; then
    echo "UNITY_INSTALL_DIR is not set"
    exit 1
fi

set -x

# remove all licenses
sudo -u ${USERNAME} ${UNITY_INSTALL_DIR}/Editor/Unity \
        -quit \
        -batchmode \
        -returnlicense \
        -username ${UNITY_USERNAME} \
        -password ${UNITY_PASSWORD} \
        -logFile -

sudo -u ${USERNAME} ${UNITY_INSTALL_DIR}/Editor/Unity \
        -quit \
        -batchmode \
        -nographics \
        -serial ${UNITY_SERIAL} \
        -username ${UNITY_USERNAME} \
        -password ${UNITY_PASSWORD} \
        -logFile -
