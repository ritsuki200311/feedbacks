import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggleButton", "toggleIcon", "commentsList"]

  connect() {
    console.log("Compact Comments Controller connected!")
    this.isExpanded = false
  }

  toggleComments() {
    this.isExpanded = !this.isExpanded
    
    if (this.isExpanded) {
      // コメント一覧を表示
      this.commentsListTarget.classList.remove('hidden')
      this.toggleIconTarget.textContent = '▲'
    } else {
      // コメント一覧を非表示
      this.commentsListTarget.classList.add('hidden')
      this.toggleIconTarget.textContent = '▼'
    }
  }

  // コンパクトコメントがクリックされた時の処理
  highlightComment(event) {
    const commentElement = event.currentTarget
    const commentId = commentElement.dataset.commentId
    
    // 既存のハイライトをリセット
    document.querySelectorAll('.compact-comment-highlight').forEach(el => {
      el.classList.remove('compact-comment-highlight')
    })
    
    // クリックされたコメントをハイライト
    commentElement.classList.add('compact-comment-highlight')
    
    // 対応するピンがあればハイライト（既存の機能を活用）
    if (commentId) {
      const imageController = document.querySelector('[data-controller*="image-comments"]')
      if (imageController) {
        const event = new CustomEvent('highlightMarker', {
          detail: { commentId: commentId }
        })
        imageController.dispatchEvent(event)
      }
    }
    
    // 2秒後にハイライトを削除
    setTimeout(() => {
      commentElement.classList.remove('compact-comment-highlight')
    }, 2000)
  }
}