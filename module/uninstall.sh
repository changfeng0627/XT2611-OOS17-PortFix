#!/system/bin/sh
F=/data/swap_ext/swapfile
grep -q "$F" /proc/swaps && /system/bin/swapoff "$F"
rm -rf /data/swap_ext
/system/bin/settings put system battery_health_current_test_mode 0
/system/bin/settings put global battery_tip_test_mode 0
