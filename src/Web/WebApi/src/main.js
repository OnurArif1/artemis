import { createApp } from 'vue';
import App from './App.vue';
import router from './router';

import Aura from '@primeuix/themes/aura';
import PrimeVue from 'primevue/config';
import ConfirmationService from 'primevue/confirmationservice';
import ToastService from 'primevue/toastservice';
import { updatePreset } from '@primeuix/themes';

import '@/assets/styles.scss';
import { createPinia } from 'pinia';
import { useAuthStore } from '@/stores/auth';
import { useLayout } from '@/layout/composables/layout';
import i18n from '@/i18n';

// Custom Electric Purple color palette
const electricPurplePalette = {
    50: '#f3f0ff',
    100: '#e8e0ff',
    200: '#ddd0ff',
    300: '#c2a0ff',
    400: '#a670ff',
    500: '#6300FF',
    600: '#5200CC',
    700: '#4100AA',
    800: '#300088',
    900: '#200066',
    950: '#100033'
};

// Create custom theme with Electric Purple as primary color
const customAuraTheme = {
    ...Aura,
    semantic: {
        ...Aura.semantic,
        primary: electricPurplePalette,
        colorScheme: {
            light: {
                ...Aura.semantic.colorScheme.light,
                primary: {
                    color: '{primary.500}',
                    contrastColor: '#ffffff',
                    hoverColor: '{primary.600}',
                    activeColor: '{primary.700}'
                },
                highlight: {
                    background: '{primary.50}',
                    focusBackground: '{primary.100}',
                    color: '{primary.700}',
                    focusColor: '{primary.800}'
                }
            },
            dark: {
                ...Aura.semantic.colorScheme.dark,
                primary: {
                    color: '{primary.400}',
                    contrastColor: '{surface.900}',
                    hoverColor: '{primary.300}',
                    activeColor: '{primary.200}'
                },
                highlight: {
                    background: 'color-mix(in srgb, {primary.400}, transparent 84%)',
                    focusBackground: 'color-mix(in srgb, {primary.400}, transparent 76%)',
                    color: 'rgba(255,255,255,.87)',
                    focusColor: 'rgba(255,255,255,.87)'
                }
            }
        }
    }
};

const app = createApp(App);

const pinia = createPinia();
app.use(pinia);
app.use(router);
app.use(i18n);
app.use(PrimeVue, {
    theme: {
        preset: customAuraTheme,
        options: {
            darkModeSelector: '.app-dark'
        }
    }
});
app.use(ToastService);
app.use(ConfirmationService);

// Update preset with custom colors after PrimeVue is initialized
updatePreset(customAuraTheme);

const auth = useAuthStore();
auth.hydrateFromStorage();

const { layoutConfig } = useLayout();
if (layoutConfig.darkTheme) {
    document.documentElement.classList.add('app-dark');
}

app.mount('#app');
