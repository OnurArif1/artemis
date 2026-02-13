import AppLayout from '@/layout/AppLayout.vue';
import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

const router = createRouter({
    history: createWebHistory(),
    routes: [
        {
            path: '/',
            name: 'landing',
            meta: { requiresAuth: false },
            component: () => import('@/views/pages/Landing.vue')
        },
        {
            path: '/app',
            component: AppLayout,
            meta: { requiresAuth: true },
            children: [
                {
                    path: '',
                    name: 'dashboard',
                    component: () => import('@/views/Dashboard.vue')
                },
                {
                    path: 'rooms',
                    name: 'room',
                    component: () => import('@/views/rooms/RoomMap.vue')
                },
                {
                    path: 'rooms/create',
                    name: 'createRoom',
                    component: () => import('@/views/rooms/CreateRoom.vue')
                },
                {
                    path: 'topics',
                    name: 'topic',
                    component: () => import('@/views/topics/TopicList.vue')
                },
                {
                    path: 'topics/create',
                    name: 'createTopic',
                    component: () => import('@/views/topics/CreateTopic.vue')
                },
                {
                    path: 'categories',
                    name: 'category',
                    component: () => import('@/views/categories/CategoryList.vue')
                },
                {
                    path: 'profile',
                    name: 'profile',
                    component: () => import('@/views/pages/Profile.vue')
                }
            ]
        },
        {
            path: '/login',
            name: 'login',
            meta: { requiresAuth: false },
            component: () => import('@/views/pages/auth/Login.vue')
        },
        {
            path: '/select-interests',
            name: 'selectInterests',
            meta: { requiresAuth: true },
            component: () => import('@/views/pages/auth/SelectInterests.vue')
        },
        {
            path: '/tell-us-about-yourself',
            name: 'tellUsAboutYourself',
            meta: { requiresAuth: true },
            component: () => import('@/views/pages/auth/TellUsAboutYourself.vue')
        },
        {
            path: '/select-purposes',
            name: 'selectPurposes',
            meta: { requiresAuth: true },
            component: () => import('@/views/pages/auth/SelectPurposes.vue')
        }
    ]
});

router.beforeEach((to, _from, next) => {
    // Landing page and login don't require auth - allow them
    if (to.name === 'landing' || to.name === 'login') {
        const auth = useAuthStore();
        // If user is authenticated and tries to access login or landing, redirect to app
        if (auth.isAuthenticated()) {
            next({ name: 'room' });
            return;
        }
        // Allow unauthenticated users to access landing/login
        next();
        return;
    }
    
    // For other routes, check authentication
    const auth = useAuthStore();
    const requiresAuth = to.matched.some((r) => r.meta && r.meta.requiresAuth);
    
    // If route requires auth but user is not authenticated, redirect to login
    if (requiresAuth && !auth.isAuthenticated()) {
        next({ name: 'login' });
        return;
    }
    
    // Select interests, tell us about yourself, and select purposes pages require auth - allow them
    if (to.name === 'selectInterests' || to.name === 'tellUsAboutYourself' || to.name === 'selectPurposes') {
        next();
        return;
    }
    
    // Default: allow navigation
    next();
});

export default router;
