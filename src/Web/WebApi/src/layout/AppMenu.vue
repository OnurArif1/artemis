<script setup>
import { ref } from 'vue';
import { useI18n } from '@/composables/useI18n';
import AppMenuItem from './AppMenuItem.vue';

const { t } = useI18n();

const model = ref([
    {
        label: t('common.home'),
        items: [
            // { label: t('common.dashboard'), icon: 'pi pi-fw pi-home', to: '/' },
            { label: t('common.rooms'), icon: 'pi pi-fw pi-map-marker', to: '/rooms' },
            { label: t('room.create'), icon: 'pi pi-fw pi-plus-circle', to: '/rooms/create' },
            { label: t('common.topics'), icon: 'pi pi-fw pi-book', to: '/topics' },
            { label: t('topic.create'), icon: 'pi pi-fw pi-plus-circle', to: '/topics/create' },
            { label: t('category.list'), icon: 'pi pi-fw pi-tags', to: '/categories' }
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
