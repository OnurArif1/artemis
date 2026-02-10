import axios from 'axios';
import { useAuthStore } from '@/stores/auth';
import router from '@/router';

const service = axios.create({
    baseURL: '/api',
    timeout: 1000000,
    maxContentLength: 200000,
    withCredentials: false
});

service.interceptors.request.use(
    (config) => {
        // Get token from localStorage directly to ensure it's always available
        const token = localStorage.getItem('auth.token');
        if (token) {
            config.headers = config.headers || {};
            config.headers.Authorization = `Bearer ${token}`;
        } else {
            console.warn('No auth token found for request:', config.url);
        }
        return config;
    },
    (error) => Promise.reject(error)
);

service.interceptors.response.use(
    (response) => {
        if (response.status === 201) {
            const { location } = response.headers || {};
            if (location && response.data === '') {
                response.data = { id: location.substr(location.lastIndexOf('/') + 1) };
            }
        }
        return response;
    },
    async (error) => {
        const status = error?.response?.status;
        if (status === 401) {
            const auth = useAuthStore();
            if (auth.token) {
                auth.clearToken();
                await router.push({ name: 'login' });
            }
        }
        return Promise.reject(error?.response || error);
    }
);

export default function request({ method, url, data, params, baseURL, headers }) {
    return service({
        method,
        url,
        data,
        params,
        baseURL: baseURL || '/api',
        headers
    });
}
