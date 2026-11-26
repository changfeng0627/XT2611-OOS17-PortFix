# XT2611-1 (moto edge 70 Max / Y70 新一代) 移植 OxygenOS 17 综合修复模块

适用于 Motorola XT2611-1 (`avr`) 移植 OxygenOS 17 的开源综合修复模块与 Material Design 3 动态取色 WebUI 控制台。

## 适用环境

- **机型**：Motorola XT2611-1 (`avr`，moto edge 70 Max / 联想拯救者 Y70 新一代)
- **适配移植包**：[Goubata/AVR-OxygenOS-Port](https://github.com/Goubata/AVR-OxygenOS-Port)（OxygenOS 17 `CPH2747_17.0.0.102` / Android 17 + 摩托原厂内核）
- **Root 方案**：通用支持 KernelSU / KernelSU Next / APatch / Magisk

## 下载文件位置（GitHub Releases）

成品刷机包与补丁版摩托相机 APK（约 338 MB）均托管在本仓库的 **[Releases (v1.1.0)](https://github.com/changfeng0627/XT2611-OOS17-PortFix/releases/tag/v1.1.0)** 页面中：

1. **[AVR_PortFix-v1.1.0.zip](https://github.com/changfeng0627/XT2611-OOS17-PortFix/releases/download/v1.1.0/AVR_PortFix-v1.1.0.zip)**
   综合核心修复模块，内置 Material Design 3 动态取色 WebUI，支持 17 项功能独立开关与实时状态巡检，免刷额外修改版 `system.img`。
2. **[MotCamera5-patched-signed.apk](https://github.com/changfeng0627/XT2611-OOS17-PortFix/releases/download/v1.1.0/MotCamera5-patched-signed.apk)**
   补丁版摩托原厂相机（位于本仓库 **Releases → v1.1.0 → Assets**），配合模块自动注入原厂离线后处理引擎，恢复暗光多帧降噪与 HDR 算法。

## 安装步骤

1. **刷入模块**
   - 在 KernelSU / KernelSU Next / APatch / Magisk 中直接刷入 `AVR_PortFix-v1.1.0.zip` 并重启。
   - **WebUI 说明**：KSU / KSU Next / APatch 在模块列表点击「打开」即可进入 MD3 控制台；Magisk 用户默认全功能生效，如需图形化开关可额外安装 KsuWebUI 独立版打开。
2. **安装补丁相机（恢复多帧算法）**
   - 前往本仓库 [Releases (v1.1.0)](https://github.com/changfeng0627/XT2611-OOS17-PortFix/releases/tag/v1.1.0) 下载 `MotCamera5-patched-signed.apk`。
   - 如已内置不同签名的摩托相机，先通过 LSPosed 开启核心破解（CorePatch）或卸载原版，再安装 `MotCamera5-patched-signed.apk`，装完重启一次（或在 WebUI 里重新开关一次「摩托相机多帧降噪」）即可生效。
3. **可选：国行游戏助手增强**
   - 模块已移除欧盟阉割标记 `com.games.euex`；可配合国行版游戏助手与 LuckyTool（LSPosed 勾选游戏助手作用域）解锁更多功能。

## 内置 17 项功能

WebUI 全部支持独立开关，配置持久化保存在 `/data/adb/avr_portfix/config.conf`。

### 显示与刷新率
- **真 2K QHD+ 控制中心零留白校准**：校准 634 物理/默认密度与 5 档缩放，真 2K 下既能用精致小 UI，又让下拉控制中心和锁屏无留白。
- **144Hz 极速高刷支持与自愈**：内置 144Hz 刷新率与 VRR 配置，设置内直接支持 120 / 144Hz 切换，重启不掉档。
- **全局固定 144Hz**：默认关闭，开启后锁定全局 144Hz，关闭恢复自适应。

### 相机与音频
- **摩托原厂杜比全景声 (DAX3)**：集成并修补原厂 `daxService` 与杜比全景声应用，直驱底层 `vendor.dolby.dms` 硬件杜比引擎与 6 套扬声器调音；已适配氧OS 原生卡片分组（位于「设置 → 声音与振动 → 音效 → 杜比全景声」）、桌面图标与控制中心快捷开关，无需手动设置 KSU 卸载模块。
- **摩托相机多帧降噪与离线 ISP 算法**：补齐原厂 `libenginepostproc.moto.so` 与 AIDL 客户端及 SELinux 权限，修复暗光满屏噪点与 `RAW_HDR` 回退。
- **相机扩展 ANR 修复**：跳过缺失的 `sendextcamcmd` 等待，修复微信扫一扫与第三方调用卡死。
- **前摄美颜防预览卡死**：自动保持前摄美颜关闭，避免 Meishe 渲染失败导致前置预览冻结。
- **Google 智能镜头指向修正**：修正 OEM 相机指向 Moto 相机，恢复智能镜头拉起。
- **游戏音频去 FAST 修复**：修复部分游戏破音或无声。
- **USB-C DAC 硬件音量映射**：同步系统媒体音量到外接 USB-C 小尾巴硬件增益。

### 性能、后台与硬件
- **后台留存优化**：开启 Android 原生 cgroup 墓碑冻结，解除幽灵进程限制并放宽 16GB 杀后台水位。
- **真实内存拓展**：通过 `nandswap_tool` 在摩托内核上真实挂载 4/8/12GB F2FS Pinned Swapfile。
- **真实电池健康同步**：读取摩托内核硬件 `state_of_health` 同步到设置电池健康页面。

### 本土化与系统
- **国行 5G 信号格数校准**：将国际版过严的 5G 阈值校准为国行标准，修复强信号仅显示 1~3 格。
- **百度网络定位与逆地理编码**：内置国行百度网络定位组件，修复室内、天气及 App 定位失败。
- **国行游戏助手去 EUEX 限制**：移除欧盟阉割标记，保留其他 GMS 与海外特性。
- **OTA 后台防崩溃**：仅禁用后台自启广播与服务防刷屏崩溃，保留关于本机顶部系统版本卡片。

## 仓库结构与自行打包

```text
.
├── module/                  # Root 模块完整源码（脚本、配置、WebUI、杜比与定位组件）
│   ├── module.prop
│   ├── customize.sh
│   ├── post-fs-data.sh
│   ├── service.sh
│   ├── usbvol.sh
│   ├── sepolicy.rule
│   └── webroot/             # Material Design 3 动态取色 WebUI
└── scripts/
    └── build_zip.py         # 一键打包脚本
```

本地重新打包模块：

```bash
python scripts/build_zip.py
```

## 更新日志

- **v1.1.0**
  - 新增并集成摩托原厂真杜比全景声（`DAX3`），直驱 `vendor.dolby.dms` 硬件杜比引擎与 6 套扬声器调音。
  - 修复「设置 → 声音与振动」中杜比全景声入口位置错位与卡片贴边问题，完美嵌入原生「音效」分组卡片内。
  - MD3 WebUI 升级至 `v1.1.0`，新增杜比全景声即时开关与引擎挂载状态巡检；补齐 Magisk `META-INF` 通用安装脚本。
- **v1.0.0**
  - 首个公开综合修复版本（内置 16 项核心修复与 MD3 动态取色 WebUI）。

## 致谢

- 移植底包：[Goubata/AVR-OxygenOS-Port](https://github.com/Goubata/AVR-OxygenOS-Port)
- 开源协议：[MIT License](LICENSE)
