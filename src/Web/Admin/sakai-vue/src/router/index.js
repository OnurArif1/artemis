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
                    component: () => import('@/views/party/PartyList.vue')
                },
                {
                    path: '/category/list',
                    name: 'category-list',
                    component: () => import('@/views/category/CategoryList.vue')
                },
                {
                    path: '/hashtag/list',
                    name: 'hashtag-list',
                    component: () => import('@/views/hashtag/HashtagList.vue')
                },
                {
                    path: '/roomhashtagmap/list',
                    name: 'roomhashtagmap-list',
                    component: () => import('@/views/roomHashtagMap/RoomHashtagMapList.vue')
                },
                {
                    path: '/categoryhashtagmap/list',
                    name: 'categoryhashtagmap-list',
                    component: () => import('@/views/categoryHashtagMap/CategoryHashtagMapList.vue')
                },
                {
                    path: '/topic/list',
                    name: 'topic-list',
                    component: () => import('@/views/topic/TopicList.vue')
                },
                {
                    path: '/topichashtagmap/list',
                    name: 'topichashtagmap-list',
                    component: () => import('@/views/topicHashtagMap/TopicHashtagMapList.vue')
                },
                {
                    path: '/mention/list',
                    name: 'mention-list',
                    component: () => import('@/views/mention/MentionList.vue')
                },
                {
                    path: '/message/list',
                    name: 'message-list',
                    component: () => import('@/views/message/MessageList.vue')
                },
                {
                    path: '/chat',
                    name: 'chat',
                    component: () => import('@/views/chat/Chat.vue')
                },
                {
                    path: '/appSubscriptionTypePrices/list',
                    name: 'appSubscriptionTypePrices-list',
                    component: () => import('@/views/appSubscriptionTypePrices/AppSubscriptionTypePricesList.vue')
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
