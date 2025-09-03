import { Controller } from "@hotwired/stimulus"

// Session management controller for handling Turbo cache and navigation
export default class extends Controller {
  connect() {
    // Ensure CSRF token is always fresh
    this.setupCSRFToken()
    
    // Handle Turbo cache events
    this.handleTurboCache()
    
    // Setup remember me functionality
    this.setupRememberMe()
  }

  setupCSRFToken() {
    document.addEventListener("turbo:before-fetch-request", (event) => {
      const token = document.querySelector('meta[name="csrf-token"]')?.content
      if (token) {
        event.detail.fetchOptions.headers["X-CSRF-Token"] = token
      }
    })
  }

  handleTurboCache() {
    // Before caching, mark session-sensitive elements
    document.addEventListener("turbo:before-cache", () => {
      // Mark forms to be refreshed
      document.querySelectorAll("form").forEach(form => {
        form.dataset.turboCacheControl = "reload"
      })
    })

    // After restoration from cache
    document.addEventListener("turbo:load", () => {
      // Refresh CSRF tokens in forms
      const token = document.querySelector('meta[name="csrf-token"]')?.content
      if (token) {
        document.querySelectorAll('input[name="authenticity_token"]').forEach(input => {
          input.value = token
        })
      }
    })
  }

  setupRememberMe() {
    // Check if remember me checkbox exists
    const rememberCheckbox = document.querySelector('#user_remember_me')
    if (rememberCheckbox && !rememberCheckbox.checked) {
      // Set default to checked for better UX
      rememberCheckbox.checked = true
    }
  }

  // Method to check session validity
  async checkSession() {
    try {
      const response = await fetch('/api/session/check', {
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content,
          'Accept': 'application/json'
        }
      })
      
      if (!response.ok && window.location.pathname !== '/users/sign_in') {
        // Session expired, redirect to login
        window.location.href = '/users/sign_in'
      }
    } catch (error) {
      console.error('Session check failed:', error)
    }
  }
}