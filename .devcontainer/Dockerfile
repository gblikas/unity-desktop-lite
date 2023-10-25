# Use a base image with necessary dependencies for Unity
FROM mcr.microsoft.com/vscode/devcontainers/javascript-node:0-18

# Arguments to allow customization
ARG UNITY_VERSION=2022.3.11f1
ARG UNITY_DOWNLOAD_HASH=d00248457e15

# Install necessary dependencies and common libraries
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y wget libgtk-3-0 libarchive13 build-essential

# Download UnitySetup to the temp directory
RUN wget -O /tmp/UnitySetup https://download.unity3d.com/download_unity/${UNITY_DOWNLOAD_HASH}/UnitySetup-${UNITY_VERSION}
RUN chmod +x /tmp/UnitySetup
RUN mkdir /opt/unity

COPY unity_install.sh /tmp/unity_install.sh

RUN chmod +x /tmp/unity_install.sh

RUN /tmp/unity_install.sh
