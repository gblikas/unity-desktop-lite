# Use a base image with necessary dependencies for Unity
FROM mcr.microsoft.com/devcontainers/base:ubuntu

##################################################################
# install noVNC, as per https://github.com/devcontainers/features/blob/main/src/desktop-lite/install.sh
##################################################################
COPY install.sh /tmp/install.sh
RUN chmod +x /tmp/install.sh 
RUN /tmp/install.sh

ARG UNITY_VERSION=2022.3.11f1
ENV UNITY_VERSION=${UNITY_VERSION}
ARG UNITY_DOWNLOAD_HASH=d00248457e15
ENV UNITY_DOWNLOAD_HASH=${UNITY_DOWNLOAD_HASH}
ARG UNITY_INSTALL_DIR=/opt/unity
ENV UNITY_INSTALL_DIR=${UNITY_INSTALL_DIR}

##################################################################
# install Unity
##################################################################
COPY unity-installer.sh /tmp/unity-installer.sh
RUN chmod +x /tmp/unity-installer.sh
RUN /tmp/unity-installer.sh

##################################################################
# activate Unity license
##################################################################
ARG UNITY_USERNAME=${UNITY_USERNAME:-"username"}
ENV UNITY_USERNAME=${UNITY_USERNAME}
ARG UNITY_PASSWORD=${UNITY_PASSWORD:-"password"}
ENV UNITY_PASSWORD=${UNITY_PASSWORD}
ARG UNITY_SERIAL=${UNITY_SERIAL:-"serial"}
ENV UNITY_SERIAL=${UNITY_SERIAL}

RUN echo "UNITY_USERNAME=${UNITY_USERNAME}"
RUN echo "UNITY_PASSWORD=${UNITY_PASSWORD}"
RUN echo "UNITY_SERIAL=${UNITY_SERIAL}"

COPY unity-activate-license.sh /tmp/unity-activate-license.sh
RUN chmod +x /tmp/unity-activate-license.sh
RUN /tmp/unity-activate-license.sh

##################################################################
# terminal settings and prefs
##################################################################
COPY terminal-settings.sh /tmp/terminal-settings.sh
RUN chmod +x /tmp/terminal-settings.sh
RUN /tmp/terminal-settings.sh

ENV DBUS_SESSION_BUS_ADDRESS="autolaunch:" \
    VNC_RESOLUTION="1440x768x16" \
    VNC_DPI="96" \
    VNC_PORT="5901" \
    NOVNC_PORT="6080" \
    DISPLAY=":1" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8"
ENTRYPOINT ["/usr/local/share/desktop-init.sh"]
CMD ["sleep", "infinity"]

