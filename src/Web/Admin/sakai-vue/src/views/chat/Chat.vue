<script setup>
import { ref, onMounted, onUnmounted, nextTick, computed } from 'vue';
import { useRoute } from 'vue-router';
import signalRService from '@/service/SignalRService';
import PartyService from '@/service/PartyService';
import request from '@/service/request';

const route = useRoute();
const partyService = new PartyService(request);

const messages = ref([]);
const messageText = ref('');
const partyId = ref(null);
const roomId = ref(null);
const partyName = ref('');
const isConnected = ref(false);
const connectionStatus = ref('Bağlanılıyor...');
const connectionId = ref(null);
const messageContainer = ref(null);
const partyMap = ref(new Map()); // partyId -> partyName mapping
const tempPartyId = ref(''); // Geçici partyId input için
const tempRoomId = ref(''); // Geçici roomId input için
let connectionIdInterval = null;

// Route query'den partyId ve roomId'yi al
const initializeParams = () => {
    const partyIdParam = route.query.partyId;
    const roomIdParam = route.query.roomId;
    
    if (partyIdParam) {
        partyId.value = parseInt(partyIdParam);
    }
    
    if (roomIdParam) {
        roomId.value = parseInt(roomIdParam);
    }
};

// Party bilgilerini API'den çek
const loadPartyInfo = async () => {
    if (!partyId.value) {
        console.error('PartyId bulunamadı!');
        return;
    }

    try {
        const result = await partyService.getLookup({ PartyId: partyId.value });
        if (result && result.ViewModels && result.ViewModels.length > 0) {
            const party = result.ViewModels[0];
            partyName.value = party.PartyName;
            partyMap.value.set(partyId.value, party.PartyName);
        } else {
            console.error('Party bilgisi bulunamadı!');
        }
    } catch (error) {
        console.error('Party bilgisi yüklenirken hata:', error);
    }
};

onMounted(async () => {
    // Route parametrelerini al
    initializeParams();

    // Party bilgilerini yükle
    if (partyId.value) {
        await loadPartyInfo();
    }

    // SignalR bağlantısını başlat
    try {
        await signalRService.startConnection();
        isConnected.value = signalRService.isConnected();
        connectionId.value = signalRService.getConnectionId();
        connectionStatus.value = isConnected.value ? 'Bağlı' : 'Bağlantı hatası';

        // ConnectionId güncellemelerini dinle
        connectionIdInterval = setInterval(() => {
            const newConnectionId = signalRService.getConnectionId();
            if (newConnectionId && newConnectionId !== connectionId.value) {
                connectionId.value = newConnectionId;
            }
        }, 1000);

        // Mesaj dinleyicisini ayarla
        signalRService.onReceiveMessage((receivedPartyId, receivedPartyName, message) => {
            // Eğer mesaj kendinizden geliyorsa ekleme (zaten sendMessage'da ekledik)
            if (receivedPartyId !== partyId.value) {
                // Party bilgisini map'e kaydet
                partyMap.value.set(receivedPartyId, receivedPartyName);
                addMessage(receivedPartyName, message, false);
            }
        });

        // Hata dinleyicisini ayarla
        signalRService.onReceiveError((errorMessage) => {
            alert(errorMessage);
        });
    } catch (error) {
        console.error('SignalR bağlantı hatası:', error);
        connectionStatus.value = 'Bağlantı hatası';
    }
});

onUnmounted(() => {
    // Interval'i temizle
    if (connectionIdInterval) {
        clearInterval(connectionIdInterval);
    }
});

function addMessage(from, message, isOwn = false) {
    messages.value.push({
        id: Date.now() + Math.random(),
        from: from,
        message: message,
        timestamp: new Date(),
        isOwn: isOwn
    });

    // Mesajları en alta kaydır
    nextTick(() => {
        if (messageContainer.value) {
            messageContainer.value.scrollTop = messageContainer.value.scrollHeight;
        }
    });
}

function sendMessage() {
    if (!messageText.value.trim()) {
        return;
    }

    if (!isConnected.value) {
        alert('Bağlantı yok! Lütfen bekleyin...');
        return;
    }

    if (!partyId.value) {
        alert('Lütfen önce Party ID girin!');
        return;
    }

    if (!roomId.value || roomId.value <= 0) {
        alert('Lütfen geçerli bir Room ID girin!');
        return;
    }

    const message = messageText.value.trim();
    signalRService.sendMessage(partyId.value, roomId.value, message);
    addMessage(partyName.value, message, true);
    messageText.value = '';
}

function onEnterKey(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault();
        sendMessage();
    }
}

function setPartyId() {
    const parsedId = parseInt(tempPartyId.value);
    if (!isNaN(parsedId) && parsedId > 0) {
        partyId.value = parsedId;
        loadPartyInfo();
    } else {
        alert('Geçerli bir PartyId girin!');
    }
}

function setRoomId() {
    const parsedId = parseInt(tempRoomId.value);
    if (!isNaN(parsedId) && parsedId > 0) {
        roomId.value = parsedId;
    } else {
        alert('Geçerli bir RoomId girin!');
    }
}
</script>

