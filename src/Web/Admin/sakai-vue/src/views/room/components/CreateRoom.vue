<script setup>
import { ref, watch, computed, onMounted } from 'vue';
import request from '@/service/request';
import PartyService from '@/service/PartyService';
import CategoryService from '@/service/CategoryService';
import TopicService from '@/service/TopicService';
import signalRService from '@/service/SignalRService';
import { useI18n } from '@/composables/useI18n';

const { t } = useI18n();
const partyService = new PartyService(request);
const categoryService = new CategoryService(request);
const topicService = new TopicService(request);

const props = defineProps({
    room: {
        type: Object,
        default: null
    },
    topic: {
        type: Object,
        default: null
    }
});

const emit = defineEmits(['created', 'updated', 'cancel', 'deleted']);

const initial = {
    topicId: null,
    partyId: null,
    categoryId: null,
    title: '',
    locationX: null,
    locationY: null,
    roomType: 1,
    lifeCycle: null,
    channelId: null,
    referenceId: null,
    upvote: null,
    downvote: null,
    subscriptionType: null,
    roomRange: null
};

const form = ref({ ...initial });
const loading = ref(false);

const partyOptions = ref([]);
const partyLoading = ref(false);
const categoryOptions = ref([]);
const categoryLoading = ref(false);
const topicOptions = ref([]);
const topicLoading = ref(false);

const roomTypeOptions = ref([
    { label: t('common.public'), value: 1 },
    { label: t('common.private'), value: 2 }
]);

const subscriptionTypeOptions = ref([
    { label: t('subscription.none') || 'None', value: 0 },
    { label: t('subscription.silver') || 'Silver', value: 1 },
    { label: t('subscription.gold') || 'Gold', value: 2 },
    { label: t('subscription.platinum') || 'Platinum', value: 3 }
]);

const isEditMode = computed(() => !!props.room?.id);

