import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image"]

  connect() {
    console.log("Image Test Controller connected!")
  }

  imageClicked() {
    console.log("Image clicked via test controller!")
    alert("Image click detected!")
  }
}