# AVR Port Fix (XT2611-1 / OxygenOS 17 移植) v2.9

XT2611-1（代号 avr，国行拯救者 Y70 新一代 / 海外 moto edge 70 Max）刷入
OxygenOS 17 移植后的修复集合。全部通过 **bind mount / overlay / 属性 / 设置** 实现，
不改分区、不刷镜像，卸载模块重启即恢复原状。

## 包含的修复

| # | 修复 | 实现 |
|---|---|---|
| 1 | **微信扫一扫 / 第三方相机 ANR** | 用补丁版 `libcsextimpl.so` 覆盖 `/system/system_ext/lib64/libcsextimpl.so`，跳过本机不存在的 `vendor.oplus.hardware.sendextcamcmd` 服务等待 |
| 2 | **游戏音频异常** | 去掉 `/vendor/etc` 两份 audio policy 里 primary 输出的 FAST 标志 |
| 3 | **USB-C 耳机音量不跟随** | `usbvol.sh` 守护进程，把媒体音量 0–160 映射到 UAC 0–120 |
| 4 | **`com.oplus.ota` 崩溃刷屏** | 开机 `pm disable-user com.oplus.ota` |
| 5 | **144Hz 属性自愈** | 开机重设 `persist.performance.rapid.refresh_rate.level=144`、`persist.game.exceed.refresh_rate=144` |
| 6 | **修正 Lens OEM 相机指向** | `ro.com.google.lens.oem_camera_package=com.motorola.camera5` |
| 7 | **默认关闭前摄美颜防预览卡死** | 自动将 Moto 相机 `face_beauty_level.FRONT_MAIN` 置 `0`，规避 Meishe 渲染失败导致前摄预览卡死 |
| 8 | **Moto 相机 Stub! 崩溃** | 模块提供 no-op 版 `moto-core_services` 库（`/system/framework` + 权限 xml） |
| 9 | **内存拓展（4/8/12GB）完整生效** | 在摩托内核上接管 `/data/swap_ext/swapfile` F2FS pinned swapfile 创建与 `swapon -p 5`，并同步 `persist.sys.oplus.nandswap.*` 状态属性 |
| 10 | **电池健康真实硬件健康度显示** | 开机读取摩托内核 `/sys/class/power_supply/battery/state_of_health` 并同步到「设置 → 电池 → 电池健康」 |
| 11 | **室内 / 天气 / App 网络定位与逆地理编码修复（v2.9 新增）** | 补齐国行底包百度网络定位与逆地理编码组件 `BaiduNetworkLocation.apk`（`com.baidu.map.location`）及其 `privapp-permissions`、`sysconfig`，配合 `UPDATED_SYSTEM_APP` 挂载命名空间兼容与自动赋权，使 `OplusNlpProxy` 与 `OplusGeocoderProxy` 在国内自动绑定 `nlp` 服务 |
| 12 | **可选：全局固定 144Hz** | 在模块目录建 `enable_global144` 文件 → 开机把 min/peak 都设 144；删除后重启恢复动态 |
