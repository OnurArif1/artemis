<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue';
import { useRoute } from 'vue-router';
import signalRService from '@/service/SignalRService';
import PartyService from '@/service/PartyService';
import MessageService from '@/service/MessageService';
import RoomService from '@/service/RoomService';
import request from '@/service/request';
import { useI18n } from '@/composables/useI18n';
import { useToast } from 'primevue/usetoast';
import { useAuthStore } from '@/stores/auth';
import { getEmailFromToken } from '@/utils/jwt';

const props = defineProps({
    roomIdProp: {
        type: Number,
        default: null
    }
});

const route = useRoute();
const { t, locale } = useI18n();
const toast = useToast();
const authStore = useAuthStore();
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
const connectionStatus = computed(() => {
    if (connectionError.value) {
        return t('chat.connectionError');
    }
    if (!isConnected.value) {
        return t('chat.connecting');
    }
    return t('chat.connected');
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

const initializeParams = () => {
    if (props.roomIdProp) {
        roomId.value = props.roomIdProp;
    } else {
        const roomIdParam = route.query.roomId;
        if (roomIdParam) {
            roomId.value = parseInt(roomIdParam);
        }
    }
};

const loadMessages = async () => {
    if (!roomId.value) {
        return;
    }

    try {
        const result = await messageService.getList({
            roomId: roomId.value,
            pageIndex: 1,
            pageSize: 1000
        });

        if (result && result.resultViewmodels) {
            const partyIds = [...new Set(result.resultViewmodels.map((m) => m.partyId))];
            for (const pid of partyIds) {
                if (!partyMap.value.has(pid)) {
                    try {
                        const partyResult = await partyService.getLookup({ PartyId: pid });
                        if (partyResult && partyResult.viewModels && partyResult.viewModels.length > 0) {
                            partyMap.value.set(pid, partyResult.viewModels[0].partyName);
                        } else {
                            partyMap.value.set(pid, `${t('chat.user')} ${pid}`);
                        }
                    } catch {
                        partyMap.value.set(pid, `Kullanıcı ${pid}`);
                    }
                }
            }

            messages.value = result.resultViewmodels
                .map((m) => ({
                    id: m.id,
                    partyId: m.partyId,
                    partyName: partyMap.value.get(m.partyId) || `${t('chat.user')} ${m.partyId}`,
                    content: m.content,
                    timestamp: new Date(m.createDate),
                    createDate: m.createDate
                }))
                .sort((a, b) => new Date(a.createDate) - new Date(b.createDate));

            if (messages.value.length > 0 && !currentPartyId.value) {
                currentPartyId.value = messages.value[0].partyId;
            }

            nextTick(() => {
                if (messageContainer.value) {
                    messageContainer.value.scrollTop = messageContainer.value.scrollHeight;
                }
            });
        }
    } catch (error) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: error?.response?.data?.message || error?.message || t('chat.errorLoadingMessages'),
            life: 5000
        });
    }
};

const getCurrentUserPartyId = async () => {
    try {
        const token = authStore.token || localStorage.getItem('auth.token');
        if (!token) {
            return null;
        }

        const email = getEmailFromToken(token);
        if (!email) {
            return null;
        }

        const lookupByEmail = await partyService.getLookup({
            searchText: email,
            partyLookupSearchType: 3
        });

        if (lookupByEmail && lookupByEmail.viewModels && lookupByEmail.viewModels.length > 0) {
            const foundParty = lookupByEmail.viewModels.find((p) => p.partyName === email);
            if (foundParty) {
                return foundParty.partyId;
            }
            return lookupByEmail.viewModels[0].partyId;
        }

        const lookupByPartyName = await partyService.getLookup({
            searchText: email,
            partyLookupSearchType: 1
        });

        if (lookupByPartyName && lookupByPartyName.viewModels && lookupByPartyName.viewModels.length > 0) {
            const exactMatch = lookupByPartyName.viewModels.find((p) => p.partyName.toLowerCase() === email.toLowerCase());
            if (exactMatch) {
                return exactMatch.partyId;
            }
        }

        return null;
    } catch (error) {
        return null;
    }
};

