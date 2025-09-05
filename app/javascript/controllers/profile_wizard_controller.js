import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "progressBar", "stepIndicator", "prevButton", "nextButton", "submitButton"]
  static values = { totalSteps: Number }
  
  connect() {
    console.log("Profile Wizard Controller connected!")
    this.currentStep = 1
    this.updateUI()
  }

  nextStep() {
    if (this.currentStep < this.totalStepsValue) {
      this.currentStep += 1
      this.updateUI()
      this.scrollToTop()
    }
  }

  previousStep() {
    if (this.currentStep > 1) {
      this.currentStep -= 1
      this.updateUI()
      this.scrollToTop()
    }
  }

  selectOption(event) {
    const card = event.currentTarget
    const checkbox = card.querySelector('input[type="checkbox"]')
    
    // チェックボックスの状態を切り替え
    checkbox.checked = !checkbox.checked
    
    // 視覚的フィードバック
    this.updateCardAppearance(card, checkbox.checked)
  }

  selectSingle(event) {
    const card = event.currentTarget
    const radio = card.querySelector('input[type="radio"]')
    const fieldName = radio.name
    
    // 同じ名前の他のラジオボタンをリセット
    document.querySelectorAll(`input[name="${fieldName}"]`).forEach(input => {
      const inputCard = input.closest('.option-card')
      this.updateCardAppearance(inputCard, false)
      input.checked = false
    })
    
    // 選択されたラジオボタンをチェック
    radio.checked = true
    this.updateCardAppearance(card, true)
  }

  updateCardAppearance(card, isSelected) {
    const cardDiv = card.querySelector('div')
    
    if (isSelected) {
      cardDiv.classList.remove('border-gray-200', 'bg-white', 'text-gray-700')
      cardDiv.classList.add('border-blue-600', 'bg-blue-200', 'text-blue-900')
      cardDiv.style.borderWidth = '4px'
      cardDiv.style.boxShadow = '0 0 0 4px rgba(37, 99, 235, 0.4), 0 4px 12px rgba(37, 99, 235, 0.3)'
      cardDiv.style.transform = 'scale(1.02)'
    } else {
      cardDiv.classList.remove('border-blue-600', 'bg-blue-200', 'text-blue-900')
      cardDiv.classList.add('border-gray-200', 'bg-white', 'text-gray-700')
      cardDiv.style.borderWidth = '2px'
      cardDiv.style.boxShadow = 'none'
      cardDiv.style.transform = 'scale(1.0)'
    }
  }

  updateUI() {
    // ステップの表示/非表示
    this.stepTargets.forEach((step, index) => {
      const stepNumber = parseInt(step.dataset.step)
      if (stepNumber === this.currentStep) {
        step.classList.remove('hidden')
        step.classList.add('animate-fade-in')
      } else {
        step.classList.add('hidden')
        step.classList.remove('animate-fade-in')
      }
    })

    // 進捗バーの更新
    const progress = (this.currentStep / this.totalStepsValue) * 100
    this.progressBarTarget.style.width = `${progress}%`

    // ステップインジケーターの更新
    this.stepIndicatorTarget.textContent = `${this.currentStep} / ${this.totalStepsValue}`

    // ボタンの表示制御
    if (this.currentStep === 1) {
      this.prevButtonTarget.classList.add('hidden')
    } else {
      this.prevButtonTarget.classList.remove('hidden')
    }

    if (this.currentStep === this.totalStepsValue) {
      this.nextButtonTarget.classList.add('hidden')
      this.submitButtonTarget.classList.remove('hidden')
    } else {
      this.nextButtonTarget.classList.remove('hidden')
      this.submitButtonTarget.classList.add('hidden')
    }
  }

  scrollToTop() {
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  // 初期化時に既存の選択状態を反映
  initializeSelections() {
    // チェックボックスの初期状態を反映
    document.querySelectorAll('.option-card input[type="checkbox"]:checked').forEach(checkbox => {
      const card = checkbox.closest('.option-card')
      this.updateCardAppearance(card, true)
    })

    // ラジオボタンの初期状態を反映
    document.querySelectorAll('.option-card input[type="radio"]:checked').forEach(radio => {
      const card = radio.closest('.option-card')
      this.updateCardAppearance(card, true)
    })
  }

  // DOMが読み込まれた後に初期化
  stepTargetConnected() {
    // 最初のステップが表示された時に初期化
    if (this.currentStep === 1) {
      setTimeout(() => this.initializeSelections(), 100)
    }
  }
}

// カスタムCSSアニメーション
const style = document.createElement('style')
style.textContent = `
  .animate-fade-in {
    animation: fadeIn 0.3s ease-in-out;
  }
  
  @keyframes fadeIn {
    from {
      opacity: 0;
      transform: translateY(10px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
`
document.head.appendChild(style)