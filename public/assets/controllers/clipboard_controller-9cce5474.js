import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]
  static values = { 
    content: String,
    message: { type: String, default: "복사되었습니다!" }
  }
  
  copy(event) {
    event.preventDefault()
    
    // content value가 있으면 그것을 복사, 없으면 source target의 내용을 복사
    const textToCopy = this.hasContentValue ? this.contentValue : this.sourceTarget.textContent
    
    // 클립보드에 복사
    navigator.clipboard.writeText(textToCopy).then(() => {
      // 복사 성공 피드백
      this.showFeedback(event.currentTarget)
    }).catch(err => {
      console.error('복사 실패:', err)
      // 폴백: 구식 방법 사용
      this.fallbackCopy(textToCopy)
    })
  }
  
  showFeedback(button) {
    const originalText = button.innerHTML
    const originalClasses = button.className
    
    // 성공 피드백 표시
    button.innerHTML = `
      <svg class="w-4 h-4 inline mr-1" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
      </svg>
      ${this.messageValue}
    `
    button.classList.add('bg-green-600', 'text-white')
    
    // 2초 후 원래 상태로 복구
    setTimeout(() => {
      button.innerHTML = originalText
      button.className = originalClasses
    }, 2000)
  }
  
  fallbackCopy(text) {
    // 구식 브라우저를 위한 폴백
    const textArea = document.createElement("textarea")
    textArea.value = text
    textArea.style.position = "fixed"
    textArea.style.opacity = "0"
    document.body.appendChild(textArea)
    textArea.select()
    
    try {
      document.execCommand('copy')
      this.showFeedback(event.currentTarget)
    } catch (err) {
      console.error('Fallback 복사 실패:', err)
      alert('복사에 실패했습니다. 수동으로 복사해주세요.')
    }
    
    document.body.removeChild(textArea)
  }
}