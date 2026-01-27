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
    (async () => {
        try {
            await router.push({ name: 'login' });
        } catch (e) {
            const fallbackPaths = ['/login', '/auth/login', '/'];
            for (const p of fallbackPaths) {
                try {
                    await router.push(p);
                    return;
                } catch {
                    /* ignore */
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
            { label: t('common.rooms'), icon: 'pi pi-fw pi-map-marker', to: '/odalar' }
        ]
    },
    {
        label: t('common.account'),
        items: [
            { label: t('common.logout'), icon: 'pi pi-fw pi-sign-out', command: onLogout }
        ]
    }
]);
</script>

<template>
    <ul class="layout-menu">
        <template v-for="(item, i) in model" :key="i">
            <app-menu-item v-if="!item.separator" :item="item" :index="i"></app-menu-item>
            <li v-if="item.separator" class="menu-separator"></li>
        </template>
    </ul>
</template>

<style lang="scss" scoped></style>
