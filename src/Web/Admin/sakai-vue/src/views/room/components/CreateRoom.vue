<script setup>
import { ref, watch, computed } from 'vue';

const props = defineProps({
  room: {
    type: Object,
    default: null
  }
});

const emit = defineEmits(['created', 'updated', 'cancel']);

const initial = {
  topicId: 1,
  partyId: 1,
  categoryId: 1,
  title: '',
  locationX: 0,
  locationY: 0,
  roomType: 1,
  lifeCycle: 0,
  channelId: 0,
  referenceId: 'onurarifciftci',
  upvote: 0,
  downvote: 0
};

const form = ref({ ...initial });
const loading = ref(false);

const roomTypeOptions = [
  { label: 'Public', value: 1 },
  { label: 'Private', value: 2 }
];

watch(
  () => props.room,
  (newRoom) => {
    if (newRoom) {
      form.value = { ...newRoom };
    } else {
      form.value = { ...initial };
    }
  },
  { immediate: true }
);

const isEditMode = computed(() => !!props.room?.id);

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
        <label for="title">Title</label>
        <InputText id="title" v-model="form.title" type="text" />
        <Message v-if="!form.title" size="small" severity="error" variant="simple">
          Name is required.
        </Message>
      </div>

      <div class="flex flex-col gap-2 mb-3">
        <label for="partyId">Party Id</label>
        <InputText id="partyId" v-model="form.partyId" type="number" />
        <Message v-if="!form.partyId" size="small" severity="error" variant="simple">
          PartyId is required.
        </Message>
      </div>

      <div class="flex flex-col gap-2 mb-3">
        <label for="locationX">Location X</label>
        <InputText id="locationX" v-model="form.locationX" type="number" />
      </div>

      <div class="flex flex-col gap-2 mb-3">
        <label for="locationY">Location Y</label>
        <InputText id="locationY" v-model="form.locationY" type="number" />
      </div>

      <div class="flex flex-col gap-2 mb-3">
        <label for="roomType">Room Type</label>
        <Dropdown
          id="roomType"
          v-model="form.roomType"
          :options="roomTypeOptions"
          option-label="label"
          option-value="value"
        />
      </div>

      <div class="flex gap-2 justify-end mt-4">
        <Button type="button" label="Cancel" class="p-button-text" @click="cancel" />
        <Button type="submit" :loading="loading" :label="isEditMode ? 'Update' : 'Create'" />
      </div>
    </form>
  </div>
</template>
