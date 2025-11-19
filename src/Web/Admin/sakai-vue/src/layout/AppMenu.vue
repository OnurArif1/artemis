<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

import AppMenuItem from './AppMenuItem.vue';

const router = useRouter();
const auth = useAuthStore();

function onLogout() {
    auth.clearToken();

    // try named route first, fallback to common login paths
    (async () => {
        try {
            const routes = router.getRoutes();
            console.log(
                'router routes:',
                routes.map((r) => ({ name: r.name, path: r.path, meta: r.meta }))
            );

            await router.push({ name: 'login' });
        } catch (e) {
            const fallbackPaths = ['/login', '/auth/login', '/signin', '/'];
            for (const p of fallbackPaths) {
                try {
                    await router.push(p);
                    return;
                } catch {
                    // ignore
                }
            }
            // last resort: hard redirect to root
            window.location.href = '/';
        }
    })();
}

const model = ref([
    {
        label: 'Home',
        items: [
            { label: 'Dashboard', icon: 'pi pi-fw pi-home', to: '/' },
            { label: 'Rooms', icon: 'pi pi-fw pi-table', to: '/room/list' },
            { label: 'Parties', icon: 'pi pi-fw pi-users', to: '/party/list' },
            { label: 'Categories', icon: 'pi pi-fw pi-align-center', to: '/category/list' },
            { label: 'Topics', icon: 'pi pi-fw pi-book', to: '/topic/list' },
            { label: 'Hashtags', icon: 'pi pi-fw pi-tag', to: '/hashtag/list' },
            { label: 'Room Hashtag Maps', icon: 'pi pi-fw pi-link', to: '/roomhashtagmap/list' },
            { label: 'Category Hashtag Maps', icon: 'pi pi-fw pi-sitemap', to: '/categoryhashtagmap/list' },
            { label: 'Topic Hashtag Maps', icon: 'pi pi-fw pi-bookmark', to: '/topichashtagmap/list' },
            { label: 'Mentions', icon: 'pi pi-fw pi-at', to: '/mention/list' },
            { label: 'Messages', icon: 'pi pi-fw pi-comments', to: '/message/list' },
            { label: 'Chat (SignalR)', icon: 'pi pi-fw pi-comment', to: '/chat' }
        ]
    },
    {
        label: 'Account',
        items: [
            {
                label: 'Logout',
                icon: 'pi pi-fw pi-sign-out',
                command: onLogout
            }
        ]
    }
]);
</script>

<template>
    <ul class="layout-menu">
        <template v-for="(item, i) in model" :key="item">
            <app-menu-item v-if="!item.separator" :item="item" :index="i"></app-menu-item>
            <li v-if="item.separator" class="menu-separator"></li>
        </template>
    </ul>
</template>

<style lang="scss" scoped></style>
