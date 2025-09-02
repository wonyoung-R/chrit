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
    
    // Process completion notification
    if (data.type === 'knowledge_completed') {
      this.handleCompletion(data)
    }
  },
  
  handleCompletion(data) {
    // Update status message
    const statusMessage = document.querySelector('[data-url-input-target="statusMessage"]')
    if (statusMessage) {
      statusMessage.innerHTML = `
        <div class="bg-green-900/50 backdrop-blur-sm border border-green-500/30 rounded-xl p-4 mt-4">
          <div class="flex items-center gap-3 mb-3">
            <svg class="w-6 h-6 text-green-400" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
            </svg>
            <span class="text-white font-medium">Analysis Complete!</span>
          </div>
          <div class="text-sm text-gray-300 space-y-1">
            <div class="font-semibold">${data.title}</div>
            <div class="text-gray-400">${data.summary}</div>
            <div class="mt-2 text-green-400">
              ⏱️ Processing time: ${data.processing_time} seconds
            </div>
          </div>
          <div class="mt-4">
            <a href="/knowledges/${data.knowledge_id}" 
               class="inline-block px-4 py-2 bg-gradient-to-r from-purple-600 to-blue-600 text-white rounded-lg hover:from-purple-700 hover:to-blue-700 transition duration-200">
              View Results →
            </a>
          </div>
        </div>
      `
      
      // Reset input field
      const inputField = document.querySelector('[data-url-input-target="input"]')
      if (inputField) {
        inputField.value = ''
      }
      
      // Re-enable button
      const submitButton = document.querySelector('[data-url-input-target="submitButton"]')
      if (submitButton) {
        submitButton.disabled = false
        submitButton.value = 'Save'
        submitButton.classList.remove('opacity-50', 'cursor-not-allowed')
      }
    }
    
    // Play notification sound (optional)
    this.playNotificationSound()
  },
  
  playNotificationSound() {
    // Use browser notification API
    if (Notification.permission === "granted") {
      new Notification("Chrit - Analysis Complete", {
        body: "Content analysis has been completed.",
        icon: "/icon.png"
      })
    }
    
    // Simple sound effect (if browser supports)
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSyBzvLYiTcIGWi77OeeThEMUKfj8LVjHAY4kNXzzHksBSR3x/DdkUAKFF6z6euoVRQKRp/g8r5gIAUsgc7y2Ik3CBlou+znnk4RDFC')
    audio.volume = 0.3
    audio.play().catch(e => console.log("Could not play sound:", e))
  }
})