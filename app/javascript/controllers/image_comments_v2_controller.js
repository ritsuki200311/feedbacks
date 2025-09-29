import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "markersContainer", "toggleButton", "toggleIcon", "toggleText", "markerCount"]
  static values = { postId: Number }

  connect() {
    console.log("🟢 NEW v2 Image Comments Controller connected!")
    this.tempPin = null
    this.documentClickListener = null
    this.setupImageClickListener()
    this.loadExistingComments()
  }

  disconnect() {
    this.removeDocumentClickListener()
  }

  setupImageClickListener() {
    console.log("🟢 Setting up v2 image click listener...")
    if (!this.hasImageTarget) {
      console.error("Image target not found!")
      return
    }
    
    this.imageTarget.addEventListener("click", (event) => {
      console.log("🟢 v2: Image clicked!")

      // まず現在のフォームを閉じる
      this.hideForm()

      const rect = this.imageTarget.getBoundingClientRect()
      const x = event.clientX - rect.left
      const y = event.clientY - rect.top

      const relativeX = (x / rect.width * 100).toFixed(2)
      const relativeY = (y / rect.height * 100).toFixed(2)

      console.log(`🟢 v2: Clicked at: ${relativeX}%, ${relativeY}%`)

      if (this.isMarkerAtPosition(relativeX, relativeY)) {
        console.log("Marker already exists at this position")
        return
      }

      console.log("🟢 v2: Creating temp pin and focusing form...")
      this.createTempPin(relativeX, relativeY)
      this.showImageCommentForm(relativeX, relativeY)
    })
  }

  createTempPin(x, y) {
    console.log("🟢 v2: Creating temp pin at", x, y)
    this.removeTempPin()
    
    const tempPin = document.createElement("div")
    tempPin.className = "absolute w-2 h-2 bg-yellow-400 text-black rounded-full flex items-center justify-center cursor-pointer z-20 transform -translate-x-1/2 -translate-y-1/2 transition-all duration-200 animate-pulse"
    tempPin.style.left = `${x}%`
    tempPin.style.top = `${y}%`
    tempPin.textContent = "?"
    tempPin.style.pointerEvents = "auto"
    tempPin.dataset.tempPin = "true"
    
    tempPin.addEventListener("click", (event) => {
      event.stopPropagation() // イベントの伝播を停止（外部クリック検出を防ぐため）
      console.log('🟢 v2: Temp pin clicked! (but not hiding form)')
      // フォームは閉じない
    })
    
    this.tempPin = tempPin
    this.markersContainerTarget.appendChild(tempPin)
    console.log("🟢 v2: Temp pin created and added!")
  }

  removeTempPin() {
    if (this.tempPin) {
      this.tempPin.remove()
      this.tempPin = null
    }
    const existingTempPins = this.markersContainerTarget.querySelectorAll("[data-temp-pin]")
    existingTempPins.forEach(pin => pin.remove())
  }

  setupDocumentClickListener() {
    // 既存のリスナーを削除
    this.removeDocumentClickListener()

    // 新しいリスナーを追加
    this.documentClickListener = (event) => {
      const form = this.element.querySelector("[data-image-comments-target='form']")
      if (!form || form.classList.contains('hidden')) {
        console.log('🟢 v2: Form not found or already hidden')
        return
      }

      console.log('🟢 v2: Document click detected, checking if should hide form')
      console.log('🟢 v2: Click target:', event.target)

      // フォームやその内部、画像がクリックされた場合は無視
      if (form.contains(event.target)) {
        console.log('🟢 v2: Click was inside form, not hiding')
        return
      }

      if (this.imageTarget && this.imageTarget.contains(event.target)) {
        console.log('🟢 v2: Click was on image, not hiding (will be handled by image click)')
        return
      }

      if (this.tempPin && this.tempPin.contains(event.target)) {
        console.log('🟢 v2: Click was on temp pin, not hiding')
        return
      }

      // それ以外の場所がクリックされたらフォームを閉じる
      console.log('🟢 v2: Outside click detected, hiding form')
      this.hideForm()
    }

    document.addEventListener('click', this.documentClickListener)
    console.log('🟢 v2: Document click listener added')
  }

  removeDocumentClickListener() {
    if (this.documentClickListener) {
      document.removeEventListener('click', this.documentClickListener)
      this.documentClickListener = null
      console.log('🟢 v2: Document click listener removed')
    }
  }

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

  showImageCommentForm(x, y) {
    const form = this.element.querySelector("[data-image-comments-target='form']")
    if (!form) {
      console.error('🟢 v2: Comment form not found!')
      return
    }

    // フォーム位置を設定
    form.style.left = `${x}%`
    form.style.top = `${y}%`
    form.classList.remove('hidden')

    // 隠しフィールドに座標を設定
    const xField = form.querySelector('input[name="comment[x_position]"]')
    const yField = form.querySelector('input[name="comment[y_position]"]')

    if (xField) xField.value = x
    if (yField) yField.value = y

    // テキストエリアにフォーカス
    const textarea = form.querySelector('textarea')
    if (textarea) {
      setTimeout(() => textarea.focus(), 50)
    }

    // ドキュメントクリックリスナーを少し遅延して設定（現在のクリックイベントが完了してから）
    setTimeout(() => {
      this.setupDocumentClickListener()
    }, 100)

    console.log('🟢 v2: Image comment form shown at:', x, y)
  }

  hideForm() {
    const form = this.element.querySelector("[data-image-comments-target='form']")
    if (form) {
      form.classList.add('hidden')

      // フォーム内容をクリア
      const textarea = form.querySelector('textarea')
      if (textarea) {
        textarea.value = ''
      }

      // 仮ピンを削除
      this.removeTempPin()

      // 青い丸も削除
      if (window.removeClickIndicator) {
        window.removeClickIndicator()
      }

      // ドキュメントクリックリスナーを削除
      this.removeDocumentClickListener()

      console.log('🟢 v2: Image comment form hidden')
    }
  }

  focusCommentForm(x, y) {
    console.log("🟢 v2: Focusing comment form with coordinates", x, y)
    const commentForm = document.querySelector("[data-comment-form-target='form']")
    if (!commentForm) {
      console.error("🟢 v2: Comment form not found!")
      return
    }
    
    const xField = commentForm.querySelector("[data-comment-form-target='xPosition']")
    const yField = commentForm.querySelector("[data-comment-form-target='yPosition']")
    
    if (xField) xField.value = x
    if (yField) yField.value = y
    
    const textarea = commentForm.querySelector("[data-comment-form-target='textarea']")
    if (textarea) {
      textarea.focus()
      textarea.placeholder = `画像の位置 (${x}%, ${y}%) にコメントを書いてください...`
      console.log("🟢 v2: Focused textarea and set placeholder")
    }
  }

  clearCommentForm() {
    const commentForm = document.querySelector("[data-comment-form-target='form']")
    if (!commentForm) return
    
    const xField = commentForm.querySelector("[data-comment-form-target='xPosition']")
    const yField = commentForm.querySelector("[data-comment-form-target='yPosition']")
    
    if (xField) xField.value = ""
    if (yField) yField.value = ""
    
    const textarea = commentForm.querySelector("[data-comment-form-target='textarea']")
    if (textarea) {
      textarea.placeholder = "画像を見ながらコメントを書いてみましょう..."
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
      this.loadCommentsFromDOM()
    }
  }

  loadCommentsFromDOM() {
    const commentElements = document.querySelectorAll("[data-comment-id]")
    const comments = []
    
    commentElements.forEach((element, index) => {
      const commentId = element.dataset.commentId
      const commentText = element.querySelector("p")?.textContent
      
      if (commentText) {
        comments.push({
          id: commentId,
          body: commentText,
          x_position: Math.random() * 200 + 50,
          y_position: Math.random() * 200 + 50,
          number: index + 1
        })
      }
    })
    
    this.renderComments(comments)
  }

  renderComments(comments) {
    const container = this.markersContainerTarget
    container.innerHTML = ""
    
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
    
    const tooltip = document.createElement("div")
    tooltip.className = "absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 bg-gray-800 text-white text-sm rounded py-2 px-3 whitespace-nowrap z-20 opacity-0 transition-opacity duration-200 pointer-events-none"
    tooltip.textContent = comment.body
    tooltip.style.maxWidth = "200px"
    tooltip.style.whiteSpace = "normal"
    tooltip.style.wordWrap = "break-word"
    
    marker.appendChild(tooltip)
    
    marker.addEventListener("mouseenter", () => {
      tooltip.style.opacity = "1"
    })
    
    marker.addEventListener("mouseleave", () => {
      tooltip.style.opacity = "0"
    })
    
    marker.addEventListener("click", (event) => {
      event.stopPropagation()
      this.showExistingComment(comment)
    })
    
    this.markersContainerTarget.appendChild(marker)
  }

  showExistingComment(comment) {
    const commentElement = document.querySelector(`[data-comment-id="${comment.id}"]`)
    if (commentElement) {
      commentElement.scrollIntoView({ behavior: "smooth", block: "center" })
      commentElement.style.backgroundColor = "#fef3c7"
      setTimeout(() => {
        commentElement.style.backgroundColor = ""
      }, 2000)
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
}