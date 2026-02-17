<script setup>
import { ref, computed } from 'vue';
import { useAuthStore } from '@/stores/auth';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useI18n } from '@/composables/useI18n';
import axios from 'axios';

const { t } = useI18n();
const email = ref('');
const password = ref('');
const loading = ref(false);
const errorMsg = ref('');
const router = useRouter();
const auth = useAuthStore();
const toast = useToast();

// Register form state
const isRegisterMode = ref(false);
const registerEmail = ref('');
const registerPassword = ref('');
const registerPasswordAgain = ref('');
const registerError = ref('');
const registerLoading = ref(false);

// Password validation rules
const passwordRules = computed(() => {
    const p = registerPassword.value || '';
    return {
        minLength: p.length >= 6,
        hasUppercase: /[A-Z]/.test(p),
        hasLowercase: /[a-z]/.test(p),
        hasNumber: /[0-9]/.test(p),
        passwordsMatch: p === registerPasswordAgain.value && p.length > 0
    };
});

const isPasswordValid = computed(() => {
    return passwordRules.value.minLength && 
           passwordRules.value.hasUppercase && 
           passwordRules.value.hasLowercase && 
           passwordRules.value.hasNumber &&
           passwordRules.value.passwordsMatch;
});

const canSubmitRegister = computed(() => {
    return registerEmail.value.trim() && 
           isPasswordValid.value && 
           !registerLoading.value;
});


function getLoginError(err) {
    const d = err?.response?.data;
    if (!d) return t('auth.emailPasswordError');
    const o =
        typeof d === 'string'
            ? (() => {
                  try {
                      return JSON.parse(d);
                  } catch {
                      return {};
                  }
              })()
            : d;
    if (o.error === 'invalid_grant') return t('auth.emailPasswordError');
    return o.error_description || o.error || t('auth.emailPasswordError');
}

async function onLogin() {
    errorMsg.value = '';
    const e = (email.value || '').trim();
    const p = password.value || '';
    if (!e || !p) {
        errorMsg.value = t('auth.emailPasswordRequired');
        return;
    }
    loading.value = true;
    try {
        const form = new URLSearchParams();
        form.append('grant_type', 'password');
        form.append('client_id', 'artemis.client');
        form.append('client_secret', 'artemis_secret');
        form.append('username', e);
        form.append('password', p);
        form.append('scope', 'openid profile email roles artemis.api');

        const tokenUrl = import.meta.env.VITE_IDENTITY_TOKEN_URL;
        console.log('token', tokenUrl);
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
        
        // Hemen yönlendir, confetti RoomMap sayfasında gösterilecek
        router.push({ name: 'room' });
    } catch (err) {
        errorMsg.value = getLoginError(err);
    } finally {
        loading.value = false;
    }
}

function toggleMode() {
    isRegisterMode.value = !isRegisterMode.value;
    errorMsg.value = '';
    registerError.value = '';
}

