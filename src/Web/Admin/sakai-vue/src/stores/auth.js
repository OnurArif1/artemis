import { defineStore } from 'pinia';
import { ref } from 'vue';
import axios from 'axios';

export const useAuthStore = defineStore('auth', () => {
    const token = ref(null);
    const expiresAt = ref(null);

    function setToken(jwt, expiresInSeconds) {
        token.value = jwt;
        if (expiresInSeconds) {
            expiresAt.value = Date.now() + expiresInSeconds * 1000;
        } else {
            expiresAt.value = null;
        }
        localStorage.setItem('auth.token', jwt);
        localStorage.setItem('auth.expiresAt', expiresAt.value ? expiresAt.value.toString() : '');
        axios.defaults.headers.common['Authorization'] = `Bearer ${jwt}`;
    }

    function hydrateFromStorage() {
        const storedToken = localStorage.getItem('auth.token');
        const storedExpires = localStorage.getItem('auth.expiresAt');
        if (storedToken) {
            if (storedExpires) {
                const exp = parseInt(storedExpires, 10);
                if (isNaN(exp) || (exp && Date.now() > exp)) {
                    clear();
                    return;
                } else {
                    token.value = storedToken;
                    expiresAt.value = exp;
                }
            } else {
                token.value = storedToken;
            }
            axios.defaults.headers.common['Authorization'] = `Bearer ${storedToken}`;
        }
    }

    function clear() {
        token.value = null;
        expiresAt.value = null;
        localStorage.removeItem('auth.token');
        localStorage.removeItem('auth.expiresAt');
        delete axios.defaults.headers.common['Authorization'];
    }

    // add compatibility alias expected by components
    function clearToken() {
        clear();
    }

    function isAuthenticated() {
        if (!token.value) return false;
        if (expiresAt.value && Date.now() > expiresAt.value) {
            clear();
            return false;
        }
        return true;
    }

    return { token, expiresAt, setToken, hydrateFromStorage, clear, clearToken, isAuthenticated };
});

export default useAuthStore;
