import axios from 'axios';
import { useAuthStore } from '@/stores/auth';
import router from '@/router';

const service = axios.create({
    baseURL: '/api',
    timeout: 100000,
    withCredentials: false
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
        return response;
    },
    async (error) => {
        if (error?.response?.status === 401) {
            const auth = useAuthStore();
            auth.clear();
            router.push({ name: 'login' });
        }
        return Promise.reject(error?.response || error);
    }
);

export default function request({ method, url, data, params, baseURL, headers }) {
    // baseURL verilmişse onu kullan, yoksa service'in baseURL'ini kullan
    const finalBaseURL = baseURL || undefined; // undefined olursa service'in baseURL'i kullanılır
    
    return service({
        method,
        url,
        data,
        params,
        baseURL: finalBaseURL,
        headers
    });
}

