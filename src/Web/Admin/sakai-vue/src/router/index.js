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
                    path: '/room/list',
                    name: 'room-list',
                    component: () => import('@/views/room/RoomList.vue')
                },
                {
                    path: '/party/list',
                    name: 'party-list',
                    component: () => import('@/views/pages/PartyList.vue')
                },
                {
                    path: '/category/list',
                    name: 'category-list',
                    component: () => import('@/views/pages/CategoryList.vue')
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

export default router;

router.beforeEach((to, from, next) => {
    const auth = useAuthStore();
    const requiresAuth = to.matched.some((r) => r.meta && r.meta.requiresAuth);
    if (requiresAuth && !auth.isAuthenticated()) {
        next({ name: 'login' });
        return;
    }

    if (to.name === 'login' && auth.isAuthenticated()) {
        next({ name: 'dashboard' });
        return;
    }

    next();
});
