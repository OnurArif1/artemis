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
const displayName = ref('');
const username = ref('');
const registerEmail = ref('');
const registerPassword = ref('');
const registerPasswordAgain = ref('');
const registerPartyType = ref(1); // 0=None, 1=Person, 2=Organization
const registerError = ref('');
const registerLoading = ref(false);

const partyTypeOptions = computed(() => [
    { label: t('auth.partyTypeNone'), value: 0 },
    { label: t('auth.partyTypePerson'), value: 1 },
    { label: t('auth.partyTypeOrganization'), value: 2 }
]);

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
    const displayNameValue = (displayName.value || '').trim();
    const usernameValue = (username.value || '').trim();
    
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
        // Prepare register request with all form fields
        // Backend expects: Email, Password, PartyName, PartyType, DeviceId, IsBanned
        const registerData = {
            Email: e,
            Password: p,
            PartyName: displayNameValue || usernameValue || null,
            PartyType: registerPartyType.value,
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
    <div class="login-page min-h-screen flex items-center justify-center p-6">
        <!-- Background Pattern -->
        <div class="absolute inset-0 bg-gradient-to-br from-orange-50 via-white to-orange-50 opacity-50"></div>
        <div class="absolute inset-0 bg-[radial-gradient(circle_at_30%_20%,rgba(255,140,0,0.1),transparent_50%)]"></div>
        
        <div class="relative w-full max-w-md">
            <!-- Card Container -->
            <div class="bg-white rounded-2xl shadow-2xl p-8 md:p-10 border border-gray-100">
                <!-- Logo -->
                <div class="flex items-center gap-2 mb-10 justify-center">
                    <div class="p-2 bg-orange-100 rounded-xl">
                        <i class="pi pi-map-marker text-2xl text-[#FF8C00]"></i>
                    </div>
                    <span class="text-3xl font-bold text-gray-900">Ghossip</span>
                </div>

                <!-- Title -->
                <h1 v-if="!isRegisterMode" class="text-4xl font-bold text-gray-900 mb-10 text-center">
                    {{ t('auth.loginTitle') }}
                </h1>

                <!-- Login Form -->
                <form v-if="!isRegisterMode" @submit.prevent="onLogin" class="space-y-6">
                    <div>
                        <label for="email" class="block text-sm font-semibold text-gray-800 mb-3">
                            {{ t('auth.email') }}
                        </label>
                        <div class="relative group">
                            <InputText 
                                id="email"
                                v-model="email" 
                                type="email" 
                                :placeholder="t('auth.emailPlaceholder')" 
                                class="custom-input w-full pl-12 pr-4 py-3.5 bg-gray-800 text-white border-0 rounded-xl placeholder-gray-400 focus:ring-2 focus:ring-orange-500 focus:ring-offset-2 transition-all"
                            />
                        </div>
                    </div>

                    <div>
                        <label for="password" class="block text-sm font-semibold text-gray-800 mb-3">
                            {{ t('auth.password') }}
                        </label>
                        <div class="relative group">
                            <Password 
                                id="password"
                                v-model="password" 
                                :placeholder="t('auth.passwordPlaceholder')" 
                                :toggle-mask="true" 
                                inputClass="custom-input w-full pl-12 pr-14 py-3.5 bg-gray-800 text-white border-0 rounded-xl placeholder-gray-400 focus:ring-2 focus:ring-orange-500 focus:ring-offset-2 transition-all"
                                class="w-full"
                                :feedback="false"
                            />
                        </div>
                    </div>

                    <div v-if="errorMsg" class="p-3 bg-red-50 border border-red-200 rounded-xl text-red-600 text-sm">
                        {{ errorMsg }}
                    </div>

                    <Button 
                        type="submit"
                        :label="t('auth.login')" 
                        :loading="loading"
                        class="w-full !bg-gradient-to-r !from-[#FF8C00] !to-[#FF7A00] hover:!from-[#FF7A00] hover:!to-[#FF6A00] !text-white !py-3.5 !rounded-xl !font-semibold !text-base !shadow-lg hover:!shadow-xl !transition-all !transform hover:!scale-[1.02]"
                    />

                    <div class="text-center text-sm text-gray-600 pt-2">
                        {{ t('auth.noAccount') }}
                        <button type="button" @click="toggleMode" class="text-[#FF8C00] hover:text-[#FF7A00] font-semibold ml-1 transition-colors">
                            {{ t('auth.signUp') }}
                        </button>
                    </div>
                </form>

                <!-- Register Form -->
                <form v-else @submit.prevent="onRegister" class="space-y-6">
                    <div>
                        <label for="displayName" class="block text-sm font-semibold text-gray-800 mb-3">
                            {{ t('auth.displayName') }}
                        </label>
                        <div class="relative group">
                            <InputText 
                                id="displayName"
                                v-model="displayName" 
                                :placeholder="t('auth.displayNamePlaceholder')" 
                                class="custom-input w-full pl-12 pr-4 py-3.5 bg-gray-800 text-white border-0 rounded-xl placeholder-gray-400 focus:ring-2 focus:ring-orange-500 focus:ring-offset-2 transition-all"
                            />
                        </div>
                    </div>

                    <div>
                        <label for="username" class="block text-sm font-semibold text-gray-800 mb-3">
                            {{ t('auth.username') }}
                        </label>
                        <div class="relative group">
                            <InputText 
                                id="username"
                                v-model="username" 
                                :placeholder="t('auth.usernamePlaceholder')" 
                                class="custom-input w-full pl-12 pr-4 py-3.5 bg-gray-800 text-white border-0 rounded-xl placeholder-gray-400 focus:ring-2 focus:ring-orange-500 focus:ring-offset-2 transition-all"
                            />
                        </div>
                    </div>

                    <div>
                        <label for="reg-email" class="block text-sm font-semibold text-gray-800 mb-3">
                            {{ t('auth.email') }}
                        </label>
                        <div class="relative group">
                            <InputText 
                                id="reg-email"
                                v-model="registerEmail" 
                                type="email" 
                                :placeholder="t('auth.emailPlaceholder')" 
                                class="custom-input w-full pl-12 pr-4 py-3.5 bg-gray-800 text-white border-0 rounded-xl placeholder-gray-400 focus:ring-2 focus:ring-orange-500 focus:ring-offset-2 transition-all"
                            />
                        </div>
                    </div>

                    <div>
                        <label for="reg-password" class="block text-sm font-semibold text-gray-800 mb-3">
                            {{ t('auth.password') }}
                        </label>
                        <div class="relative group">
                            <Password 
                                id="reg-password"
                                v-model="registerPassword" 
                                :placeholder="t('auth.passwordHint')" 
                                :toggle-mask="true" 
                                inputClass="custom-input w-full pl-12 pr-14 py-3.5 bg-gray-800 text-white border-0 rounded-xl placeholder-gray-400 focus:ring-2 focus:ring-orange-500 focus:ring-offset-2 transition-all"
                                class="w-full"
                                :feedback="true"
                            />
                        </div>
                    </div>

                    <div>
                        <label for="reg-password-again" class="block text-sm font-semibold text-gray-800 mb-3">
                            {{ t('auth.password') }} ({{ t('auth.passwordRepeat') }})
                        </label>
                        <div class="relative group">
                            <Password 
                                id="reg-password-again"
                                v-model="registerPasswordAgain" 
                                :placeholder="t('auth.passwordRepeatPlaceholder')" 
                                :toggle-mask="true" 
                                inputClass="custom-input w-full pl-12 pr-14 py-3.5 bg-gray-800 text-white border-0 rounded-xl placeholder-gray-400 focus:ring-2 focus:ring-orange-500 focus:ring-offset-2 transition-all"
                                class="w-full"
                                :feedback="false"
                            />
                        </div>
                    </div>

                    <div>
                        <label for="reg-party-type" class="block text-sm font-semibold text-gray-800 mb-3">
                            {{ t('auth.type') }}
                        </label>
                        <SelectButton 
                            id="reg-party-type" 
                            v-model="registerPartyType" 
                            :options="partyTypeOptions" 
                            optionLabel="label" 
                            optionValue="value"
                            class="w-full"
                        />
                    </div>

                    <div v-if="registerError" class="p-3 bg-red-50 border border-red-200 rounded-xl text-red-600 text-sm">
                        {{ registerError }}
                    </div>

                    <Button 
                        type="submit"
                        :label="t('auth.createAccount')" 
                        :loading="registerLoading"
                        class="w-full !bg-gradient-to-r !from-[#FF8C00] !to-[#FF7A00] hover:!from-[#FF7A00] hover:!to-[#FF6A00] !text-white !py-3.5 !rounded-xl !font-semibold !text-base !shadow-lg hover:!shadow-xl !transition-all !transform hover:!scale-[1.02]"
                    />

                    <div class="text-center text-sm text-gray-600 pt-2">
                        {{ t('auth.haveAccount') }}
                        <button type="button" @click="toggleMode" class="text-[#FF8C00] hover:text-[#FF7A00] font-semibold ml-1 transition-colors">
                            {{ t('auth.signIn') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <Toast />
    </div>
</template>

<style scoped>
.login-page {
    position: relative;
    background: linear-gradient(135deg, #fff5e6 0%, #ffffff 50%, #fff5e6 100%);
}

.custom-input {
    background-color: #1f2937 !important;
    color: white !important;
    border: none !important;
    transition: all 0.2s ease;
}

.custom-input::placeholder {
    color: #9ca3af !important;
}

.custom-input:focus {
    outline: none;
    box-shadow: 0 0 0 2px rgba(255, 140, 0, 0.5);
    transform: translateY(-1px);
}

.custom-input:hover {
    background-color: #374151 !important;
}

:deep(.p-password-input) {
    width: 100%;
    background-color: #1f2937 !important;
    color: white !important;
    transition: all 0.2s ease;
}

:deep(.p-password-input:hover) {
    background-color: #374151 !important;
}

:deep(.p-password-input::placeholder) {
    color: #9ca3af !important;
}

:deep(.p-password-panel) {
    padding: 0.75rem;
    background: white;
    border-radius: 0.75rem;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
}

:deep(.p-password-toggle-icon) {
    color: white !important;
    right: 1rem !important;
    transition: color 0.2s ease;
}

:deep(.p-password-toggle-icon:hover) {
    color: #FF8C00 !important;
}

:deep(.p-checkbox .p-checkbox-box) {
    border-radius: 0.375rem;
    border-color: #d1d5db;
    transition: all 0.2s ease;
}

:deep(.p-checkbox .p-checkbox-box.p-highlight) {
    background: #FF8C00;
    border-color: #FF8C00;
}

:deep(.p-selectbutton .p-button) {
    border-radius: 0.75rem;
    padding: 0.875rem 1.25rem;
    border-color: #d1d5db;
    transition: all 0.2s ease;
}

:deep(.p-selectbutton .p-button:hover) {
    transform: translateY(-1px);
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

:deep(.p-selectbutton .p-button.p-highlight) {
    background: linear-gradient(135deg, #FF8C00, #FF7A00);
    border-color: #FF8C00;
    color: white;
    box-shadow: 0 4px 12px rgba(255, 140, 0, 0.3);
}
</style>
