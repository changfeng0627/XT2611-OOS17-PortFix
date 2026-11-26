// AVR Port Fix v1.1.0 — KernelSU WebUI (MD3 Expressive + Monet Dynamic Color)
const CFG_DIR = '/data/adb/avr_portfix';
const CFG_PATH = '/data/adb/avr_portfix/config.conf';
const MOD_DIR = '/data/adb/modules/avr_portfix';

const DEFAULTS = {
  CAM_EXT_FIX: '1',
  CAM_POSTPROC_FIX: '1',
  CAM_FRONT_BEAUTY_OFF: '1',
  DOLBY_ATMOS_FIX: '1',
  AUDIO_NOFAST_FIX: '1',
  USB_DAC_VOL_FIX: '1',
  REFRESH_144_FIX: '1',
  GLOBAL_144: '0',
  QHD_DPI_FIX: '1',
  RAMEXT_FIX: '1',
  BATT_HEALTH_FIX: '1',
  BAIDU_NLP_FIX: '1',
  BG_RETENTION_FIX: '1',
  OTA_BG_DISABLE: '1',
  GAMES_CN_UNLOCK: '1',
  LENS_OEM_FIX: '1',
  SIGNAL_5G_FIX: '1',
};

let currentConfig = { ...DEFAULTS };
let cbSeq = 0;

function exec(cmd) {
  return new Promise((resolve) => {
    if (typeof ksu !== 'undefined' && typeof ksu.exec === 'function') {
      const cbName = `_ksu_cb_${Date.now()}_${++cbSeq}`;
      window[cbName] = (errno, stdout, stderr) => {
        delete window[cbName];
        resolve({ errno: Number(errno), stdout: stdout || '', stderr: stderr || '' });
      };
      try {
        ksu.exec(cmd, '{}', cbName);
      } catch (e) {
        delete window[cbName];
        resolve({ errno: 1, stdout: '', stderr: String(e) });
      }
    } else {
      resolve({ errno: 0, stdout: '', stderr: 'mock' });
    }
  });
}

let toastTimer = null;
function showSnack(msg) {
  const el = document.getElementById('snackbar');
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove('show'), 2600);
}

function hexToHsl(hex) {
  hex = hex.replace(/^#/, '');
  if (hex.length === 8) hex = hex.slice(2);
  if (hex.length !== 6) return null;
  const r = parseInt(hex.slice(0, 2), 16) / 255;
  const g = parseInt(hex.slice(2, 4), 16) / 255;
  const b = parseInt(hex.slice(4, 6), 16) / 255;
  const max = Math.max(r, g, b), min = Math.min(r, g, b);
  let h = 0, s = 0, l = (max + min) / 2;
  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r: h = (g - b) / d + (g < b ? 6 : 0); break;
      case g: h = (b - r) / d + 2; break;
      case b: h = (r - g) / d + 4; break;
    }
    h *= 60;
  }
  return { h: Math.round(h), s: Math.round(s * 100), l: Math.round(l * 100) };
}

