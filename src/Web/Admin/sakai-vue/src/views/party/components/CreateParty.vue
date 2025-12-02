<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from '@/composables/useI18n';

const { t } = useI18n();
const props = defineProps({
    party: {
        type: Object,
        default: null
    }
});

const emit = defineEmits(['created', 'updated', 'cancel', 'deleted']);

const initial = {
    partyName: '',
    partyType: 0,
    isBanned: false,
    deviceId: 0
};

const form = ref({ ...initial });
const loading = ref(false);

watch(
    () => props.party,
    (newParty) => {
        if (newParty) {
            form.value = { ...newParty };
        } else {
            form.value = { ...initial };
        }
    },
    { immediate: true }
);

const isEditMode = computed(() => !!props.party?.id);

async function submit() {
    loading.value = true;
    try {
        if (isEditMode.value) {
            emit('updated', { ...form.value });
        } else {
            emit('created', { ...form.value });
        }
        form.value = { ...initial };
    } catch (err) {
        console.error('Party submit error:', err);
    } finally {
        loading.value = false;
    }
}

function cancel() {
    emit('cancel');
}
</script>

<template>
    <div>
        <form @submit.prevent="submit" class="card p-4">
            <div class="flex flex-col gap-2 mb-3">
                <label for="partyName">{{ t('party.name') }}</label>
                <InputText id="partyName" v-model="form.partyName" type="text" />
                <Message v-if="!form.partyName" size="small" severity="error" variant="simple">{{ t('party.nameRequired') }}</Message>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="partyType">{{ t('party.type') }}</label>
                <InputNumber id="partyType" v-model="form.partyType" :min="0" :max="10" />
            </div>

            <div class="flex items-center gap-2 mb-3">
                <Checkbox inputId="isBanned" v-model="form.isBanned" :binary="true" />
                <label for="isBanned">{{ t('party.banned') }}</label>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="deviceId">{{ t('party.deviceId') }}</label>
                <InputNumber id="deviceId" v-model="form.deviceId" />
            </div>

            <div class="flex gap-2 justify-end mt-4">
                <Button type="button" :label="t('common.cancel')" class="p-button-text" @click="cancel" />
                <Button type="submit" :loading="loading" :label="isEditMode ? t('common.update') : t('common.create')" />
            </div>
        </form>
    </div>
</template>