<template>
    <div class="chat-container">
        <div class="card">
            <div class="chat-header">
                <div class="flex align-items-center gap-2">
                    <i class="pi pi-comments text-2xl"></i>
                    <h2 class="m-0">SignalR Mesajlaşma</h2>
                </div>
                <div class="flex align-items-center gap-2">
                    <div class="connection-status" :class="{ connected: isConnected }">
                        <i :class="isConnected ? 'pi pi-check-circle' : 'pi pi-times-circle'"></i>
                        <span>{{ connectionStatus }}</span>
                    </div>
                    <div v-if="connectionId" class="connection-id">
                        <i class="pi pi-link text-sm"></i>
                        <span class="text-sm">ID: {{ connectionId }}</span>
                    </div>
                </div>
            </div>

            <div class="chat-body">
                <!-- PartyId veya RoomId yoksa geçici input alanları -->
                <div v-if="!partyId || !roomId" class="party-id-input mb-3 p-3 border-round" style="background-color: var(--surface-50); border: 1px solid var(--surface-border);">
                    <div v-if="!partyId" class="mb-3">
                        <div class="flex gap-2 align-items-center">
                            <label for="tempPartyId" class="text-sm font-semibold">Party ID:</label>
                            <InputText id="tempPartyId" v-model="tempPartyId" placeholder="Party ID girin (örn: 1)" class="flex-1" type="number" />
                            <Button label="Ayarla" icon="pi pi-check" @click="setPartyId" />
                        </div>
                    </div>
                    <div v-if="!roomId">
                        <div class="flex gap-2 align-items-center">
                            <label for="tempRoomId" class="text-sm font-semibold">Room ID:</label>
                            <InputText id="tempRoomId" v-model="tempRoomId" placeholder="Room ID girin (örn: 1)" class="flex-1" type="number" />
                            <Button label="Ayarla" icon="pi pi-check" @click="setRoomId" />
                        </div>
                    </div>
                    <p class="text-sm text-500 mt-2">Not: Geçici olarak Party ID ve Room ID girebilirsiniz. Normalde URL'den alınır (?partyId=1&roomId=2)</p>
                </div>

                <!-- Party ve Room bilgisi gösterimi -->
                <div v-if="partyId && partyName" class="party-info mb-3 p-2 border-round" style="background-color: var(--primary-50); border: 1px solid var(--primary-200);">
                    <div class="flex align-items-center gap-2 flex-wrap">
                        <div class="flex align-items-center gap-2">
                            <i class="pi pi-user text-lg text-primary"></i>
                            <span class="font-semibold text-primary">{{ partyName }}</span>
                            <span class="text-sm text-500">(Party ID: {{ partyId }})</span>
                        </div>
                        <div v-if="roomId" class="flex align-items-center gap-2 ml-3">
                            <i class="pi pi-home text-lg text-primary"></i>
                            <span class="text-sm text-500">Room ID: {{ roomId }}</span>
                        </div>
                    </div>
                </div>

                <div ref="messageContainer" class="messages-container">
                    <div v-if="messages.length === 0" class="empty-messages">
                        <i class="pi pi-inbox text-4xl text-300"></i>
                        <p class="text-500">Henüz mesaj yok. İlk mesajı siz gönderin!</p>
                    </div>
                    <div v-for="msg in messages" :key="msg.id" class="message-item" :class="{ 'own-message': msg.isOwn }">
                        <div class="message-header">
                            <span class="message-author">{{ msg.from }}</span>
                            <span class="message-time">
                                {{ msg.timestamp.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' }) }}
                            </span>
                        </div>
                        <div class="message-content">{{ msg.message }}</div>
                    </div>
                </div>
            </div>

            <div class="chat-footer">
                <div class="flex gap-2 align-items-center w-full">
                    <InputText v-model="messageText" @keydown="onEnterKey" placeholder="Mesajınızı yazın... (Enter ile gönder)" class="flex-1" :disabled="!isConnected || !partyId || !roomId" />
                    <Button label="Gönder" icon="pi pi-send" @click="sendMessage" :disabled="!isConnected || !messageText.trim() || !partyId || !roomId" />
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
.chat-container {
    padding: 2rem;
    max-width: 1200px;
    margin: 0 auto;
    height: calc(100vh - 200px);
}

.chat-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem;
    border-bottom: 1px solid var(--surface-border);
}

.connection-status {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 1rem;
    border-radius: 4px;
    font-size: 0.875rem;
}

.connection-status.connected {
    color: var(--green-600);
    background-color: var(--green-50);
}

.connection-status:not(.connected) {
    color: var(--red-600);
    background-color: var(--red-50);
}

.connection-id {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 1rem;
    border-radius: 4px;
    background-color: var(--surface-100);
    font-family: monospace;
    font-size: 0.75rem;
}

.chat-body {
    display: flex;
    flex-direction: column;
    height: calc(100vh - 350px);
    min-height: 400px;
}

.user-info {
    padding: 1rem;
    border-bottom: 1px solid var(--surface-border);
}

.messages-container {
    flex: 1;
    overflow-y: auto;
    padding: 1rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

.empty-messages {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100%;
    gap: 1rem;
}

.message-item {
    padding: 0.75rem 1rem;
    border-radius: 8px;
    background-color: var(--surface-100);
    max-width: 70%;
    animation: slideIn 0.3s ease-out;
}

.message-item.own-message {
    background-color: var(--primary-color);
    color: white;
    margin-left: auto;
}

.message-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.5rem;
    font-size: 0.75rem;
    opacity: 0.8;
}

.message-author {
    font-weight: 600;
}

.message-time {
    font-size: 0.7rem;
}

.message-content {
    word-wrap: break-word;
    line-height: 1.5;
}

.chat-footer {
    padding: 1rem;
    border-top: 1px solid var(--surface-border);
    background-color: var(--surface-0);
}

@keyframes slideIn {
    from {
        opacity: 0;
        transform: translateY(10px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

/* Scrollbar styling */
.messages-container::-webkit-scrollbar {
    width: 8px;
}

.messages-container::-webkit-scrollbar-track {
    background: var(--surface-100);
}

.messages-container::-webkit-scrollbar-thumb {
    background: var(--surface-300);
    border-radius: 4px;
}

.messages-container::-webkit-scrollbar-thumb:hover {
    background: var(--surface-400);
}
</style>