async function onRegister() {
    registerError.value = '';
    const e = (registerEmail.value || '').trim();
    const p = registerPassword.value || '';
    const p2 = registerPasswordAgain.value || '';
    
    if (!e) {
        registerError.value = t('auth.emailRequired');
        return;
    }
    if (!p) {
        registerError.value = t('auth.passwordRequired');
        return;
    }
    if (p !== p2) {
        registerError.value = t('auth.passwordsNotMatch');
        return;
    }
    if (p.length < 6) {
        registerError.value = t('auth.passwordMinLength');
        return;
    }
    registerLoading.value = true;
    try {
        // Prepare register request
        // Backend expects: Email, Password, PartyName, PartyType, DeviceId, IsBanned
        // Default PartyType to 1 (Person)
        const registerData = {
            Email: e,
            Password: p,
            PartyName: e, // Use email as PartyName
            PartyType: 1, // Default to Person
            DeviceId: null, // Optional - can be set later if needed
            IsBanned: false // Default to false for new registrations
        };
        
        await axios.post('/identity/account/register', registerData, { headers: { 'Content-Type': 'application/json' } });
        
        // Register başarılı olduktan sonra otomatik login yap
        try {
            const form = new URLSearchParams();
            form.append('grant_type', 'password');
            form.append('client_id', 'artemis.client');
            form.append('client_secret', 'artemis_secret');
            form.append('username', e);
            form.append('password', p);
            form.append('scope', 'openid profile email roles artemis.api');

            const tokenUrl = import.meta.env.VITE_IDENTITY_TOKEN_URL;
            const resp = await axios.post(tokenUrl, form, {
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
            });

            const accessToken = resp?.data?.access_token;
            const expiresIn = resp?.data?.expires_in;
            if (accessToken) {
                // Store token in localStorage
                localStorage.setItem('auth.token', accessToken);
                if (expiresIn) {
                    localStorage.setItem('auth.expiresAt', (Date.now() + Number(expiresIn) * 1000).toString());
                }
                
                // Set token in axios defaults
                axios.defaults.headers.common['Authorization'] = `Bearer ${accessToken}`;
                
                // Set token in auth store
                if (auth.setToken) {
                    auth.setToken(accessToken, expiresIn ? Number(expiresIn) : undefined);
                }
                
                // Verify token is stored before redirecting
                const storedToken = localStorage.getItem('auth.token');
                if (!storedToken) {
                    throw new Error('Token could not be stored');
                }
                
                // İlgi alanları seçim sayfasına yönlendir
                router.push({ name: 'selectInterests' });
            } else {
                throw new Error('Invalid login response');
            }
        } catch (loginErr) {
            // Otomatik login başarısız olursa, kullanıcıyı login sayfasında bırak
            toast.add({
                severity: 'success',
                summary: t('auth.accountCreated'),
                detail: 'Hesabınız oluşturuldu. Lütfen giriş yapın.',
                life: 4000
            });
            setTimeout(() => {
                isRegisterMode.value = false;
                email.value = e;
            }, 1000);
        }
    } catch (err) {
        const d = err?.response?.data;
        let msg = d?.error;
        if (!msg && d?.errors && typeof d.errors === 'object') {
            const first = Object.values(d.errors)?.[0];
            msg = Array.isArray(first) ? first[0] : first;
        }
        if (!msg && typeof d === 'string') msg = d;
        registerError.value = msg || t('auth.registerFailed');
    } finally {
        registerLoading.value = false;
    }
}

</script>

