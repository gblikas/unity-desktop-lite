FROM mcr.microsoft.com/devcontainers/base:ubuntu

ENV UNITY_VERSION="2022.3.11f1"
ENV UNITY_DOWNLOAD_HASH="d00248457e15"
ENV UNITY_INSTALL_DIR=/opt/unity

##################################################################
# install noVNC, as per https://github.com/devcontainers/features/blob/main/src/desktop-lite/install.sh
##################################################################
COPY install.sh /tmp/install.sh
RUN chmod +x /tmp/install.sh 
RUN /tmp/install.sh

COPY unity-install.sh /tmp/unity-install.sh
RUN chmod +x /tmp/unity-install.sh
RUN /tmp/unity-install.sh

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

