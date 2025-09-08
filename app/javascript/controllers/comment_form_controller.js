import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "charCount", "form", "xPosition", "yPosition"]

  connect() {
    console.log("Comment Form Controller connected!")
    this.updateCharCount()
    this.setupFormSubmission()
  }

  setupFormSubmission() {
    if (this.hasFormTarget) {
      this.formTarget.addEventListener('submit', (event) => {
        this.handleFormSubmission(event)
      })
    }
  }

  async handleFormSubmission(event) {
    const hasCoordinates = this.hasXPositionTarget && this.hasYPositionTarget && 
                          this.xPositionTarget.value && this.yPositionTarget.value
    
    if (hasCoordinates) {
      // 画像上のコメントの場合は、Ajaxで送信
      event.preventDefault()
      await this.submitImageComment()
    }
    // 通常のコメントの場合はそのまま送信
  }

  async submitImageComment() {
    const formData = new FormData(this.formTarget)
    
    try {
      const response = await fetch(this.formTarget.action, {
        method: 'POST',
        body: formData,
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const comment = await response.json()
        
        // image_comments controllerに成功を通知
        this.notifyImageCommentsController(comment)
        
        // フォームをクリア
        this.clearForm()
        
        // 成功メッセージ
        this.showSuccessMessage()
        
        // ページをリロードしてコメント一覧を更新
        setTimeout(() => {
          window.location.reload()
        }, 1000)
      } else {
        const errorData = await response.json()
        console.error('Comment submission failed:', errorData)
        alert('コメントの投稿に失敗しました。')
      }
    } catch (error) {
      console.error('Error submitting comment:', error)
      alert('エラーが発生しました。')
    }
  }

  notifyImageCommentsController(comment) {
    const imageCommentsElement = document.querySelector('[data-controller*="image-comments"]')
    if (imageCommentsElement) {
      const controller = this.application.getControllerForElementAndIdentifier(
        imageCommentsElement, 
        'image-comments'
      )
      if (controller) {
        controller.onCommentSubmitted(comment)
      }
    }
  }

  clearForm() {
    if (this.hasTextareaTarget) {
      this.textareaTarget.value = ''
      this.textareaTarget.placeholder = '画像を見ながらコメントを書いてみましょう...'
    }
    if (this.hasXPositionTarget) this.xPositionTarget.value = ''
    if (this.hasYPositionTarget) this.yPositionTarget.value = ''
    this.updateCharCount()
  }

  showSuccessMessage() {
    const message = document.createElement('div')
    message.className = 'fixed top-4 right-4 bg-green-500 text-white px-4 py-2 rounded shadow-lg z-50'
    message.textContent = 'コメントを投稿しました！'
    document.body.appendChild(message)
    
    setTimeout(() => {
      message.remove()
    }, 3000)
  }

  textareaTargetConnected() {
    this.textareaTarget.addEventListener("input", () => {
      this.updateCharCount()
    })
  }

  updateCharCount() {
    if (this.hasTextareaTarget && this.hasCharCountTarget) {
      const currentLength = this.textareaTarget.value.length
      this.charCountTarget.textContent = currentLength
      
      // 文字数による色の変更
      if (currentLength > 450) {
        this.charCountTarget.classList.remove("text-gray-500", "text-yellow-500")
        this.charCountTarget.classList.add("text-red-500")
      } else if (currentLength > 400) {
        this.charCountTarget.classList.remove("text-gray-500", "text-red-500")
        this.charCountTarget.classList.add("text-yellow-500")
      } else {
        this.charCountTarget.classList.remove("text-yellow-500", "text-red-500")
        this.charCountTarget.classList.add("text-gray-500")
      }
    }
  }



  // 外部からアクセスできるようにグローバルに登録
  static getInstance() {
    return document.querySelector('[data-controller*="comment-form"]')?.commentFormController
  }
}

// グローバルアクセス用
window.CommentFormController = CommentFormController