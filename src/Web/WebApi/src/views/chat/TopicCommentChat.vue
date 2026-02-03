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
        <div class="card">
            <div class="chat-header">
                <div class="flex align-items-center gap-2">
                    <i class="pi pi-comments text-2xl"></i>
                    <h2 class="m-0">{{ topicTitle }}</h2>
                </div>
                <div class="flex align-items-center gap-2">
                    <div class="connection-status" :class="{ connected: isConnected }">
                        <i :class="isConnected ? 'pi pi-check-circle' : 'pi pi-times-circle'"></i>
                        <span>{{ connectionStatus }}</span>
                    </div>
                </div>
            </div>

            <div class="chat-body">
                <div ref="commentContainer" class="messages-container">
                    <div v-if="comments.length === 0" class="empty-messages">
                        <i class="pi pi-inbox text-4xl text-300"></i>
                        <p class="text-500">{{ t('chat.noMessages') }}</p>
                    </div>
                    <template v-else>
                        <div v-for="(comment, index) in comments" :key="comment.id" class="message-group">
                            <div v-if="index === 0 || comments[index - 1].partyId !== comment.partyId" class="message-party-name">
                                {{ comment.partyName }}
                            </div>
                            <div class="message-item">
                                <div class="message-content">{{ comment.content }}</div>
                                <div class="message-time">
                                    {{ comment.timestamp.toLocaleTimeString(locale.value === 'tr' ? 'tr-TR' : 'en-US', { hour: '2-digit', minute: '2-digit' }) }}
                                </div>
                            </div>
                        </div>
                    </template>
                </div>
            </div>

            <div class="chat-footer">
                <div class="flex gap-2 align-items-center w-full">
                    <InputText
                        v-model="commentText"
                        @keydown="onEnterKey"
                        :placeholder="t('chat.messagePlaceholder')"
                        class="flex-1"
                    />
                    <Button :label="t('chat.send')" icon="pi pi-send" @click="sendComment" :disabled="!isConnected || !commentText.trim() || !topicId" />
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
.chat-container {
    padding: 1rem;
    max-width: 100%;
    margin: 0 auto;
    height: 100%;
    display: flex;
    flex-direction: column;
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
    flex: 1;
    min-height: 300px;
    max-height: 500px;
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
