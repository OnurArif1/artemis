<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useLayout } from '@/layout/composables/layout';
import { useI18n } from '@/composables/useI18n';
import { useAuthStore } from '@/stores/auth';
import { getEmailFromToken } from '@/utils/jwt';

const router = useRouter();
const { toggleDarkMode, isDarkTheme, toggleMenu } = useLayout();
const { t } = useI18n();
const authStore = useAuthStore();

const userEmail = ref('');
const profileMenuRef = ref(null);
const profileMenu = ref(null);

onMounted(() => {
    const token = authStore.token || localStorage.getItem('auth.token');
    if (token) {
        const email = getEmailFromToken(token);
        if (email) {
            userEmail.value = email;
        }
    }
});

function toggleProfileMenu(event) {
    profileMenu.value.toggle(event);
}

function onLogout() {
    authStore.clearToken();
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

const profileMenuItems = computed(() => [
    {
        label: userEmail.value || t('common.account'),
        items: [
            {
                label: t('common.logout'),
                icon: 'pi pi-sign-out',
                command: onLogout
            }
        ]
    }
]);
</script>

<template>
    <div class="layout-topbar">
        <button type="button" class="layout-menu-button layout-topbar-action" @click="toggleMenu">
            <i class="pi pi-bars"></i>
        </button>
        <div class="layout-topbar-logo-container">
            <span class="layout-topbar-logo">Ghossip</span>
        </div>
        <div class="layout-topbar-actions">
            <button type="button" class="layout-topbar-action" @click="toggleDarkMode">
                <i :class="['pi', isDarkTheme ? 'pi-moon' : 'pi-sun']"></i>
            </button>
            <div v-if="userEmail" class="profile-menu-container">
                <button type="button" class="profile-button" @click="toggleProfileMenu" ref="profileMenuRef">
                    <i class="pi pi-user"></i>
                    <span class="profile-email">{{ userEmail }}</span>
                    <i class="pi pi-chevron-down profile-chevron"></i>
                </button>
                <Menu ref="profileMenu" :model="profileMenuItems" :popup="true" />
            </div>
        </div>
    </div>
</template>

<style lang="scss" scoped>
.layout-topbar-actions {
    display: flex;
    align-items: center;
    gap: 1rem;
}

.profile-menu-container {
    position: relative;
}

.profile-button {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 1rem;
    background-color: var(--surface-100);
    border: 1px solid var(--surface-200);
    border-radius: 6px;
    font-size: 0.875rem;
    color: var(--text-color);
    cursor: pointer;
    transition: all 0.2s;
}

.profile-button:hover {
    background-color: var(--surface-200);
    border-color: var(--surface-300);
}

.profile-button i:first-child {
    color: var(--primary-color);
    font-size: 1rem;
}

.profile-email {
    font-weight: 500;
    max-width: 200px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.profile-chevron {
    font-size: 0.75rem;
    color: var(--text-color-secondary);
    transition: transform 0.2s;
}

.profile-button:hover .profile-chevron {
    transform: translateY(1px);
}

</style>
