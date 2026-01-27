import { createI18n } from 'vue-i18n';
import tr from './locales/tr';
import en from './locales/en';

const defaultLocale = localStorage.getItem('locale') || 'tr';

const i18n = createI18n({
    legacy: false,
    locale: defaultLocale,
    fallbackLocale: 'tr',
    messages: { tr, en }
});

export default i18n;
