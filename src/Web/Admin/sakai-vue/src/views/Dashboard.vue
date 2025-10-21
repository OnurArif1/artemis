<script setup>
import { ref } from 'vue';
import { getProtected } from '@/service/TestService';

const loading = ref(false);
const data = ref(null);
const error = ref('');

async function fetchProtected() {
    error.value = '';
    data.value = null;
    loading.value = true;
    try {
        const res = await getProtected();
        data.value = res;
    } catch (e) {
        console.error(e);
        error.value = e?.message || 'Request failed';
    } finally {
        loading.value = false;
    }
}
</script>

<template>
    <div class="grid grid-cols-12 gap-8">
        <div>Admin Dashboard</div>

        <div class="mt-4">
            <button class="p-2 bg-blue-600 text-white rounded" :disabled="loading" @click="fetchProtected">
                {{ loading ? 'Loading...' : 'Get Protected' }}
            </button>
        </div>

        <div class="mt-4">
            <div v-if="error" class="text-red-600">Error: {{ error }}</div>
            <pre v-if="data" class="mt-2 p-2 bg-gray-100 rounded">{{ JSON.stringify(data, null, 2) }}</pre>
        </div>
    </div>
</template>
<style scoped></style>
