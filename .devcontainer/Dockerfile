# Use a base image with necessary dependencies for Unity
FROM mcr.microsoft.com/vscode/devcontainers/javascript-node:0-18

# Arguments to allow customization
ARG UNITY_VERSION=2022.3.11f1
ARG UNITY_DOWNLOAD_HASH=d00248457e15

RUN wget -O /tmp/UnitySetup https://download.unity3d.com/download_unity/${UNITY_DOWNLOAD_HASH}/UnitySetup-${UNITY_VERSION}
RUN chmod +x /tmp/UnitySetup
RUN mkdir -p /opt/unity

ARG UNITY_USERNAME=${UNITY_USERNAME:-"username"}
ENV UNITY_USERNAME=${UNITY_USERNAME}

ARG UNITY_PASSWORD=${UNITY_PASSWORD:-"password"}
ENV UNITY_PASSWORD=${UNITY_PASSWORD}

ARG UNITY_SERIAL=${UNITY_SERIAL:-"serial"}
ENV UNITY_SERIAL=${UNITY_SERIAL}

ARG UNITY_ULF=${UNITY_ULF:-"ulf"}
ENV UNITY_ULF=${UNITY_ULF}
ENV UNITY_LICENSE_FILE=/opt/unity/UnityLicenseFie.ulf
RUN echo "$UNITY_ULF" > ${UNITY_LICENSE_FILE}

# export crucial variables for the terminal shell. should work on race contition
RUN echo "export UNITY_USERNAME=${UNITY_USERNAME}" >> /etc/profile.d/unity_envs.sh
RUN echo "export UNITY_PASSWORD=${UNITY_PASSWORD}" >> /etc/profile.d/unity_envs.sh
RUN echo "export UNITY_SERIAL=${UNITY_SERIAL}" >> /etc/profile.d/unity_envs.sh
RUN echo "export UNITY_LICENSE_FILE=${UNITY_LICENSE_FILE}" >> /etc/profile.d/unity_envs.sh
RUN chmod +x /etc/profile.d/unity_envs.sh

# create a new license file each time the terminal is opened
RUN echo "echo \"=================\"" >> /etc/profile.d/unity_license.sh
RUN echo "echo \"start unity license\"" >> /etc/profile.d/unity_license.sh
RUN echo "echo \"=================\"" >> /etc/profile.d/unity_license.sh
RUN echo "/opt/unity/Editor/Unity \
        -quit \
        -batchmode \
        -returnlicense \
        -username ${UNITY_USERNAME} \
        -password ${UNITY_PASSWORD} \ 
        -logfile - || \
        true" >> /etc/profile.d/unity_license.sh
RUN echo "echo \"=================\"" >> /etc/profile.d/unity_license.sh
RUN echo "echo \"start unity license activate\"" >> /etc/profile.d/unity_license.sh
RUN echo "echo \"=================\"" >> /etc/profile.d/unity_license.sh
RUN echo "/opt/unity/Editor/Unity \
        -quit \
        -batchmode \
        -nographics \
        -serial ${UNITY_SERIAL} \
        -username ${UNITY_USERNAME} \
        -password ${UNITY_PASSWORD} \
        -logfile -" >> /etc/profile.d/unity_license.sh
RUN echo "echo \"=================\"" >> /etc/profile.d/unity_license.sh
RUN echo "echo \"end unity license\"" >> /etc/profile.d/unity_license.sh
RUN echo "echo \"=================\"" >> /etc/profile.d/unity_license.sh

RUN chmod +x /etc/profile.d/unity_license.sh

# install noVNC, along with Unity and activate it's license. 
COPY install.sh /tmp/install.sh
RUN chmod +x /tmp/install.sh 
RUN /tmp/install.sh

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

