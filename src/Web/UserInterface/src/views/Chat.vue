<template>
    <div class="chat-container">
        <div class="chat-header-bar">
            <Button icon="pi pi-arrow-left" label="Geri" text @click="goBack" />
            <h2>{{ roomTitle }}</h2>
            <div class="connection-status" :class="{ connected: isConnected }">
                <i :class="isConnected ? 'pi pi-check-circle' : 'pi pi-times-circle'"></i>
                <span>{{ connectionStatusText }}</span>
            </div>
        </div>

        <div class="card chat-card">
            <div class="chat-body">
                <div ref="messageContainer" class="messages-container">
                    <div v-if="messages.length === 0" class="empty-messages">
                        <i class="pi pi-inbox text-4xl text-300"></i>
                        <p class="text-500">Henüz mesaj yok</p>
                    </div>
                    <template v-else>
                        <div v-for="(msg, index) in messages" :key="msg.id" class="message-group">
                            <div v-if="index === 0 || messages[index - 1].partyId !== msg.partyId" class="message-party-name">
                                {{ msg.partyName }}
                            </div>
                            <div class="message-item">
                                <div class="message-content">{{ msg.content }}</div>
                                <div class="message-time">
                                    {{ formatTime(msg.timestamp) }}
                                </div>
                            </div>
                        </div>
                    </template>
                </div>
            </div>

            <div class="chat-footer">
                <div class="flex gap-2 align-items-center w-full" style="position: relative">
                    <div class="flex-1" style="position: relative">
                        <InputText
                            id="messageInput"
                            v-model="messageText"
                            @keydown="handleKeydown"
                            @input="handleMentionInput"
                            placeholder="Mesaj yazın... (@ ile kullanıcı bahsedin)"
                            class="w-full"
                        />
                        <div v-if="showMentionList && mentionList.length > 0" class="mention-list" @click.stop>
                            <div
                                v-for="(party, index) in mentionList"
                                :key="party.id"
                                :class="['mention-item', { selected: index === selectedMentionIndex }]"
                                @click="selectMention(party)"
                                @mouseenter="selectedMentionIndex = index"
                            >
                                {{ party.name }}
                            </div>
                        </div>
                    </div>
                    <Button
                        :label="'Gönder'"
                        icon="pi pi-send"
                        @click="sendMessage"
                        :disabled="!isConnected || !messageText.trim() || !roomId"
                    />
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import signalRService from '@/service/SignalRService';
import PartyService from '@/service/PartyService';
import MessageService from '@/service/MessageService';
import RoomService from '@/service/RoomService';
import request from '@/service/request';
import { useAuthStore } from '@/stores/auth';

const authStore = useAuthStore();

const route = useRoute();
const router = useRouter();
const auth = useAuthStore();
const partyService = new PartyService(request);
const messageService = new MessageService(request);
const roomService = new RoomService(request);

const messages = ref([]);
const messageText = ref('');
const roomId = ref(null);
const currentPartyId = ref(null);
const roomTitle = ref('');
const isConnected = ref(false);
const connectionError = ref(false);
const connectionStatusText = computed(() => {
    if (connectionError.value) {
        return 'Bağlantı Hatası';
    }
    if (!isConnected.value) {
        return 'Bağlanıyor...';
    }
    return 'Bağlı';
});
const connectionId = ref(null);
const messageContainer = ref(null);
const partyMap = ref(new Map());
const roomParties = ref([]);
const showMentionList = ref(false);
const mentionList = ref([]);
const mentionSearchText = ref('');
const mentionStartPosition = ref(-1);
const selectedMentionIndex = ref(-1);
let connectionIdInterval = null;

