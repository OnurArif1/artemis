<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useI18n } from '@/composables/useI18n';
import { useAuthStore } from '@/stores/auth';
import request from '@/service/request';
import PartyService from '@/service/PartyService';
import { getEmailFromToken } from '@/utils/jwt';

const router = useRouter();
const { t } = useI18n();
const toast = useToast();
const authStore = useAuthStore();
const partyService = new PartyService(request);

const fullName = ref('');
const bio = ref('');
const saving = ref(false);

const saveProfile = async () => {
    if (!fullName.value.trim()) {
        toast.add({
            severity: 'warn',
            summary: 'Uyarı',
            detail: 'Tam ad alanı zorunludur.',
            life: 3000
        });
        return;
    }

    // Get email from JWT token
    const token = authStore.token || localStorage.getItem('auth.token');
    const email = getEmailFromToken(token);
    
    if (!email) {
        toast.add({
            severity: 'error',
            summary: 'Hata',
            detail: 'Kullanıcı bilgileri bulunamadı. Lütfen tekrar giriş yapın.',
            life: 5000
        });
        return;
    }

    saving.value = true;
    try {
        await partyService.updateProfile(email, fullName.value.trim(), bio.value.trim() || null);
        toast.add({
            severity: 'success',
            summary: 'Başarılı',
            detail: 'Profil bilgileriniz kaydedildi.',
            life: 3000
        });
        router.push({ name: 'room' });
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || 'Profil bilgileri kaydedilirken bir hata oluştu.',
            life: 5000
        });
    } finally {
        saving.value = false;
    }
};

onMounted(() => {
    // Ensure auth store is hydrated from localStorage before making API calls
    authStore.hydrateFromStorage();
});
</script>

<template>
    <div class="tell-us-about-yourself-page min-h-screen flex items-center justify-center p-6">
        <!-- Pembe-mor degrade arka plan -->
        <div class="absolute inset-0 bg-gradient-to-br from-pink-500 via-purple-500 to-purple-600"></div>
        
        <!-- İlerleme çubuğu -->
        <div class="absolute top-0 left-0 right-0 h-1 bg-gray-300">
            <div class="h-full bg-gradient-to-r from-pink-500 to-purple-500" style="width: 30%"></div>
        </div>

        <div class="relative w-full max-w-2xl mt-8">
            <!-- Beyaz kart -->
            <div class="bg-white rounded-3xl shadow-2xl overflow-hidden">
                <!-- İçerik alanı -->
                <div class="p-8 md:p-12">
                    <!-- Başlık -->
                    <div class="flex items-center gap-3 mb-6">
                        <div class="w-10 h-10 rounded-full bg-gradient-to-r from-pink-500 to-purple-500 flex items-center justify-center">
                            <i class="pi pi-user text-white text-xl"></i>
                        </div>
                        <h1 class="text-3xl font-bold text-gray-800">Bize kendinizden bahsedin</h1>
                    </div>

                    <!-- Form -->
                    <form @submit.prevent="saveProfile" class="space-y-6">
                        <!-- Full Name alanı -->
                        <div>
                            <label for="fullName" class="block text-sm font-medium text-gray-700 mb-2">
                                Tam Ad
                            </label>
                            <input
                                id="fullName"
                                v-model="fullName"
                                type="text"
                                placeholder="John Doe"
                                class="w-full px-4 py-3 bg-black border-2 border-gray-200 rounded-xl focus:outline-none focus:border-purple-500 transition-colors text-white placeholder-gray-400"
                                required
                            />
                        </div>

                        <!-- Bio alanı -->
                        <div>
                            <label for="bio" class="block text-sm font-medium text-gray-700 mb-2">
                                Bio
                            </label>
                            <textarea
                                id="bio"
                                v-model="bio"
                                rows="6"
                                placeholder="Kendiniz hakkında bir şeyler yazın..."
                                class="w-full px-4 py-3 bg-black border-2 border-gray-200 rounded-xl focus:outline-none focus:border-purple-500 transition-colors text-white placeholder-gray-400 resize-none"
                            ></textarea>
                        </div>

                        <!-- Devam Et butonu -->
                        <button
                            type="submit"
                            :disabled="saving || !fullName.trim()"
                            class="w-full py-4 bg-gradient-to-r from-pink-500 via-purple-500 to-purple-600 text-white font-semibold rounded-xl shadow-lg hover:shadow-xl transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed transform hover:scale-[1.02]"
                        >
                            <span v-if="!saving">Devam Et</span>
                            <span v-else class="flex items-center justify-center gap-2">
                                <i class="pi pi-spin pi-spinner"></i>
                                Kaydediliyor...
                            </span>
                        </button>
                    </form>
                </div>
            </div>
        </div>

        <Toast />
    </div>
</template>

<style scoped>
.tell-us-about-yourself-page {
    position: relative;
}
</style>
