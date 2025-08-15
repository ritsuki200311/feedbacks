import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "toggleButton", "toggleIcon", "toggleText", 
    "initialMessage", "loading", "aiContent",
    "commentSuggestions", "summary"
  ]
  static values = { postId: Number }

  connect() {
    console.log("AI Sidebar Controller connected!")
    this.aiLoaded = false
  }

  toggleAI() {
    const isAIVisible = !this.aiContentTarget.classList.contains('hidden')
    
    if (isAIVisible) {
      // AI機能を閉じる
      this.closeAI()
    } else {
      // AI機能を開始
      this.startAI()
    }
  }

  async startAI() {
    // 初期メッセージを隠す
    this.initialMessageTarget.classList.add('hidden')
    
    // ローディング表示
    this.loadingTarget.classList.remove('hidden')
    
    // ボタンの状態を更新
    this.toggleIconTarget.textContent = '⏳'
    this.toggleTextTarget.textContent = 'AI分析中...'
    this.toggleButtonTarget.disabled = true

    try {
      if (!this.aiLoaded) {
        // AI機能を初回のみ読み込み
        await this.loadAIContent()
        this.aiLoaded = true
      }
      
      // ローディングを隠してコンテンツを表示
      this.loadingTarget.classList.add('hidden')
      this.aiContentTarget.classList.remove('hidden')
      
      // ボタンの状態を更新
      this.toggleIconTarget.textContent = '✖️'
      this.toggleTextTarget.textContent = 'AI補助を閉じる'
      this.toggleButtonTarget.classList.remove('bg-purple-600', 'hover:bg-purple-700')
      this.toggleButtonTarget.classList.add('bg-gray-600', 'hover:bg-gray-700')
      
    } catch (error) {
      console.error('AI loading error:', error)
      this.showError()
    } finally {
      this.toggleButtonTarget.disabled = false
    }
  }

  closeAI() {
    // すべてのAI関連要素を隠す
    this.loadingTarget.classList.add('hidden')
    this.aiContentTarget.classList.add('hidden')
    
    // 初期メッセージを表示
    this.initialMessageTarget.classList.remove('hidden')
    
    // ボタンの状態をリセット
    this.toggleIconTarget.textContent = '🤖'
    this.toggleTextTarget.textContent = 'AI補助を開始'
    this.toggleButtonTarget.classList.remove('bg-gray-600', 'hover:bg-gray-700')
    this.toggleButtonTarget.classList.add('bg-purple-600', 'hover:bg-purple-700')
  }

  async loadAIContent() {
    // プレースホルダーのAI提案を生成（実際のAI機能はここで実装）
    const suggestions = [
      "この作品の色使いがとても魅力的ですね！特に背景の青色が印象的です。",
      "構図のバランスが素晴らしいと思います。どのような意図でこの配置にされたのでしょうか？",
      "線の太さや質感に工夫が感じられます。制作過程で特にこだわった部分はありますか？"
    ]
    
    const summary = "この作品は色彩豊かで魅力的な構成となっています。特に色使いと構図のバランスが印象的で、作者の技術力と創造性が感じられます。"
    
    // コメント提案を表示
    this.renderSuggestions(suggestions)
    
    // 要約を表示
    if (this.hasSummaryTarget) {
      this.summaryTarget.textContent = summary
    }
    
    // 実際の実装では、ここでAPIを呼び出してAI分析を行う
    await this.simulateAIProcessing()
  }

  renderSuggestions(suggestions) {
    this.commentSuggestionsTarget.innerHTML = ''
    
    suggestions.forEach((suggestion, index) => {
      const suggestionElement = document.createElement('div')
      suggestionElement.className = 'p-2 bg-purple-50 rounded border cursor-pointer hover:bg-purple-100 transition-colors text-sm mb-2'
      suggestionElement.innerHTML = `
        <p class="text-gray-700 mb-2">${suggestion}</p>
        <button class="text-xs text-purple-600 hover:text-purple-800 font-medium" 
                data-action="click->ai-sidebar#applySuggestion" 
                data-suggestion="${suggestion}">
          このコメントを使用
        </button>
      `
      this.commentSuggestionsTarget.appendChild(suggestionElement)
    })
  }

  simulateAIProcessing() {
    // AI処理のシミュレーション
    return new Promise(resolve => {
      setTimeout(resolve, 1500)
    })
  }

  showError() {
    this.loadingTarget.classList.add('hidden')
    this.initialMessageTarget.classList.remove('hidden')
    
    const errorMessage = document.createElement('div')
    errorMessage.className = 'text-center py-4 text-red-600 text-sm'
    errorMessage.textContent = 'AI機能の読み込みに失敗しました。再試行してください。'
    
    this.initialMessageTarget.appendChild(errorMessage)
    
    setTimeout(() => {
      errorMessage.remove()
    }, 5000)
  }

  applySuggestion(event) {
    const suggestion = event.currentTarget.dataset.suggestion
    this.insertIntoCommentField(suggestion)
  }

  applyTone(event) {
    const tone = event.currentTarget.dataset.tone
    // コメントフォームコントローラーと連携
    const commentFormController = this.getCommentFormController()
    if (commentFormController) {
      commentFormController.applyTone(tone)
    }
  }

  // コメントフォームコントローラーを取得
  getCommentFormController() {
    const commentFormElement = document.querySelector('[data-controller*="comment-form"]')
    if (commentFormElement) {
      return this.application.getControllerForElementAndIdentifier(commentFormElement, 'comment-form')
    }
    return null
  }

  // コメントフィールドに提案を挿入
  insertIntoCommentField(suggestion) {
    const commentFormController = this.getCommentFormController()
    if (commentFormController) {
      // 提案をそのまま適用するか、追加するかを選択
      const confirmReplace = confirm('現在のテキストを置き換えますか？\n「キャンセル」を選ぶと末尾に追加されます。')
      
      if (confirmReplace) {
        commentFormController.applySuggestion(suggestion)
      } else {
        commentFormController.insertSuggestion(' ' + suggestion)
      }
      
      // 成功フィードバック
      this.showFeedback('コメントに反映しました！')
    }
  }

  // フィードバック表示
  showFeedback(message) {
    const feedback = document.createElement('div')
    feedback.className = 'fixed top-4 right-4 bg-green-500 text-white px-4 py-2 rounded-lg shadow-lg z-50 text-sm'
    feedback.textContent = message
    document.body.appendChild(feedback)
    
    setTimeout(() => {
      feedback.remove()
    }, 2000)
  }

  getCurrentCommentText() {
    
    let tonePrefix = ""
    switch(tone) {
      case "褒める":
        tonePrefix = "素晴らしい！"
        break
      case "質問":
        tonePrefix = "興味深いですね。"
        break
      case "建設的":
        tonePrefix = "改善案として、"
        break
      case "励まし":
        tonePrefix = "頑張っていますね！"
        break
    }
    
    const newText = currentText ? `${tonePrefix} ${currentText}` : tonePrefix
    this.insertIntoCommentField(newText)
  }

  insertIntoCommentField(text) {
    // メインのコメント入力フィールドを探す
    const commentField = document.querySelector('textarea[name="comment[body]"]')
    if (commentField) {
      commentField.value = text
      commentField.focus()
      // 入力イベントを発火してバリデーション等をトリガー
      commentField.dispatchEvent(new Event('input', { bubbles: true }))
      
      // 成功のフィードバック
      this.showAppliedFeedback()
    }
  }

  getCurrentCommentText() {
    const commentField = document.querySelector('textarea[name="comment[body]"]')
    return commentField ? commentField.value : ""
  }

  showAppliedFeedback() {
    // 一時的なフィードバック表示
    const feedback = document.createElement('div')
    feedback.className = 'fixed top-4 right-4 bg-purple-500 text-white px-4 py-2 rounded-lg shadow-lg z-50 transform transition-all duration-300'
    feedback.textContent = '提案を適用しました！'
    document.body.appendChild(feedback)
    
    // アニメーション
    setTimeout(() => {
      feedback.style.transform = 'translateY(-10px)'
      feedback.style.opacity = '0'
    }, 2000)
    
    setTimeout(() => {
      feedback.remove()
    }, 2500)
  }
}