function applyMonetFromHue(h, sat) {
  const s = Math.min(Math.max(sat, 28), 72);
  const dark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  const r = document.documentElement.style;
  const hSec = (h + 12) % 360;
  const hTer = (h + 60) % 360;

  if (dark) {
    r.setProperty('--md-sys-color-primary', `hsl(${h}, ${Math.min(s + 18, 90)}%, 82%)`);
    r.setProperty('--md-sys-color-on-primary', `hsl(${h}, ${Math.min(s + 15, 85)}%, 20%)`);
    r.setProperty('--md-sys-color-primary-container', `hsl(${h}, ${Math.min(s + 5, 70)}%, 28%)`);
    r.setProperty('--md-sys-color-on-primary-container', `hsl(${h}, ${Math.min(s + 20, 95)}%, 92%)`);
    r.setProperty('--md-sys-color-secondary-container', `hsl(${hSec}, 24%, 27%)`);
    r.setProperty('--md-sys-color-on-secondary-container', `hsl(${hSec}, 40%, 90%)`);
    r.setProperty('--md-sys-color-tertiary-container', `hsl(${hTer}, 30%, 28%)`);
    r.setProperty('--md-sys-color-on-tertiary-container', `hsl(${hTer}, 60%, 92%)`);
    r.setProperty('--md-sys-color-surface', `hsl(${h}, 14%, 8%)`);
    r.setProperty('--md-sys-color-surface-container-low', `hsl(${h}, 14%, 11%)`);
    r.setProperty('--md-sys-color-surface-container', `hsl(${h}, 15%, 13%)`);
    r.setProperty('--md-sys-color-surface-container-high', `hsl(${h}, 16%, 17%)`);
    r.setProperty('--md-sys-color-on-surface', `hsl(${h}, 16%, 91%)`);
    r.setProperty('--md-sys-color-on-surface-variant', `hsl(${h}, 12%, 78%)`);
    r.setProperty('--md-sys-color-outline', `hsl(${h}, 10%, 58%)`);
    r.setProperty('--md-sys-color-inverse-surface', `hsl(${h}, 16%, 91%)`);
    r.setProperty('--md-sys-color-inverse-on-surface', `hsl(${h}, 14%, 16%)`);
  } else {
    r.setProperty('--md-sys-color-primary', `hsl(${h}, ${Math.min(s + 8, 75)}%, 40%)`);
    r.setProperty('--md-sys-color-on-primary', `#FFFFFF`);
    r.setProperty('--md-sys-color-primary-container', `hsl(${h}, ${Math.min(s + 22, 92)}%, 91%)`);
    r.setProperty('--md-sys-color-on-primary-container', `hsl(${h}, ${Math.min(s + 15, 85)}%, 14%)`);
    r.setProperty('--md-sys-color-secondary-container', `hsl(${hSec}, 38%, 90%)`);
    r.setProperty('--md-sys-color-on-secondary-container', `hsl(${hSec}, 32%, 16%)`);
    r.setProperty('--md-sys-color-tertiary-container', `hsl(${hTer}, 48%, 90%)`);
    r.setProperty('--md-sys-color-on-tertiary-container', `hsl(${hTer}, 38%, 16%)`);
    r.setProperty('--md-sys-color-surface', `hsl(${h}, 30%, 98.5%)`);
    r.setProperty('--md-sys-color-surface-container-low', `hsl(${h}, 26%, 96%)`);
    r.setProperty('--md-sys-color-surface-container', `hsl(${h}, 24%, 94%)`);
    r.setProperty('--md-sys-color-surface-container-high', `hsl(${h}, 22%, 91%)`);
    r.setProperty('--md-sys-color-on-surface', `hsl(${h}, 16%, 11%)`);
    r.setProperty('--md-sys-color-on-surface-variant', `hsl(${h}, 12%, 30%)`);
    r.setProperty('--md-sys-color-outline', `hsl(${h}, 10%, 46%)`);
    r.setProperty('--md-sys-color-inverse-surface', `hsl(${h}, 14%, 19%)`);
    r.setProperty('--md-sys-color-inverse-on-surface', `hsl(${h}, 22%, 95%)`);
  }
}

