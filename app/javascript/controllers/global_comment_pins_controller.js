import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggleButton", "toggleIcon", "toggleText"]

  connect() {
    console.log("Global Comment Pins Controller connected!")
    this.globalPinsVisible = localStorage.getItem('globalCommentPinsVisible') === 'true'
    this.updateButtonState()
    this.updateAllPins()
    
    // 個別コントローラーからの同期イベントを監視
    this.handleIndividualToggle = this.handleIndividualToggle.bind(this)
    window.addEventListener('individualCommentPinToggled', this.handleIndividualToggle)
  }

  toggleGlobalPins() {
    console.log("Toggling global comment pins")
    this.globalPinsVisible = !this.globalPinsVisible
    localStorage.setItem('globalCommentPinsVisible', this.globalPinsVisible)
    
    this.updateButtonState()
    this.updateAllPins()
    
    // カスタムイベントを発火して他のコントローラーに通知
    window.dispatchEvent(new CustomEvent('globalCommentPinsToggled', {
      detail: { visible: this.globalPinsVisible }
    }))
  }

  updateButtonState() {
    if (!this.hasToggleButtonTarget) return
    
    const button = this.toggleButtonTarget
    const icon = this.hasToggleIconTarget ? this.toggleIconTarget : null
    const text = this.hasToggleTextTarget ? this.toggleTextTarget : null
    
    if (this.globalPinsVisible) {
      button.classList.remove('border-gray-300', 'hover:bg-gray-50')
      button.classList.add('border-blue-500', 'bg-blue-50', 'text-blue-700')
      if (icon) icon.textContent = '🙈'
      if (text) text.textContent = 'コメントピン一括非表示'
    } else {
      button.classList.remove('border-blue-500', 'bg-blue-50', 'text-blue-700')
      button.classList.add('border-gray-300', 'hover:bg-gray-50')
      if (icon) icon.textContent = '👁️'
      if (text) text.textContent = 'コメントピン一括表示'
    }
  }

  updateAllPins() {
    console.log("Updating all pins, visibility:", this.globalPinsVisible)
    
    // カスタムイベントを発火して他のコントローラーに通知
    window.dispatchEvent(new CustomEvent('globalCommentPinsToggled', {
      detail: { visible: this.globalPinsVisible }
    }))
  }

  // 個別コントローラーからの同期
  syncFromIndividual(visible) {
    this.globalPinsVisible = visible
    this.updateButtonState()
  }

  // 個別コントローラーからの通知を処理
  handleIndividualToggle(event) {
    console.log("Individual toggle received:", event.detail.visible)
    this.globalPinsVisible = event.detail.visible
    this.updateButtonState()
    // localStorage も更新（既に individual controller で更新済みだが、念のため）
    localStorage.setItem('globalCommentPinsVisible', this.globalPinsVisible)
  }

  disconnect() {
    // イベントリスナーを削除
    window.removeEventListener('individualCommentPinToggled', this.handleIndividualToggle)
  }
}