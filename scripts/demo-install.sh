#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
demo_hdc=/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc
"$demo_hdc" install entry/build/default/outputs/default/entry-default-unsigned.hap
"$demo_hdc" shell aa start -a EntryAbility -b com.fridgewidget.demo