const ensureUserInRoom = async () => {
    if (!roomId.value) {
        return false;
    }

    try {
        const userPartyId = await getCurrentUserPartyId();
        if (!userPartyId) {
            return false;
        }

        const result = await roomService.getList({
            pageIndex: 1,
            pageSize: 1000
        });

        if (result && result.resultViewModels) {
            const room = result.resultViewModels.find((r) => r.id === roomId.value);
            if (room) {
                const isUserInRoom = room.parties && room.parties.some((p) => p.id === userPartyId);
                if (!isUserInRoom) {
                    try {
                        await roomService.addPartyToRoom({
                            roomId: roomId.value,
                            partyId: userPartyId
                        });
                        return true;
                    } catch (error) {
                        throw error;
                    }
                }
                return true;
            }
        }
        return false;
    } catch (error) {
        return false;
    }
};

const loadRoomInfo = async () => {
    if (!roomId.value) {
        return;
    }

    try {
        const result = await roomService.getList({
            pageIndex: 1,
            pageSize: 1000
        });

        if (result && result.resultViewModels) {
            const room = result.resultViewModels.find((r) => r.id === roomId.value);
            if (room) {
                roomTitle.value = room.title || `Room ${roomId.value}`;

                const userPartyId = await getCurrentUserPartyId();
                if (userPartyId) {
                    currentPartyId.value = userPartyId;
                } else if (room.partyId && !currentPartyId.value) {
                    currentPartyId.value = room.partyId;
                }

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
                roomTitle.value = `Room ${roomId.value}`;
            }
        } else {
            roomTitle.value = `Room ${roomId.value}`;
        }
    } catch (error) {
        roomTitle.value = `Room ${roomId.value}`;
    }
};

