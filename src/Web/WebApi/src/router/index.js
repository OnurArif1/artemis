import AppLayout from '@/layout/AppLayout.vue';
import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

const router = createRouter({
    history: createWebHistory(),
    routes: [
        {
            path: '/',
            component: AppLayout,
            meta: { requiresAuth: true },
            children: [
                {
                    path: '/',
                    name: 'dashboard',
                    component: () => import('@/views/Dashboard.vue')
                },
                {
                    path: '/rooms',
                    name: 'room',
                    component: () => import('@/views/rooms/RoomMap.vue')
                },
                {
                    path: '/topics',
                    name: 'topic',
                    component: () => import('@/views/topics/TopicList.vue')
                }
            ]
        },
        {
            path: '/login',
            name: 'login',
            meta: { requiresAuth: false },
            component: () => import('@/views/pages/auth/Login.vue')
        }
    ]
});

router.beforeEach((to, _from, next) => {
    const auth = useAuthStore();
    const requiresAuth = to.matched.some((r) => r.meta && r.meta.requiresAuth);
    if (requiresAuth && !auth.isAuthenticated()) {
        next({ name: 'login' });
        return;
    }
    if (to.name === 'login' && auth.isAuthenticated()) {
        next({ name: 'room' });
        return;
    }
    next();
});

export default router;
