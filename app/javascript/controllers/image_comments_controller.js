import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "markersContainer", "toggleButton", "toggleIcon", "toggleText", "markerCount"]
  static values = { postId: Number, imageIndex: Number }

  // コメント投稿成功時に青い丸を削除する関数
  removeClickIndicator() {
    // グローバル関数を呼び出し
    if (window.removeClickIndicator) {
      window.removeClickIndicator();
    }
  }

  // キーボードイベントハンドラー（Enterキーでフォーム送信）
  handleKeydown(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      const form = event.target.closest('form')
      if (form) {
        // フォームを送信
        const submitEvent = new Event('submit', { bubbles: true, cancelable: true })
        form.dispatchEvent(submitEvent)
      }
    }
  }

  // コメント送信処理
  submitComment(event) {
    event.preventDefault();
    console.log('Comment form submitted');

    const form = event.target;
    const formData = new FormData(form);

    // デバッグ情報をログ出力
    console.log('Form action:', form.action);
    console.log('Form data entries:');
    for (let [key, value] of formData.entries()) {
      console.log(`  ${key}: ${value}`);
    }

    fetch(form.action, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
        'Accept': 'application/json'
      },
      body: formData
    })
    .then(response => {
      console.log('Response status:', response.status);
      console.log('Response headers:', response.headers);

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      return response.json();
    })
    .then(data => {
      console.log('Response data:', data);
      if (data.success) {
        console.log('Comment submitted successfully');
        // 青い丸を削除
        this.removeClickIndicator();
        // フォームを隠す
        this.clearCommentForm();
        // コメントをリロード
        this.loadExistingComments();
      } else {
        console.error('Comment submission failed:', data.errors);
        alert('コメントの投稿に失敗しました: ' + JSON.stringify(data.errors));
      }
    })
    .catch(error => {
      console.error('Error submitting comment:', error);
      alert('エラーが発生しました: ' + error.message);
    });
  }

  connect() {
    console.log("🔥🔥🔥 NEW VERSION 2025-10-02 🔥🔥🔥")
    console.log("=== Image Comments Controller connected! ===")
    console.log("Post ID:", this.postIdValue)
    console.log("Image Index:", this.imageIndexValue)
    console.log("Image target:", this.hasImageTarget ? "found" : "not found")
    console.log("Markers container:", this.hasMarkersContainerTarget ? "found" : "not found")
    console.log("Element ID:", this.element.id || "no-id")
    console.log("==========================================")
    this.tempPin = null
    this.tempForm = null
    this.documentClickListener = null
    this.scrollListener = null
    this.setupImageClickListener()
    this.loadExistingComments()
  }

  disconnect() {
    this.removeDocumentClickListener()
  }

  setupImageClickListener() {
    console.log("Setting up image click listener...")
    if (!this.hasImageTarget) {
      console.error("Image target not found!")
      return
    }

    this.imageTarget.addEventListener("click", (event) => {
      console.log("Image clicked!")

      // まず現在のフォームを閉じる
      this.hideForm()

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
      const markerExists = this.isMarkerAtPosition(relativeX, relativeY)
      console.log("Checking for existing marker at position:", relativeX, relativeY, "exists:", markerExists)
      if (markerExists) {
        console.log("Marker already exists at this position")
        return
      }

      console.log("Creating temp pin and focusing form...")
      console.log("About to call createTempPin with:", relativeX, relativeY)
      // 仮ピンを表示し、画像上にフォームを表示
      this.createTempPin(relativeX, relativeY)
      console.log("createTempPin called, now calling showImageCommentForm")
      this.showImageCommentForm(relativeX, relativeY)
    })
  }

  setupDocumentClickListener() {
    // 既存のリスナーを削除
    this.removeDocumentClickListener()

    // 新しいリスナーを追加
    this.documentClickListener = (event) => {
      const form = this.element.querySelector("[data-image-comments-target='form']")
      if (!form || form.classList.contains('hidden')) {
        console.log('Form not found or already hidden')
        return
      }

      console.log('Document click detected, checking if should hide form')
      console.log('Click target:', event.target)

      // フォームやその内部、画像がクリックされた場合は無視
      if (form.contains(event.target)) {
        console.log('Click was inside form, not hiding')
        return
      }

      if (this.imageTarget && this.imageTarget.contains(event.target)) {
        console.log('Click was on image, not hiding (will be handled by image click)')
        return
      }

      if (this.tempPin && this.tempPin.contains(event.target)) {
        console.log('Click was on temp pin, not hiding')
        return
      }

      // それ以外の場所がクリックされたらフォームを閉じる
      console.log('Outside click detected, hiding form')
      this.hideForm()
    }

    document.addEventListener('click', this.documentClickListener)
    console.log('Document click listener added')
  }

  removeDocumentClickListener() {
    if (this.documentClickListener) {
      document.removeEventListener('click', this.documentClickListener)
      this.documentClickListener = null
      console.log('Document click listener removed')
    }
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

    console.log('Creating temp pin at:', x, y)
    const tempPin = document.createElement("div")
    tempPin.className = "absolute w-6 h-6 bg-yellow-400 text-black rounded-full flex items-center justify-center cursor-pointer z-50 transform -translate-x-1/2 -translate-y-1/2 transition-all duration-200 animate-pulse"
    tempPin.style.left = `${x}%`
    tempPin.style.top = `${y}%`
    tempPin.textContent = "×"
    tempPin.style.pointerEvents = "auto"
    tempPin.style.fontSize = "14px"
    tempPin.style.fontWeight = "bold"
    tempPin.dataset.tempPin = "true"

    // 仮ピンにクリックイベントを追加（何もしない）
    tempPin.addEventListener("click", (event) => {
      event.stopPropagation() // イベントの伝播を停止（外部クリック検出を防ぐため）
      // フォームは閉じない
    })

    console.log('Temp pin created and event listener added')
    this.tempPin = tempPin

    if (this.hasMarkersContainerTarget) {
      console.log('Adding temp pin to markers container')
      this.markersContainerTarget.appendChild(tempPin)
    } else {
      console.error('markersContainerTarget not found!')
    }
  }


  removeTempPin() {
    if (this.tempPin) {
      this.tempPin.remove()
      this.tempPin = null
    }
    // または既存の仮ピンを全て削除
    if (this.hasMarkersContainerTarget) {
      const existingTempPins = this.markersContainerTarget.querySelectorAll("[data-temp-pin]")
      existingTempPins.forEach(pin => pin.remove())
    }
  }

  showImageCommentForm(x, y) {
    const form = this.element.querySelector("[data-image-comments-target='form']")
    if (!form) {
      console.error('Comment form not found!')
      return
    }

    // フォーム位置を設定（相対位置）
    form.style.position = 'absolute'
    form.style.left = `${x}%`
    form.style.top = `${y}%`
    form.style.transform = ''
    form.style.zIndex = '50'
    form.classList.remove('hidden')

    // 隠しフィールドに座標を設定
    const xField = form.querySelector('input[name="comment[x_position]"]')
    const yField = form.querySelector('input[name="comment[y_position]"]')
    const imageIndexField = form.querySelector('input[name="comment[image_index]"]')

    console.log('Form fields found:', {
      xField: !!xField,
      yField: !!yField,
      imageIndexField: !!imageIndexField
    })

    if (xField) xField.value = x
    if (yField) yField.value = y
    if (imageIndexField) {
      // 0も有効な値なので、undefinedやnullの場合のみ0にフォールバック
      // 確実に数値に変換
      const indexValue = (this.imageIndexValue !== undefined && this.imageIndexValue !== null) ? Number(this.imageIndexValue) : 0
      console.log(`[Image ${indexValue}] Setting image_index to: ${indexValue} (type: ${typeof indexValue})`)
      imageIndexField.value = indexValue
    } else {
      console.error("Image index field not found!")
    }

    // テキストエリアにフォーカス
    const textarea = form.querySelector('textarea')
    if (textarea) {
      setTimeout(() => textarea.focus(), 50)
    }

    // ドキュメントクリックリスナーを少し遅延して設定（現在のクリックイベントが完了してから）
    setTimeout(() => {
      this.setupDocumentClickListener()
    }, 100)

    console.log('Image comment form shown at:', x, y, 'for image index:', this.imageIndexValue)
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
    // ピンコメント用のフォームをクリア
    const form = this.element.querySelector("[data-image-comments-target='form']")
    if (form) {
      // フォーム内容をクリア
      const textarea = form.querySelector('textarea')
      if (textarea) {
        textarea.value = ''
      }

      // 隠しフィールドをクリア
      const xField = form.querySelector('input[name="comment[x_position]"]')
      const yField = form.querySelector('input[name="comment[y_position]"]')
      const imageIndexField = form.querySelector('input[name="comment[image_index]"]')

      if (xField) xField.value = ""
      if (yField) yField.value = ""
      if (imageIndexField) imageIndexField.value = ""
    }

    // 右側のコメントフォームもクリア（存在する場合）
    const commentForm = document.querySelector("[data-comment-form-target='form']")
    if (commentForm) {
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
    }

    // ピンコメント状態表示をクリア
    if (typeof window.clearPinCommentStatus === 'function') {
      window.clearPinCommentStatus()
    }
  }

  hideForm() {
    const form = this.element.querySelector("[data-image-comments-target='form']")
    if (form) {
      form.classList.add('hidden')
      // 元のスタイルに戻す
      form.style.position = ''
      form.style.left = ''
      form.style.top = ''
      form.style.transform = ''
      form.style.zIndex = ''

      // フォーム内容をクリア
      const textarea = form.querySelector('textarea')
      if (textarea) {
        textarea.value = ''
      }

      // フォームの参照をクリア
      this.tempForm = null

      // 仮ピンを削除
      this.removeTempPin()

      // 青い丸も削除
      if (window.removeClickIndicator) {
        window.removeClickIndicator()
      }

      // ドキュメントクリックリスナーを削除
      this.removeDocumentClickListener()

      console.log('Image comment form hidden')
    }
  }

  isMarkerAtPosition(x, y, tolerance = 5) {
    if (!this.hasMarkersContainerTarget) {
      console.log("No markers container found")
      return false
    }

    const markers = this.markersContainerTarget.querySelectorAll("[data-comment-id]")
    console.log("Checking", markers.length, "existing markers for image index", this.imageIndexValue)

    for (let marker of markers) {
      const markerX = parseFloat(marker.style.left)
      const markerY = parseFloat(marker.style.top)

      console.log("Marker at:", markerX, markerY, "vs clicked:", parseFloat(x), parseFloat(y))

      // 同じ画像インデックスのマーカーのみチェック（既にフィルタリングされているので現在は不要だが、念のため確認）
      if (Math.abs(markerX - parseFloat(x)) < tolerance &&
          Math.abs(markerY - parseFloat(y)) < tolerance) {
        console.log("Found existing marker within tolerance")
        return true
      }
    }
    console.log("No existing marker found at this position for this image")
    return false
  }

  async loadExistingComments() {
    try {
      console.log(`[Image ${this.imageIndexValue}] Loading existing comments...`)
      const response = await fetch(`/posts/${this.postIdValue}/comments.json`)
      if (!response.ok) {
        console.error("Failed to load comments")
        return
      }

      const comments = await response.json()
      console.log(`[Image ${this.imageIndexValue}] Total comments loaded:`, comments.length)

      // 画像上のコメントのみを抽出
      const pinComments = comments.filter(c => c.x_position !== null && c.y_position !== null)
      console.log(`[Image ${this.imageIndexValue}] Pin comments (with x/y):`, pinComments.length)

      // 現在の画像インデックスに対応するコメントのみをフィルタリング
      const filteredComments = pinComments.filter(comment => {
        const commentImageIndex = comment.image_index
        const currentImageIndex = this.imageIndexValue

        // 厳密な比較：image_indexがnullまたはundefinedの場合は0として扱う
        // 両方を数値に変換して比較
        const effectiveCommentIndex = (commentImageIndex === null || commentImageIndex === undefined) ? 0 : Number(commentImageIndex)
        const effectiveCurrentIndex = (currentImageIndex === null || currentImageIndex === undefined) ? 0 : Number(currentImageIndex)

        const shouldInclude = effectiveCommentIndex === effectiveCurrentIndex

        console.log(`[Image ${effectiveCurrentIndex}] Comment ${comment.id}: image_index=${commentImageIndex}(${effectiveCommentIndex}) vs current=${currentImageIndex}(${effectiveCurrentIndex}) => ${shouldInclude ? 'INCLUDE' : 'EXCLUDE'}`)

        return shouldInclude
      })

      console.log(`[Image ${this.imageIndexValue}] FINAL filtered comments:`, filteredComments.length)
      console.log(`[Image ${this.imageIndexValue}] Filtered comment IDs:`, filteredComments.map(c => c.id))
      this.renderComments(filteredComments)
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
    console.log(`>>> renderComments called for image index ${this.imageIndexValue}`)
    console.log(`>>> Rendering ${comments.length} comments`)

    const container = this.markersContainerTarget
    container.innerHTML = "" // 既存のマーカーをクリア

    // このコントローラーインスタンスに属するツールチップのみを削除
    const existingTooltips = document.querySelectorAll(`[data-tooltip-image-index="${this.imageIndexValue}"][data-tooltip-post-id="${this.postIdValue}"]`)
    existingTooltips.forEach(tooltip => tooltip.remove())

    // 画像上のコメントのみをフィルタリング
    const imageComments = comments.filter(comment =>
      comment.x_position !== null && comment.y_position !== null
    )

    console.log(`>>> After filtering, ${imageComments.length} image comments to render`)

    imageComments.forEach((comment, index) => {
      console.log(`>>> Creating marker ${index + 1} for comment ${comment.id} at (${comment.x_position}, ${comment.y_position})`)
      this.createMarker(comment, index + 1)
    })
  }

  createMarker(comment, number) {
    const marker = document.createElement("div")
    marker.className = "absolute w-2 h-2 bg-blue-500 text-white rounded-full flex items-center justify-center cursor-pointer transform -translate-x-1/2 -translate-y-1/2 transition-all duration-200 hover:scale-150"
    marker.style.left = `${comment.x_position}%`
    marker.style.top = `${comment.y_position}%`
    marker.style.zIndex = "10"
    marker.textContent = number
    marker.dataset.commentId = comment.id
    marker.style.pointerEvents = "auto"

    // ツールチップ作成（bodyに直接追加するため絶対位置で配置）
    const tooltip = document.createElement("div")
    tooltip.className = "fixed bg-gray-800 text-white text-sm rounded py-2 px-3 whitespace-nowrap opacity-0 transition-opacity duration-200 pointer-events-none"
    tooltip.style.zIndex = "10000"
    tooltip.textContent = comment.body
    tooltip.style.maxWidth = "200px"
    tooltip.style.whiteSpace = "normal"
    tooltip.style.wordWrap = "break-word"
    tooltip.dataset.tooltipFor = comment.id
    tooltip.dataset.tooltipImageIndex = this.imageIndexValue
    tooltip.dataset.tooltipPostId = this.postIdValue

    // マーカーにツールチップの参照を保存
    marker._tooltip = tooltip

    // ツールチップをbodyに追加
    document.body.appendChild(tooltip)

    // ホバーイベント
    marker.addEventListener("mouseenter", (event) => {
      // この画像インデックスの他のツールチップを非表示にして後ろに
      const allTooltips = document.querySelectorAll(`[data-tooltip-image-index="${this.imageIndexValue}"][data-tooltip-post-id="${this.postIdValue}"]`)
      allTooltips.forEach(t => {
        t.style.opacity = "0"
        t.style.zIndex = "10000"
      })

      // この画像のマーカーのz-indexをリセット
      const allMarkers = this.markersContainerTarget.querySelectorAll("[data-comment-id]")
      allMarkers.forEach(m => {
        m.style.zIndex = "10"
      })

      // マーカーの位置を取得
      const rect = marker.getBoundingClientRect()

      // このツールチップだけを最前面に表示
      tooltip.style.left = `${rect.left + rect.width / 2}px`
      tooltip.style.top = `${rect.top - 8}px`
      tooltip.style.transform = "translate(-50%, -100%)"
      tooltip.style.zIndex = "10001"
      tooltip.style.opacity = "1"

      // マーカーを最前面に
      marker.style.zIndex = "10000"
    })

    marker.addEventListener("mouseleave", () => {
      tooltip.style.opacity = "0"
      // z-indexを元に戻す
      marker.style.zIndex = "10"
      tooltip.style.zIndex = "10000"
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