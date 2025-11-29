import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "toggleButton", "toggleIcon", "toggleText", 
    "initialMessage", "loading", "aiContent",
    "vocabularies", "summary"
  ]
  static values = { postId: Number }

  connect() {
    console.log("AI Sidebar Controller connected!")
    this.aiLoaded = false
    this.retryCount = 0
    this.maxRetries = 2
    
    // セッションストレージからキャッシュを確認
    this.loadFromCache()
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
      this.showError(error.message)
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
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({})
      })

      console.log('Response status:', response.status)

      if (!response.ok) {
        const errorText = await response.text()
        console.error('API error response:', errorText)
        throw new Error(`AI API エラー (${response.status}): ${errorText}`)
      }

      const data = await response.json()
      console.log('AI analysis result:', data)
      
      if (!data.success) {
        throw new Error(data.error || 'AI分析に失敗しました')
      }
      
      // 語彙・表現を表示
      this.renderVocabularies(data.vocabularies || [])
      
      // 観察ポイントを表示
      if (this.hasSummaryTarget) {
        this.summaryTarget.innerHTML = ''
        data.observation_points.slice(0, 4).forEach((point, index) => {
          const pointDiv = document.createElement('div')
          pointDiv.className = 'flex items-start gap-3 p-3 bg-white rounded-lg border border-purple-200 shadow-sm'
          pointDiv.innerHTML = `
            <div class="w-6 h-6 bg-gradient-to-r from-purple-400 to-indigo-400 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
              <span class="text-white text-xs font-bold">${index + 1}</span>
            </div>
            <p class="text-sm text-gray-700 leading-relaxed font-medium">${point}</p>
          `
          this.summaryTarget.appendChild(pointDiv)
        })
      }
      
      // キャッシュに保存
      this.saveToCache(data)
      console.log('AI content rendered successfully')
    } catch (error) {
      console.error('Error loading AI content:', error)
      this.showError(error.message)
    }
  }



  renderVocabularies(vocabularies) {
    if (this.hasVocabulariesTarget) {
      this.vocabulariesTarget.innerHTML = ''
      
      // フォールバック語彙がない場合のデフォルト
      const vocabsToShow = vocabularies.length > 0 ? vocabularies.slice(0, 8) : [
        '美しい', '印象的', '繊細', '力強い', 
        '調和', '表現力', '創造性', '独創的'
      ]
      
      vocabsToShow.forEach(vocab => {
        const vocabButton = document.createElement('button')
        vocabButton.className = 'px-3 py-2 bg-white border-2 border-emerald-300 rounded-full text-sm font-medium text-emerald-700 hover:bg-emerald-50 hover:border-emerald-400 transition-all transform hover:scale-105 cursor-pointer'
        vocabButton.textContent = vocab
        vocabButton.addEventListener('click', () => this.insertVocabulary(vocab))
        this.vocabulariesTarget.appendChild(vocabButton)
      })
    }
  }

  insertVocabulary(vocabulary) {
    // コメントフォームに語彙を挿入
    const commentForm = document.querySelector('textarea[name="comment[body]"]')
    if (commentForm) {
      const currentText = commentForm.value
      const cursorPos = commentForm.selectionStart || currentText.length
      
      // カーソル位置に語彙を挿入
      const newText = currentText.slice(0, cursorPos) + vocabulary + currentText.slice(cursorPos)
      commentForm.value = newText
      
      // カーソル位置を調整
      const newCursorPos = cursorPos + vocabulary.length
      commentForm.setSelectionRange(newCursorPos, newCursorPos)
      
      // フォーカスを戻す
      commentForm.focus()
      
      // 成功エフェクト
      this.showInsertionFeedback(vocabulary)
    }
  }

  showInsertionFeedback(vocabulary) {
    const feedback = document.createElement('div')
    feedback.className = 'fixed top-4 right-4 bg-emerald-500 text-white px-4 py-2 rounded-lg shadow-lg z-50 transform scale-100 opacity-100 transition-all'
    feedback.textContent = `「${vocabulary}」を挿入しました`
    document.body.appendChild(feedback)
    
    setTimeout(() => {
      feedback.classList.add('scale-95', 'opacity-0')
      setTimeout(() => feedback.remove(), 200)
    }, 2000)
  }

  showError(message = 'AI分析でエラーが発生しました') {
    // ローディングを隠す
    this.loadingTarget.classList.add('hidden')
    
    // エラーメッセージを表示
    this.aiContentTarget.classList.remove('hidden')
    this.aiContentTarget.innerHTML = `
      <div class="bg-red-50 border-2 border-red-200 rounded-lg p-4">
        <div class="flex items-center gap-2 mb-2">
          <div class="w-6 h-6 bg-red-500 rounded-full flex items-center justify-center">
            <span class="text-white text-xs">⚠️</span>
          </div>
          <h3 class="text-sm font-bold text-red-800">エラー</h3>
        </div>
        <p class="text-sm text-red-700 mb-3">${message}</p>
        <button 
          type="button" 
          data-action="click->ai-sidebar#retryAI"
          class="px-3 py-1 bg-red-500 text-white text-xs rounded hover:bg-red-600 transition-colors">
          再試行
        </button>
      </div>
    `
    
    // ボタンの状態を更新
    this.toggleIconTarget.textContent = '⚠️'
    this.toggleTextTarget.textContent = 'エラー - 再試行'
    this.toggleButtonTarget.classList.remove('bg-purple-600', 'hover:bg-purple-700')
    this.toggleButtonTarget.classList.add('bg-red-600', 'hover:bg-red-700')
  }

  retryAI() {
    // 再試行回数制限
    if (this.retryCount >= this.maxRetries) {
      this.showError(`再試行回数の上限に達しました (${this.maxRetries}回)。しばらく時間をおいてから再度お試しください。`)
      return
    }
    
    this.retryCount++
    // AIを再試行
    this.aiLoaded = false
    this.startAI()
  }
  
  loadFromCache() {
    const cacheKey = `ai_cache_post_${this.postIdValue}`
    const cached = sessionStorage.getItem(cacheKey)
    
    if (cached) {
      try {
        const data = JSON.parse(cached)
        console.log('Loading AI data from cache')
        
        // キャッシュからデータを復元
        this.renderVocabularies(data.vocabularies || [])
        if (this.hasSummaryTarget && data.observation_points) {
          this.summaryTarget.innerHTML = ''
          data.observation_points.slice(0, 4).forEach((point, index) => {
            const pointDiv = document.createElement('div')
            pointDiv.className = 'flex items-start gap-3 p-3 bg-white rounded-lg border border-purple-200 shadow-sm'
            pointDiv.innerHTML = `
              <div class="w-6 h-6 bg-gradient-to-r from-purple-400 to-indigo-400 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
                <span class="text-white text-xs font-bold">${index + 1}</span>
              </div>
              <p class="text-sm text-gray-700 leading-relaxed font-medium">${point}</p>
            `
            this.summaryTarget.appendChild(pointDiv)
          })
        }
        
        this.aiLoaded = true
        console.log('AI data loaded from cache successfully')
      } catch (error) {
        console.error('Failed to load from cache:', error)
        sessionStorage.removeItem(cacheKey)
      }
    }
  }
  
  saveToCache(data) {
    const cacheKey = `ai_cache_post_${this.postIdValue}`
    try {
      sessionStorage.setItem(cacheKey, JSON.stringify(data))
      console.log('AI data saved to cache')
    } catch (error) {
      console.error('Failed to save to cache:', error)
    }
  }



}