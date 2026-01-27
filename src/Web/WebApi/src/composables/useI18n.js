import { useI18n as useVueI18n } from 'vue-i18n';

export function useI18n() {
    const { t, locale } = useVueI18n();

    const setLocale = (lang) => {
        locale.value = lang;
        localStorage.setItem('locale', lang);
    };

    const getLocale = () => locale.value;

    return { t, locale, setLocale, getLocale };
}
