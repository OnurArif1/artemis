<template>
  <div class="profile">
    <div class="container">
      <div class="profile-header">
        <h1>Profile</h1>
        <p>Manage your account settings and preferences</p>
      </div>

      <div class="profile-content">
        <div class="profile-card">
          <div class="card-header">
            <h3>Personal Information</h3>
          </div>
          
          <form @submit.prevent="updateProfile" class="profile-form">
            <div class="form-row">
              <div class="form-group">
                <label for="username">Username</label>
                <input
                  type="text"
                  id="username"
                  v-model="profileData.username"
                  class="form-input"
                  disabled
                />
              </div>
              
              <div class="form-group">
                <label for="email">Email</label>
                <input
                  type="email"
                  id="email"
                  v-model="profileData.email"
                  class="form-input"
                />
              </div>
            </div>

            <div class="form-row">
              <div class="form-group">
                <label for="firstName">First Name</label>
                <input
                  type="text"
                  id="firstName"
                  v-model="profileData.firstName"
                  class="form-input"
                />
              </div>
              
              <div class="form-group">
                <label for="lastName">Last Name</label>
                <input
                  type="text"
                  id="lastName"
                  v-model="profileData.lastName"
                  class="form-input"
                />
              </div>
            </div>

            <div class="form-group">
              <label for="bio">Bio</label>
              <textarea
                id="bio"
                v-model="profileData.bio"
                class="form-textarea"
                rows="4"
                placeholder="Tell us about yourself..."
              ></textarea>
            </div>

            <button type="submit" class="btn btn-primary" :disabled="loading">
              <span v-if="loading">Updating...</span>
              <span v-else>Update Profile</span>
            </button>

            <div v-if="message" class="message" :class="messageType">
              {{ message }}
            </div>
          </form>
        </div>

        <div class="profile-card">
          <div class="card-header">
            <h3>Change Password</h3>
          </div>
          
          <form @submit.prevent="changePassword" class="password-form">
            <div class="form-group">
              <label for="currentPassword">Current Password</label>
              <input
                type="password"
                id="currentPassword"
                v-model="passwordData.currentPassword"
                class="form-input"
                required
              />
            </div>

            <div class="form-group">
              <label for="newPassword">New Password</label>
              <input
                type="password"
                id="newPassword"
                v-model="passwordData.newPassword"
                class="form-input"
                required
              />
            </div>

            <div class="form-group">
              <label for="confirmPassword">Confirm New Password</label>
              <input
                type="password"
                id="confirmPassword"
                v-model="passwordData.confirmPassword"
                class="form-input"
                required
              />
            </div>

            <button type="submit" class="btn btn-secondary" :disabled="passwordLoading">
              <span v-if="passwordLoading">Changing...</span>
              <span v-else>Change Password</span>
            </button>

            <div v-if="passwordMessage" class="message" :class="passwordMessageType">
              {{ passwordMessage }}
            </div>
          </form>
        </div>

        <div class="profile-card">
          <div class="card-header">
            <h3>Account Information</h3>
          </div>
          
          <div class="account-info">
            <div class="info-item">
              <span class="info-label">Member Since:</span>
              <span class="info-value">{{ accountInfo.memberSince }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">Last Login:</span>
              <span class="info-value">{{ accountInfo.lastLogin }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">Account Status:</span>
              <span class="info-value status-active">Active</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'

const authStore = useAuthStore()

const loading = ref(false)
const passwordLoading = ref(false)
const message = ref('')
const messageType = ref('')
const passwordMessage = ref('')
const passwordMessageType = ref('')

const profileData = reactive({
  username: '',
  email: '',
  firstName: '',
  lastName: '',
  bio: ''
})

const passwordData = reactive({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const accountInfo = reactive({
  memberSince: 'January 2024',
  lastLogin: 'Today'
})

const loadProfile = async () => {
  try {
    // Simulate loading user data
    profileData.username = authStore.user?.username || 'user123'
    profileData.email = authStore.user?.email || 'user@example.com'
    profileData.firstName = authStore.user?.firstName || 'John'
    profileData.lastName = authStore.user?.lastName || 'Doe'
    profileData.bio = authStore.user?.bio || 'Software developer passionate about creating amazing web applications.'
  } catch (error) {
    console.error('Error loading profile:', error)
  }
}

const updateProfile = async () => {
  loading.value = true
  message.value = ''
  
  try {
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    message.value = 'Profile updated successfully!'
    messageType.value = 'success'
    
    // Clear message after 3 seconds
    setTimeout(() => {
      message.value = ''
    }, 3000)
  } catch (error) {
    message.value = 'Failed to update profile. Please try again.'
    messageType.value = 'error'
  } finally {
    loading.value = false
  }
}

const changePassword = async () => {
  if (passwordData.newPassword !== passwordData.confirmPassword) {
    passwordMessage.value = 'New passwords do not match'
    passwordMessageType.value = 'error'
    return
  }
  
  passwordLoading.value = true
  passwordMessage.value = ''
  
  try {
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    passwordMessage.value = 'Password changed successfully!'
    passwordMessageType.value = 'success'
    
    // Clear form
    passwordData.currentPassword = ''
    passwordData.newPassword = ''
    passwordData.confirmPassword = ''
    
    // Clear message after 3 seconds
    setTimeout(() => {
      passwordMessage.value = ''
    }, 3000)
  } catch (error) {
    passwordMessage.value = 'Failed to change password. Please try again.'
    passwordMessageType.value = 'error'
  } finally {
    passwordLoading.value = false
  }
}

onMounted(() => {
  loadProfile()
})
</script>

<style scoped>
.profile {
  min-height: 100vh;
  background: #f8f9fa;
}

.container {
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
}

.profile-header {
  margin-bottom: 2rem;
}

.profile-header h1 {
  color: #333;
  margin-bottom: 0.5rem;
}

.profile-header p {
  color: #666;
}

.profile-content {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.profile-card {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 4px 20px rgba(0,0,0,0.1);
}

.card-header {
  margin-bottom: 1.5rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #e9ecef;
}

.card-header h3 {
  color: #333;
  margin: 0;
  font-size: 1.25rem;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-bottom: 1rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  color: #333;
  font-weight: 500;
}

.form-input,
.form-textarea {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #e1e5e9;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.3s ease;
}

.form-input:focus,
.form-textarea:focus {
  outline: none;
  border-color: #667eea;
}

.form-input:disabled {
  background: #f8f9fa;
  color: #666;
}

.form-textarea {
  resize: vertical;
  min-height: 100px;
}

.btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-secondary {
  background: #6c757d;
  color: white;
}

.btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(0,0,0,0.2);
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.message {
  padding: 0.75rem;
  border-radius: 8px;
  margin-top: 1rem;
  text-align: center;
}

.message.success {
  background: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

.message.error {
  background: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
}

.account-info {
  space-y: 1rem;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 0;
  border-bottom: 1px solid #f0f0f0;
}

.info-item:last-child {
  border-bottom: none;
}

.info-label {
  color: #666;
  font-weight: 500;
}

.info-value {
  color: #333;
  font-weight: 600;
}

.status-active {
  color: #28a745;
}

@media (max-width: 768px) {
  .form-row {
    grid-template-columns: 1fr;
  }
  
  .container {
    padding: 1rem;
  }
  
  .profile-card {
    padding: 1.5rem;
  }
}
</style>
