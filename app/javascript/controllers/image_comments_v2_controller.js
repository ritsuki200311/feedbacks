import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "markersContainer", "toggleButton", "toggleIcon", "toggleText", "markerCount"]
  static values = { postId: Number }

  connect() {
    console.log("🟢 NEW v2 Image Comments Controller connected!")
    this.tempPin = null
    this.setupImageClickListener()
    this.loadExistingComments()
  }

  setupImageClickListener() {
    console.log("🟢 Setting up v2 image click listener...")
    if (!this.hasImageTarget) {
      console.error("Image target not found!")
      return
    }
    
    this.imageTarget.addEventListener("click", (event) => {
      console.log("🟢 v2: Image clicked!")
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
      this.focusCommentForm(relativeX, relativeY)
    })
  }

  createTempPin(x, y) {
    console.log("🟢 v2: Creating temp pin at", x, y)
    this.removeTempPin()
    
    const tempPin = document.createElement("div")
    tempPin.className = "absolute w-8 h-8 bg-yellow-400 text-black rounded-full flex items-center justify-center text-sm font-bold cursor-pointer z-20 transform -translate-x-1/2 -translate-y-1/2 transition-all duration-200 animate-pulse"
    tempPin.style.left = `${x}%`
    tempPin.style.top = `${y}%`
    tempPin.textContent = "?"
    tempPin.style.pointerEvents = "auto"
    tempPin.dataset.tempPin = "true"
    
    tempPin.addEventListener("click", () => {
      this.removeTempPin()
      this.clearCommentForm()
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
    marker.className = "absolute w-8 h-8 bg-blue-500 text-white rounded-full flex items-center justify-center text-sm font-bold cursor-pointer z-10 transform -translate-x-1/2 -translate-y-1/2 transition-all duration-200 hover:scale-110"
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