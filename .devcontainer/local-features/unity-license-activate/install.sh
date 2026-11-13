#!/bin/bash
#
# Installs the `unity-license` helper. The license itself is activated when the container
# starts (see postStartCommand in devcontainer-feature.json): Codespaces secrets are not
# available while the image is built, and anything passed to a feature at build time is
# printed to the build log.

set -e

install -m 0755 "$(dirname "$0")/unity-license.sh" /usr/local/bin/unity-license
