import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["imageInput", "videoInput", "audioInput", "imagePreview", "videoPreview", "audioPreview", "allFilesInput", "mediaPreview"]

  connect() {
    console.log("File Preview Controller connected!")
    console.log("Image input target:", this.hasImageInputTarget)
    console.log("Image preview target:", this.hasImagePreviewTarget)
    console.log("All files input target:", this.hasAllFilesInputTarget)
    console.log("Media preview target:", this.hasMediaPreviewTarget)

    // 選択されたファイルの配列を初期化
    this.selectedFiles = []

    // ドラッグ&ドロップのイベントリスナーを設定
    this.setupDragAndDrop()
  }

  setupDragAndDrop() {
    console.log('Setting up drag and drop...')

    const dropZone = this.element.querySelector('.drop-zone')
    console.log('Drop zone found:', !!dropZone)

    if (!dropZone) {
      console.error('Drop zone not found!')
      return
    }

    // ドラッグオーバー時のスタイル変更を防ぐ
    ;['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
      dropZone.addEventListener(eventName, this.preventDefaults.bind(this), false)
      document.body.addEventListener(eventName, this.preventDefaults.bind(this), false)
    })

    // ドラッグオーバー時のハイライト
    ;['dragenter', 'dragover'].forEach(eventName => {
      dropZone.addEventListener(eventName, () => {
        console.log('Drag over detected')
        this.highlight(dropZone)
      }, false)
    })

    ;['dragleave', 'drop'].forEach(eventName => {
      dropZone.addEventListener(eventName, () => {
        console.log('Drag leave/drop detected')
        this.unhighlight(dropZone)
      }, false)
    })

    // ドロップ時の処理
    dropZone.addEventListener('drop', (e) => {
      console.log('Drop event triggered!')
      this.handleDrop(e)
    }, false)

    console.log('Drag and drop setup complete')
  }

  preventDefaults(e) {
    e.preventDefault()
    e.stopPropagation()
  }

  highlight(dropZone) {
    dropZone.classList.add('border-blue-500', 'bg-blue-50', 'dragover')
    dropZone.classList.remove('border-gray-300')
  }

  unhighlight(dropZone) {
    dropZone.classList.remove('border-blue-500', 'bg-blue-50', 'dragover')
    dropZone.classList.add('border-gray-300')
  }

  handleDrop(e) {
    console.log('handleDrop called', e)

    e.preventDefault()
    e.stopPropagation()

    const dt = e.dataTransfer
    const files = dt.files

    console.log('Files dropped:', files.length)
    console.log('File types:', Array.from(files).map(f => f.type))

    if (files.length > 0) {
      this.handleFiles(files)
    } else {
      console.log('No files in drop event')
    }
  }

  handleFiles(files) {
    // ファイルの種類チェック
    const allowedTypes = ['image/', 'video/', 'audio/']
    const validFiles = Array.from(files).filter(file => {
      return allowedTypes.some(type => file.type.startsWith(type))
    })

    if (validFiles.length !== files.length) {
      const invalidCount = files.length - validFiles.length
      alert(`${invalidCount}個のファイルがサポートされていない形式のため除外されました。`)
    }

    if (validFiles.length === 0) {
      console.log('No valid files to add')
      return
    }

    // 既存のファイルと新しいファイルを結合
    this.selectedFiles = [...this.selectedFiles, ...validFiles]

    console.log(`Added ${validFiles.length} files. Total: ${this.selectedFiles.length}`)

    // ファイル入力フィールドを更新
    this.updateFileInput()

    // プレビューを再生成
    this.regeneratePreview()
  }

  // 統合されたファイルプレビューメソッド（新規投稿フォーム用）
  previewFiles(event) {
    console.log("previewFiles called with event:", event)
    const files = event.target.files
    console.log("Selected files:", files)
    const previewContainer = this.mediaPreviewTarget
    console.log("Preview container:", previewContainer)

    // 選択されたファイルを配列として保存
    this.selectedFiles = Array.from(files)

    // 既存のプレビューをクリア
    previewContainer.innerHTML = ''

    if (files.length === 0) {
      console.log("No files selected")
      return
    }

    // 各ファイルに対してプレビューを生成
    this.selectedFiles.forEach((file, index) => {
      console.log(`Processing file ${index + 1}:`, file.name, file.type)
      if (file.type.startsWith('image/')) {
        console.log("Creating image preview for:", file.name)
        this.createImagePreview(file, index, previewContainer)
      } else if (file.type.startsWith('video/')) {
        console.log("Creating video preview for:", file.name)
        this.createVideoPreview(file, index, previewContainer)
      } else if (file.type.startsWith('audio/')) {
        console.log("Creating audio preview for:", file.name)
        this.createAudioPreview(file, index, previewContainer)
      }
    })

    console.log('Preview container after processing:', previewContainer.innerHTML.length > 0 ? 'has content' : 'empty')
  }

  // ファイルを削除して入力フィールドを更新
  removeFile(index) {
    console.log('removeFile called with index:', index)
    console.log('Current selectedFiles length:', this.selectedFiles.length)

    // 配列から指定されたインデックスのファイルを削除
    this.selectedFiles.splice(index, 1)

    console.log('After removal, selectedFiles length:', this.selectedFiles.length)

    // ファイル入力フィールドを更新
    this.updateFileInput()

    // プレビューを再生成
    this.regeneratePreview()
  }

  // ファイル入力フィールドを更新
  updateFileInput() {
    console.log('updateFileInput called')

    if (!this.hasAllFilesInputTarget) {
      console.error('allFilesInputTarget not found')
      return
    }

    const fileInput = this.allFilesInputTarget
    console.log('Current file input files length:', fileInput.files.length)
    console.log('Selected files array length:', this.selectedFiles.length)

    const dataTransfer = new DataTransfer()

    // 残っているファイルを新しいDataTransferに追加
    this.selectedFiles.forEach((file, index) => {
      console.log(`Adding file ${index}:`, file.name)
      dataTransfer.items.add(file)
    })

    // 入力フィールドのfilesを更新
    fileInput.files = dataTransfer.files

    console.log('Updated file input files length:', fileInput.files.length)

    // 変更イベントを発火
    const event = new Event('change', { bubbles: true })
    fileInput.dispatchEvent(event)

    console.log('Change event dispatched')
  }

  // プレビューを再生成
  regeneratePreview() {
    const previewContainer = this.mediaPreviewTarget
    previewContainer.innerHTML = ''

    this.selectedFiles.forEach((file, index) => {
      if (file.type.startsWith('image/')) {
        this.createImagePreview(file, index, previewContainer)
      } else if (file.type.startsWith('video/')) {
        this.createVideoPreview(file, index, previewContainer)
      } else if (file.type.startsWith('audio/')) {
        this.createAudioPreview(file, index, previewContainer)
      }
    })
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
    const self = this  // thisの参照を保存

    reader.onload = (e) => {
      console.log('Image loaded for preview:', file.name)
      const previewDiv = document.createElement('div')
      previewDiv.className = 'relative mb-4 inline-block mx-2'

      const img = document.createElement('img')
      img.src = e.target.result
      img.className = 'w-32 h-32 object-cover rounded-lg shadow-md border border-gray-200'
      img.alt = `プレビュー ${index + 1}`

      const removeBtn = document.createElement('button')
      removeBtn.type = 'button'
      removeBtn.className = 'file-remove-btn absolute top-2 right-2 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm hover:bg-red-600 shadow-lg'
      removeBtn.innerHTML = '×'
      removeBtn.setAttribute('data-file-index', index)
      removeBtn.onclick = (e) => {
        e.preventDefault()
        e.stopPropagation()
        console.log('Remove button clicked! Index:', index)

        // プレビューを削除
        previewDiv.remove()

        // ファイル選択を完全にクリア
        const fileInput = self.allFilesInputTarget
        if (fileInput) {
          fileInput.value = ''
          console.log('File input cleared')

          // change イベントを発火
          const event = new Event('change', { bubbles: true })
          fileInput.dispatchEvent(event)
        }

        // selectedFiles配列もクリア
        self.selectedFiles = []
        console.log('Selected files cleared')
      }

      const fileName = document.createElement('p')
      fileName.textContent = file.name.length > 20 ? file.name.substring(0, 20) + '...' : file.name
      fileName.className = 'text-xs text-gray-600 mt-2 text-center font-medium'

      const fileSize = document.createElement('p')
      fileSize.textContent = `${(file.size / 1024 / 1024).toFixed(1)} MB`
      fileSize.className = 'text-xs text-gray-500 text-center'

      previewDiv.appendChild(img)
      previewDiv.appendChild(removeBtn)
      previewDiv.appendChild(fileName)
      previewDiv.appendChild(fileSize)
      container.appendChild(previewDiv)

      console.log('Image preview added to container')
    }

    reader.readAsDataURL(file)
  }

  createVideoPreview(file, index, container) {
    const previewDiv = document.createElement('div')
    previewDiv.className = 'relative mb-4 inline-block mx-2'
    const self = this  // thisの参照を保存

    const video = document.createElement('video')
    video.src = URL.createObjectURL(file)
    video.className = 'w-32 h-32 object-cover rounded-lg shadow-md border border-gray-200'
    video.controls = true
    video.preload = 'metadata'

    const removeBtn = document.createElement('button')
    removeBtn.type = 'button'
    removeBtn.className = 'absolute top-2 right-2 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm hover:bg-red-600 shadow-lg'
    removeBtn.innerHTML = '×'
    removeBtn.onclick = (e) => {
      e.preventDefault()
      e.stopPropagation()
      console.log('Video remove button clicked! Index:', index)

      URL.revokeObjectURL(video.src)

      // プレビューを削除
      previewDiv.remove()

      // ファイル選択を完全にクリア
      const fileInput = self.allFilesInputTarget
      if (fileInput) {
        fileInput.value = ''
        console.log('File input cleared')

        // change イベントを発火
        const event = new Event('change', { bubbles: true })
        fileInput.dispatchEvent(event)
      }

      // selectedFiles配列もクリア
      self.selectedFiles = []
      console.log('Selected files cleared')
    }

    const fileName = document.createElement('p')
    fileName.textContent = file.name.length > 20 ? file.name.substring(0, 20) + '...' : file.name
    fileName.className = 'text-xs text-gray-600 mt-2 text-center font-medium'

    const fileSize = document.createElement('p')
    fileSize.textContent = `${(file.size / 1024 / 1024).toFixed(1)} MB`
    fileSize.className = 'text-xs text-gray-500 text-center'

    previewDiv.appendChild(video)
    previewDiv.appendChild(removeBtn)
    previewDiv.appendChild(fileName)
    previewDiv.appendChild(fileSize)
    container.appendChild(previewDiv)

    console.log('Video preview added to container')
  }

  createAudioPreview(file, index, container) {
    const previewDiv = document.createElement('div')
    previewDiv.className = 'relative mb-4 inline-block mx-2 w-32'
    const self = this  // thisの参照を保存

    const audioWrapper = document.createElement('div')
    audioWrapper.className = 'p-3 bg-gradient-to-br from-purple-100 to-blue-100 rounded-lg border border-gray-200 h-32 flex flex-col justify-center items-center'

    const audioIcon = document.createElement('div')
    audioIcon.className = 'w-8 h-8 flex items-center justify-center bg-white rounded-full mb-2 shadow-sm'
    audioIcon.innerHTML = '<svg class="w-4 h-4 text-purple-600" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M9.383 3.076A1 1 0 0110 4v12a1 1 0 01-1.707.707L4.586 13H2a1 1 0 01-1-1V8a1 1 0 011-1h2.586l3.707-3.707a1 1 0 011.09-.217zM15.657 6.343a1 1 0 011.414 0A9.972 9.972 0 0119 12a9.972 9.972 0 01-1.929 5.657 1 1 0 01-1.414-1.414A7.971 7.971 0 0017 12c0-2.21-.895-4.21-2.343-5.657a1 1 0 010-1.414zm-2.829 2.828a1 1 0 011.415 0A5.983 5.983 0 0115 12a5.983 5.983 0 01-.757 2.828 1 1 0 01-1.415-1.414A3.987 3.987 0 0013 12a3.987 3.987 0 00-.172-1.414 1 1 0 010-1.415z" clip-rule="evenodd"/></svg>'

    const audioElement = document.createElement('audio')
    audioElement.src = URL.createObjectURL(file)
    audioElement.controls = true
    audioElement.className = 'w-full mb-1'
    audioElement.style.height = '24px'

    const removeBtn = document.createElement('button')
    removeBtn.type = 'button'
    removeBtn.className = 'absolute top-2 right-2 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm hover:bg-red-600 shadow-lg'
    removeBtn.innerHTML = '×'
    removeBtn.onclick = (e) => {
      e.preventDefault()
      e.stopPropagation()
      console.log('Audio remove button clicked! Index:', index)

      URL.revokeObjectURL(audioElement.src)

      // プレビューを削除
      previewDiv.remove()

      // ファイル選択を完全にクリア
      const fileInput = self.allFilesInputTarget
      if (fileInput) {
        fileInput.value = ''
        console.log('File input cleared')

        // change イベントを発火
        const event = new Event('change', { bubbles: true })
        fileInput.dispatchEvent(event)
      }

      // selectedFiles配列もクリア
      self.selectedFiles = []
      console.log('Selected files cleared')
    }

    const fileName = document.createElement('p')
    fileName.textContent = file.name.length > 20 ? file.name.substring(0, 20) + '...' : file.name
    fileName.className = 'text-xs text-gray-600 mt-2 text-center font-medium'

    const fileSize = document.createElement('p')
    fileSize.textContent = `${(file.size / 1024 / 1024).toFixed(1)} MB`
    fileSize.className = 'text-xs text-gray-500 text-center'

    audioWrapper.appendChild(audioIcon)
    audioWrapper.appendChild(audioElement)
    previewDiv.appendChild(audioWrapper)
    previewDiv.appendChild(removeBtn)
    previewDiv.appendChild(fileName)
    previewDiv.appendChild(fileSize)
    container.appendChild(previewDiv)

    console.log('Audio preview added to container')
  }
}

// Updated: 2025-09-17 - Reduced preview size to w-32 h-32