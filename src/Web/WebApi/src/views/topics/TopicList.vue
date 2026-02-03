<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from '@/composables/useI18n';
import { useToast } from 'primevue/usetoast';
import { useAuthStore } from '@/stores/auth';
import { getEmailFromToken } from '@/utils/jwt';
import request from '@/service/request';
import TopicService from '@/service/TopicService';
import CommentService from '@/service/CommentService';
import RoomService from '@/service/RoomService';
import PartyService from '@/service/PartyService';
import { useLayout } from '@/layout/composables/layout';

const router = useRouter();
const { t, locale } = useI18n();
const toast = useToast();
const authStore = useAuthStore();
const { setActiveMenuItem } = useLayout();

const topicService = new TopicService(request);
const commentService = new CommentService(request);
const roomService = new RoomService(request);
const partyService = new PartyService(request);

const topics = ref([]);
const filteredTopics = ref([]);
const searchText = ref('');
const pageIndex = ref(1);
const pageSize = ref(20);
const totalRecords = ref(0);
const loading = ref(false);
const roomsMap = ref(new Map());
const commentsMap = ref(new Map());
const expandedStates = ref({});

const showCommentDialog = ref(false);
const selectedTopic = ref(null);
const commentText = ref('');
const currentPartyId = ref(null);

async function loadRooms() {
    try {
        const roomData = await roomService.getList({
            pageIndex: 1,
            pageSize: 1000
        });
        const rooms = Array.isArray(roomData.resultViewModels) ? roomData.resultViewModels : (roomData?.resultViewModels ?? []);
        roomsMap.value.clear();
        rooms.forEach((room) => {
            if (room.topicId) {
                if (!roomsMap.value.has(room.topicId)) {
                    roomsMap.value.set(room.topicId, []);
                }
                roomsMap.value.get(room.topicId).push(room);
            }
        });
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || t('topic.roomsLoadError'),
            life: 5000
        });
    }
}

async function loadCommentsForTopics(topicIds) {
    try {
        if (!topicIds || topicIds.length === 0) return;

        const commentPromises = topicIds.map(async (topicId) => {
            try {
                const commentData = await commentService.getList({
                    pageIndex: 1,
                    pageSize: 100,
                    topicId: topicId
                });
                const comments = Array.isArray(commentData.resultViewModels) ? commentData.resultViewModels : (commentData?.resultViewModels ?? []);

                const actualCount = commentData?.count || comments.length;

                return { topicId, comments, count: actualCount };
            } catch (err) {
                toast.add({
                    severity: 'warn',
                    summary: t('common.warning'),
                    detail: err?.response?.data?.message || err?.message || t('topic.commentsLoadError'),
                    life: 3000
                });
                return { topicId, comments: [], count: 0 };
            }
        });

        const results = await Promise.all(commentPromises);
        commentsMap.value.clear();
        results.forEach(({ topicId, comments, count }) => {
            if (count > 0 || comments.length > 0) {
                commentsMap.value.set(topicId, { comments, count: count || comments.length });
            } else {
                commentsMap.value.set(topicId, { comments: [], count: 0 });
            }
        });
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || t('topic.commentsLoadError'),
            life: 5000
        });
    }
}

async function loadTopics() {
    loading.value = true;
    try {
        await loadRooms();

        const filter = {
            pageIndex: pageIndex.value,
            pageSize: pageSize.value
        };
        const data = await topicService.getList(filter);
        const loadedTopics = Array.isArray(data.resultViewModels) ? data.resultViewModels : (data?.resultViewModels ?? []);

        const topicIds = loadedTopics.map((t) => t.id);
        await loadCommentsForTopics(topicIds);

        topics.value = loadedTopics.map((topic) => {
            const commentData = commentsMap.value.get(topic.id);
            const commentCount = commentData?.count || 0;
            const comments = commentData?.comments || [];

            if (!(topic.id in expandedStates.value)) {
                expandedStates.value[topic.id] = false;
            }

            return {
                ...topic,
                hasRoom: roomsMap.value.has(topic.id) && roomsMap.value.get(topic.id).length > 0,
                room: roomsMap.value.has(topic.id) ? roomsMap.value.get(topic.id)[0] : null,
                comments: comments,
                commentCount: commentCount
            };
        });

        totalRecords.value = data?.count ?? 0;
        filterTopics();
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || t('topic.listLoadError'),
            life: 5000
        });
    } finally {
        loading.value = false;
    }
}

