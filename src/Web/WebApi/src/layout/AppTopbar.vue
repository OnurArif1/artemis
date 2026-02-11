<script setup>
import { ref, onMounted, computed, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { useLayout } from '@/layout/composables/layout';
import { useI18n } from '@/composables/useI18n';
import { useAuthStore } from '@/stores/auth';
import { getEmailFromToken } from '@/utils/jwt';
import request from '@/service/request';
import TopicService from '@/service/TopicService';

const router = useRouter();
const { toggleDarkMode, isDarkTheme, toggleMenu } = useLayout();
const { t } = useI18n();
const authStore = useAuthStore();

const userEmail = ref('');
const profileMenuRef = ref(null);
const profileMenu = ref(null);

const topicService = new TopicService(request);
const topics = ref([]);

async function loadAllTopics() {
    try {
        // Tüm topicleri çekmek için büyük bir pageSize kullanıyoruz
        const data = await topicService.getList({
            pageIndex: 1,
            pageSize: 1000
        });
        const loadedTopics = Array.isArray(data.resultViewModels) ? data.resultViewModels : (data?.resultViewModels ?? []);
        const topicTitles = loadedTopics.map((topic) => topic.title).filter((title) => title && title.trim() !== '');

        // Topicleri iki kez tekrarlayarak sürekli döngü için hazırlıyoruz
        topics.value = [...topicTitles, ...topicTitles];
    } catch (err) {
        console.error('Topic yükleme hatası:', err);
    }
}

onMounted(() => {
    const token = authStore.token || localStorage.getItem('auth.token');
    if (token) {
        const email = getEmailFromToken(token);
        if (email) {
            userEmail.value = email;
        }
    }
    loadAllTopics();
});

onUnmounted(() => {
    // Cleanup gerekirse buraya eklenebilir
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
        <!-- Hamburger menü butonu kaldırıldı - sidebar artık yok -->
        <div class="layout-topbar-logo-container">
            <span class="layout-topbar-logo">Ghossip</span>
        </div>
        <div class="layout-topbar-topics-wrapper" v-if="topics.length > 0">
            <div class="layout-topbar-topics">
                <div class="topics-track">
                    <span
                        v-for="(topic, index) in topics"
                        :key="index"
                        class="topic-item"
                        :style="{ '--topic-index': index % (topics.length / 2) }"
                    >
                        <span class="topic-text">{{ topic }}</span>
                    </span>
                </div>
            </div>
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

.layout-topbar-topics-wrapper {
    flex: 1;
    position: relative;
    overflow: hidden;
    margin: 0 1rem;
    height: 100%;
    display: flex;
    align-items: center;
    background: linear-gradient(
        90deg,
        transparent 0%,
        color-mix(in srgb, var(--primary-color) 3%, transparent) 20%,
        color-mix(in srgb, var(--primary-color) 5%, transparent) 50%,
        color-mix(in srgb, var(--primary-color) 3%, transparent) 80%,
        transparent 100%
    );
    border-radius: 8px;
    padding: 0.5rem 0;
    box-shadow: inset 0 1px 3px color-mix(in srgb, var(--primary-color) 10%, transparent);

    // Sağ tarafta fade-out efekti (tema butonuna yakın)
    &::after {
        content: '';
        position: absolute;
        right: 0;
        top: 0;
        bottom: 0;
        width: 100px;
        background: linear-gradient(to right, transparent, var(--surface-card) 90%);
        z-index: 2;
        pointer-events: none;
    }

    // Sol tarafta fade-in efekti (Ghossip yazısından sonra)
    &::before {
        content: '';
        position: absolute;
        left: 0;
        top: 0;
        bottom: 0;
        width: 80px;
        background: linear-gradient(to left, transparent, var(--surface-card) 90%);
        z-index: 2;
        pointer-events: none;
    }
}

.layout-topbar-topics {
    width: 100%;
    height: 100%;
    overflow: hidden;
    position: relative;
    display: flex;
    align-items: center;
}

.topics-track {
    display: inline-flex;
    align-items: center;
    white-space: nowrap;
    animation: scroll-topics 40s linear infinite;
    will-change: transform;
    padding-left: 100%;
    gap: 0;
}

.topic-item {
    white-space: nowrap;
    display: inline-flex;
    align-items: center;
    margin-right: 3rem;
    position: relative;
    padding: 0.5rem 1.2rem;
    border-radius: 25px;
    background: linear-gradient(
        135deg,
        color-mix(in srgb, var(--primary-color) 15%, transparent),
        color-mix(in srgb, var(--primary-color) 8%, transparent)
    );
    backdrop-filter: blur(10px);
    transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
    animation: topic-pulse 4s ease-in-out infinite;
    animation-delay: calc(var(--topic-index) * 0.15s);
    box-shadow: 0 2px 12px color-mix(in srgb, var(--primary-color) 20%, transparent),
        0 0 20px color-mix(in srgb, var(--primary-color) 10%, transparent);
    border: 1px solid color-mix(in srgb, var(--primary-color) 20%, transparent);

    &:hover {
        transform: translateY(-3px) scale(1.08);
        box-shadow: 0 6px 24px color-mix(in srgb, var(--primary-color) 30%, transparent),
            0 0 30px color-mix(in srgb, var(--primary-color) 20%, transparent);
        background: linear-gradient(
            135deg,
            color-mix(in srgb, var(--primary-color) 25%, transparent),
            color-mix(in srgb, var(--primary-color) 15%, transparent)
        );
    }

    .topic-text {
        font-size: 0.95rem;
        font-weight: 700;
        letter-spacing: 0.5px;
        background: linear-gradient(
            135deg,
            var(--primary-color) 0%,
            var(--text-color) 50%,
            var(--primary-color) 100%
        );
        background-size: 200% auto;
        -webkit-background-clip: text;
        background-clip: text;
        -webkit-text-fill-color: transparent;
        animation: gradient-shift 5s ease infinite;
        filter: drop-shadow(0 0 8px color-mix(in srgb, var(--primary-color) 40%, transparent));
        position: relative;
    }

    &::after {
        content: '✨';
        margin-left: 1.5rem;
        font-size: 0.75rem;
        opacity: 0.7;
        animation: sparkle 2.5s ease-in-out infinite;
        animation-delay: calc(var(--topic-index) * 0.2s);
        filter: drop-shadow(0 0 4px color-mix(in srgb, var(--primary-color) 60%, transparent));
    }

    &:last-child::after {
        display: none;
    }
}

@keyframes topic-pulse {
    0%,
    100% {
        opacity: 0.95;
        transform: scale(1);
        box-shadow: 0 2px 12px color-mix(in srgb, var(--primary-color) 20%, transparent),
            0 0 20px color-mix(in srgb, var(--primary-color) 10%, transparent);
    }
    50% {
        opacity: 1;
        transform: scale(1.03);
        box-shadow: 0 4px 16px color-mix(in srgb, var(--primary-color) 25%, transparent),
            0 0 25px color-mix(in srgb, var(--primary-color) 15%, transparent);
    }
}

@keyframes gradient-shift {
    0%,
    100% {
        background-position: 0% center;
    }
    50% {
        background-position: 100% center;
    }
}

@keyframes sparkle {
    0%,
    100% {
        opacity: 0.5;
        transform: scale(1) rotate(0deg);
    }
    25% {
        opacity: 0.8;
        transform: scale(1.1) rotate(90deg);
    }
    50% {
        opacity: 1;
        transform: scale(1.3) rotate(180deg);
    }
    75% {
        opacity: 0.8;
        transform: scale(1.1) rotate(270deg);
    }
}

@keyframes scroll-topics {
    0% {
        transform: translateX(0);
    }
    100% {
        transform: translateX(-50%);
    }
}

@media (max-width: 991px) {
    .layout-topbar-topics-wrapper {
        display: none;
    }
}

@media (max-width: 1200px) {
    .layout-topbar-topics-wrapper {
        margin: 0 0.5rem;
    }
    .topic-item {
        margin-right: 2rem;
        padding: 0.3rem 0.8rem;

        .topic-text {
            font-size: 0.85rem;
        }
    }
    .topics-track {
        gap: 1.5rem;
    }
}
</style>
