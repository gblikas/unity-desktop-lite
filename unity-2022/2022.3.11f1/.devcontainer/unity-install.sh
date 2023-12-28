#!/bin/bash
set -e -x

if [ -z ${UNITY_DOWNLOAD_HASH} ]; then
    echo "UNITY_DOWNLOAD_HASH is unset"
    exit 1
fi

if [ -z ${UNITY_VERSION} ]; then
    echo "UNITY_VERSION is unset"
    exit 1
fi

if [ -z ${UNITY_INSTALL_DIR} ]; then
    echo "UNITY_INSTALL_DIR is unset"
    exit 1
fi

UNITY_SETUP_URL=https://download.unity3d.com/download_unity/${UNITY_DOWNLOAD_HASH}/UnitySetup-${UNITY_VERSION}
UNITY_SETUP_TMP=/tmp/UnitySetup

wget -O ${UNITY_SETUP_TMP} ${UNITY_SETUP_URL}
chmod +x ${UNITY_SETUP_TMP}
mkdir -p ${UNITY_INSTALL_DIR}
yes | ${UNITY_SETUP_TMP} --unattended --install-location=${UNITY_INSTALL_DIR} --components=Unity,Android
chmod -R a+rx ${UNITY_INSTALL_DIR}/Editor/Unity