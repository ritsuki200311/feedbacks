import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { postId: Number }

  connect() {
    console.log('Post card controller connected for post:', this.postIdValue)
    // カード全体をクリック可能にする
    this.element.style.cursor = 'pointer'
    this.element.addEventListener('click', this.handleCardClick.bind(this))
  }

  disconnect() {
    this.element.removeEventListener('click', this.handleCardClick.bind(this))
  }

  handleCardClick(event) {
    console.log('Card clicked, target:', event.target)

    // リンクやボタンがクリックされた場合は無視
    if (this.shouldIgnoreClick(event.target)) {
      console.log('Click ignored for:', event.target)
      return
    }

    console.log('Navigating to post:', this.postIdValue)
    // 投稿詳細ページに遷移
    window.location.href = `/posts/${this.postIdValue}`
  }

  shouldIgnoreClick(target) {
    // クリックを無視すべき要素をチェック
    const ignoredElements = ['A', 'BUTTON', 'INPUT', 'TEXTAREA', 'SELECT']
    const ignoredClasses = ['vote-button', 'delete-button']

    // 要素タイプをチェック
    if (ignoredElements.includes(target.tagName)) {
      return true
    }

    // クラス名をチェック
    if (target.classList && ignoredClasses.some(cls => target.classList.contains(cls))) {
      return true
    }

    // 親要素をチェック（SVGアイコンなど）
    let parent = target.parentElement
    while (parent && parent !== this.element) {
      if (ignoredElements.includes(parent.tagName)) {
        return true
      }
      if (parent.classList && ignoredClasses.some(cls => parent.classList.contains(cls))) {
        return true
      }
      parent = parent.parentElement
    }

    return false
  }
}