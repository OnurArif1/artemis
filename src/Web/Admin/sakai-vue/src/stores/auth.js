import { defineStore } from 'pinia';

export const useAuthStore = defineStore('auth', {
    state: () => ({
        token: null
    }),
    getters: {
        isAuthenticated: (state) => !!state.token
    },
    actions: {
        setToken(newToken) {
            this.token = newToken;
            console.log('auth token set:', newToken);
            // persist only in production
            if (import.meta.env.PROD) {
                try {
                    localStorage.setItem('auth_token', newToken ?? '');
                } catch (_) {
                    // ignore storage errors
                }
            }
        },
        clearToken() {
            this.token = null;
            try {
                localStorage.removeItem('auth_token');
            } catch (_) {
                // ignore storage errors
            }
        },
        hydrateFromStorage() {
            // in development, do not auto-hydrate so app starts at login
            if (import.meta.env.DEV) return;
            try {
                const stored = localStorage.getItem('auth_token');
                if (stored) {
                    this.token = stored;
                    console.log('auth token hydrated from storage:', stored);
                }
            } catch (_) {
                // ignore storage errors
            }
        }
    }
});


