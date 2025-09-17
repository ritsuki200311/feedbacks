import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "markersContainer", "toggleButton", "toggleIcon", "toggleText", "markerCount"]
  static values = { postId: Number }

  // コメント投稿成功時に青い丸を削除する関数
  removeClickIndicator() {
    // グローバル関数を呼び出し
    if (window.removeClickIndicator) {
      window.removeClickIndicator();
    }
  }

  // コメント送信処理
  submitComment(event) {
    event.preventDefault();
    console.log('Comment form submitted');

    const form = event.target;
    const formData = new FormData(form);

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
        console.log('Comment submitted successfully');
        // 青い丸を削除
        this.removeClickIndicator();
        // フォームを隠す
        this.clearCommentForm();
        // コメントをリロード
        this.loadComments();
      } else {
        console.error('Comment submission failed:', data.errors);
        alert('コメントの投稿に失敗しました。');
      }
    })
    .catch(error => {
      console.error('Error submitting comment:', error);
      alert('エラーが発生しました。');
    });
  }

  connect() {
    console.log("Image Comments Controller connected! [UPDATED VERSION]")
    console.log("Post ID:", this.postIdValue)
    console.log("Image target:", this.hasImageTarget ? "found" : "not found")
    this.tempPin = null
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

      // クリック位置を青い丸で表示
      console.log("About to call showClickIndicator with:", event.clientX, event.clientY)
      this.showClickIndicator(event.clientX, event.clientY)

      const rect = this.imageTarget.getBoundingClientRect()
      const x = event.clientX - rect.left
      const y = event.clientY - rect.top
      
      // 相対座標に変換（画像サイズに対する割合）
      const relativeX = (x / rect.width * 100).toFixed(2)
      const relativeY = (y / rect.height * 100).toFixed(2)
      
      console.log(`Clicked at: ${relativeX}%, ${relativeY}%`)
      
      // 既存のマーカーがクリック位置にある場合はスキップ
      if (this.isMarkerAtPosition(relativeX, relativeY)) {
        console.log("Marker already exists at this position")
        return
      }
      
      console.log("Creating temp pin and focusing form...")
      // 仮ピンを表示し、右側のフォームにフォーカス
      this.createTempPin(relativeX, relativeY)
      this.focusCommentForm(relativeX, relativeY)
    })
  }

  showClickIndicator(clientX, clientY) {
    console.log('showClickIndicator called in controller at:', clientX, clientY);

    // 青い丸のインジケーターを作成（既存のものは削除しない）
    const indicator = document.createElement('div')
    indicator.className = 'click-indicator'
    indicator.style.cssText = `
      position: fixed;
      left: ${clientX}px;
      top: ${clientY}px;
      width: 24px;
      height: 24px;
      background-color: #3b82f6;
      border-radius: 50%;
      pointer-events: none;
      z-index: 9999;
      transform: translate(-50%, -50%);
    `

    document.body.appendChild(indicator)
    console.log('Blue indicator added to body by controller');
  }

  createTempPin(x, y) {
    // 既存の仮ピンがあれば削除
    this.removeTempPin()
    
    const tempPin = document.createElement("div")
    tempPin.className = "absolute w-2 h-2 bg-yellow-400 text-black rounded-full flex items-center justify-center cursor-pointer z-20 transform -translate-x-1/2 -translate-y-1/2 transition-all duration-200 animate-pulse"
    tempPin.style.left = `${x}%`
    tempPin.style.top = `${y}%`
    tempPin.textContent = "?"
    tempPin.style.pointerEvents = "auto"
    tempPin.dataset.tempPin = "true"
    
    // 仮ピンにクリックで削除機能を追加
    tempPin.addEventListener("click", () => {
      this.removeTempPin()
      this.clearCommentForm()
    })
    
    this.tempPin = tempPin
    this.markersContainerTarget.appendChild(tempPin)
  }

  removeTempPin() {
    if (this.tempPin) {
      this.tempPin.remove()
      this.tempPin = null
    }
    // または既存の仮ピンを全て削除
    const existingTempPins = this.markersContainerTarget.querySelectorAll("[data-temp-pin]")
    existingTempPins.forEach(pin => pin.remove())
  }

  focusCommentForm(x, y) {
    // 右側のコメントフォームを見つけてフォーカス
    const commentForm = document.querySelector("[data-comment-form-target='form']")
    if (!commentForm) return
    
    // 隠しフィールドに座標を設定
    const xField = commentForm.querySelector("[data-comment-form-target='xPosition']")
    const yField = commentForm.querySelector("[data-comment-form-target='yPosition']")
    
    if (xField) xField.value = x
    if (yField) yField.value = y
    
    // テキストエリアにフォーカス
    const textarea = commentForm.querySelector("[data-comment-form-target='textarea']")
    if (textarea) {
      textarea.focus()
      // プレースホルダーを変更してピンの位置を示す
      textarea.placeholder = `画像の位置 (${x}%, ${y}%) にコメントを書いてください...`
    }
    
    // ピンコメント状態表示を更新
    if (typeof window.updatePinCommentStatus === 'function') {
      window.updatePinCommentStatus(x, y)
    }
  }

  clearCommentForm() {
    const commentForm = document.querySelector("[data-comment-form-target='form']")
    if (!commentForm) return
    
    // 隠しフィールドをクリア
    const xField = commentForm.querySelector("[data-comment-form-target='xPosition']")
    const yField = commentForm.querySelector("[data-comment-form-target='yPosition']")
    
    if (xField) xField.value = ""
    if (yField) yField.value = ""
    
    // プレースホルダーを元に戻す
    const textarea = commentForm.querySelector("[data-comment-form-target='textarea']")
    if (textarea) {
      textarea.placeholder = "画像を見ながらコメントを書いてみましょう..."
    }
    
    // ピンコメント状態表示をクリア
    if (typeof window.clearPinCommentStatus === 'function') {
      window.clearPinCommentStatus()
    }
  }

  isMarkerAtPosition(x, y, tolerance = 5) {
    const markers = this.markersContainerTarget.querySelectorAll("[data-comment-id]")
    for (let marker of markers) {
      const markerX = parseFloat(marker.style.left)
      const markerY = parseFloat(marker.style.top)
      
      if (Math.abs(markerX - parseFloat(x)) < tolerance && 
          Math.abs(markerY - parseFloat(y)) < tolerance) {
        return true
      }
    }
    return false
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
    marker.className = "absolute w-2 h-2 bg-blue-500 text-white rounded-full flex items-center justify-center cursor-pointer z-10 transform -translate-x-1/2 -translate-y-1/2 transition-all duration-200 hover:scale-150"
    marker.style.left = `${comment.x_position}%`
    marker.style.top = `${comment.y_position}%`
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
    
    // クリックイベント（既存コメントの編集・表示用）
    marker.addEventListener("click", (event) => {
      event.stopPropagation() // 画像クリックイベントを阻止
      this.showExistingComment(comment)
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

  // コメント送信成功時に呼び出される（comment-form controllerから）
  onCommentSubmitted(comment) {
    if (comment.x_position && comment.y_position) {
      // 仮ピンを本物のピンに変換
      this.removeTempPin()
      
      // 新しいマーカーを追加
      const imageComments = this.markersContainerTarget.querySelectorAll('[data-comment-id]')
      this.createMarker(comment, imageComments.length + 1)
      
      // コメントフォームをクリア
      this.clearCommentForm()
    }
  }

  toggleMarkers() {
    const markers = this.markersContainerTarget.querySelectorAll('[data-comment-id], [data-temp-pin]')
    const isVisible = markers.length > 0 && !markers[0].classList.contains('hidden')
    
    markers.forEach(marker => {
      if (isVisible) {
        marker.classList.add('hidden')
      } else {
        marker.classList.remove('hidden')
      }
    })
    
    // ボタンのテキストとアイコンを更新
    if (this.hasToggleTextTarget) {
      this.toggleTextTarget.textContent = isVisible ? 'ピン表示' : 'ピン非表示'
    }
    if (this.hasToggleIconTarget) {
      this.toggleIconTarget.textContent = isVisible ? '👁️' : '🙈'
    }
    
    this.updateMarkerCount()
  }

  updateMarkerCount() {
    if (this.hasMarkerCountTarget) {
      const count = this.markersContainerTarget.querySelectorAll('[data-comment-id]').length
      this.markerCountTarget.textContent = `${count}個のピン`
    }
  }

  showExistingComment(comment) {
    // 既存のコメントをクリックした時の処理
    // コメント一覧にスクロールするか、詳細表示を行う
    const commentElement = document.querySelector(`[data-comment-id="${comment.id}"]`)
    if (commentElement) {
      // コメント一覧までスクロール
      commentElement.scrollIntoView({ behavior: "smooth", block: "center" })
      
      // ハイライト効果
      commentElement.style.backgroundColor = "#fef3c7" // yellow-100
      setTimeout(() => {
        commentElement.style.backgroundColor = ""
      }, 2000)
    }
  }
}