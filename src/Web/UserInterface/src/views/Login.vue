<template>
    <div class="login-container">
        <div class="login-card">
            <div class="login-header">
                <h1>Artemis</h1>
                <p>Giriş Yap</p>
            </div>

            <form @submit.prevent="handleLogin" class="login-form">
                <div class="form-group">
                    <label for="email">E-posta</label>
                    <InputText
                        id="email"
                        v-model="form.email"
                        type="email"
                        placeholder="ornek@email.com"
                        class="w-full"
                        :class="{ 'p-invalid': errors.email }"
                    />
                    <small v-if="errors.email" class="p-error">{{ errors.email }}</small>
                </div>

                <div class="form-group">
                    <label for="password">Şifre</label>
                    <Password
                        id="password"
                        v-model="form.password"
                        placeholder="Şifrenizi girin"
                        class="w-full"
                        :class="{ 'p-invalid': errors.password }"
                        :feedback="false"
                        toggleMask
                    />
                    <small v-if="errors.password" class="p-error">{{ errors.password }}</small>
                </div>

                <div v-if="errorMessage" class="error-message">
                    <Message severity="error" :closable="false">{{ errorMessage }}</Message>
                </div>

                <Button
                    type="submit"
                    label="Giriş Yap"
                    icon="pi pi-sign-in"
                    class="w-full"
                    :loading="loading"
                    :disabled="loading"
                />

                <div class="register-link">
                    <span>Hesabınız yok mu? </span>
                    <router-link to="/register">Kayıt Ol</router-link>
                </div>
            </form>
        </div>
    </div>
</template>

<script setup>
import { ref, reactive } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useAuthStore } from '@/stores/auth';
import AuthService from '@/service/AuthService';
import { useToast } from 'primevue/usetoast';

const router = useRouter();
const route = useRoute();
const auth = useAuthStore();
const toast = useToast();
const authService = new AuthService();

const loading = ref(false);
const errorMessage = ref('');

const form = reactive({
    email: '',
    password: ''
});

const errors = reactive({
    email: '',
    password: ''
});

function validate() {
    errors.email = '';
    errors.password = '';

    if (!form.email) {
        errors.email = 'E-posta gereklidir';
        return false;
    }

    if (!form.email.includes('@')) {
        errors.email = 'Geçerli bir e-posta adresi girin';
        return false;
    }

    if (!form.password) {
        errors.password = 'Şifre gereklidir';
        return false;
    }

    if (form.password.length < 6) {
        errors.password = 'Şifre en az 6 karakter olmalıdır';
        return false;
    }

    return true;
}

async function handleLogin() {
    if (!validate()) {
        return;
    }

    loading.value = true;
    errorMessage.value = '';

    try {
        const response = await authService.login(form.email, form.password);
        
        auth.setToken(response.access_token, response.expires_in);
        
        try {
            const userInfo = await authService.getUserInfo(response.access_token);
            auth.setUser(userInfo);
        } catch (err) {
            console.error('User info error:', err);
        }

        toast.add({
            severity: 'success',
            summary: 'Başarılı',
            detail: 'Giriş yapıldı',
            life: 3000
        });

        const redirect = route.query.redirect || '/';
        router.push(redirect);
    } catch (error) {
        console.error('Login error:', error);
        errorMessage.value = error?.response?.data?.error_description || error?.response?.data?.error || 'Giriş yapılamadı. Lütfen bilgilerinizi kontrol edin.';
    } finally {
        loading.value = false;
    }
}
</script>

<style scoped>
.login-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    padding: 1rem;
}

.login-card {
    background: white;
    border-radius: 12px;
    padding: 2rem;
    width: 100%;
    max-width: 400px;
    box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
}

.login-header {
    text-align: center;
    margin-bottom: 2rem;
}

.login-header h1 {
    font-size: 2rem;
    color: #667eea;
    margin-bottom: 0.5rem;
}

.login-header p {
    color: #6b7280;
    font-size: 1rem;
}

.login-form {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
}

.form-group {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}

.form-group label {
    font-weight: 500;
    color: #374151;
}

.error-message {
    margin-top: -0.5rem;
}

.register-link {
    text-align: center;
    margin-top: 1rem;
    color: #6b7280;
}

.register-link a {
    color: #667eea;
    text-decoration: none;
    font-weight: 500;
}

.register-link a:hover {
    text-decoration: underline;
}
</style>

