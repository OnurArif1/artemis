<script setup>
import FloatingConfigurator from '@/components/FloatingConfigurator.vue';
import { ref } from 'vue';
import { useAuthStore } from '@/stores/auth';
import { useRouter } from 'vue-router';
import axios from 'axios';

const email = ref('');
const password = ref('');
const checked = ref(false);
const loading = ref(false);
const errorMsg = ref('');
const router = useRouter();
const auth = useAuthStore();

async function onLogin() {
    errorMsg.value = '';
    loading.value = true;
    try {
        const form = new URLSearchParams();
        form.append('grant_type', 'password');
        form.append('client_id', 'artemis.client');
        form.append('client_secret', 'artemis_secret');
        form.append('username', email.value);
        form.append('password', password.value);
        form.append('scope', 'openid profile email roles artemis.api');

        const tokenUrl = import.meta.env.VITE_IDENTITY_TOKEN_URL;

        const resp = await axios.post(tokenUrl, form, {
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
        });

        const accessToken = resp?.data?.access_token;
        const expiresIn = resp?.data?.expires_in;
        if (!accessToken) throw new Error('Invalid login response');

        localStorage.setItem('auth.token', accessToken);
        if (expiresIn) {
            localStorage.setItem('auth.expiresAt', (Date.now() + Number(expiresIn) * 1000).toString());
        }
        axios.defaults.headers.common['Authorization'] = `Bearer ${accessToken}`;

        auth.setToken?.(accessToken, expiresIn ? Number(expiresIn) : undefined);
        router.push({ name: 'dashboard' });
    } catch (err) {
        console.log('err:', err);
        errorMsg.value = 'Invalid email or password';
    } finally {
        loading.value = false;
    }
}
</script>

<template>
    <div>
        <FloatingConfigurator />
        <div class="relative">
            <FloatingConfigurator />
            <div class="bg-surface-50 dark:bg-surface-950 flex items-center justify-center min-h-screen min-w-[100vw] overflow-hidden">
                <div class="flex flex-col items-center justify-center">
                    <div style="border-radius: 56px; padding: 0.3rem; background: linear-gradient(180deg, var(--primary-color) 10%, rgba(33, 150, 243, 0) 30%)">
                        <div class="w-full bg-surface-0 dark:bg-surface-900 py-20 px-8 sm:px-20" style="border-radius: 53px">
                            <div class="text-center mb-8">
                                <div class="text-surface-900 dark:text-surface-0 text-3xl font-medium mb-4">Welcome to Ghosipy Admin!</div>
                            </div>
                            <div>
                                <label for="email1" class="block text-surface-900 dark:text-surface-0 text-xl font-medium mb-2">Email</label>
                                <InputText id="email1" type="text" placeholder="Email address" class="w-full md:w-[30rem] mb-8" v-model="email" />

                                <label for="password1" class="block text-surface-900 dark:text-surface-0 font-medium text-xl mb-2">Password</label>
                                <Password id="password1" v-model="password" placeholder="Password" :toggleMask="true" class="mb-4" fluid :feedback="false"></Password>

                                <div class="flex items-center justify-between mt-2 mb-8 gap-8">
                                    <div class="flex items-center">
                                        <Checkbox v-model="checked" id="rememberme1" binary class="mr-2"></Checkbox>
                                        <label for="rememberme1">Remember me</label>
                                    </div>
                                </div>
                                <div class="mb-4" v-if="errorMsg">
                                    <small class="text-red-500">{{ errorMsg }}</small>
                                </div>
                                <div class="mt-4">
                                    <Button label="Log In" class="w-full" @click="onLogin" />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
.pi-eye {
    transform: scale(1.6);
    margin-right: 1rem;
}

.pi-eye-slash {
    transform: scale(1.6);
    margin-right: 1rem;
}
</style>
