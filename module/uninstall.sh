#!/system/bin/sh
F=/data/swap_ext/swapfile
grep -q "$F" /proc/swaps && /system/bin/swapoff "$F"
rm -rf /data/swap_ext
/system/bin/settings put system battery_health_current_test_mode 0
/system/bin/settings put global battery_tip_test_mode 0
pm uninstall com.motorola.dolby.dolbyui 2>/dev/null
pm uninstall com.dolby.daxservice 2>/dev/null
pm uninstall com.baidu.map.location 2>/dev/null
pm enable com.oplus.audio.effectcenter 2>/dev/null