async function initMonetTheme() {
  const res = await exec('settings get secure theme_customization_overlay_packages');
  if (res.errno === 0 && res.stdout) {
    const m = res.stdout.match(/android\.theme\.customization\.system_palette"\s*:\s*"#?([0-9a-fA-F]{6,8})"/);
    if (m && m[1]) {
      const hsl = hexToHsl(m[1]);
      if (hsl) { applyMonetFromHue(hsl.h, hsl.s); return; }
    }
  }
  const res2 = await exec('settings get system oplus_customize_ux_color');
  if (res2.errno === 0 && res2.stdout && /^[0-9-]+$/.test(res2.stdout.trim())) {
    const val = (parseInt(res2.stdout.trim(), 10) >>> 0).toString(16).padStart(8, '0').slice(-6);
    const hsl = hexToHsl(val);
    if (hsl) applyMonetFromHue(hsl.h, hsl.s);
  }
}

async function loadConfig() {
  await exec(`mkdir -p ${CFG_DIR}; [ -f ${CFG_PATH} ] || cp ${MOD_DIR}/config.default.conf ${CFG_PATH} 2>/dev/null`);
  const res = await exec(`cat ${CFG_PATH} 2>/dev/null`);
  currentConfig = { ...DEFAULTS };
  if (res.stdout) {
    res.stdout.split('\n').forEach((line) => {
      const m = line.trim().match(/^([A-Z0-9_]+)=([01])$/);
      if (m && Object.prototype.hasOwnProperty.call(DEFAULTS, m[1])) {
        currentConfig[m[1]] = m[2];
      }
    });
  }
  document.querySelectorAll('input[data-key]').forEach((el) => {
    el.checked = currentConfig[el.dataset.key] === '1';
  });
}

async function saveConfig() {
  const lines = ['# AVR Port Fix 配置（由 WebUI 自动维护）'];
  Object.keys(DEFAULTS).forEach((k) => lines.push(`${k}=${currentConfig[k]}`));
  const body = lines.join('\n') + '\n';
  await exec(`mkdir -p ${CFG_DIR} && cat << 'EOF' > ${CFG_PATH}\n${body}EOF`);
}

async function applyLiveAction(liveType, enabled) {
  switch (liveType) {
    case 'global144':
      if (enabled) {
        await exec('settings put system min_refresh_rate 144.00002; settings put system peak_refresh_rate 144.00002; settings put secure oplus_customize_screen_refresh_rate 0; touch /data/adb/avr_portfix/.global144_was_on');
      } else {
        await exec('settings delete system min_refresh_rate; settings put system peak_refresh_rate 144.00002; rm -f /data/adb/avr_portfix/.global144_was_on /data/adb/modules/avr_portfix/enable_global144');
      }
      break;
    case 'bgretention':
      if (enabled) {
        await exec('settings put global cached_apps_freezer enabled; device_config put activity_manager_native_boot use_freezer true; device_config put activity_manager max_cached_processes 256; device_config put activity_manager max_phantom_processes 2147483647; settings put global settings_enable_monitor_phantom_procs false; echo 20 > /proc/sys/vm/watermark_scale_factor; echo 80 > /proc/sys/vm/swappiness; setprop sys.lmk.minfree_levels "18432:0,23040:100,27648:200,32256:250,40960:900,51200:950"; setprop lmkd.reinit 1');
      } else {
        await exec('settings delete global cached_apps_freezer; device_config delete activity_manager_native_boot use_freezer; echo 52 > /proc/sys/vm/watermark_scale_factor; echo 100 > /proc/sys/vm/swappiness');
      }
      break;
    case 'ramext':
    case 'batthealth':
    case 'campostproc':
    case 'signal5g':
    case 'dolbyatmos':
      await exec(`sh ${MOD_DIR}/service.sh --sync >/dev/null 2>&1`);
      break;
    case 'usbdac':
      if (enabled) {
        await exec(`pgrep -f "${MOD_DIR}/usbvol.sh" >/dev/null || (nohup sh ${MOD_DIR}/usbvol.sh >/dev/null 2>&1 &)`);
      } else {
        await exec(`pkill -f "${MOD_DIR}/usbvol.sh" 2>/dev/null`);
      }
      break;
    case 'otabg':
      if (enabled) {
        await exec('pm enable com.oplus.ota; for c in .strategy.StrategyReceiver .strategy.UpgradeInviteReceiver .service.OTAService .push.OtaPushService .enterprise.EnterpriseOTAService; do pm disable "com.oplus.ota/$c"; done');
      } else {
        await exec('pm enable com.oplus.ota; for c in .strategy.StrategyReceiver .strategy.UpgradeInviteReceiver .service.OTAService .push.OtaPushService .enterprise.EnterpriseOTAService; do pm enable "com.oplus.ota/$c"; done');
      }
      break;
    case 'baidunlp':
      if (enabled) {
        await exec('pm enable com.baidu.map.location >/dev/null 2>&1');
      } else {
        await exec('pm disable-user --user 0 com.baidu.map.location >/dev/null 2>&1');
      }
      break;
    case 'frontbeauty':
      if (enabled) {
        await exec(`rm -f ${MOD_DIR}/enable_front_beauty; sh ${MOD_DIR}/service.sh --sync >/dev/null 2>&1`);
      } else {
        await exec(`touch ${MOD_DIR}/enable_front_beauty`);
      }
      break;
  }
}

async function refreshStatus() {
  const btn = document.getElementById('btn-refresh');
  btn.classList.add('spinning');

  const cmd = `
    SZ=$(wm size 2>/dev/null | tail -n 1 | awk '{print $NF}')
    DP=$(wm density 2>/dev/null | tail -n 1 | awk '{print $NF}')
    QHD=$(getprop ro.oplus.density.qhd_default)
    SWAP=$(awk '/swapfile/{printf "%.0fG", $3/1048576}' /proc/swaps 2>/dev/null)
    [ -z "$SWAP" ] && SWAP="关闭"
    SOH=$(cat /sys/class/power_supply/battery/state_of_health 2>/dev/null | tr -dc '0-9')
    CAM=$(ls /data/app/~~*/com.motorola.camera5-*/lib/arm64/libenginepostproc.moto.so 2>/dev/null | wc -l)
    DLB=$(dumpsys media.audio_flinger 2>/dev/null | grep -c "Dolby Laboratories"); [ -z "$DLB" ] && DLB=0
    NLP=$(dumpsys location 2>/dev/null | grep -q "com.baidu.map.location.*connected=true" && echo "已连接" || echo "待唤醒")
    FRZ=$(settings get global cached_apps_freezer 2>/dev/null)
    EUEX=$(grep -c "com.games.euex" /my_stock/etc/permissions/com.oplus.android-features.xml 2>/dev/null); [ -z "$EUEX" ] && EUEX=0
    echo "SZ=$SZ|DP=$DP|QHD=$QHD|SWAP=$SWAP|SOH=$SOH|CAM=$CAM|DLB=$DLB|NLP=$NLP|FRZ=$FRZ|EUEX=$EUEX"
  `;
  const res = await exec(cmd);
  const kv = {};
  (res.stdout || '').trim().split('|').forEach((pair) => {
    const idx = pair.indexOf('=');
    if (idx > 0) kv[pair.slice(0, idx)] = pair.slice(idx + 1).trim();
  });

  document.getElementById('m-disp').textContent = `${kv.SZ || '--'} · ${kv.DP || '--'}dpi (QHD锁${kv.QHD || '--'})`;
  document.getElementById('m-ram-batt').textContent = `Swap ${kv.SWAP || '--'} · 电池 ${kv.SOH ? kv.SOH + '%' : '--'}`;
  document.getElementById('m-cam-loc').textContent = `多帧${kv.CAM === '1' ? '就绪' : '待装'} · 杜比${Number(kv.DLB) > 0 ? '已挂载' : '关闭'} · 定位${kv.NLP || '--'}`;
  document.getElementById('m-bg-game').textContent = `墓碑${kv.FRZ === 'enabled' ? '开' : '关'} · 游戏${kv.EUEX === '0' ? '国行已解' : 'EUEX'}`;

  const okCount = [
    kv.QHD === '634',
    kv.SWAP && kv.SWAP !== '关闭',
    kv.CAM === '1',
    Number(kv.DLB) > 0,
    kv.FRZ === 'enabled',
    kv.EUEX === '0',
  ].filter(Boolean).length;

  const pill = document.getElementById('overall-pill');
  pill.textContent = okCount === 6 ? `全部已生效 (6/6)` : (okCount >= 5 ? `运行正常 (${okCount}/6)` : `部分待生效 (${okCount}/6)`);

  setTimeout(() => btn.classList.remove('spinning'), 350);
}

function bindEvents() {
  document.querySelectorAll('input[data-key]').forEach((el) => {
    el.addEventListener('change', async () => {
      const key = el.dataset.key;
      const checked = el.checked;
      currentConfig[key] = checked ? '1' : '0';
      el.disabled = true;
      await saveConfig();

      if (el.dataset.live) {
        await applyLiveAction(el.dataset.live, checked);
        showSnack(`${checked ? '已开启' : '已关闭'}并即时生效`);
        refreshStatus();
      } else if (el.dataset.reboot === '1') {
        document.getElementById('reboot-banner').classList.remove('hidden');
        showSnack(`已保存（${checked ? '开启' : '关闭'}），重启后生效`);
      }
      el.disabled = false;
    });
  });

  document.getElementById('btn-refresh').addEventListener('click', () => {
    refreshStatus();
    showSnack('状态已刷新');
  });

  document.getElementById('btn-reboot').addEventListener('click', async () => {
    showSnack('正在重启设备…');
    await exec('svc power reboot || reboot');
  });

  document.getElementById('btn-reset-default').addEventListener('click', async () => {
    currentConfig = { ...DEFAULTS };
    await saveConfig();
    document.querySelectorAll('input[data-key]').forEach((el) => {
      el.checked = currentConfig[el.dataset.key] === '1';
    });
    document.getElementById('reboot-banner').classList.remove('hidden');
    showSnack('已恢复全部默认开关，重启后完整生效');
  });

  if (window.matchMedia) {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', initMonetTheme);
  }
}

window.addEventListener('DOMContentLoaded', async () => {
  bindEvents();
  await initMonetTheme();
  await loadConfig();
  await refreshStatus();
});
