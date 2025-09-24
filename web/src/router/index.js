import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import Home from '../views/Home.vue'
import Login from '../views/Login.vue'
import Dashboard from '../views/Dashboard.vue'
import Profile from '../views/Profile.vue'
// Admin layout and entity views (lazy loaded)
const AdminLayout = () => import('../views/admin/AdminLayout.vue')
const AdminDashboard = () => import('../views/admin/AdminDashboard.vue')
const EntityComment = () => import('../views/admin/entities/Comment.vue')
const EntityReaction = () => import('../views/admin/entities/Reaction.vue')
const EntityPost = () => import('../views/admin/entities/Post.vue')
const EntityTopic = () => import('../views/admin/entities/Topic.vue')
const EntityUser = () => import('../views/admin/entities/User.vue')
const EntityNotification = () => import('../views/admin/entities/Notification.vue')
const EntityPlace = () => import('../views/admin/entities/Place.vue')
const EntityPlaceCategory = () => import('../views/admin/entities/PlaceCategory.vue')
const EntityReport = () => import('../views/admin/entities/Report.vue')

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/login',
    name: 'Login',
    component: Login
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: Dashboard,
    meta: { requiresAuth: true }
  },
  {
    path: '/profile',
    name: 'Profile',
    component: Profile,
    meta: { requiresAuth: true }
  }
  ,
  {
    path: '/admin',
    component: AdminLayout,
    meta: { requiresAuth: true },
    children: [
      { path: '', name: 'AdminDashboard', component: AdminDashboard },
      { path: 'entities/comment', name: 'EntityComment', component: EntityComment },
      { path: 'entities/reaction', name: 'EntityReaction', component: EntityReaction },
      { path: 'entities/post', name: 'EntityPost', component: EntityPost },
      { path: 'entities/topic', name: 'EntityTopic', component: EntityTopic },
      { path: 'entities/user', name: 'EntityUser', component: EntityUser },
      { path: 'entities/notification', name: 'EntityNotification', component: EntityNotification },
      { path: 'entities/place', name: 'EntityPlace', component: EntityPlace },
      { path: 'entities/place-category', name: 'EntityPlaceCategory', component: EntityPlaceCategory },
      { path: 'entities/report', name: 'EntityReport', component: EntityReport },
    ],
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next('/login')
  } else {
    next()
  }
})

export default router
