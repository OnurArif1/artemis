<script setup>
import { ref, watch, computed, onMounted } from 'vue';
import request from '@/service/request';
import PartyService from '@/service/PartyService';
import CategoryService from '@/service/CategoryService';
import { useI18n } from '@/composables/useI18n';

const { t } = useI18n();
const partyService = new PartyService(request);
const categoryService = new CategoryService(request);

const props = defineProps({
    topic: {
        type: Object,
        default: null
    }
});

const emit = defineEmits(['created', 'updated', 'cancel', 'deleted']);

const initial = {
    partyId: null,
    title: '',
    type: 1,
    locationX: 0,
    locationY: 0,
    categoryId: 1,
    mentionId: null,
    upvote: 0,
    downvote: 0
};

const form = ref({ ...initial });
const loading = ref(false);

const partyOptions = ref([]);
const partyLoading = ref(false);
const categoryOptions = ref([]);
const categoryLoading = ref(false);

const typeOptions = ref([
    { label: t('topic.typeNone'), value: 0 },
    { label: t('common.public'), value: 1 },
    { label: t('common.private'), value: 2 }
]);

const isEditMode = computed(() => !!props.topic?.id);

async function getPartyLookup(filterText = '') {
    const filter = {
        searchText: filterText || '',
        partyLooukpSearchType: filterText ? 1 : 0
    };

    try {
        partyLoading.value = true;
        const response = await partyService.getLookup(filter);

        const list = response?.viewModels || response?.ViewModels || response?.resultViewmodels || response?.result || [];

        partyOptions.value = list.map((p) => ({
            label: `${p.partyName || p.PartyName || 'Unnamed Party'} (ID: ${p.partyId || p.PartyId || p.id || p.Id})`,
            value: p.partyId || p.PartyId || p.id || p.Id
        }));

        console.log('✅ Party options loaded:', partyOptions.value.length, 'parties');
    } catch (error) {
        console.error('❌ Party lookup error:', error);
        partyOptions.value = [];
    } finally {
        partyLoading.value = false;
    }
}

function onPartyFilter(event) {
    const filterValue = event.value?.trim() ?? '';
    getPartyLookup(filterValue);
}

async function getCategoryLookup(filterText = '') {
    const filter = {
        searchText: filterText,
        categoryLookupSearchType: 1
    };

    try {
        categoryLoading.value = true;
        const response = await categoryService.getLookup(filter);
        categoryOptions.value = response?.viewModels.map((c) => ({
            label: c.title,
            value: c.categoryId || c.id
        }));
    } catch (error) {
        console.error('Category lookup error:', error);
    } finally {
        categoryLoading.value = false;
    }
}

function onCategoryFilter(event) {
    const filterValue = event.value?.trim() ?? '';
    if (filterValue.length >= 2) {
        getCategoryLookup(filterValue);
    } else if (!filterValue) {
        getCategoryLookup();
    }
}

onMounted(() => {
    getPartyLookup();
    getCategoryLookup();
});

watch(
    () => props.topic,
    (newTopic) => {
        if (newTopic) {
            form.value = { ...newTopic };
        } else {
            form.value = { ...initial };
            getPartyLookup();
            getCategoryLookup();
        }
    },
    { immediate: true }
);

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
        console.error('Topic submit error:', err);
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
                <label for="title">{{ t('topic.titleLabel') }}</label>
                <InputText id="title" v-model="form.title" type="text" />
                <Message v-if="!form.title" size="small" severity="error" variant="simple">{{ t('topic.titleRequired') }}</Message>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="partyId">{{ t('topic.party') }}</label>
                <Dropdown id="partyId" v-model="form.partyId" :options="partyOptions" option-label="label" option-value="value" :placeholder="t('topic.selectParty')" :loading="partyLoading" filter @filter="onPartyFilter" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="categoryId">{{ t('topic.category') }}</label>
                <Dropdown id="categoryId" v-model="form.categoryId" :options="categoryOptions" option-label="label" option-value="value" :placeholder="t('topic.selectCategory')" :loading="categoryLoading" filter @filter="onCategoryFilter" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="type">{{ t('topic.type') }}</label>
                <Dropdown id="type" v-model="form.type" :options="typeOptions" option-label="label" option-value="value" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="locationX">{{ t('topic.locationX') }}</label>
                <InputNumber id="locationX" v-model="form.locationX" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="locationY">{{ t('topic.locationY') }}</label>
                <InputNumber id="locationY" v-model="form.locationY" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="mentionId">{{ t('topic.mentionId') }} ({{ t('common.optional') }})</label>
                <InputNumber id="mentionId" v-model="form.mentionId" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="upvote">{{ t('topic.upvote') }}</label>
                <InputNumber id="upvote" v-model="form.upvote" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="downvote">{{ t('topic.downvote') }}</label>
                <InputNumber id="downvote" v-model="form.downvote" />
            </div>

            <div class="flex gap-2 justify-end mt-4">
                <Button type="button" :label="t('common.cancel')" class="p-button-text" @click="cancel" />
                <Button type="submit" :loading="loading" :label="isEditMode ? t('common.update') : t('common.create')" />
            </div>
        </form>
    </div>
</template>
