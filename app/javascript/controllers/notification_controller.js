import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["badge", "dropdown", "list", "emptyState"]
  static values = {
    userId: Number,
    pollInterval: { type: Number, default: 30000 } // 30 seconds
  }

  connect() {
    this.loadNotifications()
    this.startPolling()
    
    // Add event listener to close dropdown when clicking outside
    this.closeHandler = this.handleOutsideClick.bind(this)
    document.addEventListener('click', this.closeHandler)
    
    // Listen for broadcast events
    this.setupBroadcastListener()
  }

  disconnect() {
    this.stopPolling()
    document.removeEventListener('click', this.closeHandler)
  }

  startPolling() {
    this.pollTimer = setInterval(() => {
      this.loadNotifications()
    }, this.pollIntervalValue)
  }

  stopPolling() {
    if (this.pollTimer) {
      clearInterval(this.pollTimer)
      this.pollTimer = null
    }
  }

  async loadNotifications() {
    try {
      const response = await fetch(`/notifications.json?user_id=${this.userIdValue}`)
      if (response.ok) {
        const data = await response.json()
        this.updateUI(data)
      }
    } catch (error) {
      console.error('Failed to load notifications:', error)
    }
  }

  updateUI(data) {
    const { notifications, unread_count } = data
    
    // Update badge
    if (this.hasBadgeTarget) {
      this.badgeTarget.textContent = unread_count
      this.badgeTarget.classList.toggle('hidden', unread_count === 0)
      
      // Add animation for new notifications
      if (unread_count > 0) {
        this.animateBadge()
      }
    }
    
    // Update dropdown list
    if (this.hasListTarget) {
      if (notifications.length === 0) {
        this.showEmptyState()
      } else {
        this.renderNotifications(notifications)
      }
    }
  }

  renderNotifications(notifications) {
    this.listTarget.innerHTML = notifications.map(notification => `
      <div class="p-4 border-b border-gray-700 hover:bg-gray-800 transition-colors ${notification.read ? '' : 'bg-blue-900/20'}"
           data-notification-id="${notification.id}">
        <div class="flex items-start justify-between">
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-1">
              <h4 class="text-sm font-medium text-white truncate">${this.escapeHtml(notification.title)}</h4>
              <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${this.getTypeClass(notification.notification_type)}">
                ${this.capitalize(notification.notification_type || 'info')}
              </span>
              <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${this.getPriorityClass(notification.priority)}">
                ${this.capitalize(notification.priority)}
              </span>
            </div>
            <p class="text-sm text-gray-300 mb-2">${this.escapeHtml(notification.message)}</p>
            <p class="text-xs text-gray-500">${this.formatTime(notification.created_at)}</p>
          </div>
          ${!notification.read ? `
            <button class="ml-2 text-gray-400 hover:text-white" 
                    data-action="notification#markAsRead" 
                    data-notification-id="${notification.id}">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
              </svg>
            </button>
          ` : ''}
        </div>
      </div>
    `).join('')
    
    this.hideEmptyState()
  }

  showEmptyState() {
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.remove('hidden')
      this.listTarget.classList.add('hidden')
    }
  }

  hideEmptyState() {
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.add('hidden')
      this.listTarget.classList.remove('hidden')
    }
  }

  async markAsRead(event) {
    const notificationId = event.currentTarget.dataset.notificationId
    
    try {
      const response = await fetch(`/notifications/${notificationId}/mark_as_read`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })
      
      if (response.ok) {
        // Remove the notification from the list or update its appearance
        const notificationElement = event.currentTarget.closest('[data-notification-id]')
        if (notificationElement) {
          notificationElement.classList.remove('bg-blue-900/20')
          event.currentTarget.remove()
        }
        
        // Reload notifications to update count
        this.loadNotifications()
        
        // Show temporary confirmation
        this.showConfirmation('Notification marked as read')
      }
    } catch (error) {
      console.error('Failed to mark notification as read:', error)
    }
  }

  toggleDropdown(event) {
    event.preventDefault();
    event.stopPropagation();
    this.dropdownTarget.classList.toggle('hidden')
    
    // If opening the dropdown, load fresh notifications
    if (!this.dropdownTarget.classList.contains('hidden')) {
      this.loadNotifications()
    }
  }

  closeDropdown() {
    this.dropdownTarget.classList.add('hidden')
  }
  
  // Close dropdown when clicking outside
  connect() {
    this.loadNotifications()
    this.startPolling()
    
    // Add event listener to close dropdown when clicking outside
    this.closeHandler = this.handleOutsideClick.bind(this)
    document.addEventListener('click', this.closeHandler)
    
    // Listen for broadcast events
    this.setupBroadcastListener()
  }
  
  disconnect() {
    this.stopPolling()
    document.removeEventListener('click', this.closeHandler)
  }
  
  handleOutsideClick(event) {
    if (!this.element.contains(event.target) && !this.dropdownTarget.classList.contains('hidden')) {
      this.closeDropdown()
    }
  }

  animateBadge() {
    if (this.hasBadgeTarget) {
      this.badgeTarget.classList.add('animate-bounce')
      setTimeout(() => {
        this.badgeTarget.classList.remove('animate-bounce')
      }, 1000)
    }
  }

  showConfirmation(message) {
    // Create a temporary toast notification
    const toast = document.createElement('div')
    toast.className = 'fixed top-4 right-4 bg-green-600 text-white px-4 py-2 rounded-lg shadow-lg z-50'
    toast.textContent = message
    document.body.appendChild(toast)
    
    setTimeout(() => {
      toast.remove()
    }, 3000)
  }

  setupBroadcastListener() {
    // Listen for real-time notifications (could be enhanced with ActionCable)
    document.addEventListener('notification:received', (event) => {
      this.loadNotifications()
      this.showDesktopNotification(event.detail)
    })
  }

  showDesktopNotification(notification) {
    if ('Notification' in window && Notification.permission === 'granted') {
      new Notification(notification.title, {
        body: notification.message,
        icon: '/icon.png'
      })
    }
  }

  // Helper methods
  getPriorityClass(priority) {
    const classes = {
      'urgent': 'bg-red-500/20 text-red-400',
      'high': 'bg-orange-500/20 text-orange-400',
      'medium': 'bg-yellow-500/20 text-yellow-400',
      'low': 'bg-blue-500/20 text-blue-400'
    }
    return classes[priority] || classes['medium']
  }

  getTypeClass(type) {
    const classes = {
      'system': 'bg-gray-500/20 text-gray-400',
      'announcement': 'bg-purple-500/20 text-purple-400',
      'update': 'bg-blue-500/20 text-blue-400',
      'warning': 'bg-red-500/20 text-red-400',
      'info': 'bg-green-500/20 text-green-400'
    }
    return classes[type] || classes['info']
  }

  capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1)
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  formatTime(dateString) {
    const date = new Date(dateString)
    const now = new Date()
    const diffInSeconds = Math.floor((now - date) / 1000)
    
    if (diffInSeconds < 60) return 'Just now'
    if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`
    if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`
    return date.toLocaleDateString()
  }
}