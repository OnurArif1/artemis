<template>
  <div class="login">
    <div class="login-container">
      <div class="login-card">
        <div class="login-header">
          <h2>Welcome Back</h2>
          <p>Sign in to your Artemis account</p>
        </div>

        <form @submit.prevent="handleLogin" class="login-form">
          <div class="form-group">
            <label for="username">Username</label>
            <input
              type="text"
              id="username"
              v-model="credentials.username"
              required
              class="form-input"
              placeholder="Enter your username"
            />
          </div>

          <div class="form-group">
            <label for="password">Password</label>
            <input
              type="password"
              id="password"
              v-model="credentials.password"
              required
              class="form-input"
              placeholder="Enter your password"
            />
          </div>

          <button type="submit" class="btn btn-primary" :disabled="loading">
            <span v-if="loading">Signing in...</span>
            <span v-else>Sign In</span>
          </button>

          <div v-if="error" class="error-message">
            {{ error }}
          </div>
        </form>

        <div class="login-footer">
          <p>Don't have an account? <a href="#" @click="showRegister = true">Sign up</a></p>
        </div>
      </div>

      <!-- Register Modal -->
      <div v-if="showRegister" class="modal-overlay" @click="showRegister = false">
        <div class="modal-content" @click.stop>
          <div class="modal-header">
            <h3>Create Account</h3>
            <button @click="showRegister = false" class="close-btn">&times;</button>
          </div>
          
          <form @submit.prevent="handleRegister" class="register-form">
            <div class="form-group">
              <label for="reg-username">Username</label>
              <input
                type="text"
                id="reg-username"
                v-model="registerData.username"
                required
                class="form-input"
              />
            </div>

            <div class="form-group">
              <label for="reg-email">Email</label>
              <input
                type="email"
                id="reg-email"
                v-model="registerData.email"
                required
                class="form-input"
              />
            </div>

            <div class="form-group">
              <label for="reg-password">Password</label>
              <input
                type="password"
                id="reg-password"
                v-model="registerData.password"
                required
                class="form-input"
              />
            </div>

            <div class="form-group">
              <label for="reg-confirm-password">Confirm Password</label>
              <input
                type="password"
                id="reg-confirm-password"
                v-model="registerData.confirmPassword"
                required
                class="form-input"
              />
            </div>

            <button type="submit" class="btn btn-primary" :disabled="registerLoading">
              <span v-if="registerLoading">Creating Account...</span>
              <span v-else>Create Account</span>
            </button>

            <div v-if="registerError" class="error-message">
              {{ registerError }}
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const loading = ref(false)
const error = ref('')
const showRegister = ref(false)
const registerLoading = ref(false)
const registerError = ref('')

const credentials = reactive({
  username: '',
  password: ''
})

const registerData = reactive({
  username: '',
  email: '',
  password: '',
  confirmPassword: ''
})

const handleLogin = async () => {
  loading.value = true
  error.value = ''
  
  try {
    await authStore.login(credentials)
    router.push('/dashboard')
  } catch (err) {
    error.value = err.message
  } finally {
    loading.value = false
  }
}

const handleRegister = async () => {
  if (registerData.password !== registerData.confirmPassword) {
    registerError.value = 'Passwords do not match'
    return
  }
  
  registerLoading.value = true
  registerError.value = ''
  
  try {
    await authStore.register(registerData)
    showRegister.value = false
    // Auto login after registration
    await authStore.login({
      username: registerData.username,
      password: registerData.password
    })
    router.push('/dashboard')
  } catch (err) {
    registerError.value = err.message
  } finally {
    registerLoading.value = false
  }
}
</script>

<style scoped>
.login {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 2rem;
}

.login-container {
  width: 100%;
  max-width: 400px;
}

.login-card {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 10px 40px rgba(0,0,0,0.1);
}

.login-header {
  text-align: center;
  margin-bottom: 2rem;
}

.login-header h2 {
  color: #333;
  margin-bottom: 0.5rem;
}

.login-header p {
  color: #666;
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

.form-input {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #e1e5e9;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.3s ease;
}

.form-input:focus {
  outline: none;
  border-color: #667eea;
}

.btn {
  width: 100%;
  padding: 0.75rem;
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

.btn-primary:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error-message {
  background: #fee;
  color: #c33;
  padding: 0.75rem;
  border-radius: 8px;
  margin-top: 1rem;
  text-align: center;
}

.login-footer {
  text-align: center;
  margin-top: 1.5rem;
}

.login-footer a {
  color: #667eea;
  text-decoration: none;
  font-weight: 500;
}

.login-footer a:hover {
  text-decoration: underline;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  width: 90%;
  max-width: 500px;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.modal-header h3 {
  margin: 0;
  color: #333;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #666;
}

.register-form .form-group {
  margin-bottom: 1rem;
}
</style>
