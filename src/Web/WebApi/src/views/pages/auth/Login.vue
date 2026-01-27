<script setup>
import { ref } from 'vue';
import { useAuthStore } from '@/stores/auth';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import axios from 'axios';

const email = ref('');
const password = ref('');
const loading = ref(false);
const errorMsg = ref('');
const router = useRouter();
const auth = useAuthStore();
const toast = useToast();

const showRegisterDialog = ref(false);
const registerEmail = ref('');
const registerPassword = ref('');
const registerPasswordAgain = ref('');
const registerPartyType = ref(1); // 0=None, 1=Person, 2=Organization
const registerError = ref('');
const registerLoading = ref(false);

const partyTypeOptions = [
    { label: 'Yok', value: 0 },
    { label: 'Kişi', value: 1 },
    { label: 'Organizasyon', value: 2 }
];

function getLoginError(err) {
    const d = err?.response?.data;
    if (!d) return 'Email ya da şifre hatalı.';
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
    if (o.error === 'invalid_grant') return 'Email ya da şifre hatalı.';
    return o.error_description || o.error || 'Email ya da şifre hatalı.';
}

async function onLogin() {
    errorMsg.value = '';
    const e = (email.value || '').trim();
    const p = password.value || '';
    if (!e || !p) {
        errorMsg.value = 'E-posta ve şifre gerekli.';
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
        router.push({ name: 'dashboard' });
    } catch (err) {
        errorMsg.value = getLoginError(err);
    } finally {
        loading.value = false;
    }
}

function openRegister() {
    showRegisterDialog.value = true;
    registerEmail.value = '';
    registerPassword.value = '';
    registerPasswordAgain.value = '';
    registerPartyType.value = 1;
    registerError.value = '';
}

function closeRegister() {
    showRegisterDialog.value = false;
    registerError.value = '';
}

async function onRegister() {
    registerError.value = '';
    const e = (registerEmail.value || '').trim();
    const p = registerPassword.value || '';
    const p2 = registerPasswordAgain.value || '';
    if (!e) {
        registerError.value = 'E-posta gerekli.';
        return;
    }
    if (!p) {
        registerError.value = 'Şifre gerekli.';
        return;
    }
    if (p !== p2) {
        registerError.value = 'Şifreler eşleşmiyor.';
        return;
    }
    if (p.length < 6) {
        registerError.value = 'Şifre en az 6 karakter olmalı.';
        return;
    }
    registerLoading.value = true;
    try {
        await axios.post('/identity/account/register', { email: e, password: p, partyType: registerPartyType.value }, { headers: { 'Content-Type': 'application/json' } });
        toast.add({
            severity: 'success',
            summary: 'Hesap oluşturuldu',
            detail: 'Giriş yapabilirsiniz.',
            life: 4000
        });
        closeRegister();
    } catch (err) {
        const d = err?.response?.data;
        let msg = d?.error;
        if (!msg && d?.errors && typeof d.errors === 'object') {
            const first = Object.values(d.errors)?.[0];
            msg = Array.isArray(first) ? first[0] : first;
        }
        if (!msg && typeof d === 'string') msg = d;
        registerError.value = msg || 'Kayıt yapılamadı.';
    } finally {
        registerLoading.value = false;
    }
}
</script>

<template>
    <div class="bg-surface-50 dark:bg-surface-950 flex items-center justify-center min-h-screen min-w-[100vw] overflow-hidden">
        <div class="flex flex-col items-center justify-center">
            <div class="rounded-[56px] p-[0.3rem]" style="background: linear-gradient(180deg, var(--primary-color) 10%, rgba(33, 150, 243, 0) 30%)">
                <div class="w-full bg-surface-0 dark:bg-surface-900 py-20 px-8 sm:px-20 rounded-[53px]">
                    <div class="text-center mb-8">
                        <div class="text-surface-900 dark:text-surface-0 text-3xl font-medium mb-4">Artemis WebApi</div>
                    </div>
                    <div>
                        <label for="email1" class="block text-surface-900 dark:text-surface-0 text-xl font-medium mb-2"> E-posta </label>
                        <InputText id="email1" type="text" placeholder="E-posta adresi" class="w-full md:w-[30rem] mb-8" v-model="email" />
                        <label for="password1" class="block text-surface-900 dark:text-surface-0 font-medium text-xl mb-2"> Şifre </label>
                        <Password id="password1" v-model="password" placeholder="Şifre" :toggle-mask="true" class="mb-4" fluid :feedback="false" />
                        <div v-if="errorMsg" class="mb-4">
                            <small class="text-red-500">{{ errorMsg }}</small>
                        </div>
                        <div class="mt-4 flex flex-col gap-3">
                            <Button label="Giriş Yap" class="w-full" :loading="loading" @click="onLogin" />
                            <Button label="Yeni kişi oluştur" severity="secondary" class="w-full" outlined @click="openRegister" />
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <Dialog :visible="showRegisterDialog" header="Yeni kişi oluştur" @update:visible="(v) => (showRegisterDialog = v)" modal :style="{ width: '28rem' }" :closable="!registerLoading" :close-on-escape="!registerLoading" @hide="closeRegister">
            <div class="flex flex-col gap-4">
                <div>
                    <label for="reg-email" class="block font-medium mb-2">E-posta</label>
                    <InputText id="reg-email" v-model="registerEmail" type="email" placeholder="E-posta adresi" class="w-full" />
                </div>
                <div>
                    <label for="reg-pw" class="block font-medium mb-2">Şifre</label>
                    <Password id="reg-pw" v-model="registerPassword" placeholder="En az 6 karakter; büyük, küçük harf ve rakam" :toggle-mask="true" fluid :feedback="true" />
                </div>
                <div>
                    <label for="reg-pw2" class="block font-medium mb-2">Şifre (tekrar)</label>
                    <Password id="reg-pw2" v-model="registerPasswordAgain" placeholder="Şifreyi tekrar girin" :toggle-mask="true" fluid :feedback="false" />
                </div>
                <div>
                    <label for="reg-party-type" class="block font-medium mb-2">Tip</label>
                    <SelectButton id="reg-party-type" v-model="registerPartyType" :options="partyTypeOptions" option-label="label" option-value="value" aria-labelledby="reg-party-type" />
                </div>
                <div v-if="registerError" class="text-red-500 text-sm">
                    {{ registerError }}
                </div>
            </div>
            <template #footer>
                <Button label="İptal" severity="secondary" outlined @click="closeRegister" :disabled="registerLoading" />
                <Button label="Oluştur" :loading="registerLoading" @click="onRegister" />
            </template>
        </Dialog>

        <Toast />
    </div>
</template>

<style scoped>
.pi-eye,
.pi-eye-slash {
    transform: scale(1.6);
    margin-right: 1rem;
}
</style>
