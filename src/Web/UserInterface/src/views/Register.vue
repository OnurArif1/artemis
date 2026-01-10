<template>
    <div class="register-container">
        <div class="register-card">
            <div class="register-header">
                <h1>Artemis</h1>
                <p>Kayıt Ol</p>
            </div>

            <form @submit.prevent="handleRegister" class="register-form">
                <div class="form-group">
                    <label for="firstName">Ad</label>
                    <InputText
                        id="firstName"
                        v-model="form.firstName"
                        placeholder="Adınız"
                        class="w-full"
                        :class="{ 'p-invalid': errors.firstName }"
                    />
                    <small v-if="errors.firstName" class="p-error">{{ errors.firstName }}</small>
                </div>

                <div class="form-group">
                    <label for="lastName">Soyad</label>
                    <InputText
                        id="lastName"
                        v-model="form.lastName"
                        placeholder="Soyadınız"
                        class="w-full"
                        :class="{ 'p-invalid': errors.lastName }"
                    />
                    <small v-if="errors.lastName" class="p-error">{{ errors.lastName }}</small>
                </div>

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
                        toggleMask
                    />
                    <small v-if="errors.password" class="p-error">{{ errors.password }}</small>
                </div>

                <div class="form-group">
                    <label for="confirmPassword">Şifre Tekrar</label>
                    <Password
                        id="confirmPassword"
                        v-model="form.confirmPassword"
                        placeholder="Şifrenizi tekrar girin"
                        class="w-full"
                        :class="{ 'p-invalid': errors.confirmPassword }"
                        toggleMask
                    />
                    <small v-if="errors.confirmPassword" class="p-error">{{ errors.confirmPassword }}</small>
                </div>

                <div v-if="errorMessage" class="error-message">
                    <Message severity="error" :closable="false">{{ errorMessage }}</Message>
                </div>

                <div v-if="successMessage" class="success-message">
                    <Message severity="success" :closable="false">{{ successMessage }}</Message>
                </div>

                <Button
                    type="submit"
                    label="Kayıt Ol"
                    icon="pi pi-user-plus"
                    class="w-full"
                    :loading="loading"
                    :disabled="loading"
                />

                <div class="login-link">
                    <span>Zaten hesabınız var mı? </span>
                    <router-link to="/login">Giriş Yap</router-link>
                </div>
            </form>
        </div>
    </div>
</template>

<script setup>
import { ref, reactive } from 'vue';
import { useRouter } from 'vue-router';
import AuthService from '@/service/AuthService';
import { useToast } from 'primevue/usetoast';

const router = useRouter();
const toast = useToast();
const authService = new AuthService();

const loading = ref(false);
const errorMessage = ref('');
const successMessage = ref('');

const form = reactive({
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    confirmPassword: ''
});

const errors = reactive({
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    confirmPassword: ''
});

function validate() {
    errors.firstName = '';
    errors.lastName = '';
    errors.email = '';
    errors.password = '';
    errors.confirmPassword = '';

    if (!form.firstName.trim()) {
        errors.firstName = 'Ad gereklidir';
        return false;
    }

    if (!form.lastName.trim()) {
        errors.lastName = 'Soyad gereklidir';
        return false;
    }

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

    if (form.password !== form.confirmPassword) {
        errors.confirmPassword = 'Şifreler eşleşmiyor';
        return false;
    }

    return true;
}

async function handleRegister() {
    if (!validate()) {
        return;
    }

    loading.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
        await authService.register({
            firstName: form.firstName,
            lastName: form.lastName,
            email: form.email,
            password: form.password,
            confirmPassword: form.confirmPassword
        });

        successMessage.value = 'Kayıt başarılı! Giriş sayfasına yönlendiriliyorsunuz...';
        
        toast.add({
            severity: 'success',
            summary: 'Başarılı',
            detail: 'Kayıt işlemi tamamlandı',
            life: 3000
        });

        setTimeout(() => {
            router.push({ name: 'login' });
        }, 2000);
    } catch (error) {
        console.error('Register error:', error);
        const errorData = error?.response?.data;
        if (errorData?.errors) {
            // Validation hatalarını göster
            const errorMessages = Object.values(errorData.errors).flat().join(', ');
            errorMessage.value = `Hata: ${errorMessages}`;
        } else {
            errorMessage.value = errorData?.message || error?.response?.data?.error || 'Kayıt işlemi başarısız. Lütfen tekrar deneyin.';
        }
    } finally {
        loading.value = false;
    }
}
</script>

<style scoped>
.register-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    padding: 1rem;
}

.register-card {
    background: white;
    border-radius: 12px;
    padding: 2rem;
    width: 100%;
    max-width: 450px;
    box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
    max-height: 90vh;
    overflow-y: auto;
}

.register-header {
    text-align: center;
    margin-bottom: 2rem;
}

.register-header h1 {
    font-size: 2rem;
    color: #667eea;
    margin-bottom: 0.5rem;
}

.register-header p {
    color: #6b7280;
    font-size: 1rem;
}

.register-form {
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

.error-message,
.success-message {
    margin-top: -0.5rem;
}

.login-link {
    text-align: center;
    margin-top: 1rem;
    color: #6b7280;
}

.login-link a {
    color: #667eea;
    text-decoration: none;
    font-weight: 500;
}

.login-link a:hover {
    text-decoration: underline;
}
</style>