function filterTopics() {
    if (!searchText.value || searchText.value.trim() === '') {
        filteredTopics.value = topics.value.map((t) => ({ ...t }));
        return;
    }
    const searchLower = searchText.value.toLowerCase().trim();
    filteredTopics.value = topics.value.filter((topic) => topic.title?.toLowerCase().includes(searchLower)).map((t) => ({ ...t }));
}

function onSearch() {
    filterTopics();
}

function toggleComments(topicId) {
    const currentValue = expandedStates.value[topicId] === true;
    expandedStates.value[topicId] = !currentValue;
}

function getCommentCount(topic) {
    if (topic.commentCount && topic.commentCount > 0) {
        return topic.commentCount;
    }
    if (topic.comments && topic.comments.length > 0) {
        return topic.comments.length;
    }
    return 0;
}

async function getCurrentUserPartyId() {
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
}

async function openCommentDialog(topic) {
    selectedTopic.value = topic;
    commentText.value = '';

    if (!currentPartyId.value) {
        currentPartyId.value = await getCurrentUserPartyId();
    }

    if (!currentPartyId.value) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: t('topic.userInfoNotFound'),
            life: 5000
        });
        return;
    }

    showCommentDialog.value = true;
}

async function saveComment() {
    if (!selectedTopic.value || !currentPartyId.value) {
        return;
    }

    if (!commentText.value || commentText.value.trim() === '') {
        toast.add({
            severity: 'warn',
            summary: t('common.warning'),
            detail: t('topic.commentTextRequired'),
            life: 3000
        });
        return;
    }

    try {
        const payload = {
            topicId: selectedTopic.value.id,
            partyId: currentPartyId.value,
            content: commentText.value.trim(),
            upvote: 0,
            downvote: 0,
            lastUpdateDate: new Date().toISOString()
        };

        const result = await commentService.create(payload);

        if (result?.isSuccess) {
            toast.add({
                severity: 'success',
                summary: t('common.success'),
                detail: t('topic.commentAdded'),
                life: 3000
            });
            showCommentDialog.value = false;
            commentText.value = '';

            if (selectedTopic.value) {
                const topicId = selectedTopic.value.id;
                await loadCommentsForTopics([topicId]);

                const topicIndex = topics.value.findIndex((t) => t.id === topicId);
                if (topicIndex !== -1) {
                    const commentData = commentsMap.value.get(topicId);
                    const commentCount = commentData?.count || 0;
                    const comments = commentData?.comments || [];

                    topics.value[topicIndex] = {
                        ...topics.value[topicIndex],
                        comments: comments,
                        commentCount: commentCount
                    };
                    filterTopics();

                    if (expandedStates.value[topicId] === true) {
                        expandedStates.value[topicId] = false;
                        setTimeout(() => {
                            expandedStates.value[topicId] = true;
                        }, 0);
                    }
                }
            }

            selectedTopic.value = null;
        } else {
            toast.add({
                severity: 'error',
                summary: t('common.error'),
                detail: result?.exceptionMessage || t('topic.commentError'),
                life: 5000
            });
        }
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || t('topic.commentError'),
            life: 5000
        });
    }
}

async function goToRoom(topic) {
    try {
        if (topic.room) {
            const targetRoom = topic.room;
            setActiveMenuItem('1-1');
            await router.push({
                name: 'room',
                query: { roomId: targetRoom.id }
            });
            return;
        }

        const roomFilter = {
            pageIndex: 1,
            pageSize: 100,
            topicId: topic.id
        };

        const roomData = await roomService.getList(roomFilter);
        const rooms = Array.isArray(roomData.resultViewModels) ? roomData.resultViewModels : (roomData?.resultViewModels ?? []);

        if (!rooms || rooms.length === 0) {
            toast.add({
                severity: 'info',
                summary: t('common.info'),
                detail: t('topic.noRoomForTopic'),
                life: 3000
            });
            return;
        }

        const targetRoom = rooms[0];

        setActiveMenuItem('1-1');

        await router.push({
            name: 'room',
            query: { roomId: targetRoom.id }
        });
    } catch (err) {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: err?.response?.data?.message || err?.message || t('topic.roomNotFound'),
            life: 5000
        });
    }
}

