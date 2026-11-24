#!/system/bin/sh
MODDIR=${0%/*}
CFG_DIR=/data/adb/avr_portfix
CFG="$CFG_DIR/config.conf"
LOG=/data/local/tmp/avr_portfix.log
mkdir -p /data/local/tmp "$CFG_DIR" 2>/dev/null
[ -f "$CFG" ] || cp "$MODDIR/config.default.conf" "$CFG" 2>/dev/null
. "$CFG" 2>/dev/null

: "${CAM_EXT_FIX:=1}"
: "${AUDIO_NOFAST_FIX:=1}"
: "${REFRESH_144_FIX:=1}"
: "${QHD_DPI_FIX:=1}"
: "${BG_RETENTION_FIX:=1}"
: "${GAMES_CN_UNLOCK:=1}"
: "${LENS_OEM_FIX:=1}"

echo "==== post-fs-data $(date) ====" >> "$LOG" 2>&1

RP=""
if command -v resetprop >/dev/null 2>&1; then
  RP=resetprop
elif [ -x /data/adb/ksu/bin/resetprop ]; then
  RP=/data/adb/ksu/bin/resetprop
fi

bind_file() {
  SRC="$1"; TGT="$2"; LABEL="$3"
  [ -f "$SRC" ] || return
  [ -f "$TGT" ] || return
  chmod 0644 "$SRC" 2>/dev/null
  chcon "$LABEL" "$SRC" 2>/dev/null
  mount -o bind "$SRC" "$TGT" 2>> "$LOG"
}

[ "$CAM_EXT_FIX" = "1" ] && bind_file "$MODDIR/libcsextimpl_patched.so" /system/system_ext/lib64/libcsextimpl.so u:object_r:system_lib_file:s0
if [ "$AUDIO_NOFAST_FIX" = "1" ]; then
  bind_file "$MODDIR/audio_policy_configuration_nofast.xml" /vendor/etc/audio_policy_configuration.xml u:object_r:vendor_configs_file:s0
  bind_file "$MODDIR/audio_module_config_primary_nofast.xml" /vendor/etc/audio/audio_module_config_primary.xml u:object_r:vendor_configs_file:s0
fi
if [ "$REFRESH_144_FIX" = "1" ]; then
  bind_file "$MODDIR/display_144/refresh_rate_config.xml" "/system/my_product/etc/refresh_rate_config.xml" u:object_r:system_file:s0
  bind_file "$MODDIR/display_144/oplus_vrr_config.json" "/system/my_product/etc/oplus_vrr_config.json" u:object_r:system_file:s0
  setprop persist.performance.rapid.refresh_rate.level 144
  setprop persist.game.exceed.refresh_rate 144
  [ -n "$RP" ] && $RP ro.oplus.display.ogfr 165 2>/dev/null
fi
if [ "$QHD_DPI_FIX" = "1" ] && [ -n "$RP" ]; then
  $RP ro.sf.lcd_density 634 2>/dev/null
  $RP ro.oplus.density.qhd_default 634 2>/dev/null
  $RP ro.density.screenzoom.qdh "520,560,580,600,634" 2>/dev/null
  $RP ro.density.screenzoom.fdh "380,420,440,476,540" 2>/dev/null
fi
if [ "$BG_RETENTION_FIX" = "1" ] && [ -n "$RP" ]; then
  $RP ro.lmk.use_psi true 2>/dev/null
  $RP ro.lmk.psi_partial_stall_ms 150 2>/dev/null
  $RP ro.lmk.psi_complete_stall_ms 700 2>/dev/null
  $RP ro.lmk.thrashing_limit 100 2>/dev/null
  $RP ro.lmk.thrashing_limit_decay 10 2>/dev/null
  $RP ro.lmk.swap_free_low_percentage 10 2>/dev/null
  $RP ro.lmk.kill_timeout_ms 200 2>/dev/null
  setprop sys.lmk.minfree_levels "18432:0,23040:100,27648:200,32256:250,40960:900,51200:950"
fi
if [ "$LENS_OEM_FIX" = "1" ] && [ -n "$RP" ]; then
  $RP ro.com.google.lens.oem_camera_package com.motorola.camera5 2>/dev/null
fi
[ "$GAMES_CN_UNLOCK" = "1" ] && bind_file "$MODDIR/my_stock_android_features.xml" /my_stock/etc/permissions/com.oplus.android-features.xml u:object_r:system_file:s0
