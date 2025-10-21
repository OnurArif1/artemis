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
                }
            ]
        }
        // {
        //     path: '/landing',
        //     name: 'landing',
        //     component: () => import('@/views/pages/Landing.vue')
        // }
    ]
});

export default router;

// auth guard using route meta
router.beforeEach((to, from, next) => {
    const auth = useAuthStore();
    const requiresAuth = to.matched.some((r) => r.meta && r.meta.requiresAuth);
    if (requiresAuth && !auth.isAuthenticated) {
        next({ name: 'login' });
        return;
    }
    if (!requiresAuth && auth.isAuthenticated && to.name === 'login') {
        next({ name: 'dashboard' });
        return;
    }
    next();
});
