<script setup>
import BestSellingWidget from '@/components/dashboard/BestSellingWidget.vue';
import NotificationsWidget from '@/components/dashboard/NotificationsWidget.vue';
import RecentSalesWidget from '@/components/dashboard/RecentSalesWidget.vue';
import RevenueStreamWidget from '@/components/dashboard/RevenueStreamWidget.vue';
import StatsWidget from '@/components/dashboard/StatsWidget.vue';
import { getProtected, getPublic } from '@/service/TestService';
import { ref } from 'vue';

const protectedResult = ref(null);
const publicResult = ref(null);
const loading = ref(false);
const error = ref('');

async function callProtected() {
    loading.value = true;
    error.value = '';
    protectedResult.value = null;
    try {
        const data = await getProtected();
        protectedResult.value = data;
        console.log('protected response:', data);
    } catch (e) {
        error.value = e?.data?.message || e?.message || 'Request failed';
        console.error('protected error:', e);
    } finally {
        loading.value = false;
    }
}

async function callPublic() {
    loading.value = true;
    error.value = '';
    publicResult.value = null;
    try {
        const data = await getPublic();
        publicResult.value = data;
        console.log('public response:', data);
    } catch (e) {
        error.value = e?.data?.message || e?.message || 'Request failed';
        console.error('public error:', e);
    } finally {
        loading.value = false;
    }
}
</script>

<template>
    <div class="grid grid-cols-12 gap-8">
        <StatsWidget />

        <div class="col-span-12 xl:col-span-6">
            <RecentSalesWidget />
            <BestSellingWidget />
        </div>
        <div class="col-span-12 xl:col-span-6">
            <RevenueStreamWidget />
            <NotificationsWidget />
            <div class="mt-6 p-4 border rounded">
                <Button :label="loading ? 'Calling…' : 'Test Protected API'" @click="callProtected" :disabled="loading" />
                <pre class="mt-3 whitespace-pre-wrap" v-if="protectedResult">{{ JSON.stringify(protectedResult, null, 2) }}</pre>
                <small class="text-red-500" v-if="error">{{ error }}</small>
                <div class="mt-4"/>
                <Button :label="loading ? 'Calling…' : 'Test Public API'" @click="callPublic" :disabled="loading" />
                <pre class="mt-3 whitespace-pre-wrap" v-if="publicResult">{{ JSON.stringify(publicResult, null, 2) }}</pre>
            </div>
        </div>
    </div>
</template>
