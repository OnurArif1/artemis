import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

const router = createRouter({
    history: createWebHistory(),
    routes: [
        {
            path: '/',
            name: 'main',
            component: () => import('@/views/Main.vue'),
            meta: { requiresAuth: true }
        },
        {
            path: '/login',
            name: 'login',
            component: () => import('@/views/Login.vue'),
            meta: { requiresAuth: false }
        },
        {
            path: '/register',
            name: 'register',
            component: () => import('@/views/Register.vue'),
            meta: { requiresAuth: false }
        },
        {
            path: '/chat',
            name: 'chat',
            component: () => import('@/views/Chat.vue'),
            meta: { requiresAuth: true }
        },
        {
            path: '/chat/:roomId',
            name: 'chat-room',
            component: () => import('@/views/Chat.vue'),
            meta: { requiresAuth: true }
        }
    ]
});

router.beforeEach((to, from, next) => {
    const auth = useAuthStore();
    const requiresAuth = to.meta.requiresAuth;

    if (requiresAuth && !auth.isAuthenticated()) {
        next({ name: 'login', query: { redirect: to.fullPath } });
    } else if (!requiresAuth && auth.isAuthenticated() && (to.name === 'login' || to.name === 'register')) {
        next({ name: 'main' });
    } else {
        next();
    }
});

export default router;

