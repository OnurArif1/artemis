import { createApp } from 'vue';
import App from './App.vue';
import router from './router';

import Aura from '@primeuix/themes/aura';
import PrimeVue from 'primevue/config';
import ConfirmationService from 'primevue/confirmationservice';
import ToastService from 'primevue/toastservice';

import '@/assets/styles.scss';
import { createPinia } from 'pinia';
import { useAuthStore } from '@/stores/auth';
import { useLayout } from '@/layout/composables/layout';
import i18n from '@/i18n';

const app = createApp(App);

const pinia = createPinia();
app.use(pinia);
app.use(router);
app.use(i18n);
app.use(PrimeVue, {
    theme: {
        preset: Aura,
        options: {
            darkModeSelector: '.app-dark'
        }
    }
});
app.use(ToastService);
app.use(ConfirmationService);

const auth = useAuthStore();
auth.hydrateFromStorage();

const { layoutConfig } = useLayout();
if (layoutConfig.darkTheme) {
    document.documentElement.classList.add('app-dark');
}

app.mount('#app');
