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
        items: [{ label: 'Dashboard', icon: 'pi pi-fw pi-home', to: '/' },{ label: 'Rooms', icon: 'pi pi-fw pi-table', to: '/room/list' }]
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
