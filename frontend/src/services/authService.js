import axios from 'axios'

const API_BASE_URL = 'http://localhost:5000'
const IDENTITY_BASE_URL = 'http://localhost:5001'

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
})

const identityClient = axios.create({
  baseURL: IDENTITY_BASE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
})

// Request interceptor to add auth token
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor to handle token refresh
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Token expired, try to refresh
      try {
        const refreshResponse = await identityClient.post('/connect/token', {
          grant_type: 'refresh_token',
          refresh_token: localStorage.getItem('refresh_token')
        })
        
        const { access_token, refresh_token } = refreshResponse.data
        localStorage.setItem('token', access_token)
        localStorage.setItem('refresh_token', refresh_token)
        
        // Retry original request
        error.config.headers.Authorization = `Bearer ${access_token}`
        return apiClient.request(error.config)
      } catch (refreshError) {
        // Refresh failed, redirect to login
        localStorage.removeItem('token')
        localStorage.removeItem('refresh_token')
        window.location.href = '/login'
        return Promise.reject(refreshError)
      }
    }
    return Promise.reject(error)
  }
)

export default {
  async login(credentials) {
    try {
      const response = await identityClient.post('/connect/token', {
        grant_type: 'password',
        username: credentials.username,
        password: credentials.password,
        client_id: 'artemis-client',
        client_secret: 'artemis-secret'
      })
      
      const { access_token, refresh_token } = response.data
      
      // Get user info
      const userResponse = await apiClient.get('/api/user/profile', {
        headers: { Authorization: `Bearer ${access_token}` }
      })
      
      localStorage.setItem('token', access_token)
      localStorage.setItem('refresh_token', refresh_token)
      
      return {
        access_token,
        refresh_token,
        user: userResponse.data
      }
    } catch (error) {
      throw new Error(error.response?.data?.error_description || 'Login failed')
    }
  },

  async register(userData) {
    try {
      const response = await identityClient.post('/api/account/register', userData)
      return response.data
    } catch (error) {
      throw new Error(error.response?.data?.message || 'Registration failed')
    }
  },

  async refreshToken() {
    const refresh_token = localStorage.getItem('refresh_token')
    if (!refresh_token) {
      throw new Error('No refresh token available')
    }
    
    const response = await identityClient.post('/connect/token', {
      grant_type: 'refresh_token',
      refresh_token
    })
    
    return response.data
  },

  async getUserProfile() {
    const response = await apiClient.get('/api/user/profile')
    return response.data
  },

  async updateProfile(userData) {
    const response = await apiClient.put('/api/user/profile', userData)
    return response.data
  }
}
