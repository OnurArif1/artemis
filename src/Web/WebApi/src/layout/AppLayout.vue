<script setup>
import { useLayout } from '@/layout/composables/layout';
import { computed, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from '@/composables/useI18n';
import AppFooter from './AppFooter.vue';
import AppSidebar from './AppSidebar.vue';
import AppTopbar from './AppTopbar.vue';

const { layoutConfig, layoutState, isSidebarActive } = useLayout();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const outsideClickListener = ref(null);

const bottomNavItems = computed(() => [
    { name: t('common.map'), icon: 'pi pi-map-marker', route: 'room', active: false },
    { name: t('room.addRoom'), icon: 'pi pi-home', route: 'createRoom', active: false },
    { name: t('common.topics'), icon: 'pi pi-book', route: 'topic', active: false },
    { name: t('topic.addTopic'), icon: 'pi pi-plus', route: 'createTopic', active: false },
    { name: t('common.categories'), icon: 'pi pi-th-large', route: 'category', active: false },
    { name: t('common.profile'), icon: 'pi pi-user', route: 'profile', active: false }
]);

function navigateTo(routeName) {
    if (route.name === routeName) {
        return; // Zaten bu sayfadayız
    }
    router.push({ name: routeName });
}

watch(isSidebarActive, (newVal) => {
    if (newVal) {
        bindOutsideClickListener();
    } else {
        unbindOutsideClickListener();
    }
});

const containerClass = computed(() => ({
    'layout-overlay': layoutConfig.menuMode === 'overlay',
    'layout-static': layoutConfig.menuMode === 'static',
    'layout-static-inactive': layoutState.staticMenuDesktopInactive && layoutConfig.menuMode === 'static',
    'layout-overlay-active': layoutState.overlayMenuActive,
    'layout-mobile-active': layoutState.staticMenuMobileActive
}));

function bindOutsideClickListener() {
    if (!outsideClickListener.value) {
        outsideClickListener.value = (event) => {
            if (isOutsideClicked(event)) {
                layoutState.overlayMenuActive = false;
                layoutState.staticMenuMobileActive = false;
                layoutState.menuHoverActive = false;
            }
        };
        document.addEventListener('click', outsideClickListener.value);
    }
}

function unbindOutsideClickListener() {
    if (outsideClickListener.value) {
        document.removeEventListener('click', outsideClickListener.value);
        outsideClickListener.value = null;
    }
}

function isOutsideClicked(event) {
    const sidebarEl = document.querySelector('.layout-sidebar');
    const topbarEl = document.querySelector('.layout-menu-button');
    if (!sidebarEl || !topbarEl) return false;
    return !(sidebarEl.isSameNode(event.target) || sidebarEl.contains(event.target) || topbarEl.isSameNode(event.target) || topbarEl.contains(event.target));
}
</script>

<template>
    <div class="layout-wrapper" :class="containerClass">
        <app-topbar></app-topbar>
        <!-- Sidebar tamamen kaldırıldı -->
        <div class="layout-main-container">
            <div class="layout-main">
                <router-view></router-view>
            </div>
            <app-footer></app-footer>
        </div>
        <div class="layout-mask animate-fadein"></div>
        
        <!-- Bottom Navigation Bar - Her zaman görünür -->
        <div class="bottom-nav-bar">
            <button 
                v-for="item in bottomNavItems" 
                :key="item.name"
                class="bottom-nav-item"
                :class="{ active: route.name === item.route }"
                @click="navigateTo(item.route)"
            >
                <i :class="item.icon"></i>
                <span>{{ item.name }}</span>
            </button>
        </div>
        <Toast />
    </div>
</template>

<style lang="scss" scoped>
// Bottom Navigation Bar
.bottom-nav-bar {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    height: 70px;
    background: white;
    display: flex;
    align-items: center;
    justify-content: space-around;
    padding: 0 10px;
    z-index: 1000;
    box-shadow: 0 -2px 8px rgba(0, 0, 0, 0.1);
}

.bottom-nav-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    padding: 8px 12px;
    border: none;
    background: transparent;
    cursor: pointer;
    transition: all 0.2s;
    color: #666;
    border-radius: 12px;
    min-width: 60px;
    flex: 1;
    max-width: 100px;
    
    i {
        font-size: 18px;
    }
    
    span {
        font-size: 10px;
        font-weight: 500;
        text-align: center;
        line-height: 1.2;
    }
    
    &.active {
        color: #6300FF;
        background: rgba(99, 0, 255, 0.1);
        
        i {
            color: #6300FF;
        }
    }
    
    &:hover {
        background: rgba(0, 0, 0, 0.05);
    }
    
    &.active:hover {
        background: rgba(99, 0, 255, 0.15);
    }
}
</style>
