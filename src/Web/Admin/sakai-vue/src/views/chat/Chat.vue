<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue';
import signalRService from '@/service/SignalRService';

const messages = ref([]);
const messageText = ref('');
const userName = ref('Kullanıcı' + Math.floor(Math.random() * 1000));
const isConnected = ref(false);
const connectionStatus = ref('Bağlanılıyor...');
const messageContainer = ref(null);

onMounted(async () => {
    // Kullanıcı adını localStorage'dan al veya oluştur
    const savedName = localStorage.getItem('chatUserName');
    if (savedName) {
        userName.value = savedName;
    } else {
        localStorage.setItem('chatUserName', userName.value);
    }

    // SignalR bağlantısını başlat
    try {
        await signalRService.startConnection();
        isConnected.value = signalRService.isConnected();
        connectionStatus.value = isConnected.value ? 'Bağlı' : 'Bağlantı hatası';
        
        // Mesaj dinleyicisini ayarla
        signalRService.onReceiveMessage((from, message) => {
            addMessage(from, message, false);
        });
    } catch (error) {
        console.error('SignalR bağlantı hatası:', error);
        connectionStatus.value = 'Bağlantı hatası';
    }
});

onUnmounted(() => {
    // Component unmount olduğunda bağlantıyı kapatabilirsiniz (isteğe bağlı)
    // signalRService.connection?.stop();
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

    const message = messageText.value.trim();
    signalRService.sendMessage(userName.value, 'Everyone', message);
    addMessage(userName.value, message, true);
    messageText.value = '';
}

function onEnterKey(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault();
        sendMessage();
    }
}

function updateUserName() {
    if (userName.value.trim()) {
        localStorage.setItem('chatUserName', userName.value.trim());
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
                </div>
            </div>

            <div class="chat-body">
                <div class="user-info mb-3">
                    <label for="userName" class="text-sm font-semibold">Kullanıcı Adı:</label>
                    <InputText 
                        id="userName" 
                        v-model="userName" 
                        @blur="updateUserName"
                        placeholder="Kullanıcı adınızı girin"
                        class="w-full"
                    />
                </div>

                <div ref="messageContainer" class="messages-container">
                    <div v-if="messages.length === 0" class="empty-messages">
                        <i class="pi pi-inbox text-4xl text-300"></i>
                        <p class="text-500">Henüz mesaj yok. İlk mesajı siz gönderin!</p>
                    </div>
                    <div 
                        v-for="msg in messages" 
                        :key="msg.id" 
                        class="message-item"
                        :class="{ 'own-message': msg.isOwn }"
                    >
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
                    <InputText
                        v-model="messageText"
                        @keydown="onEnterKey"
                        placeholder="Mesajınızı yazın... (Enter ile gönder)"
                        class="flex-1"
                        :disabled="!isConnected"
                    />
                    <Button
                        label="Gönder"
                        icon="pi pi-send"
                        @click="sendMessage"
                        :disabled="!isConnected || !messageText.trim()"
                    />
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

