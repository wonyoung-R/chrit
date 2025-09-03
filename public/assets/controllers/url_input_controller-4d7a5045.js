import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submitButton", "statusMessage", "form"]
  
  connect() {
    // 페이지 로드 시 초기 상태 확인
    this.validateInput()
  }
  
  handlePaste(event) {
    // 붙여넣기 후 잠시 대기하고 검증
    setTimeout(() => {
      this.validateInput()
    }, 100)
  }
  
  handleInput(event) {
    // 타이핑 시 즉시 검증
    this.validateInput()
  }
  
  handleSubmit(event) {
    const url = this.inputTarget.value.trim()
    if (this.isValidUrl(url)) {
      event.preventDefault() // Prevent default submission
      
      // AI 처리 애니메이션 표시
      this.showAIProcessingAnimation(url)
      
      // 10초 후에 실제 폼 제출 (YouTube 처리 시간 고려)
      setTimeout(() => {
        // Create FormData and ensure URL parameter is included
        const formData = new FormData(this.formTarget)
        formData.set('url', url) // Ensure URL is included
        
        // Submit using Rails UJS for proper AJAX handling
        fetch(this.formTarget.action, {
          method: 'POST',
          body: formData,
          headers: {
            'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
            'Accept': 'text/html'
          },
          credentials: 'same-origin'
        }).then(response => {
          if (response.redirected) {
            window.location.href = response.url
          }
        })
      }, 4000) // 4초로 변경 (애니메이션과 동일)
    }
  }
  
  validateInput() {
    const url = this.inputTarget.value.trim()
    
    if (url && this.isValidUrl(url)) {
      // 유효한 URL이면 버튼 활성화
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
      this.submitButtonTarget.classList.add('hover:scale-105', 'transition-transform')
      this.showReadyMessage()
    } else {
      // 유효하지 않으면 버튼 비활성화
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
      this.submitButtonTarget.classList.remove('hover:scale-105')
      this.hideMessage()
    }
  }
  
  isValidUrl(string) {
    try {
      const url = new URL(string.trim())
      // http 또는 https 프로토콜만 허용
      return url.protocol === "http:" || url.protocol === "https:"
    } catch (_) {
      return false
    }
  }
  
  isYouTubeUrl(url) {
    return url.includes('youtube.com') || url.includes('youtu.be')
  }
  
  showReadyMessage() {
    if (this.hasStatusMessageTarget) {
      this.statusMessageTarget.innerHTML = `
        <div class="flex items-center gap-2 text-green-400 text-sm mt-2 animate-fade-in">
          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
          </svg>
          <span>URL is ready. Click the button to start analysis.</span>
        </div>
      `
    }
  }
  
  showAIProcessingAnimation(url) {
    // 입력과 버튼 숨기기
    this.inputTarget.disabled = true
    this.submitButtonTarget.style.display = 'none'
    
    const isYouTube = this.isYouTubeUrl(url)
    const contentType = isYouTube ? 'YouTube 동영상' : '웹 문서'
    
    if (this.hasStatusMessageTarget) {
      this.statusMessageTarget.innerHTML = `
        <div class="ai-processing-container animate-fade-in">
          <!-- AI 로봇 애니메이션 -->
          <div class="flex justify-center mb-6">
            <div class="ai-robot-animation">
              <div class="robot-head">
                <div class="robot-face">
                  <div class="robot-eyes">
                    <div class="robot-eye left"></div>
                    <div class="robot-eye right"></div>
                  </div>
                  <div class="robot-mouth"></div>
                </div>
                <div class="robot-antenna">
                  <div class="antenna-ball"></div>
                </div>
              </div>
              <div class="robot-body">
                <div class="robot-arm left"></div>
                <div class="robot-arm right"></div>
                <div class="robot-screen">
                  <div class="screen-content">
                    <span class="processing-text">Processing...</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- 메시지 -->
          <div class="text-center mb-4">
            <h3 class="text-2xl font-bold text-white mb-2 animate-pulse">
              🤖 AI가 열심히 일하고 있습니다
            </h3>
            <p class="text-gray-400 text-sm">
              ${contentType}를 분석하고 요약을 생성하고 있어요...
            </p>
          </div>
          
          <!-- 프로그레스 바 -->
          <div class="max-w-md mx-auto">
            <div class="bg-gray-800 rounded-full h-3 overflow-hidden">
              <div class="ai-progress-bar bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 h-full rounded-full"></div>
            </div>
            <div class="flex justify-between text-xs text-gray-500 mt-2">
              <span>Extracting content...</span>
              <span>AI analyzing...</span>
              <span>Generating summary...</span>
            </div>
          </div>
          
          <!-- 재미있는 메시지들 -->
          <div class="mt-6 text-center">
            <p class="ai-thinking-message text-sm text-gray-400 italic"></p>
          </div>
        </div>
      `
      
      // 재미있는 메시지 순환
      this.startThinkingMessages()
    }
  }
  
  startThinkingMessages() {
    const messages = [
      "🧠 뉴런을 활성화하는 중...",
      "📚 지식 데이터베이스를 검색하는 중...",
      "⚡ 시냅스 연결을 최적화하는 중...",
      "🔍 패턴을 인식하고 분석하는 중...",
      "💭 딥러닝 네트워크를 가동하는 중...",
      "🎯 핵심 내용을 추출하는 중...",
      "✨ 인사이트를 생성하는 중..."
    ]
    
    let index = 0
    const messageElement = this.statusMessageTarget.querySelector('.ai-thinking-message')
    
    if (messageElement) {
      // 즉시 첫 메시지 표시
      messageElement.textContent = messages[0]
      
      const interval = setInterval(() => {
        index = (index + 1) % messages.length
        messageElement.textContent = messages[index]
        messageElement.style.animation = 'none'
        setTimeout(() => {
          messageElement.style.animation = 'fadeIn 0.5s ease-out'
        }, 10)
      }, 571) // 4초 동안 7개 메시지 = 571ms 간격
      
      // 4초 후 정리 (애니메이션 시간과 동일하게)
      setTimeout(() => {
        clearInterval(interval)
      }, 4000)
    }
  }
  
  hideMessage() {
    if (this.hasStatusMessageTarget) {
      this.statusMessageTarget.innerHTML = ""
    }
  }
}