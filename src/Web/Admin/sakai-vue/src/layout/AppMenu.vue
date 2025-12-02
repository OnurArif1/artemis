<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';
import { useI18n } from '@/composables/useI18n';

import AppMenuItem from './AppMenuItem.vue';

const router = useRouter();
const auth = useAuthStore();
const { t } = useI18n();

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
            window.location.href = '/';
        }
    })();
}

const model = ref([
    {
        label: t('common.home'),
        items: [
            { label: t('common.dashboard'), icon: 'pi pi-fw pi-home', to: '/' },
            { label: t('common.rooms'), icon: 'pi pi-fw pi-table', to: '/room/list' },
            { label: t('common.parties'), icon: 'pi pi-fw pi-users', to: '/party/list' },
            { label: t('common.categories'), icon: 'pi pi-fw pi-align-center', to: '/category/list' },
            { label: t('common.topics'), icon: 'pi pi-fw pi-book', to: '/topic/list' },
            { label: t('common.hashtags'), icon: 'pi pi-fw pi-tag', to: '/hashtag/list' },
            { label: t('common.roomHashtagMaps'), icon: 'pi pi-fw pi-link', to: '/roomhashtagmap/list' },
            { label: t('common.categoryHashtagMaps'), icon: 'pi pi-fw pi-sitemap', to: '/categoryhashtagmap/list' },
            { label: t('common.topicHashtagMaps'), icon: 'pi pi-fw pi-bookmark', to: '/topichashtagmap/list' },
            { label: t('common.mentions'), icon: 'pi pi-fw pi-at', to: '/mention/list' },
            { label: t('common.messages'), icon: 'pi pi-fw pi-comments', to: '/message/list' },
            { label: t('common.chat'), icon: 'pi pi-fw pi-comment', to: '/chat' }
        ]
    },
    {
        label: t('common.account'),
        items: [
            {
                label: t('common.logout'),
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