onMounted(async () => {
    await loadTopics();
    currentPartyId.value = await getCurrentUserPartyId();
});
</script>

<template>
    <div class="topic-list-container">
        <div class="topic-list-header">
            <h2>{{ t('topic.list') }}</h2>
            <div class="search-container">
                <InputText v-model="searchText" :placeholder="t('topic.searchPlaceholder')" @input="onSearch" class="search-input" />
                <i class="pi pi-search search-icon" />
            </div>
        </div>

        <div v-if="loading" class="loading-container">
            <ProgressSpinner />
            <span class="ml-2">{{ t('common.loading') }}</span>
        </div>

        <div v-else class="topic-list">
            <div v-if="filteredTopics.length === 0" class="empty-state">
                <i class="pi pi-inbox" style="font-size: 3rem; color: var(--surface-400)" />
                <p>{{ searchText ? t('topic.noResults') : t('topic.noTopics') }}</p>
            </div>

            <div v-else class="topic-items">
                <div
                    v-for="(topic, index) in filteredTopics"
                    :key="`topic-${topic.id}-${index}`"
                    class="topic-item"
                    :style="{ '--delay': `${index * 0.05}s` }"
                >
                    <div class="topic-content">
                        <h3 class="topic-title">{{ topic.title }}</h3>
                        <div class="topic-meta">
                            <span v-if="topic.categoryName" class="topic-category"> <i class="pi pi-tag" /> {{ topic.categoryName }} </span>
                            <span class="topic-date"> <i class="pi pi-calendar" /> {{ new Date(topic.createDate).toLocaleDateString(locale === 'tr' ? 'tr-TR' : 'en-US') }} </span>
                        </div>
                        <div v-if="(topic.commentCount && topic.commentCount > 0) || (topic.comments && topic.comments.length > 0)" class="topic-comments">
                            <div class="comment-header" @click.stop.prevent="toggleComments(topic.id)">
                                <i class="pi pi-comments" />
                                <span class="comment-count"> {{ getCommentCount(topic) }} {{ t('topic.comments') }} </span>
                                <i :class="expandedStates[topic.id] === true ? 'pi pi-chevron-up' : 'pi pi-chevron-down'" class="comment-toggle-icon" />
                            </div>
                            <Transition name="slide-fade">
                                <div v-if="expandedStates[topic.id] === true" class="comment-list">
                                    <template v-if="topic.comments && topic.comments.length > 0">
                                        <div v-for="comment in topic.comments" :key="comment.id" class="comment-item">
                                            <div class="comment-content">
                                                <div class="comment-header-info">
                                                    <span class="comment-author">
                                                        <i class="pi pi-user" />
                                                        {{ comment.partyName || `${t('topic.partyPrefix')}${comment.partyId}` }}
                                                    </span>
                                                    <span class="comment-date">{{
                                                        new Date(comment.createDate).toLocaleDateString(locale === 'tr' ? 'tr-TR' : 'en-US', {
                                                            year: 'numeric',
                                                            month: 'long',
                                                            day: 'numeric',
                                                            hour: '2-digit',
                                                            minute: '2-digit'
                                                        })
                                                    }}</span>
                                                </div>
                                                <p class="comment-text">{{ comment.content || t('topic.noCommentText') }}</p>
                                            </div>
                                        </div>
                                    </template>
                                    <div v-else class="no-comments">
                                        <p>{{ t('topic.commentsLoading') }}</p>
                                    </div>
                                </div>
                            </Transition>
                        </div>
                    </div>
                    <div class="topic-actions">
                        <Button icon="pi pi-comment" :label="t('topic.makeComment')" class="p-button-sm p-button-outlined" @click="openCommentDialog(topic)" />
                        <Button v-if="topic.hasRoom" icon="pi pi-sign-in" :label="t('topic.goToRoom')" class="p-button-sm p-button-outlined" @click="goToRoom(topic)" />
                    </div>
                </div>
            </div>
        </div>

        <Dialog :visible="showCommentDialog" @update:visible="(val) => (showCommentDialog = val)" modal :closable="true" :header="t('topic.commentDialogTitle')" :style="{ width: '500px' }">
            <div class="comment-dialog-content">
                <div class="mb-3">
                    <label class="block mb-2 font-semibold">{{ t('common.topics') }}:</label>
                    <p class="text-lg">{{ selectedTopic?.title }}</p>
                </div>
                <div class="mb-3">
                    <label class="block mb-2 font-semibold">{{ t('topic.commentLabel') }}</label>
                    <Textarea v-model="commentText" rows="5" :placeholder="t('topic.commentPlaceholder')" class="w-full" />
                </div>
            </div>
            <template #footer>
                <Button :label="t('common.cancel')" icon="pi pi-times" class="p-button-text" @click="showCommentDialog = false" />
                <Button :label="t('common.save')" icon="pi pi-check" @click="saveComment" />
            </template>
        </Dialog>
    </div>
