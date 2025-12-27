import { defineStore } from 'pinia';
import { ref } from 'vue';
import axios from 'axios';

export const useAuthStore = defineStore('auth', () => {
    const token = ref(null);
    const expiresAt = ref(null);
    const user = ref(null);

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

    function setUser(userData) {
        user.value = userData;
        localStorage.setItem('auth.user', JSON.stringify(userData));
    }

    function hydrateFromStorage() {
        const storedToken = localStorage.getItem('auth.token');
        const storedExpires = localStorage.getItem('auth.expiresAt');
        const storedUser = localStorage.getItem('auth.user');
        
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

        if (storedUser) {
            try {
                user.value = JSON.parse(storedUser);
            } catch (e) {
                console.error('Error parsing user data:', e);
            }
        }
    }

    function clear() {
        token.value = null;
        expiresAt.value = null;
        user.value = null;
        localStorage.removeItem('auth.token');
        localStorage.removeItem('auth.expiresAt');
        localStorage.removeItem('auth.user');
        delete axios.defaults.headers.common['Authorization'];
    }

    function clearToken() {
        clear();
    }

    function isAuthenticated() {
        const storedToken = localStorage.getItem('auth.token');
        const storedExpires = localStorage.getItem('auth.expiresAt');

        if (!storedToken) {
            clear();
            return false;
        }

        if (storedExpires) {
            const exp = parseInt(storedExpires, 10);
            if (isNaN(exp) || (exp && Date.now() > exp)) {
                clear();
                return false;
            }
        }
        
        if (storedToken !== token.value) {
            token.value = storedToken;
            if (storedExpires) {
                expiresAt.value = parseInt(storedExpires, 10);
            }
            axios.defaults.headers.common['Authorization'] = `Bearer ${storedToken}`;
        }

        return true;
    }

    return { 
        token, 
        expiresAt, 
        user,
        setToken, 
        setUser,
        hydrateFromStorage, 
        clear, 
        clearToken, 
        isAuthenticated 
    };
});

export default useAuthStore;

