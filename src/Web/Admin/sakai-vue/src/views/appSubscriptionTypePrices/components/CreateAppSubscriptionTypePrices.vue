<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from '@/composables/useI18n';

const { t } = useI18n();
const props = defineProps({
    appSubscriptionTypePrices: {
        type: Object,
        default: null
    }
});

const emit = defineEmits(['created', 'updated', 'cancel', 'deleted']);

const initial = {
    subscriptionType: null,
    price: null,
    priceCurrencyType: null,
    appSubscriptionPeriodType: null
};

const form = ref({ ...initial });
const loading = ref(false);

const subscriptionTypeOptions = [
    { label: t('subscription.none') || 'None', value: 0 },
    { label: t('subscription.silver') || 'Silver', value: 1 },
    { label: t('subscription.gold') || 'Gold', value: 2 },
    { label: t('subscription.platinum') || 'Platinum', value: 3 }
];

const currencyTypeOptions = [
    { label: t('currency.none') || 'None', value: 0 },
    { label: t('currency.tl') || 'TL', value: 1 },
    { label: t('currency.eur') || 'EUR', value: 2 },
    { label: t('currency.dollar') || 'DOLLAR', value: 3 }
];

const periodTypeOptions = [
    { label: t('period.none') || 'None', value: 0 },
    { label: t('period.monthly') || 'Monthly', value: 1 },
    { label: t('period.yearly') || 'Yearly', value: 2 }
];

watch(
    () => props.appSubscriptionTypePrices,
    (newAppSubscriptionTypePrices) => {
        if (newAppSubscriptionTypePrices) {
            // ThruDate'i form'a ekleme, sadece diğer alanları al
            const { thruDate, ...rest } = newAppSubscriptionTypePrices;
            form.value = { ...rest };
        } else {
            form.value = { ...initial };
        }
    },
    { immediate: true }
);

const isEditMode = computed(() => !!props.appSubscriptionTypePrices?.id);

async function submit() {
    if (!form.value.subscriptionType && form.value.subscriptionType !== 0) {
        return;
    }
    if (!form.value.price || form.value.price <= 0) {
        return;
    }
    if (!form.value.priceCurrencyType && form.value.priceCurrencyType !== 0) {
        return;
    }

    loading.value = true;
    try {
        if (isEditMode.value) {
            emit('updated', { ...form.value });
        } else {
            emit('created', { ...form.value });
        }
        form.value = { ...initial };
    } catch (err) {
        console.error('AppSubscriptionTypePrices submit error:', err);
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
                <label for="subscriptionType">{{ t('appSubscriptionTypePrices.subscriptionType') || 'Subscription Type' }} <span class="text-red-500">*</span></label>
                <Dropdown id="subscriptionType" v-model="form.subscriptionType" :options="subscriptionTypeOptions" option-label="label" option-value="value" :placeholder="t('appSubscriptionTypePrices.selectSubscriptionType') || 'Select subscription type'" />
                <Message v-if="form.subscriptionType === null || form.subscriptionType === undefined" size="small" severity="error" variant="simple">{{ t('appSubscriptionTypePrices.subscriptionTypeRequired') || 'Subscription type is required' }}</Message>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="price">{{ t('appSubscriptionTypePrices.price') || 'Price' }} <span class="text-red-500">*</span></label>
                <InputNumber id="price" v-model="form.price" :min="0" :minFractionDigits="2" :maxFractionDigits="2" :placeholder="t('appSubscriptionTypePrices.pricePlaceholder') || 'Enter price'" />
                <Message v-if="!form.price || form.price <= 0" size="small" severity="error" variant="simple">{{ t('appSubscriptionTypePrices.priceRequired') || 'Price is required and must be greater than 0' }}</Message>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="priceCurrencyType">{{ t('appSubscriptionTypePrices.priceCurrencyType') || 'Currency Type' }} <span class="text-red-500">*</span></label>
                <Dropdown id="priceCurrencyType" v-model="form.priceCurrencyType" :options="currencyTypeOptions" option-label="label" option-value="value" :placeholder="t('appSubscriptionTypePrices.selectCurrencyType') || 'Select currency type'" />
                <Message v-if="form.priceCurrencyType === null || form.priceCurrencyType === undefined" size="small" severity="error" variant="simple">{{ t('appSubscriptionTypePrices.currencyTypeRequired') || 'Currency type is required' }}</Message>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="appSubscriptionPeriodType">{{ t('appSubscriptionTypePrices.appSubscriptionPeriodType') || 'Period Type' }}</label>
                <Dropdown id="appSubscriptionPeriodType" v-model="form.appSubscriptionPeriodType" :options="periodTypeOptions" option-label="label" option-value="value" :placeholder="t('appSubscriptionTypePrices.selectPeriodType') || 'Select period type'" />
            </div>

            <div class="flex gap-2 justify-end mt-4">
                <Button type="button" :label="t('common.cancel')" class="p-button-text" @click="cancel" />
                <Button type="submit" :loading="loading" :label="isEditMode ? t('common.update') : t('common.create')" />
            </div>
        </form>
    </div>
</template>
