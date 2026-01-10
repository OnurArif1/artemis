<template>
    <div class="main-container">
        <div class="main-header">
            <div class="header-content">
                <h1>Artemis</h1>
                <div class="user-info">
                    <span v-if="auth.user">{{ auth.user.name || auth.user.email }}</span>
                    <Button label="Çıkış Yap" icon="pi pi-sign-out" severity="danger" @click="handleLogout" />
                </div>
            </div>
        </div>

        <div class="main-content">
            <div class="welcome-section">
                <h2>Hoş Geldiniz!</h2>
                <p>Chat odalarına katılmak için aşağıdaki seçenekleri kullanabilirsiniz.</p>
            </div>

            <div class="rooms-section">
                <div class="section-header">
                    <h3>Odalar</h3>
                    <Button label="Yeni Oda Oluştur" icon="pi pi-plus" @click="showCreateRoomDialog = true" />
                </div>

                <div v-if="loading" class="loading">
                    <ProgressSpinner />
                </div>

                <div v-else-if="rooms.length === 0" class="empty-state">
                    <i class="pi pi-inbox text-4xl text-300"></i>
                    <p>Henüz oda bulunmuyor</p>
                </div>

                <div v-else class="rooms-grid">
                    <div v-for="room in rooms" :key="room.id" class="room-card" @click="joinRoom(room.id)">
                        <div class="room-icon">
                            <i class="pi pi-comments text-2xl"></i>
                        </div>
                        <div class="room-info">
                            <h4>{{ room.title || `Oda ${room.id}` }}</h4>
                            <p v-if="room.description">{{ room.description }}</p>
                            <span class="room-meta">ID: {{ room.id }}</span>
                        </div>
                        <div class="room-action">
                            <i class="pi pi-arrow-right"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <Dialog v-model:visible="showCreateRoomDialog" modal header="Yeni Oda Oluştur" :style="{ width: '400px' }">
            <div class="create-room-form">
                <div class="form-group">
                    <label for="roomTitle">Oda Başlığı</label>
                    <InputText id="roomTitle" v-model="newRoom.title" placeholder="Oda adı" class="w-full" />
                </div>
                <div class="form-group">
                    <label for="roomDescription">Açıklama (Opsiyonel)</label>
                    <Textarea id="roomDescription" v-model="newRoom.description" placeholder="Oda açıklaması" class="w-full" rows="3" />
                </div>
                <div class="form-actions">
                    <Button label="İptal" severity="secondary" @click="showCreateRoomDialog = false" />
                    <Button label="Oluştur" @click="createRoom" :loading="creatingRoom" />
                </div>
            </div>
        </Dialog>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';
import request from '@/service/request';
import RoomService from '@/service/RoomService';
import { useToast } from 'primevue/usetoast';

const router = useRouter();
const auth = useAuthStore();
const toast = useToast();
const roomService = new RoomService(request);

const loading = ref(false);
const creatingRoom = ref(false);
const rooms = ref([]);
const showCreateRoomDialog = ref(false);
const newRoom = ref({
    title: '',
    description: ''
});

async function loadRooms() {
    loading.value = true;
    try {
        const result = await roomService.getList({
            pageIndex: 1,
            pageSize: 100
        });
        rooms.value = result?.resultViewModels || result?.resultViewmodels || [];
    } catch (error) {
        console.error('Rooms load error:', error);
        toast.add({
            severity: 'error',
            summary: 'Hata',
            detail: 'Odalar yüklenemedi',
            life: 3000
        });
    } finally {
        loading.value = false;
    }
}

function joinRoom(roomId) {
    router.push({ name: 'chat-room', params: { roomId } });
}

async function createRoom() {
    if (!newRoom.value.title.trim()) {
        toast.add({
            severity: 'warn',
            summary: 'Uyarı',
            detail: 'Oda başlığı gereklidir',
            life: 3000
        });
        return;
    }

    creatingRoom.value = true;
    try {
        await roomService.create({
            title: newRoom.value.title,
            description: newRoom.value.description || null
        });

        toast.add({
            severity: 'success',
            summary: 'Başarılı',
            detail: 'Oda oluşturuldu',
            life: 3000
        });

        showCreateRoomDialog.value = false;
        newRoom.value = { title: '', description: '' };
        await loadRooms();
    } catch (error) {
        console.error('Create room error:', error);
        toast.add({
            severity: 'error',
            summary: 'Hata',
            detail: 'Oda oluşturulamadı',
            life: 3000
        });
    } finally {
        creatingRoom.value = false;
    }
}

function handleLogout() {
    auth.clear();
    router.push({ name: 'login' });
}

onMounted(() => {
    loadRooms();
});
</script>

<style scoped>
.main-container {
    min-height: 100vh;
    background: #f5f5f5;
}

.main-header {
    background: white;
    border-bottom: 1px solid #e5e7eb;
    padding: 1rem 2rem;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.header-content {
    max-width: 1200px;
    margin: 0 auto;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.header-content h1 {
    color: #667eea;
    font-size: 1.5rem;
    margin: 0;
}

.user-info {
    display: flex;
    align-items: center;
    gap: 1rem;
}

.main-content {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
}

.welcome-section {
    background: white;
    border-radius: 8px;
    padding: 2rem;
    margin-bottom: 2rem;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.welcome-section h2 {
    color: #1f2937;
    margin-bottom: 0.5rem;
}

.welcome-section p {
    color: #6b7280;
}

.rooms-section {
    background: white;
    border-radius: 8px;
    padding: 2rem;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1.5rem;
}

.section-header h3 {
    color: #1f2937;
    margin: 0;
}

.loading {
    display: flex;
    justify-content: center;
    padding: 3rem;
}

.empty-state {
    text-align: center;
    padding: 3rem;
    color: #9ca3af;
}

.rooms-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 1.5rem;
}

.room-card {
    background: #f9fafb;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    padding: 1.5rem;
    cursor: pointer;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    gap: 1rem;
}

.room-card:hover {
    background: #f3f4f6;
    border-color: #667eea;
    transform: translateY(-2px);
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.room-icon {
    color: #667eea;
    flex-shrink: 0;
}

.room-info {
    flex: 1;
}

.room-info h4 {
    margin: 0 0 0.5rem 0;
    color: #1f2937;
}

.room-info p {
    margin: 0 0 0.5rem 0;
    color: #6b7280;
    font-size: 0.875rem;
}

.room-meta {
    font-size: 0.75rem;
    color: #9ca3af;
}

.room-action {
    color: #667eea;
    flex-shrink: 0;
}

.create-room-form {
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

.form-group {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}

.form-group label {
    font-weight: 500;
    color: #374151;
}

.form-actions {
    display: flex;
    justify-content: flex-end;
    gap: 0.5rem;
    margin-top: 1rem;
}
</style>

