import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["up", "down", "barPos", "barNeg", "barLabel", "barWrapper", "commentModal", "commentText", "commentForm"]
  static values = {
    votableType: String,
    votableId: Number,
    upCount: Number,
    downCount: Number,
    userVote: Number
  }

  connect() {
    console.log("Vote controller connected!")
    console.log("Vote controller data:", {
      votableType: this.votableTypeValue,
      votableId: this.votableIdValue,
      upCount: this.upCountValue,
      downCount: this.downCountValue,
      userVote: this.userVoteValue
    })
    this.updateDisplay()
  }

  upvote(event) {
    event.preventDefault()
    console.log("Upvote clicked")
    this.showCommentModal(1)
  }

  downvote(event) {
    event.preventDefault()
    console.log("Downvote clicked")
    this.showCommentModal(-1)
  }

  showCommentModal(value) {
    // 既に投票済みの場合は何もしない
    if (this.userVoteValue !== 0) {
      return
    }

    this.pendingVoteValue = value
    
    // モーダルを表示
    if (this.hasCommentModalTarget) {
      this.commentModalTarget.classList.remove('hidden')
      this.commentTextTarget.focus()
      
      // モーダル内のメッセージを更新
      const messageElement = this.commentModalTarget.querySelector('[data-vote-target="modalMessage"]')
      if (messageElement) {
        messageElement.textContent = value === 1 ? 
          'なぜプラス評価だと思いますか？コメントを書いてみてください。' : 
          'なぜマイナス評価だと思いますか？コメントを書いてみてください。'
      }
    }
  }

  submitWithComment(event) {
    event.preventDefault()
    const comment = this.commentTextTarget.value.trim()
    this.hideCommentModal()
    this.submitVote(this.pendingVoteValue, comment)
  }

  submitWithoutComment(event) {
    event.preventDefault()
    this.hideCommentModal()
    this.submitVote(this.pendingVoteValue, '')
  }

  hideCommentModal(event) {
    if (event) event.preventDefault()
    if (this.hasCommentModalTarget) {
      this.commentModalTarget.classList.add('hidden')
      this.commentTextTarget.value = ''
    }
  }

  submitVote(value, comment = '') {
    // 既に投票済みの場合は何もしない
    if (this.userVoteValue !== 0) {
      return
    }

    const formData = new FormData()
    formData.append('votable_type', this.votableTypeValue)
    formData.append('votable_id', this.votableIdValue)
    formData.append('value', value)
    formData.append('comment', comment)

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
      }
    })
    .catch(error => {
      console.error('通信エラー:', error)
    })
  }

  updateDisplay() {
    const total = this.upCountValue + this.downCountValue
    const net = this.upCountValue - this.downCountValue
    
    // プログレスバーの更新
    if (total > 0) {
      const upPercentage = (this.upCountValue / total) * 100
      const downPercentage = (this.downCountValue / total) * 100
      
      this.barPosTarget.style.width = `${upPercentage}%`
      this.barNegTarget.style.width = `${downPercentage}%`
      this.barLabelTarget.textContent = `${net > 0 ? '+' : ''}${net}`
    } else {
      this.barPosTarget.style.width = '0%'
      this.barNegTarget.style.width = '0%'
      this.barLabelTarget.textContent = '0'
    }

    // ボタンの見た目を更新（投票済みを強調）
    this.updateButtonStyles()
  }

  updateButtonStyles() {
    // リセット
    this.upTarget.classList.remove('text-green-600', 'bg-green-100', 'scale-110', 'shadow-md')
    this.downTarget.classList.remove('text-red-600', 'bg-red-100', 'scale-110', 'shadow-md')
    
    this.upTarget.classList.add('text-gray-500')
    this.downTarget.classList.add('text-gray-500')

    // 投票済みの場合は強調表示
    if (this.userVoteValue === 1) {
      this.upTarget.classList.remove('text-gray-500', 'hover:text-green-600')
      this.upTarget.classList.add('text-green-600', 'bg-green-100', 'scale-110', 'shadow-md', 'rounded-full', 'p-2', 'transform', 'transition-all')
      
      // SVGのfillも変更
      const svg = this.upTarget.querySelector('svg')
      if (svg) {
        svg.setAttribute('fill', 'currentColor')
        svg.setAttribute('stroke', 'none')
      }
    } else if (this.userVoteValue === -1) {
      this.downTarget.classList.remove('text-gray-500', 'hover:text-red-600')
      this.downTarget.classList.add('text-red-600', 'bg-red-100', 'scale-110', 'shadow-md', 'rounded-full', 'p-2', 'transform', 'transition-all')
      
      // SVGのfillも変更
      const svg = this.downTarget.querySelector('svg')
      if (svg) {
        svg.setAttribute('fill', 'currentColor')
        svg.setAttribute('stroke', 'none')
      }
    }

    // 投票済みの場合はカーソルを無効化
    if (this.userVoteValue !== 0) {
      this.upTarget.classList.add('cursor-not-allowed')
      this.downTarget.classList.add('cursor-not-allowed')
      this.upTarget.classList.remove('hover:text-green-600')
      this.downTarget.classList.remove('hover:text-red-600')
    }
  }
}