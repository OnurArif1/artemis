<script setup>
import { ref, watch, onMounted } from 'vue';
import { useI18n } from '@/composables/useI18n';

const { locale, setLocale } = useI18n();

const languages = [
    { label: 'Türkçe', value: 'tr', flag: '🇹🇷' },
    { label: 'English', value: 'en', flag: '🇬🇧' }
];

const selectedLanguage = ref('tr');

onMounted(() => {
    const savedLocale = localStorage.getItem('locale') || 'tr';
    selectedLanguage.value = savedLocale;
    if (locale.value !== savedLocale) {
        setLocale(savedLocale);
    }
});

watch(locale, (newLocale) => {
    selectedLanguage.value = newLocale;
});

const changeLanguage = (event) => {
    const newLang = event.value;
    setLocale(newLang);
    selectedLanguage.value = newLang;
};
</script>

<template>
    <div class="layout-topbar">
        <div class="layout-topbar-logo-container">
            <button class="layout-menu-button layout-topbar-action" @click="toggleMenu">
                <i class="pi pi-bars"></i>
            </button>
            <span class="layout-topbar-logo">Ghossip</span>
        </div>

        <div class="layout-topbar-actions">
            <div class="layout-config-menu">
                <button type="button" class="layout-topbar-action" @click="toggleDarkMode">
                    <i :class="['pi', { 'pi-moon': isDarkTheme, 'pi-sun': !isDarkTheme }]"></i>
                </button>
                <Dropdown
                    v-model="selectedLanguage"
                    :options="languages"
                    optionLabel="label"
                    optionValue="value"
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

            <button
                class="layout-topbar-menu-button layout-topbar-action"
                v-styleclass="{ selector: '@next', enterFromClass: 'hidden', enterActiveClass: 'animate-scalein', leaveToClass: 'hidden', leaveActiveClass: 'animate-fadeout', hideOnOutsideClick: true }"
            >
                <i class="pi pi-ellipsis-v"></i>
            </button>
        </div>
    </div>
</template>
