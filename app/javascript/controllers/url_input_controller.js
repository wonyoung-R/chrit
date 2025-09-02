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
    event.preventDefault()
    
    const url = this.inputTarget.value
    if (this.isValidUrl(url)) {
      // AI 처리 애니메이션 표시
      this.showAIProcessingAnimation(url)
      
      // 3초 후에 실제 폼 제출
      setTimeout(() => {
        this.formTarget.submit()
      }, 3000)
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
    const contentType = isYouTube ? 'YouTube video' : 'web document'
    
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
              🤖 AI is working hard on the task
            </h3>
            <p class="text-gray-400 text-sm">
              Analyzing ${contentType} and generating summary...
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
        
        <style>
          @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
          }
          
          .animate-fade-in {
            animation: fadeIn 0.5s ease-out;
          }
          
          .ai-robot-animation {
            width: 120px;
            height: 150px;
            position: relative;
            animation: robotFloat 2s ease-in-out infinite;
          }
          
          @keyframes robotFloat {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-10px); }
          }
          
          .robot-head {
            width: 80px;
            height: 60px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 40px 40px 20px 20px;
            position: relative;
            margin: 0 auto;
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
          }
          
          .robot-face {
            position: absolute;
            width: 100%;
            height: 100%;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
          }
          
          .robot-eyes {
            display: flex;
            gap: 20px;
            margin-bottom: 10px;
          }
          
          .robot-eye {
            width: 12px;
            height: 12px;
            background: white;
            border-radius: 50%;
            position: relative;
            animation: blink 3s infinite;
          }
          
          @keyframes blink {
            0%, 90%, 100% { transform: scaleY(1); }
            95% { transform: scaleY(0.1); }
          }
          
          .robot-eye::after {
            content: '';
            position: absolute;
            width: 6px;
            height: 6px;
            background: #333;
            border-radius: 50%;
            top: 3px;
            left: 3px;
            animation: lookAround 4s infinite;
          }
          
          @keyframes lookAround {
            0%, 100% { transform: translate(0, 0); }
            25% { transform: translate(2px, 0); }
            50% { transform: translate(0, 2px); }
            75% { transform: translate(-2px, 0); }
          }
          
          .robot-mouth {
            width: 20px;
            height: 4px;
            background: white;
            border-radius: 2px;
            animation: talk 1s infinite;
          }
          
          @keyframes talk {
            0%, 100% { transform: scaleX(1); }
            50% { transform: scaleX(1.3); }
          }
          
          .robot-antenna {
            position: absolute;
            top: -15px;
            left: 50%;
            transform: translateX(-50%);
            width: 2px;
            height: 20px;
            background: #667eea;
          }
          
          .antenna-ball {
            position: absolute;
            top: -8px;
            left: -6px;
            width: 14px;
            height: 14px;
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            border-radius: 50%;
            animation: pulse 1s infinite;
          }
          
          @keyframes pulse {
            0%, 100% { 
              transform: scale(1); 
              box-shadow: 0 0 0 0 rgba(245, 87, 108, 0.7);
            }
            50% { 
              transform: scale(1.2); 
              box-shadow: 0 0 0 10px rgba(245, 87, 108, 0);
            }
          }
          
          .robot-body {
            width: 100px;
            height: 70px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 20px;
            margin: 10px auto 0;
            position: relative;
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
          }
          
          .robot-arm {
            position: absolute;
            width: 15px;
            height: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 10px;
            top: 10px;
          }
          
          .robot-arm.left {
            left: -20px;
            animation: leftArmMove 2s infinite;
            transform-origin: top center;
          }
          
          .robot-arm.right {
            right: -20px;
            animation: rightArmMove 2s infinite;
            transform-origin: top center;
          }
          
          @keyframes leftArmMove {
            0%, 100% { transform: rotate(-10deg); }
            50% { transform: rotate(10deg); }
          }
          
          @keyframes rightArmMove {
            0%, 100% { transform: rotate(10deg); }
            50% { transform: rotate(-10deg); }
          }
          
          .robot-screen {
            position: absolute;
            width: 70px;
            height: 40px;
            background: #1a1a2e;
            border-radius: 5px;
            top: 15px;
            left: 15px;
            border: 2px solid #16213e;
            overflow: hidden;
          }
          
          .screen-content {
            width: 100%;
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(90deg, transparent, rgba(102, 126, 234, 0.3), transparent);
            background-size: 200% 100%;
            animation: scanline 2s linear infinite;
          }
          
          @keyframes scanline {
            0% { background-position: -100% 0; }
            100% { background-position: 100% 0; }
          }
          
          .processing-text {
            color: #00ff00;
            font-size: 10px;
            font-family: monospace;
            text-shadow: 0 0 5px #00ff00;
            animation: flicker 0.5s infinite;
          }
          
          @keyframes flicker {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.8; }
          }
          
          .ai-progress-bar {
            animation: progressFill 3s ease-out forwards;
          }
          
          @keyframes progressFill {
            0% { width: 0%; }
            30% { width: 35%; }
            60% { width: 70%; }
            100% { width: 100%; }
          }
        </style>
      `
      
      // 재미있는 메시지 순환
      this.startThinkingMessages()
    }
  }
  
  startThinkingMessages() {
    const messages = [
      "🧠 Activating neurons...",
      "📚 Searching knowledge database...",
      "⚡ Optimizing synaptic connections...",
      "🔍 Recognizing and analyzing patterns...",
      "💭 Powering up deep learning network...",
      "🎯 Extracting key content...",
      "✨ Generating insights..."
    ]
    
    let index = 0
    const messageElement = this.statusMessageTarget.querySelector('.ai-thinking-message')
    
    if (messageElement) {
      const interval = setInterval(() => {
        messageElement.textContent = messages[index]
        messageElement.style.animation = 'none'
        setTimeout(() => {
          messageElement.style.animation = 'fadeIn 0.5s ease-out'
        }, 10)
        
        index = (index + 1) % messages.length
      }, 500)
      
      // 3초 후 정리
      setTimeout(() => {
        clearInterval(interval)
      }, 3000)
    }
  }
  
  hideMessage() {
    if (this.hasStatusMessageTarget) {
      this.statusMessageTarget.innerHTML = ""
    }
  }
}