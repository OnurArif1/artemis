<script setup>
import { ref, onMounted, onUnmounted, nextTick, watch } from 'vue';
import { useRoute } from 'vue-router';
import signalRService from '@/service/SignalRService';
import PartyService from '@/service/PartyService';
import MessageService from '@/service/MessageService';
import RoomService from '@/service/RoomService';
import request from '@/service/request';

const route = useRoute();
const partyService = new PartyService(request);
const messageService = new MessageService(request);
const roomService = new RoomService(request);

const messages = ref([]);
const messageText = ref('');
const roomId = ref(null);
const currentPartyId = ref(null); // Mesaj göndermek için kullanılacak partyId
const roomTitle = ref('');
const isConnected = ref(false);
const connectionStatus = ref('Bağlanılıyor...');
const connectionId = ref(null);
const messageContainer = ref(null);
const partyMap = ref(new Map()); // partyId -> partyName mapping
let connectionIdInterval = null;

// Route query'den roomId'yi al
const initializeParams = () => {
    const roomIdParam = route.query.roomId;
    if (roomIdParam) {
        roomId.value = parseInt(roomIdParam);
    }
};

// Mesajları veritabanından yükle
const loadMessages = async () => {
    if (!roomId.value) {
        return;
    }

    try {
        const result = await messageService.getList({
            roomId: roomId.value,
            pageIndex: 1,
            pageSize: 1000 // Tüm mesajları al
        });

        if (result && result.resultViewmodels) {
            // Party bilgilerini yükle
            const partyIds = [...new Set(result.resultViewmodels.map((m) => m.partyId))];
            for (const pid of partyIds) {
                if (!partyMap.value.has(pid)) {
                    try {
                        const partyResult = await partyService.getLookup({ PartyId: pid });
                        if (partyResult && partyResult.ViewModels && partyResult.ViewModels.length > 0) {
                            partyMap.value.set(pid, partyResult.ViewModels[0].PartyName);
                        } else {
                            partyMap.value.set(pid, `Kullanıcı ${pid}`);
                        }
                    } catch {
                        partyMap.value.set(pid, `Kullanıcı ${pid}`);
                    }
                }
            }

            // Mesajları formatla ve sırala
            messages.value = result.resultViewmodels
                .map((m) => ({
                    id: m.id,
                    partyId: m.partyId,
                    partyName: partyMap.value.get(m.partyId) || `Kullanıcı ${m.partyId}`,
                    content: m.content,
                    timestamp: new Date(m.createDate),
                    createDate: m.createDate
                }))
                .sort((a, b) => new Date(a.createDate) - new Date(b.createDate));

            // İlk party'yi currentPartyId olarak ayarla (mesaj göndermek için)
            if (messages.value.length > 0 && !currentPartyId.value) {
                currentPartyId.value = messages.value[0].partyId;
            }

            // Scroll to bottom
            nextTick(() => {
                if (messageContainer.value) {
                    messageContainer.value.scrollTop = messageContainer.value.scrollHeight;
                }
            });
        }
    } catch (error) {
        console.error('Mesajlar yüklenirken hata:', error);
    }
};

// Room bilgilerini yükle (title için)
const loadRoomInfo = async () => {
    if (!roomId.value) {
        return;
    }

    try {
        // Room listesinden bu room'u bul
        const result = await roomService.getList({
            pageIndex: 1,
            pageSize: 1000
        });

        if (result && result.resultViewModels) {
            const room = result.resultViewModels.find((r) => r.id === roomId.value);
            if (room) {
                roomTitle.value = room.title || `Room ${roomId.value}`;
                // Room'un partyId'sini currentPartyId olarak ayarla (mesaj göndermek için)
                if (room.partyId && !currentPartyId.value) {
                    currentPartyId.value = room.partyId;
                }
            } else {
                roomTitle.value = `Room ${roomId.value}`;
            }
        } else {
            roomTitle.value = `Room ${roomId.value}`;
        }
    } catch (error) {
        console.error('Room bilgisi yüklenirken hata:', error);
        roomTitle.value = `Room ${roomId.value}`;
    }
};

