import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image"]

  connect() {
    // 画像が読み込まれた後にアスペクト比をチェック
    this.imageTarget.addEventListener('load', () => {
      this.checkAspectRatio()
    })
    
    // 既に画像が読み込まれている場合は即座にチェック
    if (this.imageTarget.complete) {
      this.checkAspectRatio()
    }
  }

  checkAspectRatio() {
    const img = this.imageTarget
    const aspectRatio = img.naturalWidth / img.naturalHeight
    
    // 横長の画像（アスペクト比が1.5以上）の場合
    if (aspectRatio >= 1.5) {
      // 小さいサイズのクラスを削除し、大きいサイズのクラスを追加
      img.classList.remove('max-w-xs')
      img.classList.add('max-w-xl', 'landscape-image')
    } else if (aspectRatio < 0.8) {
      // 縦長の画像（アスペクト比が0.8未満）の場合は小さく表示
      img.classList.remove('max-w-xs')
      img.classList.add('max-w-20', 'portrait-image')
    } else {
      // 正方形に近い画像は元のサイズを維持
      img.classList.add('square-image')
    }
  }
}