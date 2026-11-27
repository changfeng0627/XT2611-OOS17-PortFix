SKIPUNZIP=0
ui_print "- Installing AVR Port Fix v1.2.1 (XT2611-1 / OOS 17)..."
# Remove standalone test MotoDolby module if previously installed
if [ -d /data/adb/modules/moto_dolby_xt2611 ]; then
  touch /data/adb/modules/moto_dolby_xt2611/remove
  ui_print "- Marked standalone moto_dolby_xt2611 for removal (merged into AVR Port Fix)"
fi
rm -rf /data/adb/modules_update/moto_dolby_xt2611 2>/dev/null
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/usbvol.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
ui_print "- Done! Reboot to apply."
