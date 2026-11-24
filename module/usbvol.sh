#!/system/bin/sh
# 把 Android 媒体音量（0..160 级）映射到 USB-C DAC 的 UAC 音量（0..120）
export PATH=/system/bin:/vendor/bin:/system/xbin:$PATH
LOG=/data/local/tmp/usbvol.log
TINYMIX=/vendor/bin/tinymix
[ -x "$TINYMIX" ] || TINYMIX=$(command -v tinymix)
[ -n "$TINYMIX" ] || { echo "tinymix not found, exit $(date)" > "$LOG"; exit 0; }

last=""; present=0
echo "start $(date)" > "$LOG"

find_usb_card() {
  for c in /proc/asound/card*; do
    n=${c##*/card}
    [ -e "$c/usbmixer" ] && { echo "$n"; return; }
  done
}

while true; do
  ucard=$(find_usb_card)
  idx=$(cmd media_session volume --stream 3 --get 2>/dev/null | awk '/volume is/{for(i=1;i<=NF;i++) if($i=="is"){print $(i+1); exit}}')
  case "$idx" in ''|*[!0-9]*) idx="" ;; esac
  if [ -n "$ucard" ]; then
    ctl=$("$TINYMIX" -D "$ucard" 2>/dev/null | awk '/PCM Playback Volume/{print $1; exit}')
    if [ -n "$ctl" ] && [ -n "$idx" ] && { [ "$idx" != "$last" ] || [ "$present" = "0" ]; }; then
      v=$(( idx * 120 / 160 ))
      [ "$v" -gt 120 ] && v=120
      "$TINYMIX" -D "$ucard" "$ctl" "$v" "$v" >/dev/null 2>&1
      echo "$(date +%H:%M:%S) card=$ucard ctl=$ctl idx=$idx uac=$v replug=$present" >> "$LOG"
      last="$idx"
    fi
    present=1
  else
    present=0
  fi
  sleep 1
done