onMounted(async () => {
    // Route parametrelerini al
    initializeParams();

    if (!roomId.value) {
        alert('Room ID bulunamadı! Lütfen geçerli bir Room ID ile girin.');
        return;
    }

    // Room bilgilerini yükle
    await loadRoomInfo();

    // Mesajları yükle
    await loadMessages();

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
        signalRService.onReceiveMessage(() => {
            // Sadece bu room'un mesajlarını göster
            // Mesajı ekle ve veritabanından yeniden yükle
            loadMessages();
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

function sendMessage() {
    if (!messageText.value.trim()) {
        return;
    }

    if (!isConnected.value) {
        alert('Bağlantı yok! Lütfen bekleyin...');
        return;
    }

    if (!roomId.value || roomId.value <= 0) {
        alert('Geçerli bir Room ID gerekli!');
        return;
    }

    if (!currentPartyId.value) {
        alert('Party ID bulunamadı! Lütfen önce bir mesaj gönderilmiş olmalı.');
        return;
    }

    const message = messageText.value.trim();
    signalRService.sendMessage(currentPartyId.value, roomId.value, message);

    // Mesajı hemen ekle (optimistic update)
    const partyName = partyMap.value.get(currentPartyId.value) || `Kullanıcı ${currentPartyId.value}`;
    messages.value.push({
        id: Date.now(),
        partyId: currentPartyId.value,
        partyName: partyName,
        content: message,
        timestamp: new Date(),
        createDate: new Date().toISOString()
    });

    messageText.value = '';

    // Scroll to bottom
    nextTick(() => {
        if (messageContainer.value) {
            messageContainer.value.scrollTop = messageContainer.value.scrollHeight;
        }
    });

    // Veritabanından yeniden yükle (güncel veri için)
    setTimeout(() => {
        loadMessages();
    }, 500);
}

function onEnterKey(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault();
        sendMessage();
    }
}

// RoomId değiştiğinde mesajları yeniden yükle
watch(
    () => route.query.roomId,
    (newRoomId) => {
        if (newRoomId) {
            roomId.value = parseInt(newRoomId);
            loadMessages();
        }
    }
);
</script>

<template>
    <div class="chat-container">
        <div class="card">
            <div class="chat-header">
                <div class="flex align-items-center gap-2">
                    <i class="pi pi-comments text-2xl"></i>
                    <h2 class="m-0">{{ roomTitle }}</h2>
                </div>
                <div class="flex align-items-center gap-2">
                    <div class="connection-status" :class="{ connected: isConnected }">
                        <i :class="isConnected ? 'pi pi-check-circle' : 'pi pi-times-circle'"></i>
                        <span>{{ connectionStatus }}</span>
                    </div>
                    <div v-if="roomId" class="connection-id">
                        <i class="pi pi-home text-sm"></i>
                        <span class="text-sm">Room ID: {{ roomId }}</span>
                    </div>
                </div>
            </div>

            <div class="chat-body">
                <div ref="messageContainer" class="messages-container">
                    <div v-if="messages.length === 0" class="empty-messages">
                        <i class="pi pi-inbox text-4xl text-300"></i>
                        <p class="text-500">Henüz mesaj yok. İlk mesajı siz gönderin!</p>
                    </div>
                    <template v-else>
                        <div v-for="(msg, index) in messages" :key="msg.id" class="message-group">
                            <!-- Party ismi (sadece önceki mesajdan farklıysa göster) -->
                            <div v-if="index === 0 || messages[index - 1].partyId !== msg.partyId" class="message-party-name">
                                {{ msg.partyName }}
                            </div>
                            <!-- Mesaj içeriği -->
                            <div class="message-item">
                                <div class="message-content">{{ msg.content }}</div>
                                <div class="message-time">
                                    {{ msg.timestamp.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' }) }}
                                </div>
                            </div>
                        </div>
                    </template>
                </div>
            </div>

            <div class="chat-footer">
                <div class="flex gap-2 align-items-center w-full">
                    <InputText v-model="messageText" @keydown="onEnterKey" placeholder="Mesajınızı yazın... (Enter ile gönder)" class="flex-1" :disabled="!isConnected || !roomId" />
                    <Button label="Gönder" icon="pi pi-send" @click="sendMessage" :disabled="!isConnected || !messageText.trim() || !roomId" />
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

.messages-container {
    flex: 1;
    overflow-y: auto;
    padding: 1rem;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}

.empty-messages {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100%;
    gap: 1rem;
}

.message-group {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
    margin-bottom: 0.5rem;
}

.message-party-name {
    font-weight: 600;
    font-size: 0.875rem;
    color: var(--primary-color);
    margin-bottom: 0.25rem;
    padding-left: 0.5rem;
}

.message-item {
    padding: 0.75rem 1rem;
    border-radius: 8px;
    background-color: var(--surface-100);
    max-width: 100%;
    animation: slideIn 0.3s ease-out;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}

.message-content {
    word-wrap: break-word;
    line-height: 1.5;
}

.message-time {
    font-size: 0.7rem;
    color: var(--text-color-secondary);
    opacity: 0.7;
    align-self: flex-end;
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
