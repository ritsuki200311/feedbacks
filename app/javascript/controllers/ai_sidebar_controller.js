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
    try {
      console.log('Starting AI analysis for post:', this.postIdValue)
      
      const response = await fetch(`/posts/${this.postIdValue}/ai_comment_assistant/analyze`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({})
      })

      console.log('Response status:', response.status)

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      console.log('AI analysis result:', data)
      
      if (data.success) {
        // コメント例と観察ポイントを表示
        this.renderSuggestions(data.comment_examples || [])
        if (this.hasSummaryTarget) {
          this.summaryTarget.innerHTML = ''
          data.observation_points.forEach(point => {
            const p = document.createElement('p')
            p.textContent = `• ${point}`
            p.className = 'mb-1'
            this.summaryTarget.appendChild(p)
          })
        }
        console.log('AI content rendered successfully')
      } else {
        console.error('AI analysis failed:', data.error)
        // フォールバックデータを表示
        this.renderFallbackContent()
      }
    } catch (error) {
      console.error('Error loading AI content:', error)
      this.renderFallbackContent()
    }
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

  renderFallbackContent() {
    const fallbackSuggestions = [
      "とても興味深い投稿ですね。特に画像投稿として魅力的だと思います。",
      "この作品の表現力に感銘を受けました。今後の作品も楽しみにしています。",
      "素晴らしい投稿をありがとうございます。参考になりました。"
    ]
    
    this.renderSuggestions(fallbackSuggestions)
    
    if (this.hasSummaryTarget) {
      this.summaryTarget.innerHTML = `
        <p class="mb-1">• 投稿の目的や意図を考えてみる</p>
        <p class="mb-1">• 使用されている技法や手法に注目する</p>
        <p class="mb-1">• 感情や印象を言葉にしてみる</p>
        <p class="mb-1">• 改善点や発展の可能性を考える</p>
      `
    }
  }

  applySuggestion(event) {
    const suggestion = event.currentTarget.dataset.suggestion
    this.insertText(suggestion)
  }

  insertText(text) {
    // コメントフォームにテキストを挿入
    const commentForm = document.querySelector('textarea[name="comment[body]"]')
    if (commentForm) {
      const currentText = commentForm.value
      const newText = currentText ? `${currentText} ${text}` : text
      commentForm.value = newText
      commentForm.focus()
    }
  }


}