</template>

<style scoped lang="scss">
.topic-list-container {
    padding: 2rem;
    max-width: 1200px;
    margin: 0 auto;
}

.topic-list-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;
    flex-wrap: wrap;
    gap: 1rem;
}

.topic-list-header h2 {
    margin: 0;
    color: var(--text-color);
}

.search-container {
    position: relative;
    width: 100%;
    max-width: 400px;
}

.search-input {
    width: 100%;
    padding-right: 2.5rem;
}

.search-icon {
    position: absolute;
    right: 0.75rem;
    top: 50%;
    transform: translateY(-50%);
    color: var(--surface-400);
    pointer-events: none;
}

.loading-container {
    display: flex;
    justify-content: center;
    align-items: center;
    padding: 3rem;
}

.topic-list {
    min-height: 400px;
}

.empty-state {
    text-align: center;
    padding: 4rem 2rem;
    color: var(--surface-400);
}

.empty-state p {
    margin-top: 1rem;
    font-size: 1.1rem;
}

.topic-items {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 1.5rem;
}

@media (max-width: 1400px) {
    .topic-items {
        grid-template-columns: repeat(3, 1fr);
    }
}

@media (max-width: 1024px) {
    .topic-items {
        grid-template-columns: repeat(2, 1fr);
    }
}

@media (max-width: 768px) {
    .topic-items {
        grid-template-columns: 1fr;
    }
}

.topic-item {
    position: relative;
    display: flex;
    flex-direction: column;
    padding: 2rem;
    background: linear-gradient(
        145deg,
        color-mix(in srgb, var(--surface-0) 98%, var(--primary-color)) 0%,
        var(--surface-0) 50%,
        color-mix(in srgb, var(--surface-0) 95%, var(--primary-color)) 100%
    );
    border: 1.5px solid color-mix(in srgb, var(--primary-color) 12%, transparent);
    border-radius: 24px;
    box-shadow:
        0 8px 32px rgba(0, 0, 0, 0.08),
        0 2px 8px rgba(0, 0, 0, 0.04),
        inset 0 1px 0 rgba(255, 255, 255, 0.6),
        inset 0 -1px 0 rgba(0, 0, 0, 0.02);
    transition:
        all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1),
        box-shadow 0.3s ease,
        border-color 0.3s ease;
    height: 100%;
    overflow: hidden;
    backdrop-filter: blur(20px) saturate(180%);
    animation: cardFadeIn 0.6s ease-out var(--delay, 0s) both;
    will-change: transform;
}

.topic-item::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 3px;
    background: linear-gradient(
        90deg,
        transparent 0%,
        var(--primary-color) 20%,
        color-mix(in srgb, var(--primary-color) 90%, #ff6b9d) 50%,
        var(--primary-color) 80%,
        transparent 100%
    );
    background-size: 300% 100%;
    animation: shimmer 4s ease-in-out infinite;
    opacity: 0.9;
    border-radius: 24px 24px 0 0;
    filter: blur(1px);
}