async function loadUserParty() {
    try {
        console.log('loadUserParty çağrıldı');
        
        // Token kontrolü
        if (!authStore.token) {
            console.error('Token bulunamadı');
            alert('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
            router.push({ name: 'login' });
            return false;
        }
        
        console.log('Token mevcut, istek gönderiliyor...');
        console.log('Token:', authStore.token?.substring(0, 20) + '...');
        
        // Direkt axios ile istek at (proxy çalışmıyorsa)
        const axios = (await import('axios')).default;
        const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5091';
        console.log('API Base URL:', API_BASE_URL);
        console.log('Full URL:', `${API_BASE_URL}/api/user/party`);
        
        const response = await axios({
            method: 'get',
            url: `${API_BASE_URL}/api/user/party`,
            headers: {
                'Authorization': `Bearer ${authStore.token}`
            },
            timeout: 10000
        });
        
        console.log('✅ Party response alındı:', response);
        console.log('Party response data:', response?.data);
        
        // Axios response'u direkt data içerir
        const responseData = response?.data || response;
        
        if (responseData?.partyId) {
            currentPartyId.value = responseData.partyId;
            console.log('✅ Party ID yüklendi:', currentPartyId.value);
            // Party adını da kaydet
            if (responseData.partyName) {
                partyMap.value.set(responseData.partyId, responseData.partyName);
            }
            return true;
        } else {
            console.error('❌ Party ID response\'da bulunamadı:', responseData);
            throw new Error('Party ID response\'da bulunamadı');
        }
    } catch (error) {
        console.error('❌ Kullanıcı Party yükleme hatası:', error);
        console.error('Error object:', error);
        console.error('Error response:', error?.response);
        console.error('Error response data:', error?.response?.data);
        console.error('Error response status:', error?.response?.status);
        console.error('Error message:', error?.message);
        console.error('Error stack:', error?.stack);
        
        // 401 hatası ise login'e yönlendir
        if (error?.response?.status === 401 || error?.status === 401) {
            alert('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
            router.push({ name: 'login' });
            return false;
        }
        
        // Network hatası
        if (!error?.response) {
            console.error('Network hatası - backend erişilemiyor');
            alert('Backend servisine erişilemiyor. Lütfen servislerin çalıştığından emin olun.');
            return false;
        }
        
        // Diğer hatalar için detaylı mesaj
        const errorMessage = error?.response?.data?.message || 
                            error?.response?.data?.error || 
                            error?.message || 
                            `HTTP ${error?.response?.status || 'Unknown'}`;
        console.error('Hata mesajı:', errorMessage);
        alert(`Kullanıcı Party ID yüklenemedi: ${errorMessage}`);
        return false;
    }
}

function initializeParams() {
    const roomIdParam = route.params.roomId;
    if (roomIdParam) {
        roomId.value = parseInt(roomIdParam);
    }
}

async function loadMessages() {
    if (!roomId.value) {
        return;
    }

    try {
        const result = await messageService.getList({
            roomId: roomId.value,
            pageIndex: 1,
            pageSize: 1000
        });

        if (result && (result.resultViewmodels || result.resultViewModels)) {
            const messageList = result.resultViewmodels || result.resultViewModels;
            const partyIds = [...new Set(messageList.map((m) => m.partyId))];
            
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

            messages.value = messageList
                .map((m) => ({
                    id: m.id,
                    partyId: m.partyId,
                    partyName: partyMap.value.get(m.partyId) || `Kullanıcı ${m.partyId}`,
                    content: m.content,
                    timestamp: new Date(m.createDate),
                    createDate: m.createDate
                }))
                .sort((a, b) => new Date(a.createDate) - new Date(b.createDate));

            nextTick(() => {
                if (messageContainer.value) {
                    messageContainer.value.scrollTop = messageContainer.value.scrollHeight;
                }
            });
        }
    } catch (error) {
        console.error('Mesaj yükleme hatası:', error);
    }
}

async function loadRoomInfo() {
    if (!roomId.value) {
        return;
    }

    try {
        const result = await roomService.getList({
            pageIndex: 1,
            pageSize: 1000
        });

        if (result && (result.resultViewModels || result.resultViewmodels)) {
            const roomList = result.resultViewModels || result.resultViewmodels;
            const room = roomList.find((r) => r.id === roomId.value);
            if (room) {
                roomTitle.value = room.title || `Oda ${roomId.value}`;
                if (room.parties && room.parties.length > 0) {
                    roomParties.value = room.parties.map((p) => ({
                        id: p.id,
                        name: p.partyName
                    }));
                    room.parties.forEach((p) => {
                        partyMap.value.set(p.id, p.partyName);
                    });
                }
            } else {
                roomTitle.value = `Oda ${roomId.value}`;
            }
        } else {
            roomTitle.value = `Oda ${roomId.value}`;
        }
    } catch (error) {
        console.error('Oda bilgisi yükleme hatası:', error);
        roomTitle.value = `Oda ${roomId.value}`;
    }
}

function formatTime(date) {
    if (!date) return '';
    const d = new Date(date);
    return d.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' });
}

function goBack() {
    router.push({ name: 'main' });
}

onMounted(async () => {
    initializeParams();

    if (!roomId.value) {
        alert('Oda ID bulunamadı');
        router.push({ name: 'main' });
        return;
    }

    // Önce kullanıcının Party ID'sini yükle - BAŞARILI OLMALI
    const partyLoaded = await loadUserParty();
    if (!partyLoaded) {
        console.error('Party yüklenemedi, chat başlatılamıyor');
        return;
    }

    await loadRoomInfo();
    await loadMessages();

    try {
        await signalRService.startConnection();
        isConnected.value = signalRService.isConnected();
        connectionId.value = signalRService.getConnectionId();
        connectionError.value = false;

        connectionIdInterval = setInterval(() => {
            const newConnectionId = signalRService.getConnectionId();
            if (newConnectionId && newConnectionId !== connectionId.value) {
                connectionId.value = newConnectionId;
            }
            isConnected.value = signalRService.isConnected();
        }, 1000);

        if (roomId.value && isConnected.value) {
            signalRService.joinRoom(roomId.value);
        }

        signalRService.onReceiveMessage((partyId, partyName, message, receivedRoomId) => {
            if (receivedRoomId === roomId.value) {
                const partyNameToUse = partyMap.value.get(partyId) || partyName || `Kullanıcı ${partyId}`;

                const now = new Date();
                const messageExists = messages.value.some(
                    (m) => m.partyId === partyId && m.content === message && Math.abs(now - new Date(m.timestamp)) < 5000
                );

                if (!messageExists) {
                    messages.value.push({
                        id: Date.now(),
                        partyId: partyId,
                        partyName: partyNameToUse,
                        content: message,
                        timestamp: now,
                        createDate: now.toISOString()
                    });

                    if (!partyMap.value.has(partyId)) {
                        partyMap.value.set(partyId, partyNameToUse);
                    }
                    nextTick(() => {
                        if (messageContainer.value) {
                            messageContainer.value.scrollTop = messageContainer.value.scrollHeight;
                        }
                    });
                }
            }
        });

        signalRService.onReceiveError((errorMessage) => {
            alert(errorMessage);
        });
    } catch (error) {
        console.error('Bağlantı hatası:', error);
        connectionError.value = true;
    }
});

onUnmounted(() => {
    if (connectionIdInterval) {
        clearInterval(connectionIdInterval);
    }

    if (roomId.value) {
        signalRService.leaveRoom(roomId.value);
    }
});

async function sendMessage() {
    if (!messageText.value.trim()) {
        return;
    }

    if (!isConnected.value) {
        alert('Bağlantı yok');
        return;
    }

    if (!roomId.value || roomId.value <= 0) {
        alert('Geçersiz oda ID');
        return;
    }

    if (!currentPartyId.value) {
        console.error('currentPartyId null:', currentPartyId.value);
        // Party ID yoksa tekrar yüklemeyi dene
        await loadUserParty();
        if (!currentPartyId.value) {
            alert('Kullanıcı ID bulunamadı. Lütfen sayfayı yenileyin.');
            return;
        }
    }

    const message = messageText.value.trim();
    const mentionedPartyIds = parseMentions(message);

    signalRService.sendMessage(currentPartyId.value, roomId.value, message, mentionedPartyIds.length > 0 ? mentionedPartyIds : null);

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

    nextTick(() => {
        if (messageContainer.value) {
            messageContainer.value.scrollTop = messageContainer.value.scrollHeight;
        }
    });
}

function parseMentions(text) {
    const mentionRegex = /@([^\s@]+)/g;
    const mentions = [];
    let match;

    while ((match = mentionRegex.exec(text)) !== null) {
        const mentionedName = match[1].trim();
        const party = roomParties.value.find((p) => {
            const partyName = p.name.toLowerCase();
            const searchName = mentionedName.toLowerCase();
            return partyName === searchName;
        });
        if (party) {
            mentions.push(party.id);
        }
    }

    return [...new Set(mentions)];
}

function handleMentionInput(event) {
    const text = event.target.value;
    const cursorPosition = event.target.selectionStart || 0;
    const textBeforeCursor = text.substring(0, cursorPosition);
    const lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex !== -1) {
        const textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
        if (!textAfterAt.includes(' ') && !textAfterAt.includes('\n') && textAfterAt.length > 0) {
            mentionStartPosition.value = lastAtIndex;
            mentionSearchText.value = textAfterAt.toLowerCase();

            const filtered = roomParties.value.filter((p) => p.name.toLowerCase().includes(mentionSearchText.value));

            if (filtered.length > 0) {
                mentionList.value = filtered;
                showMentionList.value = true;
                selectedMentionIndex.value = -1;
            } else {
                showMentionList.value = false;
            }
            return;
        } else if (textAfterAt.length === 0) {
            mentionStartPosition.value = lastAtIndex;
            mentionSearchText.value = '';
            mentionList.value = roomParties.value;
            showMentionList.value = roomParties.value.length > 0;
            selectedMentionIndex.value = -1;
            return;
        }
    }

    showMentionList.value = false;
    mentionStartPosition.value = -1;
}

function selectMention(party) {
    if (mentionStartPosition.value === -1) return;

    const text = messageText.value;
    const cursorPosition = mentionStartPosition.value;
    const textAfterAt = text.substring(cursorPosition + 1);
    const spaceIndex = textAfterAt.indexOf(' ');
    const newlineIndex = textAfterAt.indexOf('\n');
    let endIndex;

    if (spaceIndex !== -1 && newlineIndex !== -1) {
        endIndex = cursorPosition + 1 + Math.min(spaceIndex, newlineIndex);
    } else if (spaceIndex !== -1) {
        endIndex = cursorPosition + 1 + spaceIndex;
    } else if (newlineIndex !== -1) {
        endIndex = cursorPosition + 1 + newlineIndex;
    } else {
        endIndex = text.length;
    }

    const beforeMention = text.substring(0, cursorPosition);
    const afterMention = text.substring(endIndex);
    const newText = beforeMention + '@' + party.name + ' ' + afterMention;
    messageText.value = newText;

    showMentionList.value = false;
    mentionStartPosition.value = -1;
    mentionSearchText.value = '';

    nextTick(() => {
        const input = document.getElementById('messageInput');
        if (input) {
            const newPosition = cursorPosition + party.name.length + 2;
            input.focus();
            input.setSelectionRange(newPosition, newPosition);
        }
    });
}

function handleKeydown(event) {
    if (event.key === 'Backspace' || event.key === 'Delete') {
        if (showMentionList.value) {
            showMentionList.value = false;
            mentionStartPosition.value = -1;
        }
        return;
    }

    if (!showMentionList.value) {
        if (event.key === 'Enter' && !event.shiftKey) {
            event.preventDefault();
            sendMessage();
        }
        return;
    }

    if (event.key === 'ArrowDown') {
        event.preventDefault();
        selectedMentionIndex.value = Math.min(selectedMentionIndex.value + 1, mentionList.value.length - 1);
    } else if (event.key === 'ArrowUp') {
        event.preventDefault();
        selectedMentionIndex.value = Math.max(selectedMentionIndex.value - 1, -1);
    } else if (event.key === 'Escape') {
        event.preventDefault();
        showMentionList.value = false;
        mentionStartPosition.value = -1;
    } else if (event.key === 'Enter') {
        if (selectedMentionIndex.value >= 0) {
            event.preventDefault();
            selectMention(mentionList.value[selectedMentionIndex.value]);
            return;
        } else if (mentionList.value.length > 0) {
            event.preventDefault();
            selectMention(mentionList.value[0]);
            return;
        }
    }
}

watch(
    () => route.params.roomId,
    async (newRoomId) => {
        if (newRoomId) {
            const oldRoomId = roomId.value;
            if (oldRoomId) {
                signalRService.leaveRoom(oldRoomId);
            }

            roomId.value = parseInt(newRoomId);
            await loadRoomInfo();
            await loadMessages();

            if (isConnected.value) {
                signalRService.joinRoom(parseInt(newRoomId));
            }
        }
    }
);
</script>

<style scoped>
.chat-container {
    height: 100vh;
    display: flex;
    flex-direction: column;
    background: #f5f5f5;
}

.chat-header-bar {
    background: white;
    border-bottom: 1px solid #e5e7eb;
    padding: 1rem;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
}

.chat-header-bar h2 {
    flex: 1;
    margin: 0;
    color: #1f2937;
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
    color: #10b981;
    background-color: #d1fae5;
}

.connection-status:not(.connected) {
    color: #ef4444;
    background-color: #fee2e2;
}

.chat-card {
    flex: 1;
    display: flex;
    flex-direction: column;
    margin: 0;
    border-radius: 0;
}

.chat-body {
    flex: 1;
    display: flex;
    flex-direction: column;
    min-height: 0;
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
    color: #667eea;
    margin-bottom: 0.25rem;
    padding-left: 0.5rem;
}

.message-item {
    padding: 0.75rem 1rem;
    border-radius: 8px;
    background-color: #f3f4f6;
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
    color: #6b7280;
    opacity: 0.7;
    align-self: flex-end;
}

.chat-footer {
    padding: 1rem;
    border-top: 1px solid #e5e7eb;
    background-color: white;
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

.messages-container::-webkit-scrollbar {
    width: 8px;
}

.messages-container::-webkit-scrollbar-track {
    background: #f3f4f6;
}

.messages-container::-webkit-scrollbar-thumb {
    background: #d1d5db;
    border-radius: 4px;
}

.messages-container::-webkit-scrollbar-thumb:hover {
    background: #9ca3af;
}

.mention-list {
    position: absolute;
    bottom: 100%;
    left: 0;
    right: 0;
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 4px;
    max-height: 200px;
    overflow-y: auto;
    z-index: 1000;
    margin-bottom: 0.5rem;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.mention-item {
    padding: 0.5rem 1rem;
    cursor: pointer;
    transition: background-color 0.2s;
}

.mention-item:hover,
.mention-item.selected {
    background-color: #667eea;
    color: white;
}

.mention-item:first-child {
    border-top-left-radius: 4px;
    border-top-right-radius: 4px;
}

.mention-item:last-child {
    border-bottom-left-radius: 4px;
    border-bottom-right-radius: 4px;
}
</style>

