#!/system/bin/sh
MODDIR=${0%/*}
CFG_DIR=/data/adb/avr_portfix
CFG="$CFG_DIR/config.conf"
LOG=/data/local/tmp/avr_portfix.log
mkdir -p /data/local/tmp "$CFG_DIR" 2>/dev/null
[ -f "$CFG" ] || cp "$MODDIR/config.default.conf" "$CFG" 2>/dev/null
. "$CFG" 2>/dev/null

: "${AUDIO_NOFAST_FIX:=1}"
: "${QHD_DPI_FIX:=1}"
: "${BG_RETENTION_FIX:=1}"

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

# === 内置常驻底层修复（无需开关） ===
# 1) 相机扩展 ANR 修复（扫码防卡死）
bind_file "$MODDIR/libcsextimpl_patched.so" /system/system_ext/lib64/libcsextimpl.so u:object_r:system_lib_file:s0

# 2) 144Hz 极速高刷档位自愈（不锁定全局，仅恢复档位配置）
bind_file "$MODDIR/display_144/refresh_rate_config.xml" "/system/my_product/etc/refresh_rate_config.xml" u:object_r:system_file:s0
bind_file "$MODDIR/display_144/oplus_vrr_config.json" "/system/my_product/etc/oplus_vrr_config.json" u:object_r:system_file:s0
setprop persist.performance.rapid.refresh_rate.level 144
setprop persist.game.exceed.refresh_rate 144
[ -n "$RP" ] && $RP ro.oplus.display.ogfr 165 2>/dev/null

# 3) Google 智能镜头包名修正 + 国行游戏助手去 EUEX 阉割
[ -n "$RP" ] && $RP ro.com.google.lens.oem_camera_package com.motorola.camera5 2>/dev/null
bind_file "$MODDIR/my_stock_android_features.xml" /my_stock/etc/permissions/com.oplus.android-features.xml u:object_r:system_file:s0

# 4) 电池用量与亮屏/息屏活动时长统计目录 SELinux 修复（早于 system_server 启动）
mkdir -p \
  /data/oplus/os/battery/oplus_battery_stats/apppower \
  /data/oplus/os/battery/oplus_battery_stats/apppower_onbattery \
  /data/oplus/os/battery/oplus_battery_stats/screenactive \
  /data/oplus/os/battery/oplus_battery_stats/temp \
  /data/oplus/os/battery/oplus_battery_stats/shutdown \
  /data/oplus/os/battery/oplus_battery_stats/systemtime/poweraction 2>/dev/null
chown -R system:system /data/oplus/os/battery 2>/dev/null
chmod 0755 /data/oplus /data/oplus/os /data/oplus/os/battery \
  /data/oplus/os/battery/oplus_battery_stats \
  /data/oplus/os/battery/oplus_battery_stats/apppower \
  /data/oplus/os/battery/oplus_battery_stats/apppower_onbattery \
  /data/oplus/os/battery/oplus_battery_stats/screenactive \
  /data/oplus/os/battery/oplus_battery_stats/temp \
  /data/oplus/os/battery/oplus_battery_stats/shutdown \
  /data/oplus/os/battery/oplus_battery_stats/systemtime \
  /data/oplus/os/battery/oplus_battery_stats/systemtime/poweraction 2>/dev/null
restorecon /data/oplus 2>/dev/null
restorecon -RF /data/oplus/os 2>/dev/null

# === 用户可调开关 ===
if [ "$AUDIO_NOFAST_FIX" = "1" ]; then
  bind_file "$MODDIR/audio_policy_configuration_nofast.xml" /vendor/etc/audio_policy_configuration.xml u:object_r:vendor_configs_file:s0
  bind_file "$MODDIR/audio_module_config_primary_nofast.xml" /vendor/etc/audio/audio_module_config_primary.xml u:object_r:vendor_configs_file:s0
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
