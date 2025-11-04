// レイアウト切り替えユーティリティ
import { isMobileDevice, watchDeviceChange } from 'utils/device_detection';

// レイアウトを切り替える
export function switchLayout() {
  const isMobile = isMobileDevice();

  // デスクトップ専用要素
  const desktopElements = document.querySelectorAll('[data-layout="desktop"]');
  desktopElements.forEach(el => {
    el.style.display = isMobile ? 'none' : '';
  });

  // モバイル専用要素
  const mobileElements = document.querySelectorAll('[data-layout="mobile"]');
  mobileElements.forEach(el => {
    el.style.display = isMobile ? '' : 'none';
  });

  // サイドバーのスタイル調整
  const sidebar = document.getElementById('sidebar');
  if (sidebar) {
    if (isMobile) {
      // モバイル：スライド式
      sidebar.classList.add('mobile-sidebar');
      sidebar.classList.remove('desktop-sidebar');
    } else {
      // デスクトップ：固定表示
      sidebar.classList.add('desktop-sidebar');
      sidebar.classList.remove('mobile-sidebar');
    }
  }

  // メインコンテンツのマージン調整
  const mainContent = document.getElementById('main-content');
  if (mainContent) {
    if (isMobile) {
      mainContent.classList.add('mobile-content');
      mainContent.classList.remove('desktop-content');
    } else {
      mainContent.classList.add('desktop-content');
      mainContent.classList.remove('mobile-content');
    }
  }

  console.log(`Layout switched to: ${isMobile ? 'mobile' : 'desktop'}`);
}

// 初期化：ページ読み込み時とリサイズ時にレイアウトを切り替え
export function initLayoutSwitcher() {
  // 初回実行
  switchLayout();

  // 画面サイズ変更を監視
  watchDeviceChange((deviceType) => {
    console.log(`Device changed to: ${deviceType}`);
    switchLayout();
  });
}

// DOMContentLoaded時に自動初期化
if (typeof document !== 'undefined') {
  document.addEventListener('DOMContentLoaded', initLayoutSwitcher);
}