<template>
    <div class="login-page min-h-screen flex">
        <!-- Logo - Top Left -->
        <div class="logo-top-left">
            <div class="logo-badge">
                <i class="pi pi-map-marker text-electric-purple text-xl"></i>
                <span class="text-lg font-bold text-dark-charcoal ml-2">Ghossip</span>
            </div>
        </div>
        
        <!-- Left Panel - Login Form -->
        <div class="login-left-panel">
            <div class="login-content-wrapper">

                <!-- Login Form -->
                <form v-if="!isRegisterMode" @submit.prevent="onLogin" class="login-form">
                    <div class="form-group">
                        <label for="email" class="form-label">
                            {{ t('auth.email') }}
                        </label>
                        <InputText 
                            id="email"
                            v-model="email" 
                            type="email" 
                            :placeholder="t('auth.emailPlaceholder')" 
                            class="form-input"
                        />
                    </div>

                    <div class="form-group">
                        <label for="password" class="form-label">
                            {{ t('auth.password') }}
                        </label>
                        <Password 
                            id="password"
                            v-model="password" 
                            :placeholder="t('auth.passwordPlaceholder')" 
                            :toggle-mask="true" 
                            inputClass="form-input"
                            class="w-full"
                            :feedback="false"
                        />
                    </div>

                    <div v-if="errorMsg" class="error-message">
                        {{ errorMsg }}
                    </div>

                    <Button 
                        type="submit"
                        :label="t('auth.login')" 
                        :loading="loading"
                        class="submit-button"
                    />

                    <div class="form-footer">
                        <span class="text-gray-600">{{ t('auth.noAccount') }}</span>
                        <button type="button" @click="toggleMode" class="footer-link">
                            {{ t('auth.signUp') }}
                        </button>
                    </div>
                </form>

                <!-- Register Form -->
                <form v-else @submit.prevent="onRegister" class="login-form">
                    <div class="form-group">
                        <label for="reg-email" class="form-label">
                            {{ t('auth.email') }}
                        </label>
                        <InputText 
                            id="reg-email"
                            v-model="registerEmail" 
                            type="email" 
                            :placeholder="t('auth.emailPlaceholder')" 
                            class="form-input"
                        />
                    </div>

                    <div class="form-group">
                        <label for="reg-password" class="form-label">
                            {{ t('auth.password') }}
                        </label>
                        
                        <!-- Password Rules -->
                        <div class="password-rules">
                            <div class="rule-item" :class="{ 'rule-valid': passwordRules.minLength }">
                                <i :class="passwordRules.minLength ? 'pi pi-check-circle' : 'pi pi-circle'" 
                                   class="rule-icon"></i>
                                <span>En az 6 karakter</span>
                            </div>
                            <div class="rule-item" :class="{ 'rule-valid': passwordRules.hasUppercase }">
                                <i :class="passwordRules.hasUppercase ? 'pi pi-check-circle' : 'pi pi-circle'" 
                                   class="rule-icon"></i>
                                <span>En az bir büyük harf</span>
                            </div>
                            <div class="rule-item" :class="{ 'rule-valid': passwordRules.hasLowercase }">
                                <i :class="passwordRules.hasLowercase ? 'pi pi-check-circle' : 'pi pi-circle'" 
                                   class="rule-icon"></i>
                                <span>En az bir küçük harf</span>
                            </div>
                            <div class="rule-item" :class="{ 'rule-valid': passwordRules.hasNumber }">
                                <i :class="passwordRules.hasNumber ? 'pi pi-check-circle' : 'pi pi-circle'" 
                                   class="rule-icon"></i>
                                <span>En az bir rakam</span>
                            </div>
                        </div>
                        
                        <Password 
                            id="reg-password"
                            v-model="registerPassword" 
                            :placeholder="t('auth.passwordHint')" 
                            :toggle-mask="true" 
                            inputClass="form-input"
                            class="w-full"
                            :feedback="false"
                        />
                    </div>

                    <div class="form-group">
                        <label for="reg-password-again" class="form-label">
                            {{ t('auth.password') }} ({{ t('auth.passwordRepeat') }})
                        </label>
                        <Password 
                            id="reg-password-again"
                            v-model="registerPasswordAgain" 
                            :placeholder="t('auth.passwordRepeatPlaceholder')" 
                            :toggle-mask="true" 
                            inputClass="form-input"
                            :class="['w-full', { 'password-mismatch': registerPasswordAgain && !passwordRules.passwordsMatch }]"
                            :feedback="false"
                        />
                        <div v-if="registerPasswordAgain && !passwordRules.passwordsMatch" class="password-error-text">
                            Şifreler eşleşmiyor
                        </div>
                    </div>

                    <div v-if="registerError" class="error-message">
                        {{ registerError }}
                    </div>

                    <Button 
                        type="submit"
                        :label="t('auth.createAccount')" 
                        :loading="registerLoading"
                        :disabled="!canSubmitRegister"
                        class="submit-button"
                    />

                    <div class="form-footer">
                        <span class="text-gray-600">{{ t('auth.haveAccount') }}</span>
                        <button type="button" @click="toggleMode" class="footer-link">
                            {{ t('auth.signIn') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Right Panel - Visual Background -->
        <div class="login-right-panel">
            <div class="right-panel-content">
                <!-- Decorative Elements -->
                <div class="floating-card card-1">
                    <div class="card-header">
                        <div class="card-dot"></div>
                        <span class="card-title">Topluluk Buluşması</span>
                    </div>
                    <div class="card-time">09:30 - 10:00</div>
                </div>

                <div class="floating-card card-2">
                    <div class="card-header">
                        <div class="card-dot"></div>
                        <span class="card-title">Günlük Toplantı</span>
                    </div>
                    <div class="card-time">12:00 - 13:00</div>
                    <div class="card-avatars">
                        <div class="avatar"></div>
                        <div class="avatar"></div>
                        <div class="avatar"></div>
                        <div class="avatar"></div>
                    </div>
                </div>

                <!-- Calendar -->
                <div class="calendar-widget">
                    <div class="calendar-header">
                        <span>Pzt</span>
                        <span>Sal</span>
                        <span>Çar</span>
                        <span>Per</span>
                        <span>Cum</span>
                        <span>Cmt</span>
                        <span>Paz</span>
                    </div>
                    <div class="calendar-dates">
                        <span>22</span>
                        <span>23</span>
                        <span class="active">24</span>
                        <span>25</span>
                        <span>26</span>
                        <span>27</span>
                        <span>28</span>
                    </div>
                </div>
            </div>
        </div>

        <Toast />
    </div>
</template>

<style scoped>
.login-page {
    min-height: 100vh;
    display: flex;
    overflow: hidden;
    position: relative;
}

.logo-top-left {
    position: fixed;
    top: 2rem;
    left: 2rem;
    z-index: 100;
}

/* Left Panel - Form */
.login-left-panel {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #fafafa 0%, #ffffff 50%, #f9f9f9 100%);
    padding: 3rem;
    overflow-y: auto;
}

.login-content-wrapper {
    width: 100%;
    max-width: 480px;
}

.logo-badge {
    display: inline-flex;
    align-items: center;
    padding: 0.75rem 1.25rem;
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 0.75rem;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.login-title {
    font-size: 2.5rem;
    font-weight: 700;
    color: #1A1A1D;
    margin-bottom: 0.5rem;
    line-height: 1.2;
}

.login-subtitle {
    font-size: 1rem;
    color: #6b7280;
    font-weight: 400;
}

.login-form {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
    margin-top: 2rem;
}

.form-group {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}

.form-label {
    font-size: 0.875rem;
    font-weight: 600;
    color: #1A1A1D;
}

.form-input {
    width: 100% !important;
    padding: 1rem 1.25rem !important;
    background: white !important;
    color: #1A1A1D !important;
    border: 1.5px solid #e5e7eb !important;
    border-radius: 0.75rem !important;
    font-size: 0.9375rem !important;
    transition: all 0.3s ease !important;
}

.form-input::placeholder {
    color: #9ca3af !important;
}

.form-input:hover {
    border-color: rgba(99, 0, 255, 0.3) !important;
}

.form-input:focus {
    outline: none !important;
    border-color: #6300FF !important;
    box-shadow: 0 0 0 3px rgba(99, 0, 255, 0.1) !important;
}

.submit-button {
    width: 100% !important;
    background: linear-gradient(135deg, #6300FF, #5200CC) !important;
    color: white !important;
    padding: 1rem 2rem !important;
    border-radius: 0.75rem !important;
    font-weight: 600 !important;
    font-size: 1rem !important;
    border: none !important;
    box-shadow: 0 4px 15px rgba(99, 0, 255, 0.3) !important;
    transition: all 0.3s ease !important;
}

.submit-button:hover:not(:disabled) {
    transform: translateY(-2px) !important;
    box-shadow: 0 6px 20px rgba(99, 0, 255, 0.4) !important;
}

.submit-button:disabled {
    opacity: 0.5 !important;
    cursor: not-allowed !important;
    transform: none !important;
}


.form-footer {
    text-align: center;
    font-size: 0.875rem;
    margin-top: 1rem;
}

.footer-link {
    color: #6300FF;
    font-weight: 600;
    margin-left: 0.25rem;
    transition: color 0.3s ease;
    background: none;
    border: none;
    cursor: pointer;
}

.footer-link:hover {
    color: #5200CC;
}

.error-message {
    padding: 0.875rem 1rem;
    background: #fef2f2;
    border: 1px solid #fecaca;
    border-radius: 0.75rem;
    color: #dc2626;
    font-size: 0.875rem;
}

/* Password Input Styles */
:deep(.p-password-input) {
    width: 100% !important;
    padding: 1rem 3rem 1rem 1.25rem !important;
    background: white !important;
    color: #1A1A1D !important;
    border: 1.5px solid #e5e7eb !important;
    border-radius: 0.75rem !important;
    font-size: 0.9375rem !important;
    transition: all 0.3s ease !important;
}

:deep(.p-password-input:hover) {
    border-color: rgba(99, 0, 255, 0.3) !important;
}

:deep(.p-password-input:focus) {
    outline: none !important;
    border-color: #6300FF !important;
    box-shadow: 0 0 0 3px rgba(99, 0, 255, 0.1) !important;
}

:deep(.p-password-input::placeholder) {
    color: #9ca3af !important;
}

/* Password Rules */
.password-rules {
    background: #f9fafb;
    border: 1px solid rgba(99, 0, 255, 0.1);
    border-radius: 0.75rem;
    padding: 1rem;
    margin-bottom: 0.75rem;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}

.rule-item {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    font-size: 0.875rem;
    color: #6b7280;
    transition: all 0.3s ease;
}

.rule-item .rule-icon {
    font-size: 1rem;
    color: #d1d5db;
    transition: all 0.3s ease;
    flex-shrink: 0;
}

.rule-item.rule-valid {
    color: #1A1A1D;
}

.rule-item.rule-valid .rule-icon {
    color: #6300FF;
}

.password-error-text {
    margin-top: 0.5rem;
    font-size: 0.8125rem;
    color: #dc2626;
}

.password-mismatch :deep(.p-password-input) {
    border-color: #dc2626 !important;
}

:deep(.p-password-toggle-icon) {
    color: #6b7280 !important;
    right: 1rem !important;
    transition: all 0.3s ease !important;
}

:deep(.p-password-toggle-icon:hover) {
    color: #6300FF !important;
}

/* Right Panel - Visual */
.login-right-panel {
    flex: 1;
    background: linear-gradient(135deg, #6300FF 0%, #5200CC 50%, #4100AA 100%);
    position: relative;
    overflow: hidden;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 3rem;
}

.login-right-panel::before {
    content: '';
    position: absolute;
    inset: 0;
    background: 
        radial-gradient(circle at 20% 30%, rgba(255, 255, 255, 0.1) 0%, transparent 50%),
        radial-gradient(circle at 80% 70%, rgba(255, 255, 255, 0.05) 0%, transparent 50%);
    opacity: 0.6;
}

.right-panel-content {
    position: relative;
    z-index: 1;
    width: 100%;
    max-width: 500px;
}

.floating-card {
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(10px);
    border-radius: 1rem;
    padding: 1.25rem;
    margin-bottom: 1.5rem;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.15);
    animation: float 3s ease-in-out infinite;
}

.card-1 {
    animation-delay: 0s;
}

.card-2 {
    animation-delay: 0.5s;
}

@keyframes float {
    0%, 100% {
        transform: translateY(0px);
    }
    50% {
        transform: translateY(-10px);
    }
}

.card-header {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    margin-bottom: 0.5rem;
}

.card-dot {
    width: 0.5rem;
    height: 0.5rem;
    background: #6300FF;
    border-radius: 50%;
}

.card-title {
    font-weight: 600;
    color: #1A1A1D;
    font-size: 0.9375rem;
}

.card-time {
    color: #6b7280;
    font-size: 0.875rem;
    margin-left: 1.25rem;
}

.card-avatars {
    display: flex;
    gap: -0.5rem;
    margin-top: 0.75rem;
    margin-left: 1.25rem;
}

.avatar {
    width: 2rem;
    height: 2rem;
    border-radius: 50%;
    background: linear-gradient(135deg, #6300FF, #5200CC);
    border: 2px solid white;
    margin-left: -0.5rem;
}

.avatar:first-child {
    margin-left: 0;
}

.calendar-widget {
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(10px);
    border-radius: 1rem;
    padding: 1.5rem;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.15);
}

.calendar-header {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    gap: 0.5rem;
    margin-bottom: 1rem;
    text-align: center;
    font-size: 0.75rem;
    font-weight: 600;
    color: #6b7280;
}

.calendar-dates {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    gap: 0.5rem;
    text-align: center;
}

.calendar-dates span {
    padding: 0.5rem;
    border-radius: 0.5rem;
    font-size: 0.875rem;
    color: #1A1A1D;
    transition: all 0.3s ease;
}

.calendar-dates span.active {
    background: linear-gradient(135deg, #6300FF, #5200CC);
    color: white;
    font-weight: 600;
}

/* SelectButton Styles */
:deep(.p-selectbutton .p-button) {
    border-radius: 0.75rem;
    padding: 0.875rem 1.25rem;
    border: 1.5px solid #e5e7eb;
    background: white;
    color: #1A1A1D;
    transition: all 0.3s ease;
    font-weight: 500;
}

:deep(.p-selectbutton .p-button:hover) {
    background: #fafafa;
    border-color: rgba(99, 0, 255, 0.3);
    transform: translateY(-1px);
}

:deep(.p-selectbutton .p-button.p-highlight) {
    background: linear-gradient(135deg, #6300FF, #5200CC);
    border-color: #6300FF;
    color: white;
    box-shadow: 0 4px 15px rgba(99, 0, 255, 0.3);
}

/* Responsive */
@media (max-width: 1024px) {
    .login-page {
        flex-direction: column;
    }
    
    .login-right-panel {
        display: none;
    }
    
    .login-left-panel {
        min-height: 100vh;
    }
}

@media (max-width: 640px) {
    .login-left-panel {
        padding: 2rem 1.5rem;
    }
    
    .login-title {
        font-size: 2rem;
    }
    
    .social-buttons {
        grid-template-columns: 1fr;
    }
}
</style>
