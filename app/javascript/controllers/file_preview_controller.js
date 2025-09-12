import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["imageInput", "videoInput", "audioInput", "imagePreview", "videoPreview", "audioPreview"]

  connect() {
    console.log("File Preview Controller connected!")
    console.log("Image input target:", this.hasImageInputTarget)
    console.log("Image preview target:", this.hasImagePreviewTarget)
  }

  previewImages(event) {
    console.log("previewImages called with event:", event)
    const files = event.target.files
    console.log("Selected files:", files)
    const previewContainer = this.imagePreviewTarget
    console.log("Preview container:", previewContainer)
    
    // クリア既存のプレビュー
    previewContainer.innerHTML = ''
    
    if (files.length === 0) {
      console.log("No files selected")
      return
    }

    // 各ファイルに対してプレビューを生成
    Array.from(files).forEach((file, index) => {
      console.log(`Processing file ${index + 1}:`, file.name, file.type)
      if (file.type.startsWith('image/')) {
        console.log("Creating image preview for:", file.name)
        this.createImagePreview(file, index, previewContainer)
      }
    })
  }

  previewVideos(event) {
    const files = event.target.files
    const previewContainer = this.videoPreviewTarget
    
    // クリア既存のプレビュー
    previewContainer.innerHTML = ''
    
    if (files.length === 0) {
      return
    }

    Array.from(files).forEach((file, index) => {
      if (file.type.startsWith('video/')) {
        this.createVideoPreview(file, index, previewContainer)
      }
    })
  }

  previewAudios(event) {
    const files = event.target.files
    const previewContainer = this.audioPreviewTarget
    
    // クリア既存のプレビュー
    previewContainer.innerHTML = ''
    
    if (files.length === 0) {
      return
    }

    Array.from(files).forEach((file, index) => {
      if (file.type.startsWith('audio/')) {
        this.createAudioPreview(file, index, previewContainer)
      }
    })
  }

  createImagePreview(file, index, container) {
    const reader = new FileReader()
    
    reader.onload = (e) => {
      const previewDiv = document.createElement('div')
      previewDiv.className = 'relative mb-6'
      
      const img = document.createElement('img')
      img.src = e.target.result
      img.className = 'w-full max-w-lg h-auto rounded-lg shadow-lg'
      img.alt = `プレビュー ${index + 1}`
      
      const removeBtn = document.createElement('button')
      removeBtn.type = 'button'
      removeBtn.className = 'absolute top-2 right-2 bg-red-500 text-white rounded-full w-8 h-8 flex items-center justify-center text-lg hover:bg-red-600 shadow-lg'
      removeBtn.innerHTML = '×'
      removeBtn.onclick = () => previewDiv.remove()
      
      const fileName = document.createElement('p')
      fileName.textContent = file.name
      fileName.className = 'text-sm text-gray-700 mt-3 font-medium'
      
      const fileSize = document.createElement('p')
      fileSize.textContent = `ファイルサイズ: ${(file.size / 1024 / 1024).toFixed(2)} MB`
      fileSize.className = 'text-xs text-gray-500'
      
      previewDiv.appendChild(img)
      previewDiv.appendChild(removeBtn)
      previewDiv.appendChild(fileName)
      previewDiv.appendChild(fileSize)
      container.appendChild(previewDiv)
    }
    
    reader.readAsDataURL(file)
  }

  createVideoPreview(file, index, container) {
    const previewDiv = document.createElement('div')
    previewDiv.className = 'relative mb-6'
    
    const video = document.createElement('video')
    video.src = URL.createObjectURL(file)
    video.className = 'w-full max-w-lg h-auto rounded-lg shadow-lg'
    video.controls = true
    video.preload = 'metadata'
    
    const removeBtn = document.createElement('button')
    removeBtn.type = 'button'
    removeBtn.className = 'absolute top-2 right-2 bg-red-500 text-white rounded-full w-8 h-8 flex items-center justify-center text-lg hover:bg-red-600 shadow-lg'
    removeBtn.innerHTML = '×'
    removeBtn.onclick = () => {
      URL.revokeObjectURL(video.src)
      previewDiv.remove()
    }
    
    const fileName = document.createElement('p')
    fileName.textContent = file.name
    fileName.className = 'text-sm text-gray-700 mt-3 font-medium'
    
    const fileSize = document.createElement('p')
    fileSize.textContent = `ファイルサイズ: ${(file.size / 1024 / 1024).toFixed(2)} MB`
    fileSize.className = 'text-xs text-gray-500'
    
    previewDiv.appendChild(video)
    previewDiv.appendChild(removeBtn)
    previewDiv.appendChild(fileName)
    previewDiv.appendChild(fileSize)
    container.appendChild(previewDiv)
  }

  createAudioPreview(file, index, container) {
    const previewDiv = document.createElement('div')
    previewDiv.className = 'relative mb-6 p-6 bg-gray-100 rounded-lg max-w-lg'
    
    const audioElement = document.createElement('audio')
    audioElement.src = URL.createObjectURL(file)
    audioElement.controls = true
    audioElement.className = 'w-full mb-4'
    
    const audioIcon = document.createElement('div')
    audioIcon.className = 'w-32 h-32 flex items-center justify-center bg-blue-100 rounded-lg mx-auto mb-4'
    audioIcon.innerHTML = '<svg class="w-16 h-16 text-blue-600" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M9.383 3.076A1 1 0 0110 4v12a1 1 0 01-1.707.707L4.586 13H2a1 1 0 01-1-1V8a1 1 0 011-1h2.586l3.707-3.707a1 1 0 011.09-.217zM15.657 6.343a1 1 0 011.414 0A9.972 9.972 0 0119 12a9.972 9.972 0 01-1.929 5.657 1 1 0 01-1.414-1.414A7.971 7.971 0 0017 12c0-2.21-.895-4.21-2.343-5.657a1 1 0 010-1.414zm-2.829 2.828a1 1 0 011.415 0A5.983 5.983 0 0115 12a5.983 5.983 0 01-.757 2.828 1 1 0 01-1.415-1.414A3.987 3.987 0 0013 12a3.987 3.987 0 00-.172-1.414 1 1 0 010-1.415z" clip-rule="evenodd"/></svg>'
    
    const removeBtn = document.createElement('button')
    removeBtn.type = 'button'
    removeBtn.className = 'absolute top-2 right-2 bg-red-500 text-white rounded-full w-8 h-8 flex items-center justify-center text-lg hover:bg-red-600 shadow-lg'
    removeBtn.innerHTML = '×'
    removeBtn.onclick = () => {
      URL.revokeObjectURL(audioElement.src)
      previewDiv.remove()
    }
    
    const fileName = document.createElement('p')
    fileName.textContent = file.name
    fileName.className = 'text-sm text-gray-700 font-medium text-center'
    
    const fileSize = document.createElement('p')
    fileSize.textContent = `ファイルサイズ: ${(file.size / 1024 / 1024).toFixed(2)} MB`
    fileSize.className = 'text-xs text-gray-500 text-center'
    
    previewDiv.appendChild(audioIcon)
    previewDiv.appendChild(audioElement)
    previewDiv.appendChild(removeBtn)
    previewDiv.appendChild(fileName)
    previewDiv.appendChild(fileSize)
    container.appendChild(previewDiv)
  }
}