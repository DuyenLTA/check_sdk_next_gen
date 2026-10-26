#!/bin/bash
# HT-09 / HT-07 / HV-06: film the onboarding OB3 full-screen native page frame by frame.
# OB3 only stays ~5 s before auto-swiping, and uiautomator (2-3 s per dump) sees too little and too late,
# so this starts screencapping the moment Firebase logs ob3_view and stamps every frame with DEVICE time.
#
# New user every run. Default launches OFFLINE and turns network back on at Language: the app then runs on
# default Remote Config, which is the only state where OB3 native has filled so far (real RC -> no-fill).
# PRE=fetch first opens the app online once so the real RC is fetched and activated, then does the same.
#
# usage: [PRE=fetch] capture-ob3-fullscreen-native-frames.sh <package> <out-dir> <tag> [back-at-s|none] [frames=22]
#   back-at-s : press BACK this many seconds after ob3_view (HV-06), or none
# writes in <out-dir>: log-<tag>.txt (threadtime), marks-<tag>.txt, <tag>-fNN-<device-epoch>.png,
#   <tag>-ob3.txt (device epochs of ob3_view / complete_ob3 / ob4_view / back_sent / back_done) -> feed to ob3_frames_montage.py
D=$(cd "$(dirname "$0")" && pwd)
P=$1; O=${2:-.}; TAG=${3:-ob3}; BACKAT=${4:-none}; N=${5:-22}
cd "$O" || exit 1
M=marks-$TAG.txt; LOG=log-$TAG.txt; rm -f "$TAG"-f*.png "$TAG"-ob3.txt
top() { adb shell dumpsys activity activities | grep -m1 -E "topResumedActivity|mResumedActivity" | grep -oE '/[a-zA-Z.0-9_$]+' | tail -1; }
mark() { echo "$1 $(date +%T.%N | cut -c1-12)" >> "$M"; echo "$1 $(date +%T)"; }
waitfor() { for i in $(seq 1 "${2:-40}"); do top | grep -qE "$1" && return 0; sleep 1; done; return 1; }
dev_now() { adb shell 'echo $EPOCHREALTIME' | tr -d '\r'; }
# device epoch of the last FA event <name> still in the logcat buffer
fa_epoch() { adb logcat -d -v epoch -s FA-SVC | grep "Logging event: .*name=$1[,(]" | tail -1 | awk '{print $1}'; }
net_on() { adb shell svc wifi enable; adb shell svc data enable
  for i in $(seq 1 30); do adb shell ping -c1 -W2 8.8.8.8 >/dev/null 2>&1 && return 0; sleep 1; done; return 1; }
trap net_on EXIT   # never leave the phone offline, even if the run breaks half way

adb shell setprop debug.firebase.analytics.app "$P"; adb shell setprop log.tag.FA-SVC VERBOSE
pkill -f "^adb logcat -v threadtime" ; adb logcat -c; adb logcat -v threadtime > "$LOG" & LC=$!
adb shell am force-stop "$P"; adb shell pm clear "$P" >/dev/null; adb shell pm grant "$P" android.permission.POST_NOTIFICATIONS 2>/dev/null
if [ "$PRE" = fetch ]; then
  adb shell monkey -p "$P" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
  for i in $(seq 1 20); do sleep 1; grep -q "Fetch firebase successfully" "$LOG" && break; done
  mark rc_fetched; sleep 2; adb shell am force-stop "$P"
fi
adb shell svc wifi disable; adb shell svc data disable; sleep 3
mark launch_offline; adb shell monkey -p "$P" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
waitfor Language 20 || mark "warn: Language not reached offline ($(top))"
net_on; mark net_up
timeout 150 bash "$D/continue-fo-from-current-screen.sh" "$M" 'Onboarding' >/dev/null
# step OB1 -> OB2 -> OB3 with Next (tutorial button id); stop as soon as ob3_view is logged
for i in 1 2 3 4 5 6; do
  grep -q "name=ob3_view" "$LOG" && break
  bash "$D/dismiss-native-validator.sh" >/dev/null; bash "$D/tap-by-id.sh" "${NEXT_RE:-btnNextOnboarding}" right >/dev/null
  for j in 1 2 3 4 5 6; do sleep 0.5; grep -q "name=ob3_view" "$LOG" && break 2; done
done
grep -q "name=ob3_view" "$LOG" || { mark "fail: ob3_view never logged ($(top))"; kill $LC; exit 1; }
# time zero = ob3_view itself (device log), not the moment this loop noticed it (~0.5-1 s later)
D0=$(fa_epoch ob3_view); [ -z "$D0" ] && D0=$(dev_now); mark "ob3_seen ob3_view_dev=$D0 now_dev=$(dev_now)"
done_back=
for k in $(seq 1 "$N"); do
  d=$(dev_now); adb exec-out screencap -p > "$TAG-f$(printf %02d "$k")-$d.png"
  if [ "$BACKAT" != none ] && [ -z "$done_back" ] && [ "$(echo "$d - $D0 >= $BACKAT" | bc)" = 1 ]; then
    # 'input keyevent' itself takes ~0.6 s on device: keep both ends so the press is bracketed
    B=$d; adb shell input keyevent BACK; B2=$(dev_now); mark "back sent_dev=$B done_dev=$B2"; done_back=1
  fi
done
sleep 2; mark "end top=$(top)"
{ echo "ob3_view $(fa_epoch ob3_view)"; echo "complete_ob3 $(fa_epoch complete_ob3)"; echo "ob4_view $(fa_epoch ob4_view)"
  [ -n "$B" ] && { echo "back_sent $B"; echo "back_done $B2"; }; } > "$TAG-ob3.txt"
cat "$TAG-ob3.txt"; kill $LC
