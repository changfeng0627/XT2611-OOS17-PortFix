#!/system/bin/sh
MODDIR=${0%/*}
CFG_DIR=/data/adb/avr_portfix
CFG="$CFG_DIR/config.conf"
LOG=/data/local/tmp/avr_portfix.log
mkdir -p /data/local/tmp "$CFG_DIR" 2>/dev/null
[ -f "$CFG" ] || cp "$MODDIR/config.default.conf" "$CFG" 2>/dev/null
. "$CFG" 2>/dev/null

: "${CAM_POSTPROC_FIX:=1}"
: "${CAM_FRONT_BEAUTY_OFF:=1}"
: "${DOLBY_ATMOS_FIX:=1}"
: "${USB_DAC_VOL_FIX:=1}"
: "${GLOBAL_144:=0}"
: "${RAMEXT_FIX:=1}"
: "${BATT_HEALTH_FIX:=1}"
: "${BAIDU_NLP_FIX:=1}"
: "${BG_RETENTION_FIX:=1}"
: "${OTA_BG_DISABLE:=1}"
: "${SIGNAL_5G_FIX:=1}"

echo "==== service $(date) ====" >> "$LOG" 2>&1

i=0
while [ $i -lt 60 ]; do
  if cmd package list packages >/dev/null 2>&1; then break; fi
  sleep 2; i=$((i+1))
done

if [ "$OTA_BG_DISABLE" = "1" ]; then
  pm list packages 2>/dev/null | grep -q "^package:com\.oplus\.cota$" && pm disable-user --user 0 com.oplus.cota >> "$LOG" 2>&1
  if pm list packages 2>/dev/null | grep -q "^package:com\.oplus\.ota$"; then
    pm enable com.oplus.ota >> "$LOG" 2>&1
    for comp in \
      com.oplus.ota/.strategy.StrategyReceiver \
      com.oplus.ota/.strategy.UpgradeInviteReceiver \
      com.oplus.ota/.service.OTAService \
      com.oplus.ota/.push.OtaPushService \
      com.oplus.ota/.enterprise.EnterpriseOTAService; do
      pm disable "$comp" >> "$LOG" 2>&1
    done
  fi
fi

if [ "$BAIDU_NLP_FIX" = "1" ]; then
  if pm list packages 2>/dev/null | grep -q "^package:com\.baidu\.map\.location$"; then
    if ! dumpsys package com.baidu.map.location 2>/dev/null | grep -q "UPDATED_SYSTEM_APP"; then
      pm install -r -g "$MODDIR/system/priv-app/BaiduNetworkLocation/BaiduNetworkLocation.apk" >> "$LOG" 2>&1
    fi
    for perm in ACCESS_COARSE_LOCATION ACCESS_FINE_LOCATION ACCESS_BACKGROUND_LOCATION WRITE_EXTERNAL_STORAGE READ_EXTERNAL_STORAGE; do
      pm grant com.baidu.map.location "android.permission.${perm}" >> "$LOG" 2>&1
    done
    appops set com.baidu.map.location COARSE_LOCATION allow >> "$LOG" 2>&1
    appops set com.baidu.map.location FINE_LOCATION allow >> "$LOG" 2>&1
    appops set com.baidu.map.location MONITOR_LOCATION allow >> "$LOG" 2>&1
    appops set com.baidu.map.location MONITOR_HIGH_POWER_LOCATION allow >> "$LOG" 2>&1
  fi
fi

setup_moto_dolby() {
  if [ "$DOLBY_ATMOS_FIX" = "1" ]; then
    if ! pm path com.dolby.daxservice 2>/dev/null | grep -q "/data/app/"; then
      pm install -r -g "$MODDIR/system/priv-app/daxService/daxService.apk" >> "$LOG" 2>&1
    fi
    if ! pm path com.motorola.dolby.dolbyui 2>/dev/null | grep -q "/data/app/"; then
      pm install -r -g "$MODDIR/system/app/MotoDolbyDax3/MotoDolbyDax3.apk" >> "$LOG" 2>&1
    fi
    pm enable com.dolby.daxservice >> "$LOG" 2>&1
    pm enable com.motorola.dolby.dolbyui >> "$LOG" 2>&1
    dumpsys deviceidle whitelist +com.dolby.daxservice >> "$LOG" 2>&1
    am startservice -n com.dolby.daxservice/.DaxService >> "$LOG" 2>&1
    sleep 1
    local DAX_PID
    DAX_PID=$(pidof com.dolby.daxservice 2>/dev/null)
    if [ -n "$DAX_PID" ] && [ -w "/proc/$DAX_PID/oom_score_adj" ]; then
      echo -800 > "/proc/$DAX_PID/oom_score_adj" 2>/dev/null
    fi
  else
    pm disable-user --user 0 com.motorola.dolby.dolbyui >> "$LOG" 2>&1
    pm disable-user --user 0 com.dolby.daxservice >> "$LOG" 2>&1
  fi
}

MARK="$CFG_DIR/.global144_was_on"
if [ "$GLOBAL_144" = "1" ] || [ -f "$MODDIR/enable_global144" ]; then
  settings put system min_refresh_rate 144.00002 >> "$LOG" 2>&1
  settings put system peak_refresh_rate 144.00002 >> "$LOG" 2>&1
  settings put secure oplus_customize_screen_refresh_rate 0 >> "$LOG" 2>&1
  touch "$MARK"
else
  if [ -f "$MARK" ]; then
    settings delete system min_refresh_rate >> "$LOG" 2>&1
    settings put system peak_refresh_rate 144.00002 >> "$LOG" 2>&1
    rm -f "$MARK"
  fi
fi

if [ "$USB_DAC_VOL_FIX" = "1" ]; then
  pgrep -f "$MODDIR/usbvol.sh" >/dev/null 2>&1 || ( nohup sh "$MODDIR/usbvol.sh" >/dev/null 2>&1 & )
else
  pkill -f "$MODDIR/usbvol.sh" 2>/dev/null
fi

enforce_front_beauty_off() {
  PREFS=/data/user/0/com.motorola.camera5/shared_prefs/com.motorola.camera_preferences.xml
  [ -f "$PREFS" ] || return 1
  grep -q 'face_beauty_level.FRONT_MAIN" value="[1-9]' "$PREFS" 2>/dev/null || return 2
  cp "$PREFS" /data/local/tmp/camera_prefs.bak 2>/dev/null
  sed -e 's/name="com.motorola.camera.face_beauty_level.FRONT_MAIN" value="[1-9]"/name="com.motorola.camera.face_beauty_level.FRONT_MAIN" value="0"/' \
      -e 's/name="com.motorola.camera.face_beauty" value="1"/name="com.motorola.camera.face_beauty" value="0"/' \
      /data/local/tmp/camera_prefs.bak > /data/local/tmp/camera_prefs.new 2>/dev/null
  [ -s /data/local/tmp/camera_prefs.new ] || return 1
  cat /data/local/tmp/camera_prefs.new > "$PREFS"
  return 0
}
if [ "$CAM_FRONT_BEAUTY_OFF" = "1" ]; then
  (
    i=0
    while [ $i -lt 20 ]; do
      enforce_front_beauty_off && break
      sleep 10
      i=$((i+1))
    done
  ) &
fi

sync_moto_camera_postproc() {
  [ "$CAM_POSTPROC_FIX" = "1" ] || return 0
  local SRC="$MODDIR/cam_postproc"
  [ -d "$SRC" ] || return 0
  local CAM_LIB_DIR
  CAM_LIB_DIR=$(ls -d /data/app/~~*/com.motorola.camera5-*/lib/arm64 2>/dev/null | head -n 1)
  [ -d "$CAM_LIB_DIR" ] || return 0

  if [ -f "$CAM_LIB_DIR/libenginepostproc.moto.so" ] \
     && [ -f "$CAM_LIB_DIR/libmotopostprocaidlclient.so" ] \
     && [ -f "$CAM_LIB_DIR/com.motorola.hardware.camera.postprocess-V1-ndk.so" ] \
     && [ -f "$CAM_LIB_DIR/libbinder.so" ] \
     && cmp -s "$SRC/libenginepostproc.moto.so" "$CAM_LIB_DIR/libenginepostproc.moto.so" 2>/dev/null \
     && cmp -s /system/lib64/libc++.so "$CAM_LIB_DIR/libc++.so" 2>/dev/null; then
    return 0
  fi

  cp "$SRC/libenginepostproc.moto.so" "$CAM_LIB_DIR/libenginepostproc.moto.so"
  cp "$SRC/libmotopostprocaidlclient.so" "$CAM_LIB_DIR/libmotopostprocaidlclient.so"
  cp /vendor/lib64/com.motorola.hardware.camera.postprocess-V1-ndk.so "$CAM_LIB_DIR/com.motorola.hardware.camera.postprocess-V1-ndk.so"
  cp /system/lib64/libc++.so "$CAM_LIB_DIR/libc++.so"

  local NDK_PUBLIC="libc.so libm.so libdl.so liblog.so libnativewindow.so libbinder_ndk.so libandroid.so libcamera2ndk.so libmediandk.so libjnigraphics.so libEGL.so libGLESv1_CM.so libGLESv2.so libGLESv3.so libvulkan.so libz.so libsync.so libc++.so libc++_shared.so"
  local QUEUE="$CAM_LIB_DIR/libenginepostproc.moto.so $CAM_LIB_DIR/libmotopostprocaidlclient.so"
  local VISITED=""
  local CUR NEEDED lib p is_pub TARGET

  while [ -n "$QUEUE" ]; do
    CUR=$(echo "$QUEUE" | awk '{print $1}')
    QUEUE=$(echo "$QUEUE" | awk '{$1=""; sub(/^ +/, ""); print}')
    case " $VISITED " in
      *" $CUR "*) continue ;;
    esac
    VISITED="$VISITED $CUR"
    [ -f "$CUR" ] || continue
    NEEDED=$(readelf -d "$CUR" 2>/dev/null | grep '(NEEDED)' | sed 's/.*\[//;s/\].*//')
    for lib in $NEEDED; do
      is_pub=0
      for p in $NDK_PUBLIC; do
        if [ "$lib" = "$p" ]; then is_pub=1; break; fi
      done
      [ "$is_pub" -eq 1 ] && continue
      TARGET="$CAM_LIB_DIR/$lib"
      if [ ! -f "$TARGET" ]; then
        if [ -f "/system/lib64/$lib" ]; then cp "/system/lib64/$lib" "$TARGET"
        elif [ -f "/system_ext/lib64/$lib" ]; then cp "/system_ext/lib64/$lib" "$TARGET"
        elif [ -f "/vendor/lib64/$lib" ]; then cp "/vendor/lib64/$lib" "$TARGET"
        else continue
        fi
      fi
      QUEUE="$QUEUE $TARGET"
    done
  done

  chown system:system "$CAM_LIB_DIR"/*.so
  chmod 755 "$CAM_LIB_DIR"/*.so
  chcon u:object_r:apk_data_file:s0 "$CAM_LIB_DIR"/*.so
}

tune_bg_retention() {
  if [ "$BG_RETENTION_FIX" = "1" ]; then
    settings put global cached_apps_freezer enabled >> "$LOG" 2>&1
    device_config put activity_manager_native_boot use_freezer true >> "$LOG" 2>&1
    device_config put activity_manager max_cached_processes 256 >> "$LOG" 2>&1
    device_config put activity_manager max_phantom_processes 2147483647 >> "$LOG" 2>&1
    settings put global settings_enable_monitor_phantom_procs false >> "$LOG" 2>&1
    echo 20 > /proc/sys/vm/watermark_scale_factor 2>/dev/null
    echo 80 > /proc/sys/vm/swappiness 2>/dev/null
    setprop sys.lmk.minfree_levels "18432:0,23040:100,27648:200,32256:250,40960:900,51200:950"
    setprop lmkd.reinit 1
  else
    settings delete global cached_apps_freezer >> "$LOG" 2>&1
    device_config delete activity_manager_native_boot use_freezer >> "$LOG" 2>&1
    echo 52 > /proc/sys/vm/watermark_scale_factor 2>/dev/null
    echo 100 > /proc/sys/vm/swappiness 2>/dev/null
  fi
}

run_ramext_and_battery_health() {
  local w=0
  while [ "$(getprop sys.boot_completed)" != "1" ] && [ $w -lt 120 ]; do
    sleep 1; w=$((w + 1))
  done
  # Wait for Oplus nandswap init script to finish so it doesn't race and reset err=1004
  sleep 8
  w=0
  while [ "$(getprop init.svc.init.oplus.nandswap.sh)" = "running" ] && [ $w -lt 30 ]; do
    sleep 1; w=$((w + 1))
  done

  if [ "$BATT_HEALTH_FIX" = "1" ]; then
    local SOH
    SOH=$(cat /sys/class/power_supply/battery/state_of_health 2>/dev/null | tr -dc '0-9')
    if [ -n "$SOH" ] && [ "$SOH" -ge 50 ] && [ "$SOH" -le 100 ]; then
      settings put system battery_health_soh "$SOH" 2>/dev/null
      settings put system battery_health_soh_real "$SOH" 2>/dev/null
      settings put secure battery_health_soh "$SOH" 2>/dev/null
      setprop persist.sys.oplus.battery.soh "$SOH" 2>/dev/null
    fi
  fi

  local F=/data/swap_ext/swapfile
  if [ "$RAMEXT_FIX" != "1" ]; then
    grep -q "$F" /proc/swaps 2>/dev/null && /system/bin/swapoff "$F" 2>/dev/null
    return 0
  fi

  local EN SZ WANT CUR PIN
  EN=$(getprop persist.sys.oplus.nandswap)
  SZ=$(getprop persist.sys.oplus.nandswap.swapsize)
  if [ "$EN" != "true" ] || [ -z "$SZ" ] || [ "$SZ" -le 0 ] 2>/dev/null; then
    grep -q "$F" /proc/swaps 2>/dev/null && /system/bin/swapoff "$F" 2>/dev/null
    setprop persist.sys.oplus.nandswap.swapsize.curr 0
    return 0
  fi

  WANT=$(awk -v s="$SZ" 'BEGIN{printf "%.0f", s * 1073741824}')
  if grep -q "$F" /proc/swaps 2>/dev/null; then
    CUR=$(stat -c%s "$F" 2>/dev/null || echo 0)
    if [ "$CUR" = "$WANT" ]; then
      setprop persist.sys.oplus.nandswap.swapsize.curr "$SZ"
      setprop persist.sys.oplus.nandswap.condition true
      setprop persist.sys.oplus.nandswap.err 0
      return 0
    fi
    /system/bin/swapoff "$F" 2>/dev/null
  fi

  mkdir -p /data/swap_ext
  chmod 0700 /data/swap_ext
  CUR=$(stat -c%s "$F" 2>/dev/null || echo 0)

  make_swap() {
    rm -f "$F"
    local AVAIL_GB NEED_GB
    AVAIL_GB=$(df -k /data | awk 'NR==2{printf "%d", $4/1048576}')
    NEED_GB=$((SZ + 10))
    if [ "$AVAIL_GB" -lt "$NEED_GB" ]; then
      echo "ramext: low storage (${AVAIL_GB}GB), skip" >> "$LOG"
      return 1
    fi
    touch "$F"
    /product/bin/nandswap_tool -s1 "$F" >> "$LOG" 2>&1
    /system/bin/fallocate -l "$WANT" -o 0 "$F" >> "$LOG" 2>&1 || { rm -f "$F"; return 1; }
    chmod 0600 "$F"
    /system/bin/mkswap "$F" >> "$LOG" 2>&1 || { rm -f "$F"; return 1; }
  }

  if [ "$CUR" != "$WANT" ]; then
    make_swap || return 1
  fi
  if ! /system/bin/swapon -p 5 "$F" 2>> "$LOG"; then
    make_swap || return 1
    /system/bin/swapon -p 5 "$F" 2>> "$LOG" || return 1
  fi
  setprop persist.sys.oplus.nandswap.swapsize.curr "$SZ"
  setprop persist.sys.oplus.nandswap.condition true
  setprop persist.sys.oplus.nandswap.err 0
}


# 9) 国行 5G 状态栏信号格数阈值校准（将国际版严格阈值 [-110,-90,-80,-65] 校准为国行 [-128,-118,-108,-98]）
fix_5g_signal_thresholds() {
  local CC_FILES CC_FILE CHANGED=0
  CC_FILES=$(ls /data/user_de/0/com.android.phone/files/carrierconfig-com.android.carrierconfig-*.xml 2>/dev/null | grep -v nosim)
  [ -n "$CC_FILES" ] || return 0
  for CC_FILE in $CC_FILES; do
    if [ "$SIGNAL_5G_FIX" = "1" ]; then
      if ! grep -q "5g_nr_ssrsrp_thresholds_int_array" "$CC_FILE" 2>/dev/null; then
        sed -i 's|</bundle>|    <int-array name="5g_nr_ssrsrp_thresholds_int_array" num="4">\n        <item value="-128" />\n        <item value="-118" />\n        <item value="-108" />\n        <item value="-98" />\n    </int-array>\n</bundle>|' "$CC_FILE"
        chown radio:radio "$CC_FILE" 2>/dev/null
        chmod 600 "$CC_FILE" 2>/dev/null
        CHANGED=1
      fi
    else
      if grep -q "5g_nr_ssrsrp_thresholds_int_array" "$CC_FILE" 2>/dev/null; then
        sed -i '/<int-array name="5g_nr_ssrsrp_thresholds_int_array"/,/<\/int-array>/d' "$CC_FILE"
        chown radio:radio "$CC_FILE" 2>/dev/null
        chmod 600 "$CC_FILE" 2>/dev/null
        CHANGED=1
      fi
    fi
  done
  if [ "$CHANGED" = "1" ]; then
    echo "signal_5g: carrierconfig updated (SIGNAL_5G_FIX=$SIGNAL_5G_FIX), reloading phone" >> "$LOG"
    killall com.android.phone 2>/dev/null || pkill -f "^com.android.phone$" 2>/dev/null
  fi
}

if [ "${1:-}" = "--sync" ]; then
  setup_moto_dolby
  sync_moto_camera_postproc
  tune_bg_retention
  fix_5g_signal_thresholds
  run_ramext_and_battery_health
else
  setup_moto_dolby &
  sync_moto_camera_postproc &
  tune_bg_retention &
  fix_5g_signal_thresholds &
  run_ramext_and_battery_health &
fi
