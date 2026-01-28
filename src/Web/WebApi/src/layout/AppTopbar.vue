<script setup>
import { ref, watch, onMounted } from 'vue';
import { useLayout } from '@/layout/composables/layout';
import { useI18n } from '@/composables/useI18n';
import { useAuthStore } from '@/stores/auth';
import { getEmailFromToken } from '@/utils/jwt';

const { toggleDarkMode, isDarkTheme, toggleMenu } = useLayout();
const { locale, setLocale } = useI18n();
const authStore = useAuthStore();

const languages = [
    { label: 'Türkçe', value: 'tr', flag: '🇹🇷' },
    { label: 'English', value: 'en', flag: '🇬🇧' }
];

const selectedLanguage = ref('tr');
const userEmail = ref('');

onMounted(() => {
    const savedLocale = localStorage.getItem('locale') || 'tr';
    selectedLanguage.value = savedLocale;
    if (locale.value !== savedLocale) {
        setLocale(savedLocale);
    }

    const token = authStore.token || localStorage.getItem('auth.token');
    if (token) {
        const email = getEmailFromToken(token);
        if (email) {
            userEmail.value = email;
        }
    }
});

watch(locale, (newLocale) => {
    selectedLanguage.value = newLocale;
});

function changeLanguage(event) {
    const newLang = event.value;
    setLocale(newLang);
    selectedLanguage.value = newLang;
}
</script>

<template>
    <div class="layout-topbar">
        <button type="button" class="layout-menu-button layout-topbar-action" @click="toggleMenu">
            <i class="pi pi-bars"></i>
        </button>
        <div class="layout-topbar-logo-container">
            <span class="layout-topbar-logo">Artemis WebApi</span>
        </div>
        <div class="layout-topbar-actions">
            <button type="button" class="layout-topbar-action" @click="toggleDarkMode">
                <i :class="['pi', isDarkTheme ? 'pi-moon' : 'pi-sun']"></i>
            </button>
            <div v-if="userEmail" class="user-email">
                <i class="pi pi-user"></i>
                <span>{{ userEmail }}</span>
            </div>
            <Dropdown
                v-model="selectedLanguage"
                :options="languages"
                option-label="label"
                option-value="value"
                @change="changeLanguage"
                class="language-dropdown"
                :pt="{
                    root: { class: 'language-dropdown-root' },
                    input: { class: 'language-dropdown-input' }
                }"
            >
                <template #value="slotProps">
                    <span v-if="slotProps.value" class="language-dropdown-value">
                        <span class="language-flag">{{ languages.find((l) => l.value === slotProps.value)?.flag }}</span>
                    </span>
                    <span v-else>
                        <span class="language-flag">🇹🇷</span>
                    </span>
                </template>
                <template #option="slotProps">
                    <div class="language-option">
                        <span class="language-flag">{{ slotProps.option.flag }}</span>
                        <span>{{ slotProps.option.label }}</span>
                    </div>
                </template>
            </Dropdown>
        </div>
    </div>
</template>

<style lang="scss" scoped>
.layout-topbar-actions {
    display: flex;
    align-items: center;
    gap: 1rem;
}

.user-email {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 1rem;
    background-color: var(--surface-100);
    border-radius: 4px;
    font-size: 0.875rem;
    color: var(--text-color);

    i {
        color: var(--primary-color);
    }
}

.language-dropdown-root {
    min-width: 2.5rem;
}
.language-dropdown-input {
    padding: 0.25rem 0.5rem;
}
.language-dropdown-value,
.language-option {
    display: flex;
    align-items: center;
    gap: 0.5rem;
}
.language-flag {
    font-size: 1.25rem;
}
</style>