.topic-item::after {
    content: '';
    position: absolute;
    top: -100%;
    left: -100%;
    width: 300%;
    height: 300%;
    background: radial-gradient(
        circle at center,
        color-mix(in srgb, var(--primary-color) 18%, transparent) 0%,
        color-mix(in srgb, var(--primary-color) 8%, transparent) 40%,
        transparent 70%
    );
    opacity: 0;
    transition: opacity 0.5s cubic-bezier(0.4, 0, 0.2, 1);
    pointer-events: none;
    border-radius: 50%;
}

.topic-item:hover {
    transform: translateY(-8px) scale(1.02);
    box-shadow:
        0 20px 60px color-mix(in srgb, var(--primary-color) 25%, rgba(0, 0, 0, 0.25)),
        0 8px 24px color-mix(in srgb, var(--primary-color) 15%, rgba(0, 0, 0, 0.15)),
        0 0 0 1.5px var(--primary-color),
        0 0 40px color-mix(in srgb, var(--primary-color) 35%, transparent),
        inset 0 2px 4px rgba(255, 255, 255, 0.3),
        inset 0 -1px 0 rgba(0, 0, 0, 0.05);
    border-color: color-mix(in srgb, var(--primary-color) 60%, transparent);
}

.topic-item:hover::after {
    opacity: 0.6;
    animation: pulseGlow 2s ease-in-out infinite;
}

@keyframes shimmer {
    0% {
        background-position: -200% 0;
    }
    100% {
        background-position: 200% 0;
    }
}

@keyframes cardFadeIn {
    from {
        opacity: 0;
        transform: translateY(20px) scale(0.95);
    }
    to {
        opacity: 1;
        transform: translateY(0) scale(1);
    }
}

@keyframes pulseGlow {
    0%, 100% {
        transform: scale(1);
        opacity: 0.6;
    }
    50% {
        transform: scale(1.1);
        opacity: 0.4;
    }
}

.topic-content {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
}

