import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "content"]
  static values = { postId: Number }

  connect() {
    console.log("Comment modal controller connected!")
  }

  open() {
    console.log("Opening modal for post ID:", this.postIdValue)
    this.modalTarget.classList.remove("hidden")
    this.fetchComments()
  }

  close() {
    this.modalTarget.classList.add("hidden")
    this.contentTarget.innerHTML = ""
  }

  fetchComments() {
    fetch(`/posts/${this.postIdValue}/comments_modal`)
      .then(response => response.text())
      .then(html => {
        this.contentTarget.innerHTML = html
      })
      .catch(error => {
        console.error("Error fetching comments:", error)
        this.contentTarget.innerHTML = "<p>コメントの読み込み中にエラーが発生しました。</p>"
      })
  }
}