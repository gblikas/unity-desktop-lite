#!/bin/bash
set -x

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

# required to make sure the variables are exported to the terminal
echo "export UNITY_USERNAME=${UNITY_USERNAME}" >> /etc/profile.d/unity_activate_license.sh
echo "export UNITY_PASSWORD=${UNITY_PASSWORD}" >> /etc/profile.d/unity_activate_license.sh
echo "export UNITY_SERIAL=${UNITY_SERIAL}" >> /etc/profile.d/unity_activate_license.sh

# remove all licenses
${UNITY_INSTALL_DIR}/Editor/Unity \
        -quit \
        -batchmode \
        -returnlicense \
        -username ${UNITY_USERNAME} \
        -password ${UNITY_PASSWORD} \
        -logFile -

${UNITY_INSTALL_DIR}/Editor/Unity \
        -quit \
        -batchmode \
        -nographics \
        -serial ${UNITY_SERIAL} \
        -username ${UNITY_USERNAME} \
        -password ${UNITY_PASSWORD} \
        -logFile -
chmod +x /etc/profile.d/unity_activate_license.sh
