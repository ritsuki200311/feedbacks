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

    // CSRFトークンの確認
    const csrfToken = document.querySelector('meta[name="csrf-token"]');
    console.log('CSRF token element:', csrfToken);
    console.log('CSRF token value:', csrfToken ? csrfToken.getAttribute('content') : 'NOT FOUND');

    // URLに.jsonを追加してJSON形式のレスポンスを要求
    const actionUrl = form.action.endsWith('.json') ? form.action : form.action + '.json'

    fetch(actionUrl, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken ? csrfToken.getAttribute('content') : '',
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: formData,
      credentials: 'same-origin'
    })
    .then(response => {
      console.log('Response status:', response.status);
      console.log('Response ok:', response.ok);

      // レスポンスのテキストを取得してログに出力
      return response.text().then(text => {
        console.log('Response text:', text);

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}\nResponse: ${text}`);
        }

        // JSONとしてパース
        try {
          return JSON.parse(text);
        } catch (e) {
          console.error('Failed to parse JSON:', e);
          throw new Error('サーバーからの応答が不正です: ' + text);
        }
      });
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
        // 成功メッセージ
        alert('コメントを投稿しました！');
        // ページをリロード
        setTimeout(() => {
          window.location.reload();
        }, 1000);
      } else {
        console.error('Comment submission failed:', data.errors);
        const errorMsg = data.errors ? JSON.stringify(data.errors) : '不明なエラー';
        alert('コメントの投稿に失敗しました: ' + errorMsg);
      }
    })
    .catch(error => {
      console.error('Error submitting comment:', error);
      alert('エラーが発生しました:\n' + error.message);
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
    this.preventScrollListener = null
    this.savedScrollY = 0
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

    // ダブルタップズーム防止用の変数
    let lastTap = 0
    let tapTimeout = null

    // クリック/タッチ処理の共通ハンドラー
    const handleImageInteraction = (event) => {
      console.log("Image interacted!", event.type)

      // タッチイベントの場合はデフォルト動作を防ぐ
      if (event.type === 'touchstart') {
        event.preventDefault()

        // ダブルタップズームを防止
        const currentTime = new Date().getTime()
        const tapLength = currentTime - lastTap

        if (tapLength < 300 && tapLength > 0) {
          // ダブルタップ検出 - ズームを防止
          console.log("Double tap detected, preventing zoom")
          event.preventDefault()
          event.stopPropagation()
          // ダブルタップの場合は処理を続行しない
          return
        }

        lastTap = currentTime
      }

      // まず現在のフォームを閉じる
      this.hideForm()

      // タッチイベントかクリックイベントかで座標取得方法を変える
      let clientX, clientY
      if (event.type === 'touchstart' && event.touches && event.touches.length > 0) {
        clientX = event.touches[0].clientX
        clientY = event.touches[0].clientY
      } else {
        clientX = event.clientX
        clientY = event.clientY
      }

      // クリック位置を青い丸で表示
      console.log("About to call showClickIndicator with:", clientX, clientY)
      this.showClickIndicator(clientX, clientY)

      const rect = this.imageTarget.getBoundingClientRect()
      const x = clientX - rect.left
      const y = clientY - rect.top

      // 相対座標に変換（画像サイズに対する割合）
      const relativeX = (x / rect.width * 100).toFixed(2)
      const relativeY = (y / rect.height * 100).toFixed(2)

      console.log(`Interacted at: ${relativeX}%, ${relativeY}%`)

      // 既存のマーカーがクリック位置にある場合はスキップ
      const markerExists = this.isMarkerAtPosition(relativeX, relativeY)
      console.log("Checking for existing marker at position:", relativeX, relativeY, "exists:", markerExists)
      if (markerExists) {
        console.log("Marker already exists at this position")
        return
      }

      console.log("Creating temp pin and focusing form...")
      console.log("About to call createTempPin with:", relativeX, relativeY)
      // 仮ピンを表示し、画像上にフォームを表示（固定位置で表示）
      this.createTempPin(relativeX, relativeY, clientX, clientY)
      console.log("createTempPin called, now calling showImageCommentForm")
      this.showImageCommentForm(relativeX, relativeY)
    }

    // クリックイベント（デスクトップ用）
    this.imageTarget.addEventListener("click", handleImageInteraction)

    // タッチイベント（スマホ・タブレット用）
    this.imageTarget.addEventListener("touchstart", handleImageInteraction, { passive: false })
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

      console.log('Document interaction detected, checking if should hide form')
      console.log('Interaction target:', event.target)

      // フォームやその内部、画像がクリックされた場合は無視
      if (form.contains(event.target)) {
        console.log('Interaction was inside form, not hiding')
        return
      }

      if (this.imageTarget && this.imageTarget.contains(event.target)) {
        console.log('Interaction was on image, not hiding (will be handled by image interaction)')
        return
      }

      if (this.tempPin && this.tempPin.contains(event.target)) {
        console.log('Interaction was on temp pin, not hiding')
        return
      }

      // それ以外の場所がクリックされたらフォームを閉じる
      console.log('Outside interaction detected, hiding form')
      this.hideForm()
    }

    // クリックとタッチの両方に対応
    document.addEventListener('click', this.documentClickListener)
    document.addEventListener('touchstart', this.documentClickListener)
    console.log('Document interaction listeners added')
  }

  removeDocumentClickListener() {
    if (this.documentClickListener) {
      document.removeEventListener('click', this.documentClickListener)
      document.removeEventListener('touchstart', this.documentClickListener)
      this.documentClickListener = null
      console.log('Document interaction listeners removed')
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

  createTempPin(x, y, clientX, clientY) {
    // 既存の仮ピンがあれば削除
    this.removeTempPin()

    console.log('Creating temp pin at:', x, y, 'fixed position:', clientX, clientY)
    const tempPin = document.createElement("div")
    // position: fixedに変更して、青い丸と同じ位置に表示
    tempPin.className = "w-6 h-6 bg-yellow-400 text-black rounded-full flex items-center justify-center cursor-pointer transform -translate-x-1/2 -translate-y-1/2 transition-all duration-200 animate-pulse"
    tempPin.style.position = "fixed"
    tempPin.style.left = `${clientX}px`
    tempPin.style.top = `${clientY}px`
    tempPin.style.zIndex = "9998"  // 青い丸と同じレイヤー
    tempPin.textContent = "×"
    tempPin.style.pointerEvents = "auto"
    tempPin.style.fontSize = "14px"
    tempPin.style.fontWeight = "bold"
    tempPin.dataset.tempPin = "true"
    // 相対座標を保存（コメント保存時に使用）
    tempPin.dataset.relativeX = x
    tempPin.dataset.relativeY = y

    // 仮ピンにクリックイベントを追加（何もしない）
    tempPin.addEventListener("click", (event) => {
      event.stopPropagation() // イベントの伝播を停止（外部クリック検出を防ぐため）
      // フォームは閉じない
    })

    console.log('Temp pin created and event listener added')
    this.tempPin = tempPin

    // bodyに直接追加（固定位置なので）
    document.body.appendChild(tempPin)
  }


  removeTempPin() {
    if (this.tempPin) {
      this.tempPin.remove()
      this.tempPin = null
    }
    // bodyに追加された仮ピンも全て削除
    const existingTempPins = document.querySelectorAll("[data-temp-pin='true']")
    existingTempPins.forEach(pin => pin.remove())
  }

  showImageCommentForm(x, y) {
    const form = this.element.querySelector("[data-image-comments-target='form']")
    if (!form) {
      console.error('Comment form not found!')
      return
    }

    // 現在のスクロール位置を保存
    this.savedScrollY = window.scrollY

    // スクロールを無効化（ピンコメント入力中）
    document.body.style.overflow = 'hidden'
    document.body.style.position = 'fixed'
    document.body.style.top = `-${this.savedScrollY}px`
    document.body.style.width = '100%'

    // touchmoveイベントでスクロールを完全に防止
    this.preventScrollListener = (e) => {
      e.preventDefault()
    }
    document.addEventListener('touchmove', this.preventScrollListener, { passive: false })
    document.addEventListener('wheel', this.preventScrollListener, { passive: false })

    console.log('Scroll disabled at position:', this.savedScrollY)

    // フォームを一旦表示して、サイズを計算できるようにする
    form.classList.remove('hidden')
    form.style.position = 'fixed'  // absoluteからfixedに変更
    form.style.zIndex = '9999'  // より高いz-indexに設定

    // 画像コンテナのサイズを取得
    const containerRect = this.imageTarget.getBoundingClientRect()

    // 画面全体のビューポートサイズを取得
    const viewportWidth = window.innerWidth
    const viewportHeight = window.innerHeight

    // フォームのサイズを取得
    const formRect = form.getBoundingClientRect()
    const formWidth = formRect.width
    const formHeight = formRect.height

    // パーセント位置をピクセル位置に変換（画像コンテナ内の位置）
    let leftPx = (parseFloat(x) / 100) * containerRect.width
    let topPx = (parseFloat(y) / 100) * containerRect.height

    // 画像コンテナの画面上での位置を考慮
    const containerLeft = containerRect.left
    const containerTop = containerRect.top

    // フォームの画面上での絶対位置を計算（固定配置用）
    let formAbsoluteLeft = containerLeft + leftPx
    let formAbsoluteTop = containerTop + topPx

    // ビューポートの右端を超える場合は左に移動
    if (formAbsoluteLeft + formWidth > viewportWidth - 10) {
      formAbsoluteLeft = viewportWidth - formWidth - 10
      // 最小マージンを確保
      if (formAbsoluteLeft < 10) {
        formAbsoluteLeft = 10
      }
    }

    // 左端からはみ出さないように
    if (formAbsoluteLeft < 10) {
      formAbsoluteLeft = 10
    }

    // ビューポートの下端を超える場合は上に移動
    if (formAbsoluteTop + formHeight > viewportHeight - 10) {
      formAbsoluteTop = formAbsoluteTop - formHeight - 20 // ピンの上に表示
      if (formAbsoluteTop < 10) {
        formAbsoluteTop = 10
      }
    }

    // fixed positionの場合はピクセル値で直接設定
    form.style.left = `${formAbsoluteLeft}px`
    form.style.top = `${formAbsoluteTop}px`
    form.style.transform = ''

    // 隠しフィールドに座標を設定（元の位置を保存）
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
      console.log("Current imageIndexValue:", this.imageIndexValue)
      console.log("Type of imageIndexValue:", typeof this.imageIndexValue)
      // 0も有効な値なので、undefinedやnullの場合のみ0にフォールバック
      const indexValue = (this.imageIndexValue !== undefined && this.imageIndexValue !== null) ? this.imageIndexValue : 0
      console.log("Setting image index to:", indexValue)
      imageIndexField.value = indexValue
      console.log("Image index field value after setting:", imageIndexField.value)
    } else {
      console.error("Image index field not found!")
    }

    // テキストエリアにフォーカス（スマホでは少し遅延）
    // preventScrollオプションでスクロールを防止
    const textarea = form.querySelector('textarea')
    if (textarea) {
      setTimeout(() => {
        textarea.focus({ preventScroll: true })
      }, 100)
    }

    // ドキュメントクリックリスナーを少し遅延して設定（現在のクリックイベントが完了してから）
    setTimeout(() => {
      this.setupDocumentClickListener()
    }, 150)

    console.log('Image comment form shown at:', x, y, 'adjusted to:', adjustedX, adjustedY, 'for image index:', this.imageIndexValue)
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
      // 元のスタイルに戻す（fixed positionをリセット）
      form.style.position = ''
      form.style.left = ''
      form.style.top = ''
      form.style.transform = ''
      form.style.zIndex = ''

      // スクロール防止リスナーを削除
      if (this.preventScrollListener) {
        document.removeEventListener('touchmove', this.preventScrollListener, { passive: false })
        document.removeEventListener('wheel', this.preventScrollListener, { passive: false })
        this.preventScrollListener = null
      }

      // スクロールを再度有効化
      document.body.style.overflow = ''
      document.body.style.position = ''
      document.body.style.top = ''
      document.body.style.width = ''

      // 元のスクロール位置に戻す
      window.scrollTo(0, this.savedScrollY)
      console.log('Scroll restored to position:', this.savedScrollY)

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
        const effectiveCommentIndex = (commentImageIndex === null || commentImageIndex === undefined) ? 0 : parseInt(commentImageIndex)
        const effectiveCurrentIndex = (currentImageIndex === null || currentImageIndex === undefined) ? 0 : parseInt(currentImageIndex)

        const shouldInclude = effectiveCommentIndex === effectiveCurrentIndex

        if (comment.x_position !== null) {
          console.log(`[Image ${this.imageIndexValue}] Comment ${comment.id} (body: "${comment.body}"): image_index=${commentImageIndex} -> effective=${effectiveCommentIndex}, match=${shouldInclude}`)
        }

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

    // 既存のツールチップを削除（bodyに追加されたもの）
    const existingTooltips = document.querySelectorAll('[data-tooltip-for]')
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

    // マーカーにツールチップの参照を保存
    marker._tooltip = tooltip

    // ツールチップ表示関数
    const showTooltip = (event) => {
      // 他のすべてのツールチップを非表示にして後ろに
      const allTooltips = document.querySelectorAll('[data-tooltip-for]')
      allTooltips.forEach(t => {
        t.style.opacity = "0"
        t.style.zIndex = "10000"
      })

      // すべてのマーカーのz-indexをリセット
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
    }

    // ツールチップ非表示関数
    const hideTooltip = () => {
      tooltip.style.opacity = "0"
      // z-indexを元に戻す
      marker.style.zIndex = "10"
      tooltip.style.zIndex = "10000"
    }

    // ホバーイベント（デスクトップ用）
    marker.addEventListener("mouseenter", showTooltip)
    marker.addEventListener("mouseleave", hideTooltip)

    // タッチイベント（スマホ用）
    let touchTimer = null
    marker.addEventListener("touchstart", (event) => {
      event.stopPropagation()
      touchTimer = setTimeout(() => {
        showTooltip(event)
      }, 500) // 0.5秒長押しでツールチップ表示
    })

    marker.addEventListener("touchend", (event) => {
      if (touchTimer) {
        clearTimeout(touchTimer)
        touchTimer = null
      }
      // タッチ終了時はツールチップを非表示
      setTimeout(hideTooltip, 1000) // 1秒後に非表示
    })

    marker.addEventListener("touchmove", () => {
      if (touchTimer) {
        clearTimeout(touchTimer)
        touchTimer = null
      }
    })
    
    // クリックイベント（既存コメントの編集・表示用）
    marker.addEventListener("click", (event) => {
      event.stopPropagation() // 画像クリックイベントを阻止
      this.showExistingComment(comment)
    })

    // マーカーコンテナーに追加
    this.markersContainerTarget.appendChild(marker)

    // ツールチップをbodyに追加
    document.body.appendChild(tooltip)
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