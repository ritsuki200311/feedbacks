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
    this.updateButtonStyles()
  }

  upvote(event) {
    event.preventDefault()

    // 既に投票済みの場合は何もしない
    if (this.userVoteValue !== 0) {
      return
    }

    this.submitVote(1)
  }

  downvote(event) {
    event.preventDefault()

    // 既に投票済みの場合は何もしない
    if (this.userVoteValue !== 0) {
      return
    }

    this.submitVote(-1)
  }

  submitVote(value) {
    const formData = new FormData()
    formData.append('votable_type', 'Comment')
    formData.append('votable_id', this.commentIdValue)
    formData.append('value', value)

    fetch('/vote', {
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
      console.error('通信エラー:', error)
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

    // 投票済みの場合はカーソルを無効化
    if (this.userVoteValue !== 0) {
      this.upButtonTarget.classList.add('cursor-not-allowed')
      this.downButtonTarget.classList.add('cursor-not-allowed')
      this.upButtonTarget.classList.remove('hover:text-green-500')
      this.downButtonTarget.classList.remove('hover:text-red-500')
    }
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