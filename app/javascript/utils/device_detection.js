// デバイス検出ユーティリティ（画面サイズ + User-Agent）
export function isMobileDevice() {
  const ua = navigator.userAgent.toLowerCase();
  const isMobileUA = /iphone|android(?!.*mobile)|ipod|ipad/.test(ua);
  const isSmallScreen = window.innerWidth <= 768; // 768px以下をモバイル扱い

  // User-Agentがモバイル OR 画面が小さい場合はモバイル
  return isMobileUA || isSmallScreen;
}

export function isDesktopDevice() {
  return !isMobileDevice();
}

// デバイスタイプを文字列で返す
export function getDeviceType() {
  return isMobileDevice() ? 'mobile' : 'desktop';
}

// 画面サイズ変更を監視してコールバックを実行
export function watchDeviceChange(callback) {
  let currentDeviceType = getDeviceType();

  window.addEventListener('resize', () => {
    const newDeviceType = getDeviceType();
    if (newDeviceType !== currentDeviceType) {
      currentDeviceType = newDeviceType;
      callback(newDeviceType);
    }
  });
}
