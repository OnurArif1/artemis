<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

import AppMenuItem from './AppMenuItem.vue';

const router = useRouter();
const auth = useAuthStore();

function onLogout() {
    auth.clearToken();
    router.push({ name: 'login' });
}

const model = ref([
    {
        label: 'Home',
        items: [{ label: 'Dashboard', icon: 'pi pi-fw pi-home', to: '/' }]
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
