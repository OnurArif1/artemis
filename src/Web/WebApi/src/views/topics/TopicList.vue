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
const { t } = useI18n();
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
const roomsMap = ref(new Map()); // topicId -> room mapping
const commentsMap = ref(new Map()); // topicId -> comments array mapping
const expandedComments = ref(new Set()); // topicId -> expanded state

const showCommentDialog = ref(false);
const selectedTopic = ref(null);
const commentText = ref('');
const currentPartyId = ref(null);

async function loadRooms() {
    try {
        // Tüm room'ları yükle (topicId ile filtreleme için)
        const roomData = await roomService.getList({
            pageIndex: 1,
            pageSize: 1000 // Tüm room'ları almak için büyük bir sayı
        });
        const rooms = Array.isArray(roomData.resultViewModels) 
            ? roomData.resultViewModels 
            : (roomData?.resultViewModels ?? []);
        
        // TopicId'ye göre room'ları map'le
        roomsMap.value.clear();
        rooms.forEach(room => {
            if (room.topicId) {
                if (!roomsMap.value.has(room.topicId)) {
                    roomsMap.value.set(room.topicId, []);
                }
                roomsMap.value.get(room.topicId).push(room);
            }
        });
    } catch (err) {
        console.error('Room list load error:', err);
    }
}

async function loadCommentsForTopics(topicIds) {
    try {
        if (!topicIds || topicIds.length === 0) return;
        
        // Her topic için comment'leri yükle
        const commentPromises = topicIds.map(async (topicId) => {
            try {
                const commentData = await commentService.getList({
                    pageIndex: 1,
                    pageSize: 100, // Tüm yorumları almak için büyük sayı
                    topicId: topicId
                });
                const comments = Array.isArray(commentData.resultViewModels) 
                    ? commentData.resultViewModels 
                    : (commentData?.resultViewModels ?? []);
                
                // Count'u doğru al - sadece bu topic için olan comment sayısı
                const actualCount = commentData?.count || comments.length;
                
                console.log(`Topic ${topicId} - Comments loaded:`, comments.length, 'Count:', actualCount);
                
                return { topicId, comments, count: actualCount };
            } catch (err) {
                console.error(`Error loading comments for topic ${topicId}:`, err);
                return { topicId, comments: [], count: 0 };
            }
        });
        
        const results = await Promise.all(commentPromises);
        commentsMap.value.clear();
        results.forEach(({ topicId, comments, count }) => {
            // Sadece gerçekten yorum varsa map'e ekle
            if (count > 0 || comments.length > 0) {
                commentsMap.value.set(topicId, { comments, count: count || comments.length });
            } else {
                commentsMap.value.set(topicId, { comments: [], count: 0 });
            }
        });
    } catch (err) {
        console.error('Comments load error:', err);
    }
}

async function loadTopics() {
    loading.value = true;
    try {
        // Önce room'ları yükle
        await loadRooms();
        
        const filter = {
            pageIndex: pageIndex.value,
            pageSize: pageSize.value
        };
        const data = await topicService.getList(filter);
        const loadedTopics = Array.isArray(data.resultViewModels) ? data.resultViewModels : (data?.resultViewModels ?? []);
        
        // Topic ID'lerini al ve comment'leri yükle
        const topicIds = loadedTopics.map(t => t.id);
        await loadCommentsForTopics(topicIds);
        
        // Her topic için room ve comment bilgisini ekle
        topics.value = loadedTopics.map(topic => {
            const commentData = commentsMap.value.get(topic.id);
            const commentCount = commentData?.count || 0;
            const comments = commentData?.comments || [];
            
            // Debug log
            console.log(`Topic ${topic.id} (${topic.title}):`, {
                commentCount,
                commentsLength: comments.length,
                hasComments: commentCount > 0 || comments.length > 0
            });
            
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
        console.error('Topic list load error:', err);
        toast.add({ 
            severity: 'error', 
            summary: t('common.error'), 
            detail: err?.response?.data?.message || err?.message || 'Topic listesi yüklenemedi', 
            life: 5000 
        });
    } finally {
        loading.value = false;
    }
}

function filterTopics() {
    if (!searchText.value || searchText.value.trim() === '') {
        filteredTopics.value = topics.value;
        return;
    }
    const searchLower = searchText.value.toLowerCase().trim();
    filteredTopics.value = topics.value.filter(topic => 
        topic.title?.toLowerCase().includes(searchLower)
    );
}

function onSearch() {
    filterTopics();
}

function toggleComments(topicId) {
    if (expandedComments.value.has(topicId)) {
        expandedComments.value.delete(topicId);
    } else {
        expandedComments.value.add(topicId);
    }
}

function getCommentCount(topic) {
    // Önce commentCount'u kontrol et, yoksa comments array'inin uzunluğunu kullan
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
        console.error('Error getting party ID:', error);
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
            detail: 'Kullanıcı bilgisi bulunamadı', 
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
            summary: 'Uyarı', 
            detail: 'Lütfen yorum metni girin', 
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
                summary: 'Başarılı', 
                detail: 'Yorum başarıyla eklendi', 
                life: 3000 
            });
            showCommentDialog.value = false;
            commentText.value = '';
            
            // Yorum eklendikten sonra ilgili topic'in comment'lerini yenile
            if (selectedTopic.value) {
                const topicId = selectedTopic.value.id;
                await loadCommentsForTopics([topicId]);
                
                // Topic listesindeki ilgili topic'i güncelle
                const topicIndex = topics.value.findIndex(t => t.id === topicId);
                if (topicIndex !== -1) {
                    const commentData = commentsMap.value.get(topicId);
                    const commentCount = commentData?.count || 0;
                    const comments = commentData?.comments || [];
                    
                    topics.value[topicIndex] = {
                        ...topics.value[topicIndex],
                        comments: comments,
                        commentCount: commentCount
                    };
                    filterTopics(); // Filtrelenmiş listeyi de güncelle
                    
                    // Eğer comment section açıksa, yeni yorumu görmek için yeniden aç
                    if (expandedComments.value.has(topicId)) {
                        expandedComments.value.delete(topicId);
                        expandedComments.value.add(topicId);
                    }
                }
            }
            
            selectedTopic.value = null;
        } else {
            toast.add({ 
                severity: 'error', 
                summary: t('common.error'), 
                detail: result?.exceptionMessage || 'Yorum eklenirken bir hata oluştu', 
                life: 5000 
            });
        }
    } catch (err) {
        console.error('Comment create error:', err);
        toast.add({ 
            severity: 'error', 
            summary: t('common.error'), 
            detail: err?.response?.data?.message || err?.message || 'Yorum eklenirken bir hata oluştu', 
            life: 5000 
        });
    }
}

