<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue';
import signalRService from '@/service/SignalRService';
import PartyService from '@/service/PartyService';
import CommentService from '@/service/CommentService';
import TopicService from '@/service/TopicService';
import request from '@/service/request';
import { useI18n } from '@/composables/useI18n';
import { useToast } from 'primevue/usetoast';
import { useAuthStore } from '@/stores/auth';
import { getEmailFromToken } from '@/utils/jwt';

const props = defineProps({
    topicIdProp: {
        type: Number,
        default: null
    }
});

const { t, locale } = useI18n();
const toast = useToast();
const authStore = useAuthStore();
const partyService = new PartyService(request);
const commentService = new CommentService(request);
const topicService = new TopicService(request);

const comments = ref([]);
const commentText = ref('');
const topicId = ref(null);
const currentPartyId = ref(null);
const topicTitle = ref('');
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
const commentContainer = ref(null);
const partyMap = ref(new Map());
let connectionIdInterval = null;

const initializeParams = () => {
    if (props.topicIdProp) {
        topicId.value = props.topicIdProp;
    }
};

const loadComments = async () => {
    if (!topicId.value) {
        return;
    }

    try {
        const result = await commentService.getList({
            topicId: topicId.value,
            pageIndex: 1,
            pageSize: 1000
        });

        if (result && result.resultViewModels) {
            const partyIds = [...new Set(result.resultViewModels.map((c) => c.partyId))];
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
                        partyMap.value.set(pid, `${t('chat.user')} ${pid}`);
                    }
                }
            }

            comments.value = result.resultViewModels
                .map((c) => ({
                    id: c.id,
                    partyId: c.partyId,
                    partyName: partyMap.value.get(c.partyId) || `${t('chat.user')} ${c.partyId}`,
                    content: c.content,
                    timestamp: new Date(c.createDate),
                    createDate: c.createDate
                }))
                .sort((a, b) => new Date(a.createDate) - new Date(b.createDate));

            nextTick(() => {
                if (commentContainer.value) {
                    commentContainer.value.scrollTop = commentContainer.value.scrollHeight;
                }
            });
        }
    } catch (error) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: error?.response?.data?.message || error?.message || t('topic.commentsLoadError'),
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

const loadTopicInfo = async () => {
    if (!topicId.value) {
        return;
    }

    try {
        const result = await topicService.getById(topicId.value);

        if (result) {
            topicTitle.value = result.title || `Topic ${topicId.value}`;

            const userPartyId = await getCurrentUserPartyId();
            if (userPartyId) {
                currentPartyId.value = userPartyId;
            }
        } else {
            topicTitle.value = `Topic ${topicId.value}`;
        }
    } catch (error) {
        topicTitle.value = `Topic ${topicId.value}`;
    }
};

onMounted(async () => {
    initializeParams();

    if (!topicId.value) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: t('chat.roomIdNotFound'),
            life: 5000
        });
        return;
    }

    await loadTopicInfo();
    await loadComments();

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

        if (topicId.value && isConnected.value) {
            signalRService.joinTopic(topicId.value);
        }

        signalRService.onReceiveComment((partyId, partyName, message, receivedTopicId) => {
            if (receivedTopicId === topicId.value) {
                const partyNameToUse = partyMap.value.get(partyId) || partyName || `${t('chat.user')} ${partyId}`;

                const now = new Date();
                const commentExists = comments.value.some((c) => c.partyId === partyId && c.content === message && Math.abs(now - new Date(c.timestamp)) < 5000);

                if (!commentExists) {
                    comments.value.push({
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
                        if (commentContainer.value) {
                            commentContainer.value.scrollTop = commentContainer.value.scrollHeight;
                        }
                    });
                }
            }
        });

        signalRService.onReceiveError((errorMessage) => {
            toast.add({
                severity: 'error',
                summary: t('common.error'),
                detail: errorMessage,
                life: 5000
            });
        });
    } catch (error) {
        connectionError.value = true;
    }
});

onUnmounted(() => {
    if (connectionIdInterval) {
        clearInterval(connectionIdInterval);
    }

    if (topicId.value) {
        signalRService.leaveTopic(topicId.value);
    }
});

