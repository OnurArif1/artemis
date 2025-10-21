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
import axios from 'axios';

const app = createApp(App);

const pinia = createPinia();
app.use(pinia);
app.use(router);
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

// İlk çalışma kontrolü: eğer daha önce "first run" yapılmamışsa
// saved token'ı temizle ki uygulama ilk açılışta dashboard'a atmasın.
const FIRST_RUN_KEY = 'app.firstRunDone';
if (!localStorage.getItem(FIRST_RUN_KEY)) {
    localStorage.removeItem('auth.token');
    localStorage.removeItem('auth.expiresAt');
    delete axios.defaults.headers.common['Authorization'];
    localStorage.setItem(FIRST_RUN_KEY, '1');
} else {
    // normal hydrate: token varsa ve süresi dolmadıysa axios header'ı ayarla
    const storedToken = localStorage.getItem('auth.token');
    const storedExpires = localStorage.getItem('auth.expiresAt');
    if (storedToken && (!storedExpires || Date.now() < Number(storedExpires))) {
        axios.defaults.headers.common['Authorization'] = `Bearer ${storedToken}`;
    } else {
        localStorage.removeItem('auth.token');
        localStorage.removeItem('auth.expiresAt');
    }
}

// (istenirse) Pinia store içine de hydrate edilebilir
const auth = useAuthStore();
if (axios.defaults.headers.common['Authorization'] && auth.hydrateFromStorage) {
    auth.hydrateFromStorage();
}

app.mount('#app');
