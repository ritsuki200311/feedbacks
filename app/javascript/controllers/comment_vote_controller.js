import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["upButton", "downButton", "voteCount"]
  static values = {
    commentId: Number,
    userVote: Number,
    upCount: Number,
    downCount: Number
  }

  connect() {
    console.log('🔥 Comment Vote Controller connected!', {
      element: this.element,
      commentId: this.commentIdValue,
      userVote: this.userVoteValue,
      upCount: this.upCountValue,
      downCount: this.downCountValue,
      hasUpButton: this.hasUpButtonTarget,
      hasDownButton: this.hasDownButtonTarget,
      hasVoteCount: this.hasVoteCountTarget
    })
    this.updateButtonStyles()

    // テスト用: グローバルからアクセス可能にする
    window.testCommentVote = this

    // 要素にコントローラーへの参照を保存
    this.element.commentVoteController = this
  }

  upvote(event) {
    event.preventDefault()
    console.log('🔥 Upvote clicked!', {
      event: event,
      currentUserVote: this.userVoteValue,
      commentId: this.commentIdValue,
      element: this.element
    })

    // 既にupvoteしている場合は取り消し、そうでなければupvote
    const newVote = this.userVoteValue === 1 ? 0 : 1
    console.log('🔥 New vote value:', newVote)
    this.submitVote(newVote)
  }

  downvote(event) {
    event.preventDefault()
    console.log('🔥 Downvote clicked!', {
      event: event,
      currentUserVote: this.userVoteValue,
      commentId: this.commentIdValue,
      element: this.element
    })

    // 既にdownvoteしている場合は取り消し、そうでなければdownvote
    const newVote = this.userVoteValue === -1 ? 0 : -1
    console.log('🔥 New vote value:', newVote)
    this.submitVote(newVote)
  }

  submitVote(value) {
    console.log('🔥 submitVote called with value:', value)

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    console.log('🔥 CSRF Token found:', csrfToken ? 'Yes' : 'No')

    const formData = new FormData()
    formData.append('votable_type', 'Comment')
    formData.append('votable_id', this.commentIdValue)
    formData.append('value', value)

    console.log('🔥 Sending vote request:', {
      url: '/vote',
      votable_type: 'Comment',
      votable_id: this.commentIdValue,
      value: value,
      csrfToken: csrfToken
    })

    fetch('/vote', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      },
      body: formData
    })
    .then(response => {
      console.log('🔥 Vote response received:', response.status, response.statusText)
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      return response.json()
    })
    .then(data => {
      console.log('🔥 Vote response data:', data)
      if (data.success) {
        console.log('🔥 Vote successful, updating display')
        this.upCountValue = data.up_count
        this.downCountValue = data.down_count
        this.userVoteValue = data.user_vote
        this.updateDisplay()
      } else {
        console.error('投票エラー:', data.error)
        if (data.error === 'already_voted') {
          // サーバーから返された最新の投票状態で更新
          this.upCountValue = data.up_count
          this.downCountValue = data.down_count
          this.userVoteValue = data.user_vote
          this.updateDisplay()
        }
      }
    })
    .catch(error => {
      console.error('🔥 Vote fetch error:', error)
    })
  }

  updateDisplay() {
    const netVotes = this.upCountValue - this.downCountValue
    this.voteCountTarget.textContent = netVotes >= 0 ? `+${netVotes}` : netVotes
    this.updateButtonStyles()
  }

  updateButtonStyles() {
    // リセット
    this.resetButtonStyles()

    // 投票済みの場合は強調表示
    if (this.userVoteValue === 1) {
      this.highlightUpButton()
    } else if (this.userVoteValue === -1) {
      this.highlightDownButton()
    }

    // ボタンは常にクリック可能にする（投票の変更・取り消しを許可）
  }

  resetButtonStyles() {
    // アップボタンのリセット
    this.upButtonTarget.classList.remove(
      'text-white', 'bg-green-500', 'shadow-lg', 'scale-110', 'border-2', 'border-green-400', 'cursor-not-allowed'
    )
    this.upButtonTarget.classList.add('text-gray-400', 'hover:text-green-500', 'border', 'border-gray-300')

    // ダウンボタンのリセット
    this.downButtonTarget.classList.remove(
      'text-white', 'bg-red-500', 'shadow-lg', 'scale-110', 'border-2', 'border-red-400', 'cursor-not-allowed'
    )
    this.downButtonTarget.classList.add('text-gray-400', 'hover:text-red-500', 'border', 'border-gray-300')

    // SVGのリセット
    const upSvg = this.upButtonTarget.querySelector('svg')
    const downSvg = this.downButtonTarget.querySelector('svg')

    if (upSvg) {
      upSvg.setAttribute('fill', 'none')
      upSvg.setAttribute('stroke', 'currentColor')
      upSvg.setAttribute('stroke-width', '2')
    }

    if (downSvg) {
      downSvg.setAttribute('fill', 'none')
      downSvg.setAttribute('stroke', 'currentColor')
      downSvg.setAttribute('stroke-width', '2')
    }
  }

  highlightUpButton() {
    this.upButtonTarget.classList.remove('text-gray-400', 'hover:text-green-500', 'border', 'border-gray-300')
    this.upButtonTarget.classList.add('text-white', 'bg-green-500', 'shadow-lg', 'scale-110', 'border-2', 'border-green-400')

    // SVGを強調表示
    const svg = this.upButtonTarget.querySelector('svg')
    if (svg) {
      svg.setAttribute('fill', 'none')
      svg.setAttribute('stroke', 'currentColor')
      svg.setAttribute('stroke-width', '3')
    }
  }

  highlightDownButton() {
    this.downButtonTarget.classList.remove('text-gray-400', 'hover:text-red-500', 'border', 'border-gray-300')
    this.downButtonTarget.classList.add('text-white', 'bg-red-500', 'shadow-lg', 'scale-110', 'border-2', 'border-red-400')

    // SVGを強調表示
    const svg = this.downButtonTarget.querySelector('svg')
    if (svg) {
      svg.setAttribute('fill', 'none')
      svg.setAttribute('stroke', 'currentColor')
      svg.setAttribute('stroke-width', '3')
    }
  }
}