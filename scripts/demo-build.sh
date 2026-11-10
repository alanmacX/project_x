#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
export NODE_HOME=/Applications/DevEco-Studio.app/Contents/tools/node
export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p product=default -p module=entry@default -p buildMode=debug assembleHap --no-daemon