onMounted(async () => {
    initializeParams();

    if (!roomId.value) {
        alert(t('chat.roomIdNotFound'));
        return;
    }

    const userAdded = await ensureUserInRoom();
    if (userAdded) {
        await loadRoomInfo();
    } else {
        await loadRoomInfo();
    }

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
        }, 1000);

        if (roomId.value && isConnected.value) {
            signalRService.joinRoom(roomId.value);
        }

        signalRService.onReceiveMessage((partyId, partyName, message, receivedRoomId) => {
            if (receivedRoomId === roomId.value) {
                const partyNameToUse = partyMap.value.get(partyId) || partyName || `${t('chat.user')} ${partyId}`;

                const now = new Date();
                const messageExists = messages.value.some((m) => m.partyId === partyId && m.content === message && Math.abs(now - new Date(m.timestamp)) < 5000);

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

function sendMessage() {
    if (!messageText.value.trim()) {
        return;
    }

    if (!isConnected.value) {
        alert(t('chat.noConnection'));
        return;
    }

    if (!roomId.value || roomId.value <= 0) {
        alert(t('chat.invalidRoomId'));
        return;
    }

    if (!currentPartyId.value) {
        alert(t('chat.partyIdNotFound'));
        return;
    }

    const message = messageText.value.trim();
    const mentionedPartyIds = parseMentions(message);

    signalRService.sendMessage(currentPartyId.value, roomId.value, message, mentionedPartyIds.length > 0 ? mentionedPartyIds : null);

    const partyName = partyMap.value.get(currentPartyId.value) || `${t('chat.user')} ${currentPartyId.value}`;
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

function deleteMention(event) {
    const text = messageText.value;
    const cursorPosition = event.target.selectionStart || 0;

    if (cursorPosition === 0) return;

    const textBeforeCursor = text.substring(0, cursorPosition);
    const lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex !== -1) {
        const textAfterAt = text.substring(lastAtIndex + 1);
        const spaceIndex = textAfterAt.indexOf(' ');
        const newlineIndex = textAfterAt.indexOf('\n');
        let mentionEnd;

        if (spaceIndex !== -1 && newlineIndex !== -1) {
            mentionEnd = lastAtIndex + 1 + Math.min(spaceIndex, newlineIndex) + 1;
        } else if (spaceIndex !== -1) {
            mentionEnd = lastAtIndex + 1 + spaceIndex + 1;
        } else if (newlineIndex !== -1) {
            mentionEnd = lastAtIndex + 1 + newlineIndex;
        } else {
            mentionEnd = text.length;
        }

        if (cursorPosition > lastAtIndex && cursorPosition <= mentionEnd) {
            event.preventDefault();
            const beforeMention = text.substring(0, lastAtIndex);
            const afterMention = text.substring(mentionEnd);
            messageText.value = beforeMention + afterMention;

            nextTick(() => {
                const input = document.getElementById('messageInput');
                if (input) {
                    input.focus();
                    input.setSelectionRange(lastAtIndex, lastAtIndex);
                }
            });
        }
    }
}

function handleMentionKeydown(event) {
    if (event.key === 'Backspace' || event.key === 'Delete') {
        if (showMentionList.value) {
            showMentionList.value = false;
            mentionStartPosition.value = -1;
        }
        deleteMention(event);
        return;
    }

    if (!showMentionList.value) {
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
    }
}

function onEnterKey(event) {
    if (showMentionList.value) {
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

    if (event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault();
        sendMessage();
    }
}

watch(
    () => props.roomIdProp,
    async (newRoomId, oldRoomId) => {
        if (newRoomId) {
            if (oldRoomId) {
                signalRService.leaveRoom(oldRoomId);
            }

            roomId.value = newRoomId;
            await loadRoomInfo();
            await loadMessages();

            if (isConnected.value) {
                signalRService.joinRoom(newRoomId);
            }
        }
    }
);

watch(
    () => route.query.roomId,
    async (newRoomId, oldRoomId) => {
        if (newRoomId && !props.roomIdProp) {
            if (oldRoomId) {
                signalRService.leaveRoom(parseInt(oldRoomId));
            }

            roomId.value = parseInt(newRoomId);
            await loadMessages();

            if (isConnected.value) {
                signalRService.joinRoom(parseInt(newRoomId));
            }
        }
    }
);
</script>

<template>
    <div class="chat-container">
        <div class="chat-card">
            <!-- Modern Header -->
            <div class="chat-header">
                <div class="header-left">
                    <div class="room-icon">
                        <i class="pi pi-home"></i>
                    </div>
                    <div class="room-info">
                        <h2 class="room-title">{{ roomTitle }}</h2>
                        <div class="connection-status" :class="{ connected: isConnected }">
                            <div class="status-dot"></div>
                            <span>{{ connectionStatus }}</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Messages Area -->
            <div class="chat-body">
                <div ref="messageContainer" class="messages-container">
                    <div v-if="messages.length === 0" class="empty-messages">
                        <div class="empty-icon">
                            <i class="pi pi-inbox"></i>
                        </div>
                        <p class="empty-text">{{ t('chat.noMessages') }}</p>
                    </div>
                    <template v-else>
                        <div 
                            v-for="(msg, index) in messages" 
                            :key="msg.id" 
                            class="message-wrapper"
                            :class="{ 'is-own-message': msg.partyId === currentPartyId }"
                        >
                            <!-- Show avatar and name only for first message from a user or when user changes -->
                            <div 
                                v-if="index === 0 || messages[index - 1].partyId !== msg.partyId" 
                                class="message-header"
                                :class="{ 'own-header': msg.partyId === currentPartyId }"
                            >
                                <div class="message-avatar" :class="{ 'own-avatar': msg.partyId === currentPartyId }">
                                    {{ getInitials(msg.partyName) }}
                                </div>
                                <span class="message-sender">{{ msg.partyName }}</span>
                                <span class="message-date">
                                    {{ formatDate(msg.timestamp) }}
                                </span>
                            </div>
                            
                            <!-- Message Bubble -->
                            <div class="message-bubble" :class="{ 'own-bubble': msg.partyId === currentPartyId }">
                                <div class="message-text">{{ msg.content }}</div>
                                <div class="message-timestamp">
                                    {{ msg.timestamp.toLocaleTimeString(locale.value === 'tr' ? 'tr-TR' : 'en-US', { hour: '2-digit', minute: '2-digit' }) }}
                                </div>
                            </div>
                        </div>
                    </template>
                </div>
            </div>

            <!-- Modern Input Area -->
            <div class="chat-footer">
                <div class="input-wrapper">
                    <div class="input-container" :class="{ 'has-mentions': showMentionList && mentionList.length > 0 }">
                        <InputText
                            id="messageInput"
                            v-model="messageText"
                            @keydown="
                                (e) => {
                                    handleMentionKeydown(e);
                                    onEnterKey(e);
                                }
                            "
                            @input="handleMentionInput"
                            :placeholder="t('chat.messagePlaceholder')"
                            class="message-input"
                        />
                        <div v-if="showMentionList && mentionList.length > 0" class="mention-list" @click.stop>
                            <div 
                                v-for="(party, index) in mentionList" 
                                :key="party.id" 
                                :class="['mention-item', { selected: index === selectedMentionIndex }]" 
                                @click="selectMention(party)" 
                                @mouseenter="selectedMentionIndex = index"
                            >
                                <div class="mention-avatar">{{ getInitials(party.name) }}</div>
                                <span>{{ party.name }}</span>
                            </div>
                        </div>
                        <button 
                            class="send-button"
                            @click="sendMessage" 
                            :disabled="!isConnected || !messageText.trim() || !roomId"
                        >
                            <i class="pi pi-send"></i>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
.chat-container {
    padding: 0;
    max-width: 100%;
    margin: 0;
    height: 100%;
    display: flex;
    flex-direction: column;
    background: white !important;
}

.chat-card {
    display: flex;
    flex-direction: column;
    height: 100%;
    background: white !important;
    border-radius: 0;
}

/* Modern Header */
.chat-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1.25rem 1.5rem;
    background: linear-gradient(135deg, rgba(99, 0, 255, 0.05), rgba(99, 0, 255, 0.02));
    border-bottom: 1px solid rgba(99, 0, 255, 0.1);
}

.header-left {
    display: flex;
    align-items: center;
    gap: 1rem;
    flex: 1;
}

.room-icon {
    width: 2.5rem;
    height: 2.5rem;
    background: linear-gradient(135deg, #6300FF, #5200CC);
    border-radius: 0.75rem;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 1.25rem;
    box-shadow: 0 4px 12px rgba(99, 0, 255, 0.2);
}

.room-info {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
    flex: 1;
}

.room-title {
    margin: 0;
    font-size: 1.25rem;
    font-weight: 700;
    color: #374151;
    line-height: 1.3;
}

.connection-status {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.8125rem;
    font-weight: 500;
    margin-top: 0.25rem;
}

.connection-status.connected {
    color: #22c55e;
}

.connection-status:not(.connected) {
    color: #ef4444;
}

.status-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: currentColor;
    animation: pulse-dot 2s ease-in-out infinite;
}

.connection-status.connected .status-dot {
    background: #22c55e;
}

.connection-status:not(.connected) .status-dot {
    background: #ef4444;
}

@keyframes pulse-dot {
    0%, 100% {
        opacity: 1;
    }
    50% {
        opacity: 0.5;
    }
}

/* Chat Body */
.chat-body {
    display: flex;
    flex-direction: column;
    flex: 1;
    min-height: 0;
    overflow: hidden;
    background: white !important;
}

.messages-container {
    flex: 1;
    overflow-y: auto;
    padding: 1.5rem 1rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;
    background: white !important;
}

.messages-container::-webkit-scrollbar {
    width: 6px;
}

.messages-container::-webkit-scrollbar-track {
    background: transparent;
}

.messages-container::-webkit-scrollbar-thumb {
    background: rgba(99, 0, 255, 0.2);
    border-radius: 3px;
}

.messages-container::-webkit-scrollbar-thumb:hover {
    background: rgba(99, 0, 255, 0.3);
}

/* Empty State */
.empty-messages {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100%;
    gap: 1rem;
    padding: 3rem 1rem;
}

.empty-icon {
    width: 5rem;
    height: 5rem;
    background: linear-gradient(135deg, rgba(99, 0, 255, 0.1), rgba(99, 0, 255, 0.05));
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #6300FF;
    font-size: 2rem;
}

.empty-text {
    color: #6b7280;
    font-size: 0.9375rem;
    margin: 0;
}

/* Message Wrapper */
.message-wrapper {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    max-width: 75%;
    animation: messageSlideIn 0.3s ease-out;
}

.message-wrapper.is-own-message {
    align-self: flex-end;
    align-items: flex-end;
}

/* Message Header */
.message-header {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0 0.5rem;
    margin-bottom: 0.25rem;
}

.message-header.own-header {
    flex-direction: row-reverse;
}

.message-avatar {
    width: 2rem;
    height: 2rem;
    border-radius: 50%;
    background: linear-gradient(135deg, #6300FF, #5200CC);
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 0.75rem;
    font-weight: 600;
    flex-shrink: 0;
}

.message-avatar.own-avatar {
    background: linear-gradient(135deg, #22c55e, #16a34a);
}

.message-sender {
    font-size: 0.8125rem;
    font-weight: 600;
    color: #374151;
}

.message-date {
    font-size: 0.75rem;
    color: #9ca3af;
    margin-left: auto;
}

.message-header.own-header .message-date {
    margin-left: 0;
    margin-right: auto;
}

/* Message Bubble */
.message-bubble {
    padding: 0.75rem 1rem;
    border-radius: 1rem;
    background: white;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
    max-width: 100%;
    position: relative;
    word-wrap: break-word;
    border: 1px solid #e5e7eb;
}

.message-bubble.own-bubble {
    background: linear-gradient(135deg, #6300FF, #5200CC);
    color: white;
    border-color: transparent;
    border-bottom-right-radius: 0.25rem;
}

.message-wrapper:not(.is-own-message) .message-bubble {
    border-bottom-left-radius: 0.25rem;
}

.message-text {
    font-size: 0.9375rem;
    line-height: 1.5;
    color: #374151;
    word-wrap: break-word;
    white-space: pre-wrap;
}

.message-bubble.own-bubble .message-text {
    color: white;
}

.message-timestamp {
    font-size: 0.6875rem;
    color: #9ca3af;
    margin-top: 0.375rem;
    text-align: right;
}

.message-bubble.own-bubble .message-timestamp {
    color: rgba(255, 255, 255, 0.8);
}

.message-wrapper:not(.is-own-message) .message-timestamp {
    text-align: left;
}

@keyframes messageSlideIn {
    from {
        opacity: 0;
        transform: translateY(10px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

/* Chat Footer */
.chat-footer {
    padding: 1.25rem 1.5rem;
    background: white;
    border-top: 1px solid #e5e7eb;
}

.input-wrapper {
    width: 100%;
    position: relative;
}

.input-container {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    background: #f9fafb;
    border: 1.5px solid #e5e7eb;
    border-radius: 1.5rem;
    padding: 0.5rem 0.75rem;
    transition: all 0.2s ease;
    position: relative;
}

.input-container:focus-within {
    border-color: #6300FF;
    box-shadow: 0 0 0 3px rgba(99, 0, 255, 0.1);
    background: white;
}

:deep(.message-input) {
    flex: 1;
    border: none;
    background: transparent;
    padding: 0.5rem 0.75rem;
    font-size: 0.9375rem;
    color: #374151;
}

:deep(.message-input:focus) {
    outline: none;
    box-shadow: none;
}

:deep(.message-input::placeholder) {
    color: #9ca3af;
}

.send-button {
    width: 2.5rem;
    height: 2.5rem;
    border-radius: 50%;
    border: none;
    background: linear-gradient(135deg, #6300FF, #5200CC);
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.2s ease;
    flex-shrink: 0;
    box-shadow: 0 2px 8px rgba(99, 0, 255, 0.3);
}

.send-button:hover:not(:disabled) {
    transform: scale(1.05);
    box-shadow: 0 4px 12px rgba(99, 0, 255, 0.4);
}

.send-button:active:not(:disabled) {
    transform: scale(0.95);
}

.send-button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
    transform: none;
}

.send-button i {
    font-size: 1rem;
}

/* Mention List */
.mention-list {
    position: absolute;
    bottom: calc(100% + 0.5rem);
    left: 0;
    right: 0;
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 0.75rem;
    max-height: 200px;
    overflow-y: auto;
    z-index: 1000;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
    padding: 0.5rem;
}

.mention-list::-webkit-scrollbar {
    width: 6px;
}

.mention-list::-webkit-scrollbar-track {
    background: transparent;
}

.mention-list::-webkit-scrollbar-thumb {
    background: rgba(99, 0, 255, 0.2);
    border-radius: 3px;
}

.mention-item {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.75rem;
    cursor: pointer;
    transition: all 0.2s ease;
    border-radius: 0.5rem;
}

.mention-item:hover,
.mention-item.selected {
    background: linear-gradient(135deg, rgba(99, 0, 255, 0.1), rgba(99, 0, 255, 0.05));
}

.mention-avatar {
    width: 2rem;
    height: 2rem;
    border-radius: 50%;
    background: linear-gradient(135deg, #6300FF, #5200CC);
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 0.75rem;
    font-weight: 600;
    flex-shrink: 0;
}

.mention-item span {
    font-size: 0.9375rem;
    color: #374151;
    font-weight: 500;
}

/* Responsive */
@media (max-width: 768px) {
    .message-wrapper {
        max-width: 85%;
    }
    
    .chat-header {
        padding: 1rem;
    }
    
    .room-title {
        font-size: 1.125rem;
    }
    
    .messages-container {
        padding: 1rem 0.75rem;
    }
}
</style>
