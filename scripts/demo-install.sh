#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
demo_hdc=/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc
demo_targets=$("$demo_hdc" list targets)
if [[ "$demo_targets" == *"[Empty]"* ]]; then
  print -u2 "没有已连接的鸿蒙模拟器或设备"
  exit 1
fi
"$demo_hdc" install entry/build/default/outputs/default/entry-default-unsigned.hap
"$demo_hdc" shell aa start -a EntryAbility -b com.fridgewidget.demo
