#!/bin/bash
echo "Installing Unity"
yes | /tmp/UnitySetup --unattended --install-location=/opt/unity --components=Unity,Android
echo "Done installing Unity"