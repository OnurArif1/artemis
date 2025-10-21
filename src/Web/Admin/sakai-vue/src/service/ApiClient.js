import axios from 'axios';
import { useAuthStore } from '@/stores/auth';

const apiClient = axios.create({
    baseURL: '/api',
    withCredentials: false
});

apiClient.interceptors.request.use((config) => {
    const authStore = useAuthStore();
    console.log('authStore.token:', authStore.token);
    if (authStore.token) {
        config.headers = config.headers || {};
        config.headers.Authorization = `Bearer ${authStore.token}`;
    }
    return config;
});

export default apiClient;
