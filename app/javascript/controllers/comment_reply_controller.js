import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["replyForm", "replyButton", "textarea", "form"]
  static values = {
    commentId: Number,
    postId: Number
  }

  connect() {
    console.log("Comment reply controller connected for comment:", this.commentIdValue)
  }

  toggleReplyForm(event) {
    event.preventDefault()

    const isHidden = this.replyFormTarget.classList.contains('hidden')

    if (isHidden) {
      this.showReplyForm()
    } else {
      this.hideReplyForm()
    }
  }

  showReplyForm() {
    this.replyFormTarget.classList.remove('hidden')
    this.replyButtonTarget.textContent = '返信を閉じる'
    this.replyButtonTarget.classList.add('text-gray-500')
    this.replyButtonTarget.classList.remove('text-blue-500', 'hover:text-blue-700')

    // テキストエリアにフォーカス
    setTimeout(() => {
      this.textareaTarget.focus()
    }, 100)
  }

  hideReplyForm() {
    this.replyFormTarget.classList.add('hidden')
    this.replyButtonTarget.textContent = '返信'
    this.replyButtonTarget.classList.remove('text-gray-500')
    this.replyButtonTarget.classList.add('text-blue-500', 'hover:text-blue-700')

    // テキストエリアをクリア
    this.textareaTarget.value = ''
  }

  submitReply(event) {
    event.preventDefault()

    const form = this.formTarget
    const formData = new FormData(form)

    fetch(form.action, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
        'Accept': 'application/json'
      },
      body: formData
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // 成功時はページをリロード（簡単な実装）
        window.location.reload()
      } else {
        console.error('返信エラー:', data.error)
        alert('返信の投稿に失敗しました。')
      }
    })
    .catch(error => {
      console.error('通信エラー:', error)
      alert('通信エラーが発生しました。')
    })
  }
}