.topic-title {
    position: relative;
    margin: 0 0 1rem 0;
    font-size: 1.4rem;
    font-weight: 800;
    line-height: 1.3;
    letter-spacing: -0.02em;
    color: var(--text-color);
    background: linear-gradient(
        135deg,
        var(--text-color) 0%,
        color-mix(in srgb, var(--primary-color) 25%, var(--text-color)) 50%,
        var(--text-color) 100%
    );
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
    z-index: 1;
    text-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.topic-item:hover .topic-title {
    background: linear-gradient(
        135deg,
        var(--primary-color) 0%,
        color-mix(in srgb, var(--primary-color) 90%, #ff6b9d) 50%,
        var(--primary-color) 100%
    );
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    filter: drop-shadow(0 4px 12px color-mix(in srgb, var(--primary-color) 40%, transparent));
    transform: translateX(2px);
}

.topic-meta {
    display: flex;
    gap: 1rem;
    flex-wrap: wrap;
    font-size: 0.875rem;
    color: var(--surface-500);
    z-index: 1;
    margin-bottom: 0.5rem;
}

.topic-meta span {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 1rem;
    background: linear-gradient(
        135deg,
        color-mix(in srgb, var(--primary-color) 8%, var(--surface-0)) 0%,
        color-mix(in srgb, var(--primary-color) 12%, var(--surface-0)) 100%
    );
    border-radius: 12px;
    border: 1px solid color-mix(in srgb, var(--primary-color) 18%, transparent);
    transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
    backdrop-filter: blur(12px) saturate(180%);
    box-shadow:
        0 2px 8px rgba(0, 0, 0, 0.04),
        inset 0 1px 0 rgba(255, 255, 255, 0.5);
    font-weight: 500;
    position: relative;
    overflow: hidden;
}

.topic-meta span::before {
    content: '';
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(
        90deg,
        transparent,
        rgba(255, 255, 255, 0.3),
        transparent
    );
    transition: left 0.5s;
}

.topic-meta span i {
    color: var(--primary-color);
    font-size: 0.8rem;
    filter: drop-shadow(0 1px 3px color-mix(in srgb, var(--primary-color) 50%, transparent));
    transition: transform 0.3s;
}

.topic-item:hover .topic-meta span {
    background: linear-gradient(
        135deg,
        color-mix(in srgb, var(--primary-color) 18%, var(--surface-0)) 0%,
        color-mix(in srgb, var(--primary-color) 25%, var(--surface-0)) 100%
    );
    border-color: color-mix(in srgb, var(--primary-color) 45%, transparent);
    box-shadow:
        0 4px 16px color-mix(in srgb, var(--primary-color) 25%, rgba(0, 0, 0, 0.1)),
        inset 0 1px 0 rgba(255, 255, 255, 0.6);
    transform: translateY(-2px) scale(1.05);
}

.topic-item:hover .topic-meta span::before {
    left: 100%;
}

.topic-item:hover .topic-meta span i {
    transform: scale(1.2) rotate(5deg);
}

.topic-comments {
    margin-top: 1.5rem;
    padding-top: 1.25rem;
    border-top: 1.5px solid color-mix(in srgb, var(--primary-color) 10%, var(--surface-200));
    position: relative;
    z-index: 1;
}

.topic-comments::before {
    content: '';
    position: absolute;
    top: -1.5px;
    left: 0;
    right: 0;
    height: 2px;
    background: linear-gradient(
        90deg,
        transparent 0%,
        var(--primary-color) 20%,
        color-mix(in srgb, var(--primary-color) 80%, #ff6b9d) 50%,
        var(--primary-color) 80%,
        transparent 100%
    );
    opacity: 0.5;
    border-radius: 2px;
}

.comment-header {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    margin-bottom: 1rem;
    font-weight: 600;
    color: var(--text-color);
    font-size: 0.9rem;
    cursor: pointer;
    user-select: none;
    padding: 0.75rem 1rem;
    border-radius: 12px;
    background: linear-gradient(
        135deg,
        color-mix(in srgb, var(--primary-color) 10%, var(--surface-0)) 0%,
        color-mix(in srgb, var(--primary-color) 6%, var(--surface-0)) 100%
    );
    border: 1.5px solid color-mix(in srgb, var(--primary-color) 20%, transparent);
    transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
    position: relative;
    overflow: hidden;
    box-shadow:
        0 2px 8px rgba(0, 0, 0, 0.04),
        inset 0 1px 0 rgba(255, 255, 255, 0.4);
}

.comment-header::before {
    content: '';
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(
        90deg,
        transparent,
        color-mix(in srgb, var(--primary-color) 25%, rgba(255, 255, 255, 0.3)),
        transparent
    );
    transition: left 0.6s cubic-bezier(0.4, 0, 0.2, 1);
}

.comment-header:hover {
    background: linear-gradient(
        135deg,
        color-mix(in srgb, var(--primary-color) 18%, var(--surface-0)) 0%,
        color-mix(in srgb, var(--primary-color) 12%, var(--surface-0)) 100%
    );
    border-color: color-mix(in srgb, var(--primary-color) 40%, transparent);
    box-shadow:
        0 4px 16px color-mix(in srgb, var(--primary-color) 25%, rgba(0, 0, 0, 0.1)),
        inset 0 1px 0 rgba(255, 255, 255, 0.5);
    transform: translateX(4px) scale(1.02);
}

.comment-header:hover::before {
    left: 100%;
}

.comment-toggle-icon {
    margin-left: auto;
    transition: transform 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
    color: var(--primary-color);
    filter: drop-shadow(0 1px 3px color-mix(in srgb, var(--primary-color) 40%, transparent));
}

.comment-header:hover .comment-toggle-icon {
    transform: scale(1.15) rotate(180deg);
}

.comment-count {
    color: var(--primary-color);
    font-weight: 700;
    text-shadow: 0 2px 4px color-mix(in srgb, var(--primary-color) 30%, transparent);
    letter-spacing: 0.02em;
}

.comment-header i:first-child {
    color: var(--primary-color);
    filter: drop-shadow(0 1px 3px color-mix(in srgb, var(--primary-color) 50%, transparent));
    transition: transform 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
    font-size: 1rem;
}

.comment-header:hover i:first-child {
    transform: scale(1.2) rotate(-5deg);
}

.comment-list {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
}

.comment-item {
    background: linear-gradient(
        135deg,
        color-mix(in srgb, var(--primary-color) 6%, var(--surface-0)) 0%,
        color-mix(in srgb, var(--primary-color) 3%, var(--surface-50)) 50%,
        var(--surface-50) 100%
    );
    padding: 1rem 1rem 1rem 1.25rem;
    border-radius: 12px;
    border-left: 4px solid var(--primary-color);
    box-shadow:
        0 3px 12px color-mix(in srgb, var(--primary-color) 12%, rgba(0, 0, 0, 0.06)),
        inset 0 1px 0 rgba(255, 255, 255, 0.5);
    transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
    position: relative;
    overflow: hidden;
    backdrop-filter: blur(8px);
}

.comment-item::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    width: 4px;
    height: 100%;
    background: linear-gradient(
        180deg,
        var(--primary-color) 0%,
        color-mix(in srgb, var(--primary-color) 80%, #ff6b9d) 50%,
        var(--primary-color) 100%
    );
    box-shadow:
        0 0 12px color-mix(in srgb, var(--primary-color) 60%, transparent),
        inset -1px 0 4px rgba(255, 255, 255, 0.3);
    border-radius: 0 2px 2px 0;
}

.comment-item::after {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: linear-gradient(
        135deg,
        transparent 0%,
        color-mix(in srgb, var(--primary-color) 5%, transparent) 100%
    );
    opacity: 0;
    transition: opacity 0.3s;
    pointer-events: none;
}

.comment-item:hover {
    transform: translateX(6px) translateY(-2px);
    box-shadow:
        0 6px 20px color-mix(in srgb, var(--primary-color) 25%, rgba(0, 0, 0, 0.12)),
        inset 0 1px 0 rgba(255, 255, 255, 0.6);
    border-left-width: 5px;
}

.comment-item:hover::after {
    opacity: 1;
}

.comment-content {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}

.comment-header-info {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 1rem;
    flex-wrap: wrap;
}

.comment-author {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    font-weight: 600;
    font-size: 0.875rem;
    color: var(--primary-color);
    background: linear-gradient(
        135deg,
        color-mix(in srgb, var(--primary-color) 12%, transparent) 0%,
        color-mix(in srgb, var(--primary-color) 8%, transparent) 100%
    );
    padding: 0.375rem 0.75rem;
    border-radius: 10px;
    transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
    border: 1px solid color-mix(in srgb, var(--primary-color) 20%, transparent);
    box-shadow: 0 1px 4px rgba(0, 0, 0, 0.04);
    backdrop-filter: blur(8px);
}

.comment-author i {
    font-size: 0.8rem;
    filter: drop-shadow(0 1px 3px color-mix(in srgb, var(--primary-color) 50%, transparent));
    transition: transform 0.3s;
}

.comment-item:hover .comment-author {
    background: linear-gradient(
        135deg,
        color-mix(in srgb, var(--primary-color) 18%, transparent) 0%,
        color-mix(in srgb, var(--primary-color) 12%, transparent) 100%
    );
    border-color: color-mix(in srgb, var(--primary-color) 35%, transparent);
    box-shadow:
        0 3px 8px color-mix(in srgb, var(--primary-color) 20%, rgba(0, 0, 0, 0.08)),
        inset 0 1px 0 rgba(255, 255, 255, 0.4);
    transform: scale(1.05);
}

.comment-item:hover .comment-author i {
    transform: scale(1.15) rotate(5deg);
}

.comment-text {
    margin: 0;
    font-size: 0.875rem;
    color: var(--text-color);
    line-height: 1.4;
    word-wrap: break-word;
}

.comment-date {
    font-size: 0.75rem;
    color: var(--surface-500);
    white-space: nowrap;
}

.comment-more {
    font-size: 0.875rem;
    color: var(--primary-color);
    font-style: italic;
    padding-left: 0.75rem;
}

.no-comments {
    padding: 1rem;
    text-align: center;
    color: var(--surface-500);
    font-style: italic;
}

.slide-fade-enter-active {
    transition: all 0.3s ease-out;
}

.slide-fade-leave-active {
    transition: all 0.2s ease-in;
}

.slide-fade-enter-from {
    transform: translateY(-10px);
    opacity: 0;
}

.slide-fade-leave-to {
    transform: translateY(-10px);
    opacity: 0;
}

.topic-actions {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    flex-shrink: 0;
    margin-top: auto;
    padding-top: 1.5rem;
    border-top: 1.5px solid color-mix(in srgb, var(--primary-color) 10%, var(--surface-200));
    position: relative;
    z-index: 1;
}

.topic-actions::before {
    content: '';
    position: absolute;
    top: -1.5px;
    left: 0;
    right: 0;
    height: 2px;
    background: linear-gradient(
        90deg,
        transparent 0%,
        var(--primary-color) 20%,
        color-mix(in srgb, var(--primary-color) 80%, #ff6b9d) 50%,
        var(--primary-color) 80%,
        transparent 100%
    );
    opacity: 0.5;
    border-radius: 2px;
}

.topic-actions :deep(.p-button) {
    transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
    border-radius: 12px;
    font-weight: 600;
    position: relative;
    overflow: hidden;
    padding: 0.75rem 1.25rem;
    font-size: 0.9rem;
    letter-spacing: 0.01em;
    box-shadow:
        0 2px 8px rgba(0, 0, 0, 0.06),
        inset 0 1px 0 rgba(255, 255, 255, 0.3);
}

.topic-actions :deep(.p-button::before) {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    width: 0;
    height: 0;
    border-radius: 50%;
    background: radial-gradient(
        circle,
        color-mix(in srgb, var(--primary-color) 40%, rgba(255, 255, 255, 0.3)) 0%,
        transparent 70%
    );
    transform: translate(-50%, -50%);
    transition: width 0.7s cubic-bezier(0.4, 0, 0.2, 1), height 0.7s cubic-bezier(0.4, 0, 0.2, 1);
    opacity: 0;
}

.topic-actions :deep(.p-button:hover::before) {
    width: 400px;
    height: 400px;
    opacity: 0.8;
}

.topic-actions :deep(.p-button:hover) {
    transform: translateY(-3px) scale(1.02);
    box-shadow:
        0 8px 24px color-mix(in srgb, var(--primary-color) 35%, rgba(0, 0, 0, 0.25)),
        0 2px 8px rgba(0, 0, 0, 0.1),
        inset 0 1px 0 rgba(255, 255, 255, 0.4);
}

.topic-actions :deep(.p-button-outlined) {
    border-width: 2px;
    border-color: var(--primary-color);
    background: linear-gradient(
        135deg,
        color-mix(in srgb, var(--primary-color) 5%, var(--surface-0)) 0%,
        var(--surface-0) 100%
    );
}

.topic-actions :deep(.p-button-outlined:hover) {
    background: linear-gradient(
        135deg,
        color-mix(in srgb, var(--primary-color) 15%, var(--surface-0)) 0%,
        color-mix(in srgb, var(--primary-color) 8%, var(--surface-0)) 100%
    );
    border-color: color-mix(in srgb, var(--primary-color) 80%, transparent);
    box-shadow:
        0 0 30px color-mix(in srgb, var(--primary-color) 45%, transparent),
        0 8px 24px color-mix(in srgb, var(--primary-color) 25%, rgba(0, 0, 0, 0.2)),
        inset 0 1px 0 rgba(255, 255, 255, 0.5);
}

.topic-actions :deep(.p-button i) {
    transition: transform 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.topic-actions :deep(.p-button:hover i) {
    transform: scale(1.15) rotate(-5deg);
}

.comment-dialog-content {
    padding: 0.5rem 0;
}

@media (max-width: 768px) {
    .topic-list-header {
        flex-direction: column;
        align-items: flex-start;
    }

    .search-container {
        max-width: 100%;
    }
}
</style>
