import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "toggleButton", "assistantContent", "loading", "results", "error",
    "commentExamples", "observationPoints", "observationToggle", "observationIcon"
  ]
  static values = { postId: Number }

  connect() {
    console.log("AI Comment Assistant Controller connected!")
    console.log("Post ID:", this.postIdValue)
  }

  async toggleAssistant() {
    const isHidden = this.assistantContentTarget.classList.contains('hidden')
    
    if (isHidden) {
      // 補助機能を開始
      this.assistantContentTarget.classList.remove('hidden')
      this.toggleButtonTarget.textContent = '補助を閉じる'
      this.toggleButtonTarget.classList.remove('bg-blue-600', 'hover:bg-blue-700')
      this.toggleButtonTarget.classList.add('bg-gray-500', 'hover:bg-gray-600')
      
      // 既に結果が表示されている場合は分析をスキップ
      if (!this.resultsTarget.classList.contains('hidden')) {
        return
      }
      
      // AI分析を開始
      await this.analyzePost()
    } else {
      // 補助機能を閉じる
      this.assistantContentTarget.classList.add('hidden')
      this.toggleButtonTarget.textContent = '補助を開始'
      this.toggleButtonTarget.classList.remove('bg-gray-500', 'hover:bg-gray-600')
      this.toggleButtonTarget.classList.add('bg-blue-600', 'hover:bg-blue-700')
    }
  }

  async analyzePost() {
    // ローディング表示
    this.showLoading()
    
    try {
      const response = await fetch(`/posts/${this.postIdValue}/ai_comment_assistant/analyze`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })
      
      const data = await response.json()
      
      if (data.success) {
        this.displayResults(data.comment_examples, data.observation_points)
      } else {
        this.showError(data.error || 'AI分析中にエラーが発生しました。')
      }
    } catch (error) {
      console.error('AI Comment Assistant Error:', error)
      this.showError('ネットワークエラーが発生しました。インターネット接続を確認してください。')
    }
  }

  showLoading() {
    this.hideAllStates()
    this.loadingTarget.classList.remove('hidden')
  }

  displayResults(commentExamples, observationPoints) {
    this.hideAllStates()
    
    // コメント例を表示
    this.renderCommentExamples(commentExamples)
    
    // 観察ポイントを表示
    this.renderObservationPoints(observationPoints)
    
    this.resultsTarget.classList.remove('hidden')
  }

  showError(message) {
    this.hideAllStates()
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove('hidden')
  }

  hideAllStates() {
    this.loadingTarget.classList.add('hidden')
    this.resultsTarget.classList.add('hidden')
    this.errorTarget.classList.add('hidden')
  }

  renderCommentExamples(examples) {
    this.commentExamplesTarget.innerHTML = ''
    
    examples.forEach((example, index) => {
      const exampleDiv = document.createElement('div')
      exampleDiv.className = 'p-3 bg-white rounded-lg border border-gray-200 hover:border-blue-300 transition-colors cursor-pointer'
      exampleDiv.innerHTML = `
        <div class="flex items-start gap-3">
          <span class="flex-shrink-0 w-6 h-6 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center text-sm font-semibold">${index + 1}</span>
          <div class="flex-1">
            <p class="text-gray-800 leading-relaxed">${this.escapeHtml(example)}</p>
            <div class="mt-2 flex gap-2">
              <button type="button" 
                      class="text-xs text-blue-600 hover:text-blue-800 font-medium"
                      data-action="click->ai-comment-assistant#useComment"
                      data-comment="${this.escapeHtml(example)}">
                このコメントを使用
              </button>
              <button type="button" 
                      class="text-xs text-gray-500 hover:text-gray-700 font-medium"
                      data-action="click->ai-comment-assistant#editComment"
                      data-comment="${this.escapeHtml(example)}">
                編集して使用
              </button>
            </div>
          </div>
        </div>
      `
      this.commentExamplesTarget.appendChild(exampleDiv)
    })
  }

  renderObservationPoints(points) {
    this.observationPointsTarget.innerHTML = ''
    
    const pointsList = document.createElement('ul')
    pointsList.className = 'space-y-2'
    
    points.forEach(point => {
      const li = document.createElement('li')
      li.className = 'flex items-start gap-2 text-gray-700'
      li.innerHTML = `
        <span class="flex-shrink-0 w-2 h-2 bg-blue-400 rounded-full mt-2"></span>
        <span>${this.escapeHtml(point)}</span>
      `
      pointsList.appendChild(li)
    })
    
    this.observationPointsTarget.appendChild(pointsList)
  }

  toggleObservationPoints() {
    const isHidden = this.observationPointsTarget.classList.contains('hidden')
    
    if (isHidden) {
      this.observationPointsTarget.classList.remove('hidden')
      this.observationIconTarget.textContent = '▲'
    } else {
      this.observationPointsTarget.classList.add('hidden')
      this.observationIconTarget.textContent = '▼'
    }
  }

  useComment(event) {
    const comment = event.currentTarget.dataset.comment
    this.insertCommentIntoForm(comment)
  }

  editComment(event) {
    const comment = event.currentTarget.dataset.comment
    this.insertCommentIntoForm(comment)
    
    // コメントフォームにフォーカスを当てる
    const commentTextArea = document.querySelector('textarea[name="comment[body]"]')
    if (commentTextArea) {
      commentTextArea.focus()
      // テキストの最後にカーソルを移動
      commentTextArea.setSelectionRange(commentTextArea.value.length, commentTextArea.value.length)
    }
  }

  insertCommentIntoForm(comment) {
    const commentTextArea = document.querySelector('textarea[name="comment[body]"]')
    if (commentTextArea) {
      commentTextArea.value = comment
      
      // 高さを自動調整（もしauto-resizeがある場合）
      commentTextArea.dispatchEvent(new Event('input', { bubbles: true }))
      
      // 成功フィードバック
      this.showSuccessMessage('コメントをフォームに挿入しました')
    } else {
      console.error('Comment textarea not found')
      alert('コメントフォームが見つかりません')
    }
  }

  showSuccessMessage(message) {
    const successDiv = document.createElement('div')
    successDiv.className = 'fixed top-4 right-4 bg-green-500 text-white px-4 py-2 rounded-lg shadow-lg z-50 transform translate-x-0 opacity-100 transition-all duration-300'
    successDiv.textContent = message
    
    document.body.appendChild(successDiv)
    
    // 3秒後にフェードアウト
    setTimeout(() => {
      successDiv.classList.add('translate-x-full', 'opacity-0')
      setTimeout(() => {
        if (successDiv.parentNode) {
          successDiv.parentNode.removeChild(successDiv)
        }
      }, 300)
    }, 3000)
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}