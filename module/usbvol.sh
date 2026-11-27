#!/system/bin/sh
# 把 Android 媒体音量（0..160 级）映射到 USB-C DAC 的 UAC 音量（0..120）
# 低功耗版：未插 USB-C DAC 时零 Binder IPC、零子进程 fork，避免阻断深度睡眠
export PATH=/system/bin:/vendor/bin:/system/xbin:$PATH
LOG=/data/local/tmp/usbvol.log
TINYMIX=/vendor/bin/tinymix
[ -x "$TINYMIX" ] || TINYMIX=$(command -v tinymix)
[ -n "$TINYMIX" ] || { echo "tinymix not found, exit $(date)" > "$LOG"; exit 0; }

last=""; present=0; ucard=""; ctl=""
echo "start low-power $(date)" > "$LOG"

while true; do
  ucard=""
  for c in /proc/asound/card*; do
    if [ -e "$c/usbmixer" ]; then
      ucard=${c##*/card}
      break
    fi
  done

  if [ -n "$ucard" ]; then
    if [ "$present" = "0" ] || [ -z "$ctl" ]; then
      ctl=$("$TINYMIX" -D "$ucard" 2>/dev/null | awk '/PCM Playback Volume/{print $1; exit}')
    fi
    idx=$(cmd media_session volume --stream 3 --get 2>/dev/null | awk '/volume is/{for(i=1;i<=NF;i++) if($i=="is"){print $(i+1); exit}}')
    case "$idx" in ''|*[!0-9]*) idx="" ;; esac
    if [ -n "$ctl" ] && [ -n "$idx" ] && { [ "$idx" != "$last" ] || [ "$present" = "0" ]; }; then
      v=$(( idx * 120 / 160 ))
      [ "$v" -gt 120 ] && v=120
      "$TINYMIX" -D "$ucard" "$ctl" "$v" "$v" >/dev/null 2>&1
      echo "$(date +%H:%M:%S) card=$ucard ctl=$ctl idx=$idx uac=$v replug=$present" >> "$LOG"
      last="$idx"
    fi
    present=1
    sleep 1
  else
    present=0
    ctl=""
    last=""
    sleep 8
  fi
done