function sendComment() {
    if (!commentText.value.trim()) {
        return;
    }

    if (!isConnected.value) {
        toast.add({
            severity: 'warn',
            summary: t('common.warning'),
            detail: t('chat.noConnection'),
            life: 5000
        });
        return;
    }

    if (!topicId.value || topicId.value <= 0) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: t('chat.invalidRoomId'),
            life: 5000
        });
        return;
    }

    if (!currentPartyId.value) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: t('chat.partyIdNotFound'),
            life: 5000
        });
        return;
    }

    const message = commentText.value.trim();

    signalRService.sendComment(currentPartyId.value, topicId.value, message);

    const partyName = partyMap.value.get(currentPartyId.value) || `${t('chat.user')} ${currentPartyId.value}`;
    comments.value.push({
        id: Date.now(),
        partyId: currentPartyId.value,
        partyName: partyName,
        content: message,
        timestamp: new Date(),
        createDate: new Date().toISOString()
    });

    commentText.value = '';

    nextTick(() => {
        if (commentContainer.value) {
            commentContainer.value.scrollTop = commentContainer.value.scrollHeight;
        }
    });
}

function onEnterKey(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault();
        sendComment();
    }
}

function getInitials(name) {
    if (!name) return '?';
    const parts = name.split(' ');
    if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
}

function formatDate(date) {
    const now = new Date();
    const messageDate = new Date(date);
    const diffTime = Math.abs(now - messageDate);
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays === 0) {
        return t('common.today');
    } else if (diffDays === 1) {
        return t('common.yesterday');
    } else if (diffDays < 7) {
        return messageDate.toLocaleDateString(locale.value === 'tr' ? 'tr-TR' : 'en-US', { weekday: 'long' });
    } else {
        return messageDate.toLocaleDateString(locale.value === 'tr' ? 'tr-TR' : 'en-US', { day: 'numeric', month: 'short' });
    }
}

watch(
    () => props.topicIdProp,
    async (newTopicId, oldTopicId) => {
        if (newTopicId) {
            if (oldTopicId) {
                signalRService.leaveTopic(oldTopicId);
            }

            topicId.value = newTopicId;
            await loadTopicInfo();
            await loadComments();

            if (isConnected.value) {
                signalRService.joinTopic(newTopicId);
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
                    <div class="topic-icon">
                        <i class="pi pi-comments"></i>
                    </div>
                    <div class="topic-info">
                        <h2 class="topic-title">{{ topicTitle }}</h2>
                        <div class="connection-status" :class="{ connected: isConnected }">
                            <div class="status-dot"></div>
                            <span>{{ connectionStatus }}</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Messages Area -->
            <div class="chat-body">
                <div ref="commentContainer" class="messages-container">
                    <div v-if="comments.length === 0" class="empty-messages">
                        <div class="empty-icon">
                            <i class="pi pi-comments"></i>
                        </div>
                        <p class="empty-text">{{ t('chat.noMessages') }}</p>
                    </div>
                    <template v-else>
                        <div 
                            v-for="(comment, index) in comments" 
                            :key="comment.id" 
                            class="message-wrapper"
                            :class="{ 'is-own-message': comment.partyId === currentPartyId }"
                        >
                            <!-- Show avatar and name only for first message from a user or when user changes -->
                            <div 
                                v-if="index === 0 || comments[index - 1].partyId !== comment.partyId" 
                                class="message-header"
                                :class="{ 'own-header': comment.partyId === currentPartyId }"
                            >
                                <div class="message-avatar" :class="{ 'own-avatar': comment.partyId === currentPartyId }">
                                    {{ getInitials(comment.partyName) }}
                                </div>
                                <span class="message-sender">{{ comment.partyName }}</span>
                                <span class="message-date">
                                    {{ formatDate(comment.timestamp) }}
                                </span>
                            </div>
                            
                            <!-- Message Bubble -->
                            <div class="message-bubble" :class="{ 'own-bubble': comment.partyId === currentPartyId }">
                                <div class="message-text">{{ comment.content }}</div>
                                <div class="message-timestamp">
                                    {{ comment.timestamp.toLocaleTimeString(locale.value === 'tr' ? 'tr-TR' : 'en-US', { hour: '2-digit', minute: '2-digit' }) }}
                                </div>
                            </div>
                        </div>
                    </template>
                </div>
            </div>

            <!-- Modern Input Area -->
            <div class="chat-footer">
                <div class="input-wrapper">
                    <div class="input-container">
                        <InputText
                            v-model="commentText"
                            @keydown="onEnterKey"
                            :placeholder="t('chat.messagePlaceholder')"
                            class="message-input"
                        />
                        <button 
                            class="send-button"
                            @click="sendComment" 
                            :disabled="!isConnected || !commentText.trim() || !topicId"
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

.topic-icon {
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

.topic-info {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
    flex: 1;
}

.topic-title {
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

/* Responsive */
@media (max-width: 768px) {
    .message-wrapper {
        max-width: 85%;
    }
    
    .chat-header {
        padding: 1rem;
    }
    
    .topic-title {
        font-size: 1.125rem;
    }
    
    .messages-container {
        padding: 1rem 0.75rem;
    }
}
</style>
