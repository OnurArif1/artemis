import { fileURLToPath, URL } from 'node:url';

import { PrimeVueResolver } from '@primevue/auto-import-resolver';
import vue from '@vitejs/plugin-vue';
import Components from 'unplugin-vue-components/vite';
import { defineConfig } from 'vite';

export default defineConfig({
    optimizeDeps: {
        noDiscovery: true
    },
    server: {
        port: 5175,
        proxy: {
            '/api': {
                target: 'http://localhost:5091',
                changeOrigin: true
            },
            '/identity': {
                target: 'http://localhost:5091',
                changeOrigin: true
            }
        }
    },
    plugins: [
        vue(),
        Components({
            resolvers: [PrimeVueResolver()]
        })
    ],
    resolve: {
        alias: {
            '@': fileURLToPath(new URL('./src', import.meta.url))
        }
    }
});
