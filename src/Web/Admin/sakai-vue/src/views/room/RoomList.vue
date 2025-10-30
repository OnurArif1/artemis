<script setup>
import { ref, onMounted } from 'vue';
import request from '@/service/request';
import RoomService from '@/service/RoomService';
import CreateRoom from './components/CreateRoom.vue';

const rooms = ref([]);
const roomService = new RoomService(request);
const showCreate = ref(false);
const pageIndex = ref(1);
const pageSize = ref(10);
const totalRecords = ref(0);


async function load() {
    try {
        const roomFilter = {
            pageIndex: pageIndex.value,
            pageSize: pageSize.value
        };

        const data = await roomService.getList(roomFilter);
        rooms.value = Array.isArray(data.resultViewmodels) ? data.resultViewmodels : (data?.resultViewmodels ?? []);
        totalRecords.value = data?.count;
    } catch (err) {
        console.error('Room list load error:', err);
    }
}

function openCreate() {
    showCreate.value = true;
}

function onCreated(payload) {
    (async () => {
        try {
            const data = {
                topicId: payload.topicId || null,
                partyId: payload.partyId,
                categoryId: payload.categoryId || null,
                title: payload.title,
                locationX: payload.locationX || 0,
                locationY: payload.locationY || 0,
                roomType: payload.roomType || 1,
                lifeCycle: payload.lifeCycle || 0,
                channelId: payload.channelId || 0,
                referenceId: payload.referenceId || '',
                upvote: payload.upvote || 0,
                downvote: payload.downvote || 0
            };

            await roomService.create(data);
            showCreate.value = false;
            await load();
        } catch (err) {
            console.error('Room create error:', err);
        }
    })();
}

function onCancel() {
    showCreate.value = false;
}

function onPage(event) {
    pageIndex.value = event.page + 1;
    pageSize.value = event.rows;
    load();
}

onMounted(load);
</script>

<template>
    <div>
        <div class="flex justify-end mb-3">
            <Button label="Create" icon="pi pi-plus" @click="openCreate" />
        </div>

        <DataTable :value="rooms" paginator :rows="10"
                    :first="(pageIndex - 1) * pageSize"
                    :totalRecords="totalRecords" lazy
                    :rowsPerPageOptions="[5, 10, 20, 50]"
                    @page="onPage">
            <template #empty> No room data found. </template>
            <template #loading> Loading room data. Please wait.</template>
            <Column field="id" header="Id"/>
            <Column field="title" header="Title"/>
            <Column field="locationX" header="LocationX"/>
            <Column field="locationY" header="LocationY"/>
            <Column field="roomType" header="RoomType">
                <template #body="{ data }">
                    {{ data.roomType === 1 ? 'Public' : 'Private' }}
                </template>
            </Column>
            <Column field="lifeCycle" header="LifeCycle"/>
            <Column field="upvote" header="Upvote"/>
            <Column field="downvote" header="Downvote"/>
            <Column field="createDate" header="CreateDate">
                <template #body="{ data }">
                    {{ data.createDate}}
                </template>
            </Column>
        </DataTable>

        <Dialog v-model:visible="showCreate" modal :closable="false" header="Create Room" style="width: 500px">
            <CreateRoom @created="onCreated" @cancel="onCancel" />
        </Dialog>
    </div>
</template>
