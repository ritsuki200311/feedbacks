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

    // シンプルなファイル復元
    this.simpleFileRestore()

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

  // ファイル名で特定してファイルを削除（より安全）
  removeFileByName(fileName, expectedIndex) {
    console.log('removeFileByName called with fileName:', fileName, 'expectedIndex:', expectedIndex)
    console.log('Current selectedFiles length:', this.selectedFiles.length)

    // ファイル名で一致するファイルを探す
    const fileIndex = this.selectedFiles.findIndex(file => file.name === fileName)

    if (fileIndex === -1) {
      console.warn('File not found in selectedFiles array:', fileName)
      return
    }

    console.log('Found file at index:', fileIndex, 'expected:', expectedIndex)

    // 配列から該当ファイルを削除
    this.selectedFiles.splice(fileIndex, 1)

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
    console.log('regeneratePreview called, selectedFiles length:', this.selectedFiles.length)
    const previewContainer = this.mediaPreviewTarget
    previewContainer.innerHTML = ''

    this.selectedFiles.forEach((file, index) => {
      console.log(`Regenerating preview for file ${index}:`, file.name)
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
        console.log('Remove button clicked! Index:', index, 'File:', file.name)

        // ファイル名で特定して削除（より安全）
        self.removeFileByName(file.name, index)
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
      console.log('Video remove button clicked! Index:', index, 'File:', file.name)

      URL.revokeObjectURL(video.src)

      // ファイル名で特定して削除（より安全）
      self.removeFileByName(file.name, index)
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
      console.log('Audio remove button clicked! Index:', index, 'File:', file.name)

      URL.revokeObjectURL(audioElement.src)

      // ファイル名で特定して削除（より安全）
      self.removeFileByName(file.name, index)
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

  // バリデーションエラー後のファイル復元
  restoreFilesAfterError() {
    // フォームがエラー状態かどうかをチェック
    const errorDiv = document.querySelector('.bg-red-100')
    if (!errorDiv || !this.hasAllFilesInputTarget) {
      console.log('No errors found or file input not available')
      return
    }

    console.log('Attempting to restore files after validation error')

    // まずグローバル変数から復元を試行
    if (window.tempSelectedFiles && window.tempSelectedFiles.length > 0) {
      console.log('Restoring files from global variable:', window.tempSelectedFiles.length, 'files')
      this.selectedFiles = window.tempSelectedFiles
      this.updateFileInput()
      this.regeneratePreview()

      // グローバル変数をクリア
      window.tempSelectedFiles = null

      // sessionStorageもクリア
      sessionStorage.removeItem('pendingFilesBasic')
      sessionStorage.removeItem('pendingFilesCount')

      console.log('Files restored successfully from global variable')
      return
    }

    // sessionStorageから復元を試行
    const savedBasicFiles = sessionStorage.getItem('pendingFilesBasic')
    const savedCount = sessionStorage.getItem('pendingFilesCount')

    if (savedBasicFiles && savedCount) {
      try {
        const basicFilesData = JSON.parse(savedBasicFiles)
        console.log('Found files in sessionStorage, showing restoration message')
        this.showFileRestorationMessage(basicFilesData)

        sessionStorage.removeItem('pendingFilesBasic')
        sessionStorage.removeItem('pendingFilesCount')
      } catch (error) {
        console.error('Error parsing sessionStorage files:', error)
      }
      return
    }

    // LocalStorageから復元を試行（フォールバック）
    const savedFilesData = localStorage.getItem('pendingFilesData')
    const savedLocalCount = localStorage.getItem('pendingFilesCount')

    if (savedFilesData && savedLocalCount) {
      try {
        const filesData = JSON.parse(savedFilesData)
        if (filesData && filesData.length > 0) {
          console.log('Restoring files from localStorage:', filesData.length, 'files')
          this.recreateFilesFromData(filesData)

          localStorage.removeItem('pendingFilesData')
          localStorage.removeItem('pendingFilesCount')
        }
      } catch (error) {
        console.error('Error parsing localStorage files:', error)
        localStorage.removeItem('pendingFilesData')
        localStorage.removeItem('pendingFilesCount')
      }
    } else {
      console.log('No saved files found in any storage')
    }
  }

  // ファイル情報からプレビューを表示
  displayFileInfoPreviews(fileInfos) {
    const previewContainer = this.mediaPreviewTarget
    previewContainer.innerHTML = ''

    fileInfos.forEach((fileInfo, index) => {
      const previewDiv = document.createElement('div')
      previewDiv.className = 'relative mb-4 inline-block mx-2'

      if (fileInfo.type.startsWith('image/')) {
        const img = document.createElement('img')
        img.src = fileInfo.dataUrl
        img.className = 'w-32 h-32 object-cover rounded-lg shadow-md border border-gray-200'
        img.alt = `復元されたプレビュー ${index + 1}`
        previewDiv.appendChild(img)
      } else if (fileInfo.type.startsWith('video/')) {
        const video = document.createElement('video')
        video.src = fileInfo.dataUrl
        video.className = 'w-32 h-32 object-cover rounded-lg shadow-md border border-gray-200'
        video.controls = true
        video.preload = 'metadata'
        previewDiv.appendChild(video)
      } else if (fileInfo.type.startsWith('audio/')) {
        const audioWrapper = document.createElement('div')
        audioWrapper.className = 'p-3 bg-gradient-to-br from-purple-100 to-blue-100 rounded-lg border border-gray-200 h-32 flex flex-col justify-center items-center'

        const audioIcon = document.createElement('div')
        audioIcon.className = 'w-8 h-8 flex items-center justify-center bg-white rounded-full mb-2 shadow-sm'
        audioIcon.innerHTML = '<svg class="w-4 h-4 text-purple-600" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M9.383 3.076A1 1 0 0110 4v12a1 1 0 01-1.707.707L4.586 13H2a1 1 0 01-1-1V8a1 1 0 011-1h2.586l3.707-3.707a1 1 0 011.09-.217zM15.657 6.343a1 1 0 011.414 0A9.972 9.972 0 0119 12a9.972 9.972 0 01-1.929 5.657 1 1 0 01-1.414-1.414A7.971 7.971 0 0017 12c0-2.21-.895-4.21-2.343-5.657a1 1 0 010-1.414zm-2.829 2.828a1 1 0 011.415 0A5.983 5.983 0 0115 12a5.983 5.983 0 01-.757 2.828 1 1 0 01-1.415-1.414A3.987 3.987 0 0013 12a3.987 3.987 0 00-.172-1.414 1 1 0 010-1.415z" clip-rule="evenodd"/></svg>'

        const audioElement = document.createElement('audio')
        audioElement.src = fileInfo.dataUrl
        audioElement.controls = true
        audioElement.className = 'w-full mb-1'
        audioElement.style.height = '24px'

        audioWrapper.appendChild(audioIcon)
        audioWrapper.appendChild(audioElement)
        previewDiv.appendChild(audioWrapper)
      }

      // ファイル名とサイズ情報
      const fileName = document.createElement('p')
      fileName.textContent = fileInfo.name.length > 20 ? fileInfo.name.substring(0, 20) + '...' : fileInfo.name
      fileName.className = 'text-xs text-gray-600 mt-2 text-center font-medium'

      const fileSize = document.createElement('p')
      fileSize.textContent = `${(fileInfo.size / 1024 / 1024).toFixed(1)} MB`
      fileSize.className = 'text-xs text-gray-500 text-center'

      // 削除ボタン（復元されたファイルはプレビューのみ削除）
      const removeBtn = document.createElement('button')
      removeBtn.type = 'button'
      removeBtn.className = 'absolute top-2 right-2 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm hover:bg-red-600 shadow-lg'
      removeBtn.innerHTML = '×'
      removeBtn.title = '復元されたプレビューを削除'
      removeBtn.onclick = (e) => {
        e.preventDefault()
        e.stopPropagation()
        console.log('Removing restored file preview')
        previewDiv.remove()
      }

      previewDiv.appendChild(fileName)
      previewDiv.appendChild(fileSize)
      previewDiv.appendChild(removeBtn)
      previewContainer.appendChild(previewDiv)
    })

    console.log('File info previews displayed')
  }

  // ファイル復元メッセージを表示
  showFileRestorationMessage(fileInfos) {
    const previewContainer = this.mediaPreviewTarget

    // 復元メッセージを作成
    const messageDiv = document.createElement('div')
    messageDiv.className = 'bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4 text-center'
    messageDiv.innerHTML = `
      <div class="flex items-center justify-center mb-2">
        <svg class="w-5 h-5 text-blue-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
        </svg>
        <span class="text-blue-800 font-semibold">選択されたファイルが保持されています</span>
      </div>
      <p class="text-blue-700 text-sm">
        ${fileInfos.length}個のファイルが選択されています。再度ファイルを選択する必要はありません。
      </p>
      <div class="mt-2 text-xs text-blue-600">
        ${fileInfos.map(file => `📎 ${file.name} (${(file.size / 1024 / 1024).toFixed(1)}MB)`).join(', ')}
      </div>
    `

    // メッセージをプレビューエリアに追加
    previewContainer.appendChild(messageDiv)

    // 5秒後にメッセージを自動削除
    setTimeout(() => {
      if (messageDiv.parentNode) {
        messageDiv.remove()
      }
    }, 5000)

    console.log('File restoration message displayed')
  }

  // フォーム送信前にファイル情報を保存
  setupFormSubmitHandler() {
    const form = this.element.closest('form')
    if (!form) {
      console.log('Form not found')
      return
    }

    // フォーム送信前にファイル情報を即座に保存
    form.addEventListener('submit', (e) => {
      console.log('Form submit detected')

      // ファイルが選択されている場合のみ保存
      if (this.hasAllFilesInputTarget && this.allFilesInputTarget.files.length > 0) {
        console.log('Saving files before submit:', this.allFilesInputTarget.files.length)

        // 現在の選択ファイルを更新
        this.selectedFiles = Array.from(this.allFilesInputTarget.files)

        // 即座に保存（同期的に）
        this.saveCurrentFilesSync()

        console.log('Files saved before form submission')
      }
    })
  }

  // 現在のファイル情報をLocalStorageに保存（ファイルデータも含めて保存）
  saveCurrentFiles() {
    if (!this.selectedFiles || this.selectedFiles.length === 0) {
      console.log('No files to save')
      localStorage.removeItem('pendingFilesData')
      localStorage.removeItem('pendingFilesCount')
      return
    }

    console.log('Saving', this.selectedFiles.length, 'files to localStorage with data')

    // ファイルデータを含めて保存
    const promises = this.selectedFiles.map((file, index) => {
      return new Promise((resolve) => {
        const reader = new FileReader()
        reader.onload = (e) => {
          resolve({
            name: file.name,
            size: file.size,
            type: file.type,
            lastModified: file.lastModified,
            dataUrl: e.target.result
          })
        }
        reader.onerror = () => {
          resolve({
            name: file.name,
            size: file.size,
            type: file.type,
            lastModified: file.lastModified,
            dataUrl: null
          })
        }
        reader.readAsDataURL(file)
      })
    })

    Promise.all(promises).then((filesData) => {
      try {
        localStorage.setItem('pendingFilesData', JSON.stringify(filesData))
        localStorage.setItem('pendingFilesCount', this.selectedFiles.length.toString())
        console.log('Files with data saved to localStorage successfully')
      } catch (error) {
        console.error('Error saving files to localStorage:', error)
        // 容量オーバーの場合は基本情報のみ保存
        const basicFileInfos = this.selectedFiles.map(file => ({
          name: file.name,
          size: file.size,
          type: file.type,
          lastModified: file.lastModified
        }))
        try {
          localStorage.setItem('pendingFilesData', JSON.stringify(basicFileInfos))
          localStorage.setItem('pendingFilesCount', this.selectedFiles.length.toString())
          console.log('Basic file info saved as fallback')
        } catch (fallbackError) {
          console.error('Failed to save even basic file info:', fallbackError)
        }
      }
    }).catch((error) => {
      console.error('Error reading files for saving:', error)
    })
  }

  // フォームにファイル情報を持続させる
  preserveFilesInForm() {
    console.log('Preserving files in form for potential error recovery')

    // ファイル情報を hidden input として追加
    const form = this.element.closest('form')
    if (!form) return

    // 既存の保存用 hidden field があれば削除
    const existingHidden = form.querySelector('input[name="preserved_files"]')
    if (existingHidden) {
      existingHidden.remove()
    }

    // 新しい hidden field を作成
    const hiddenInput = document.createElement('input')
    hiddenInput.type = 'hidden'
    hiddenInput.name = 'preserved_files'
    hiddenInput.value = 'true'
    form.appendChild(hiddenInput)

    console.log('Files preservation flag added to form')
  }

  // 保存されたデータからファイルオブジェクトを再作成
  recreateFilesFromData(filesData) {
    console.log('Recreating files from saved data:', filesData.length, 'files')

    const recreatedFiles = []
    let processedCount = 0

    filesData.forEach((fileData, index) => {
      if (fileData.dataUrl) {
        // Base64データからBlobを作成
        fetch(fileData.dataUrl)
          .then(res => res.blob())
          .then(blob => {
            // BlobからFileオブジェクトを作成
            const file = new File([blob], fileData.name, {
              type: fileData.type,
              lastModified: fileData.lastModified
            })
            recreatedFiles[index] = file
            processedCount++

            // 全てのファイルが処理されたら復元完了
            if (processedCount === filesData.length) {
              this.completeFileRestoration(recreatedFiles.filter(f => f !== undefined))
            }
          })
          .catch(error => {
            console.error('Error recreating file:', fileData.name, error)
            processedCount++
            if (processedCount === filesData.length) {
              this.completeFileRestoration(recreatedFiles.filter(f => f !== undefined))
            }
          })
      } else {
        // データがない場合はスキップ
        processedCount++
        if (processedCount === filesData.length) {
          this.completeFileRestoration(recreatedFiles.filter(f => f !== undefined))
        }
      }
    })

    // データがない場合は復元メッセージのみ表示
    if (filesData.every(f => !f.dataUrl)) {
      this.showFileRestorationMessage(filesData)
    }
  }

  // ファイル復元完了処理
  completeFileRestoration(restoredFiles) {
    console.log('File restoration completed with', restoredFiles.length, 'files')

    if (restoredFiles.length > 0) {
      // 復元されたファイルをselectedFilesに設定
      this.selectedFiles = restoredFiles

      // ファイル入力フィールドを更新
      this.updateFileInput()

      // プレビューを再生成
      this.regeneratePreview()

      console.log('Files successfully restored and preview regenerated')
    }
  }

  // フォーム送信をインターセプトしてファイル状態を維持
  simpleFileRestore() {
    const form = this.element.closest('form')
    if (!form) {
      console.log('Form not found')
      return
    }

    console.log('Setting up form submission handling')

    // フォーム送信をインターセプト
    form.addEventListener('submit', (e) => {
      e.preventDefault()
      console.log('Form submission intercepted')

      // 現在のファイル状態を保存
      if (this.hasAllFilesInputTarget && this.allFilesInputTarget.files.length > 0) {
        this.savedFiles = Array.from(this.allFilesInputTarget.files)
        this.savedSelectedFiles = [...this.selectedFiles]
        console.log('Saved current file state:', this.savedFiles.length, 'files')
      }

      // フォームデータを作成
      const formData = new FormData(form)

      // Fetch APIでフォームを送信
      fetch(form.action, {
        method: 'POST',
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        }
      })
      .then(response => {
        if (response.redirected) {
          // 成功時のリダイレクト
          console.log('Form submission successful, redirecting')
          window.location.href = response.url
          return
        }
        return response.text()
      })
      .then(html => {
        if (!html) return // リダイレクトの場合はhtmlがない

        if (html.includes('bg-red-100')) {
          // エラーがある場合、エラーメッセージだけを表示してファイル状態を維持
          console.log('Validation errors detected, maintaining file state')
          this.showValidationErrors(html)
          this.restoreFileState()
        } else {
          // その他の成功ケース
          console.log('Form submission successful')
          window.location.href = '/'
        }
      })
      .catch(error => {
        console.error('Form submission error:', error)
        alert('送信エラーが発生しました。')
      })
    })
  }

  // バリデーションエラーを表示
  showValidationErrors(html) {
    const parser = new DOMParser()
    const doc = parser.parseFromString(html, 'text/html')
    const errorDiv = doc.querySelector('.bg-red-100')

    if (errorDiv) {
      // 既存のエラーメッセージを削除
      const existingError = document.querySelector('.bg-red-100')
      if (existingError) {
        existingError.remove()
      }

      // 新しいエラーメッセージを挿入
      const form = this.element.closest('form')
      form.insertBefore(errorDiv, form.firstChild)

      console.log('Validation errors displayed')
    }
  }

  // ファイル状態を復元
  restoreFileState() {
    if (this.savedFiles && this.savedFiles.length > 0) {
      console.log('Restoring file state:', this.savedFiles.length, 'files')

      // selectedFiles配列を復元
      this.selectedFiles = this.savedSelectedFiles || this.savedFiles

      // ファイル入力を復元
      const dataTransfer = new DataTransfer()
      this.savedFiles.forEach(file => dataTransfer.items.add(file))
      this.allFilesInputTarget.files = dataTransfer.files

      // プレビューを復元
      this.regeneratePreview()

      console.log('File state restored successfully')
    }
  }
}

// Updated: 2025-09-17 - Reduced preview size to w-32 h-32