async function getPartyLookup(filterText = '') {
    const filter = {
        searchText: filterText || '',
        partyLookupSearchType: filterText ? 1 : 0
    };

    try {
        partyLoading.value = true;
        const response = await partyService.getLookup(filter);

        partyOptions.value = response?.viewModels.map((p) => ({
            label: `${p.partyName}`,
            value: p.partyId
        }));
    } catch (error) {
        console.error('Party lookup error:', error);
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

async function getTopicLookup(filterText = '') {
    const filter = {
        searchText: filterText || '',
        partyLookupSearchType: filterText ? 1 : 0
    };

    try {
        topicLoading.value = true;
        const response = await topicService.getLookup(filter);
        topicOptions.value = (response?.viewModels || []).map((t) => ({
            label: `${t.title}`,
            value: t.topicId
        }));
    } catch (error) {
        console.error('Topic lookup error:', error);
        topicOptions.value = [];
    } finally {
        topicLoading.value = false;
    }
}

onMounted(() => {
    getPartyLookup();
    getCategoryLookup();
    getTopicLookup();
});

watch(
    () => props.room,
    async (newRoom) => {
        if (newRoom) {
            await getTopicLookup();
            await getPartyLookup();
            await getCategoryLookup();
            form.value = { ...newRoom };
        } else {
            form.value = { ...initial };
            
            if (props.topic) {
                form.value.topicId = props.topic.id || props.topic.Id;
                form.value.locationX = props.topic.locationX || props.topic.LocationX || 0;
                form.value.locationY = props.topic.locationY || props.topic.LocationY || 0;
            }
            
            getPartyLookup();
            getCategoryLookup();
            getTopicLookup();

            try {
                if (!signalRService.isConnected()) {
                    await signalRService.startConnection();
                }

                const connectionId = signalRService.getConnectionId();
                if (connectionId) {
                    form.value.channelId = connectionId;
                } else {
                    setTimeout(async () => {
                        const retryConnectionId = signalRService.getConnectionId();
                        if (retryConnectionId) {
                            form.value.channelId = retryConnectionId;
                        }
                    }, 500);
                }
            } catch (error) {
            }
        }
    },
    { immediate: true }
);

watch(
    () => props.topic,
    async (newTopic) => {
        if (newTopic && !props.room) {
            await getTopicLookup();
            form.value.topicId = newTopic.id || newTopic.Id;
            form.value.locationX = newTopic.locationX || newTopic.LocationX || 0;
            form.value.locationY = newTopic.locationY || newTopic.LocationY || 0;
        }
    },
    { immediate: true }
);

async function submit() {
    if (!form.value.topicId) {
        return;
    }

    if (!form.value.title || form.value.title.trim() === '') {
        return;
    }

    if (!form.value.roomType) {
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
        console.error('Room submit error:', err);
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
                <label for="title">{{ t('room.titleLabel') }} <span class="text-red-500">*</span></label>
                <InputText id="title" v-model="form.title" type="text" />
                <Message v-if="!form.title || form.title.trim() === ''" size="small" severity="error" variant="simple">{{ t('room.titleRequired') }}</Message>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="topicId">{{ t('room.topic') }} <span class="text-red-500">*</span></label>
                <Dropdown id="topicId" v-model="form.topicId" :options="topicOptions" option-label="label" option-value="value" :placeholder="t('room.selectTopic')" :loading="topicLoading" :disabled="!!props.topic" />
                <Message v-if="!form.topicId" size="small" severity="error" variant="simple">{{ t('room.topicRequired') }}</Message>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="partyId">{{ t('party.title') }}</label>
                <Dropdown id="partyId" v-model="form.partyId" :options="partyOptions" option-label="label" option-value="value" :placeholder="t('room.selectParty')" :loading="partyLoading" filter @filter="onPartyFilter" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="categoryId">{{ t('room.category') }}</label>
                <Dropdown id="categoryId" v-model="form.categoryId" :options="categoryOptions" option-label="label" option-value="value" :placeholder="t('room.selectCategory')" :loading="categoryLoading" filter @filter="onCategoryFilter" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="locationX">{{ t('room.locationX') }}</label>
                <InputText id="locationX" v-model="form.locationX" type="number" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="locationY">{{ t('room.locationY') }}</label>
                <InputText id="locationY" v-model="form.locationY" type="number" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="roomType">{{ t('room.roomType') }} <span class="text-red-500">*</span></label>
                <Dropdown id="roomType" v-model="form.roomType" :options="roomTypeOptions" option-label="label" option-value="value" />
                <Message v-if="!form.roomType" size="small" severity="error" variant="simple">{{ t('room.roomType') }} {{ t('common.required') }}</Message>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="channelId">{{ t('room.channelId') }}</label>
                <InputText id="channelId" v-model="form.channelId" type="text" :placeholder="t('room.channelIdPlaceholder')" />
                <small class="text-500">{{ t('room.channelIdDescription') }}</small>
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="subscriptionType">{{ t('room.subscriptionType') || 'Subscription Type' }}</label>
                <Dropdown id="subscriptionType" v-model="form.subscriptionType" :options="subscriptionTypeOptions" option-label="label" option-value="value" :placeholder="t('room.selectSubscriptionType') || 'Select subscription type'" />
            </div>

            <div class="flex flex-col gap-2 mb-3">
                <label for="roomRange">{{ t('room.roomRange') || 'Room Range' }}</label>
                <InputNumber id="roomRange" v-model="form.roomRange" :min="0" :minFractionDigits="0" :maxFractionDigits="2" />
            </div>

            <div class="flex gap-2 justify-end mt-4">
                <Button type="button" :label="t('common.cancel')" class="p-button-text" @click="cancel" />
                <Button type="submit" :loading="loading" :label="isEditMode ? t('common.update') : t('common.create')" />
            </div>
        </form>
    </div>
</template>
