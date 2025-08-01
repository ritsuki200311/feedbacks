import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "form", "commentForm", "markersContainer"]
  static values = { postId: Number }

  connect() {
    console.log("Image Comments Controller connected!")
    console.log("Post ID:", this.postIdValue)
    console.log("Image target:", this.hasImageTarget ? "found" : "not found")
    console.log("Form target:", this.hasFormTarget ? "found" : "not found")
    this.setupImageClickListener()
    this.loadExistingComments()
  }

  setupImageClickListener() {
    console.log("Setting up image click listener...")
    if (!this.hasImageTarget) {
      console.error("Image target not found!")
      return
    }
    
    this.imageTarget.addEventListener("click", (event) => {
      console.log("Image clicked!")
      const rect = this.imageTarget.getBoundingClientRect()
      const x = event.clientX - rect.left
      const y = event.clientY - rect.top
      console.log("Click position:", x, y)
      
      // 既存のフォームを非表示にする
      this.hideForm()
      
      // 新しい位置にフォームを表示
      this.showFormAt(x, y)
    })
  }

  showFormAt(x, y) {
    console.log("Showing form at:", x, y)
    if (!this.hasFormTarget) {
      console.error("Form target not found!")
      return
    }
    
    const form = this.formTarget
    
    // フォームの位置を設定
    form.style.left = `${x}px`
    form.style.top = `${y}px`
    form.classList.remove("hidden")
    console.log("Form should be visible now")
    
    // 隠しフィールドに座標を設定
    const xField = form.querySelector("input[name='comment[x_position]']")
    const yField = form.querySelector("input[name='comment[y_position]']")
    
    if (xField) xField.value = x
    if (yField) yField.value = y
    
    // テキストエリアにフォーカス
    const textarea = form.querySelector("textarea")
    if (textarea) {
      textarea.focus()
      textarea.value = ""
    }
  }

  hideForm() {
    this.formTarget.classList.add("hidden")
  }

  async loadExistingComments() {
    try {
      const response = await fetch(`/posts/${this.postIdValue}/comments.json`)
      if (!response.ok) {
        console.error("Failed to load comments")
        return
      }
      
      const comments = await response.json()
      this.renderComments(comments)
    } catch (error) {
      console.error("Error loading comments:", error)
      // エラーが出た場合はページのデータから読み込む
      this.loadCommentsFromDOM()
    }
  }

  loadCommentsFromDOM() {
    // ページ内の画像上コメントデータから読み込む（フォールバック）
    const commentElements = document.querySelectorAll("[data-comment-id]")
    const comments = []
    
    commentElements.forEach((element, index) => {
      const commentId = element.dataset.commentId
      const commentText = element.querySelector("p")?.textContent
      
      if (commentText) {
        comments.push({
          id: commentId,
          body: commentText,
          x_position: Math.random() * 200 + 50, // デモ用のランダム位置
          y_position: Math.random() * 200 + 50,
          number: index + 1
        })
      }
    })
    
    this.renderComments(comments)
  }

  renderComments(comments) {
    const container = this.markersContainerTarget
    container.innerHTML = "" // 既存のマーカーをクリア
    
    // 画像上のコメントのみをフィルタリング
    const imageComments = comments.filter(comment => 
      comment.x_position !== null && comment.y_position !== null
    )
    
    imageComments.forEach((comment, index) => {
      this.createMarker(comment, index + 1)
    })
  }

  createMarker(comment, number) {
    const marker = document.createElement("div")
    marker.className = "absolute w-8 h-8 bg-blue-500 text-white rounded-full flex items-center justify-center text-sm font-bold cursor-pointer z-10 transform -translate-x-1/2 -translate-y-1/2 transition-all duration-200 hover:scale-110"
    marker.style.left = `${comment.x_position}px`
    marker.style.top = `${comment.y_position}px`
    marker.textContent = number
    marker.dataset.commentId = comment.id
    marker.style.pointerEvents = "auto"
    
    // ツールチップ作成
    const tooltip = document.createElement("div")
    tooltip.className = "absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 bg-gray-800 text-white text-sm rounded py-2 px-3 whitespace-nowrap z-20 opacity-0 transition-opacity duration-200 pointer-events-none"
    tooltip.textContent = comment.body
    tooltip.style.maxWidth = "200px"
    tooltip.style.whiteSpace = "normal"
    tooltip.style.wordWrap = "break-word"
    
    // マーカーにツールチップを追加
    marker.appendChild(tooltip)
    
    // ホバーイベント
    marker.addEventListener("mouseenter", () => {
      tooltip.style.opacity = "1"
    })
    
    marker.addEventListener("mouseleave", () => {
      tooltip.style.opacity = "0"
    })
    
    // マーカーコンテナーに追加
    this.markersContainerTarget.appendChild(marker)
  }

  highlightMarker(event) {
    const commentId = event.currentTarget.dataset.commentId
    if (!commentId) return
    
    // 対応するマーカーを見つけて強調表示
    const marker = this.markersContainerTarget.querySelector(`[data-comment-id="${commentId}"]`)
    if (!marker) return
    
    // 既存の強調表示をリセット
    this.resetMarkerHighlights()
    
    // マーカーを強調表示
    marker.style.backgroundColor = "#ef4444" // 赤色
    marker.style.transform = "translate(-50%, -50%) scale(1.3)"
    marker.style.zIndex = "30"
    
    // アニメーション効果
    marker.classList.add("animate-ping")
    
    // 2秒後に元に戻す
    setTimeout(() => {
      marker.style.backgroundColor = "#3b82f6" // 元の青色
      marker.style.transform = "translate(-50%, -50%) scale(1)"
      marker.style.zIndex = "10"
      marker.classList.remove("animate-ping")
    }, 2000)
    
    // マーカーが見える位置にスクロール
    marker.scrollIntoView({ behavior: "smooth", block: "center" })
  }

  resetMarkerHighlights() {
    const markers = this.markersContainerTarget.querySelectorAll("[data-comment-id]")
    markers.forEach(marker => {
      marker.style.backgroundColor = "#3b82f6"
      marker.style.transform = "translate(-50%, -50%) scale(1)"
      marker.style.zIndex = "10"
      marker.classList.remove("animate-ping")
    })
  }

  async submitComment(event) {
    event.preventDefault()
    
    const form = event.target
    const formData = new FormData(form)
    
    try {
      const response = await fetch(form.action, {
        method: 'POST',
        body: formData,
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const comment = await response.json()
        this.addNewComment(comment)
        
        // 成功メッセージを表示（オプション）
        this.showSuccessMessage()
        
        // ページをリロードして通常のコメント一覧も更新
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

  showSuccessMessage() {
    // 一時的な成功メッセージを表示
    const message = document.createElement('div')
    message.className = 'fixed top-4 right-4 bg-green-500 text-white px-4 py-2 rounded shadow-lg z-50'
    message.textContent = 'コメントを投稿しました！'
    document.body.appendChild(message)
    
    setTimeout(() => {
      message.remove()
    }, 3000)
  }

  // フォーム送信後の処理（成功時にマーカーを追加）
  addNewComment(comment) {
    const commentsCount = this.markersContainerTarget.children.length
    this.createMarker(comment, commentsCount + 1)
    this.hideForm()
  }
}