async function goToRoom(topic) {
    try {
        // Topic objesinde room bilgisi varsa onu kullan
        if (topic.room) {
            const targetRoom = topic.room;
            
            // Sol menüdeki odalar kısmını aç
            setActiveMenuItem('1-1'); // Odalar menü item'ının index'i
            
            // Router ile odalar sayfasına git ve room'u seç
            await router.push({ 
                name: 'rooms',
                query: { roomId: targetRoom.id }
            });
            return;
        }

        // Eğer topic objesinde room yoksa, tekrar kontrol et
        const roomFilter = {
            pageIndex: 1,
            pageSize: 100,
            topicId: topic.id
        };
        
        const roomData = await roomService.getList(roomFilter);
        const rooms = Array.isArray(roomData.resultViewModels) 
            ? roomData.resultViewModels 
            : (roomData?.resultViewModels ?? []);
        
        if (!rooms || rooms.length === 0) {
            toast.add({ 
                severity: 'info', 
                summary: 'Bilgi', 
                detail: 'Bu topic için henüz bir oda oluşturulmamış', 
                life: 3000 
            });
            return;
        }

        // İlk room'u kullan
        const targetRoom = rooms[0];
        
        // Sol menüdeki odalar kısmını aç
        setActiveMenuItem('1-1'); // Odalar menü item'ının index'i
        
        // Router ile odalar sayfasına git ve room'u seç
        await router.push({ 
            name: 'rooms',
            query: { roomId: targetRoom.id }
        });
    } catch (err) {
        console.error('Go to room error:', err);
        toast.add({ 
            severity: 'error', 
            summary: t('common.error'), 
            detail: err?.response?.data?.message || err?.message || 'Oda bulunamadı', 
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
            <h2>Topic Listesi</h2>
            <div class="search-container">
                <InputText 
                    v-model="searchText" 
                    placeholder="Topic başlığına göre ara..." 
                    @input="onSearch"
                    class="search-input"
                />
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
                <p>{{ searchText ? 'Arama sonucu bulunamadı' : 'Henüz topic bulunmuyor' }}</p>
            </div>

            <div v-else class="topic-items">
                <div 
                    v-for="topic in filteredTopics" 
                    :key="topic.id" 
                    class="topic-item"
                >
                    <div class="topic-content">
                        <h3 class="topic-title">{{ topic.title }}</h3>
                        <div class="topic-meta">
                            <span v-if="topic.categoryName" class="topic-category">
                                <i class="pi pi-tag" /> {{ topic.categoryName }}
                            </span>
                            <span v-if="topic.partyName" class="topic-party">
                                <i class="pi pi-user" /> {{ topic.partyName }}
                            </span>
                            <span class="topic-date">
                                <i class="pi pi-calendar" /> {{ new Date(topic.createDate).toLocaleDateString('tr-TR') }}
                            </span>
                        </div>
                        <div v-if="(topic.commentCount && topic.commentCount > 0) || (topic.comments && topic.comments.length > 0)" class="topic-comments">
                            <div class="comment-header" @click="toggleComments(topic.id)">
                                <i class="pi pi-comments" />
                                <span class="comment-count">
                                    {{ getCommentCount(topic) }} Yorum
                                </span>
                                <i 
                                    :class="expandedComments.has(topic.id) ? 'pi pi-chevron-up' : 'pi pi-chevron-down'" 
                                    class="comment-toggle-icon"
                                />
                            </div>
                            <Transition name="slide-fade">
                                <div v-if="expandedComments.has(topic.id)" class="comment-list">
                                    <div 
                                        v-if="topic.comments && topic.comments.length > 0"
                                        v-for="comment in topic.comments" 
                                        :key="comment.id" 
                                        class="comment-item"
                                    >
                                        <div class="comment-content">
                                            <p class="comment-text">{{ comment.content || '(Yorum metni yok)' }}</p>
                                            <span class="comment-date">{{ new Date(comment.createDate).toLocaleDateString('tr-TR', { 
                                                year: 'numeric', 
                                                month: 'long', 
                                                day: 'numeric',
                                                hour: '2-digit',
                                                minute: '2-digit'
                                            }) }}</span>
                                        </div>
                                    </div>
                                    <div v-else class="no-comments">
                                        <p>Yorum yükleniyor...</p>
                                    </div>
                                </div>
                            </Transition>
                        </div>
                    </div>
                    <div class="topic-actions">
                        <Button 
                            icon="pi pi-comment" 
                            label="Yorum Yap" 
                            class="p-button-sm p-button-outlined"
                            @click="openCommentDialog(topic)"
                        />
                        <Button 
                            v-if="topic.hasRoom"
                            icon="pi pi-sign-in" 
                            label="Odaya Git" 
                            class="p-button-sm p-button-outlined"
                            @click="goToRoom(topic)"
                        />
                    </div>
                </div>
            </div>
        </div>

        <!-- Comment Dialog -->
        <Dialog 
            v-model:visible="showCommentDialog" 
            modal 
            :closable="true" 
            header="Yorum Yap" 
            :style="{ width: '500px' }"
        >
            <div class="comment-dialog-content">
                <div class="mb-3">
                    <label class="block mb-2 font-semibold">Topic:</label>
                    <p class="text-lg">{{ selectedTopic?.title }}</p>
                </div>
                <div class="mb-3">
                    <label class="block mb-2 font-semibold">Yorum:</label>
                    <Textarea 
                        v-model="commentText" 
                        rows="5" 
                        placeholder="Yorumunuzu buraya yazın..."
                        class="w-full"
                    />
                </div>
            </div>
            <template #footer>
                <Button 
                    label="İptal" 
                    icon="pi pi-times" 
                    class="p-button-text" 
                    @click="showCommentDialog = false" 
                />
                <Button 
                    label="Kaydet" 
                    icon="pi pi-check" 
                    @click="saveComment" 
                />
            </template>
        </Dialog>
    </div>
</template>

<style scoped>
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
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

.topic-item {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    padding: 1.5rem;
    background: var(--surface-0);
    border: 2px solid var(--primary-color);
    border-radius: 8px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
    transition: box-shadow 0.2s, transform 0.2s;
    gap: 1.5rem;
}

.topic-item:hover {
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
    transform: translateY(-2px);
}

.topic-content {
    flex: 1;
    min-width: 0; /* Flexbox overflow için */
}

.topic-title {
    margin: 0 0 0.5rem 0;
    font-size: 1.25rem;
    font-weight: 600;
    color: var(--text-color);
}

.topic-meta {
    display: flex;
    gap: 1.5rem;
    flex-wrap: wrap;
    font-size: 0.875rem;
    color: var(--surface-500);
}

.topic-meta span {
    display: flex;
    align-items: center;
    gap: 0.25rem;
}

.topic-comments {
    margin-top: 1rem;
    padding-top: 1rem;
    border-top: 1px solid var(--surface-200);
}

.comment-header {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 0.75rem;
    font-weight: 600;
    color: var(--text-color);
    font-size: 0.875rem;
    cursor: pointer;
    user-select: none;
    padding: 0.5rem;
    border-radius: 4px;
    transition: background-color 0.2s;
}

.comment-header:hover {
    background-color: var(--surface-100);
}

.comment-toggle-icon {
    margin-left: auto;
    transition: transform 0.2s;
}

.comment-count {
    color: var(--primary-color);
}

.comment-list {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
}

.comment-item {
    background: var(--surface-50);
    padding: 0.75rem;
    border-radius: 6px;
    border-left: 3px solid var(--primary-color);
}

.comment-content {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
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
    gap: 0.5rem;
    flex-shrink: 0;
    align-self: flex-start;
    position: sticky;
    top: 1.5rem;
}

.comment-dialog-content {
    padding: 0.5rem 0;
}

@media (max-width: 768px) {
    .topic-item {
        flex-direction: column;
        align-items: flex-start;
        gap: 1rem;
    }

    .topic-actions {
        width: 100%;
        justify-content: flex-end;
    }

    .topic-list-header {
        flex-direction: column;
        align-items: flex-start;
    }

    .search-container {
        max-width: 100%;
    }
}
</style>
