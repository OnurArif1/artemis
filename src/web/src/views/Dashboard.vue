<template>
  <div class="dashboard">
    <div class="container">
      <div class="dashboard-header">
        <h1>Dashboard</h1>
        <p>Welcome back, {{ authStore.user?.username || 'User' }}!</p>
      </div>

      <div class="dashboard-grid">
        <div class="dashboard-card">
          <div class="card-header">
            <h3>Quick Stats</h3>
          </div>
          <div class="stats-grid">
            <div class="stat-item">
              <div class="stat-value">{{ stats.totalUsers }}</div>
              <div class="stat-label">Total Users</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">{{ stats.activeSessions }}</div>
              <div class="stat-label">Active Sessions</div>
            </div>
            <div class="stat-item">
              <div class="stat-value">{{ stats.apiCalls }}</div>
              <div class="stat-label">API Calls Today</div>
            </div>
          </div>
        </div>

        <div class="dashboard-card">
          <div class="card-header">
            <h3>Recent Activity</h3>
          </div>
          <div class="activity-list">
            <div v-for="activity in recentActivity" :key="activity.id" class="activity-item">
              <div class="activity-icon">{{ activity.icon }}</div>
              <div class="activity-content">
                <div class="activity-title">{{ activity.title }}</div>
                <div class="activity-time">{{ activity.time }}</div>
              </div>
            </div>
          </div>
        </div>

        <div class="dashboard-card">
          <div class="card-header">
            <h3>System Status</h3>
          </div>
          <div class="status-list">
            <div class="status-item">
              <div class="status-indicator status-online"></div>
              <span>API Gateway</span>
              <span class="status-text">Online</span>
            </div>
            <div class="status-item">
              <div class="status-indicator status-online"></div>
              <span>Identity Server</span>
              <span class="status-text">Online</span>
            </div>
            <div class="status-item">
              <div class="status-indicator status-online"></div>
              <span>Database</span>
              <span class="status-text">Online</span>
            </div>
          </div>
        </div>

        <div class="dashboard-card">
          <div class="card-header">
            <h3>Quick Actions</h3>
          </div>
          <div class="action-buttons">
            <button class="action-btn" @click="refreshData">
              <span class="btn-icon">🔄</span>
              Refresh Data
            </button>
            <button class="action-btn" @click="exportData">
              <span class="btn-icon">📊</span>
              Export Data
            </button>
            <button class="action-btn" @click="viewLogs">
              <span class="btn-icon">📋</span>
              View Logs
            </button>
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

const stats = reactive({
  totalUsers: 0,
  activeSessions: 0,
  apiCalls: 0
})

const recentActivity = ref([
  {
    id: 1,
    icon: '👤',
    title: 'New user registered',
    time: '2 minutes ago'
  },
  {
    id: 2,
    icon: '🔐',
    title: 'User logged in',
    time: '5 minutes ago'
  },
  {
    id: 3,
    icon: '📊',
    title: 'Data export completed',
    time: '10 minutes ago'
  },
  {
    id: 4,
    icon: '⚙️',
    title: 'System configuration updated',
    time: '15 minutes ago'
  }
])

const loadDashboardData = async () => {
  // Simulate API call
  await new Promise(resolve => setTimeout(resolve, 1000))
  
  stats.totalUsers = Math.floor(Math.random() * 1000) + 500
  stats.activeSessions = Math.floor(Math.random() * 100) + 20
  stats.apiCalls = Math.floor(Math.random() * 10000) + 5000
}

const refreshData = () => {
  loadDashboardData()
}

const exportData = () => {
  alert('Export functionality would be implemented here')
}

const viewLogs = () => {
  alert('Log viewer would be implemented here')
}

onMounted(() => {
  loadDashboardData()
})
</script>

<style scoped>
.dashboard {
  min-height: 100vh;
  background: #f8f9fa;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.dashboard-header {
  margin-bottom: 2rem;
}

.dashboard-header h1 {
  color: #333;
  margin-bottom: 0.5rem;
}

.dashboard-header p {
  color: #666;
  font-size: 1.1rem;
}

.dashboard-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
}

.dashboard-card {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 20px rgba(0,0,0,0.1);
  transition: transform 0.3s ease;
}

.dashboard-card:hover {
  transform: translateY(-2px);
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

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
}

.stat-item {
  text-align: center;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 8px;
}

.stat-value {
  font-size: 2rem;
  font-weight: 700;
  color: #667eea;
  margin-bottom: 0.5rem;
}

.stat-label {
  color: #666;
  font-size: 0.9rem;
}

.activity-list {
  space-y: 1rem;
}

.activity-item {
  display: flex;
  align-items: center;
  padding: 1rem 0;
  border-bottom: 1px solid #f0f0f0;
}

.activity-item:last-child {
  border-bottom: none;
}

.activity-icon {
  font-size: 1.5rem;
  margin-right: 1rem;
  width: 40px;
  text-align: center;
}

.activity-content {
  flex: 1;
}

.activity-title {
  color: #333;
  font-weight: 500;
  margin-bottom: 0.25rem;
}

.activity-time {
  color: #666;
  font-size: 0.9rem;
}

.status-list {
  space-y: 1rem;
}

.status-item {
  display: flex;
  align-items: center;
  padding: 0.75rem 0;
  border-bottom: 1px solid #f0f0f0;
}

.status-item:last-child {
  border-bottom: none;
}

.status-indicator {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  margin-right: 1rem;
}

.status-online {
  background: #28a745;
}

.status-offline {
  background: #dc3545;
}

.status-text {
  margin-left: auto;
  color: #28a745;
  font-weight: 500;
}

.action-buttons {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.action-btn {
  display: flex;
  align-items: center;
  padding: 1rem;
  background: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 1rem;
}

.action-btn:hover {
  background: #e9ecef;
  transform: translateY(-1px);
}

.btn-icon {
  margin-right: 0.75rem;
  font-size: 1.2rem;
}

@media (max-width: 768px) {
  .dashboard-grid {
    grid-template-columns: 1fr;
  }
  
  .stats-grid {
    grid-template-columns: 1fr;
  }
  
  .container {
    padding: 1rem;
  }
}
</style>
