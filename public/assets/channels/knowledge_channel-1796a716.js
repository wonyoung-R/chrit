import consumer from "./consumer"

consumer.subscriptions.create("KnowledgeChannel", {
  connected() {
    console.log("Connected to knowledge channel")
  },

  disconnected() {
    console.log("Disconnected from knowledge channel")
  },

  received(data) {
    console.log("Received data:", data)
    
    // 처리 완료 알림
    if (data.type === 'knowledge_completed') {
      this.handleCompletion(data)
    }
  },
  
  handleCompletion(data) {
    // 상태 메시지 업데이트
    const statusMessage = document.querySelector('[data-url-input-target="statusMessage"]')
    if (statusMessage) {
      statusMessage.innerHTML = `
        <div class="bg-green-900/50 backdrop-blur-sm border border-green-500/30 rounded-xl p-4 mt-4">
          <div class="flex items-center gap-3 mb-3">
            <svg class="w-6 h-6 text-green-400" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
            </svg>
            <span class="text-white font-medium">분석 완료!</span>
          </div>
          <div class="text-sm text-gray-300 space-y-1">
            <div class="font-semibold">${data.title}</div>
            <div class="text-gray-400">${data.summary}</div>
            <div class="mt-2 text-green-400">
              ⏱️ 처리 시간: ${data.processing_time}초
            </div>
          </div>
          <div class="mt-4">
            <a href="/knowledges/${data.knowledge_id}" 
               class="inline-block px-4 py-2 bg-gradient-to-r from-purple-600 to-blue-600 text-white rounded-lg hover:from-purple-700 hover:to-blue-700 transition duration-200">
              결과 보기 →
            </a>
          </div>
        </div>
      `
      
      // 입력 필드 초기화
      const inputField = document.querySelector('[data-url-input-target="input"]')
      if (inputField) {
        inputField.value = ''
      }
      
      // 버튼 재활성화
      const submitButton = document.querySelector('[data-url-input-target="submitButton"]')
      if (submitButton) {
        submitButton.disabled = false
        submitButton.value = '저장'
        submitButton.classList.remove('opacity-50', 'cursor-not-allowed')
      }
    }
    
    // 알림 소리 재생 (옵션)
    this.playNotificationSound()
  },
  
  playNotificationSound() {
    // 브라우저 알림 API를 사용하여 알림
    if (Notification.permission === "granted") {
      new Notification("Chrit - 분석 완료", {
        body: "콘텐츠 분석이 완료되었습니다.",
        icon: "/icon.png"
      })
    }
    
    // 간단한 사운드 효과 (브라우저 지원 시)
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSyBzvLYiTcIGWi77OeeThEMUKfj8LVjHAY4kNXzzHksBSR3x/DdkUAKFF6z6euoVRQKRp/g8r5gIAUsgc7y2Ik3CBlou+znnk4RDFC')
    audio.volume = 0.3
    audio.play().catch(e => console.log("Could not play sound:", e))
  }
})