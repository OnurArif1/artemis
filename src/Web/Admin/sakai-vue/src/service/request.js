import axios from 'axios';
import { useAuthStore } from '@/stores/auth';
import router from '@/router';

const service = axios.create({
    baseURL: '/api',
    timeout: 1000000,
    maxContentLength: 200000,
    withCredentials: true
});

service.interceptors.request.use(
    (config) => {
        const auth = useAuthStore();
        if (auth.token) {
            config.headers = config.headers || {};
            config.headers.Authorization = `Bearer ${auth.token}`;
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


