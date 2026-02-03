<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from '@/composables/useI18n';
import { useLayout } from '@/layout/composables/layout';
import request from '@/service/request';
import RoomService from '@/service/RoomService';
import Chat from '@/views/chat/Chat.vue';
import TopicCommentChat from '@/views/chat/TopicCommentChat.vue';

const route = useRoute();
const roomService = new RoomService(request);
const { t } = useI18n();
const { isDarkTheme } = useLayout();
const mapContainer = ref(null);
const loading = ref(true);
const error = ref('');
const showChatDialog = ref(false);
const selectedRoom = ref(null);
const showTopicChatDialog = ref(false);
const selectedTopic = ref(null);
let map = null;
let markersLayer = null;
let tileLayer = null;

const TURKEY_CENTER = [39, 35.5];

function updateTileLayer() {
    if (!map) return;

    if (tileLayer) {
        map.removeLayer(tileLayer);
    }

    const L = window.L;
    const tileUrl = isDarkTheme.value ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png' : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

    tileLayer = L.tileLayer(tileUrl, {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/attributions">CARTO</a>',
        subdomains: 'abcd',
        maxZoom: 19
    }).addTo(map);
}

onMounted(async () => {
    if (!mapContainer.value) return;

    const L = window.L;

    if (!L || typeof L.map !== 'function') {
        error.value = t('common.error') + ': ' + t('room.leafletLoadError');
        loading.value = false;
        return;
    }

    map = L.map(mapContainer.value).setView(TURKEY_CENTER, 6);
    updateTileLayer();

    loading.value = true;
    error.value = '';
    try {
        const res = await roomService.getList({ pageIndex: 1, pageSize: 500 });
        const rooms = res?.resultViewModels ?? res?.ResultViewModels ?? [];
        if (!Array.isArray(rooms)) {
            loading.value = false;
            return;
        }

        if (markersLayer) {
            map.removeLayer(markersLayer);
        }
        markersLayer = L.layerGroup().addTo(map);

        const validCoords = [];

        for (const r of rooms) {
            const lat = Number(r.locationY ?? r.LocationY);
            const lng = Number(r.locationX ?? r.LocationX);
            if (Number.isNaN(lat) || Number.isNaN(lng)) continue;

            validCoords.push([lat, lng]);

            const title = r.title ?? r.Title ?? `${t('room.prefix')}${r.id ?? r.Id}`;
            const roomId = r.id ?? r.Id;
            const topicId = r.topicId ?? r.TopicId;
            const topicTitle = r.topicTitle ?? r.TopicTitle;

            // Room marker için benzersiz ID
            const roomMarkerId = `room-marker-${roomId}`;
            const topicMarkerId = topicId ? `topic-marker-${topicId}` : null;

            let markerHtml = `
                <div class="marker-container" data-marker-id="${roomMarkerId}">
                    <div class="marker-group room-marker-group">
                        <div class="marker-pulse-ring"></div>
                        <div class="marker-dot room-dot">
                            <div class="marker-dot-inner">
                                <svg width="8" height="8" viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg">
                                    <path d="M6 1L7.5 4.5L11 6L7.5 7.5L6 11L4.5 7.5L1 6L4.5 4.5L6 1Z" fill="white" opacity="0.9"/>
                                </svg>
                            </div>
                        </div>
                        <div class="marker-card room-card">
                            <div class="marker-card-content">
                                <div class="marker-icon">🏠</div>
                                <div class="marker-title">${escapeHtml(title)}</div>
                            </div>
                            <div class="marker-card-glow"></div>
                        </div>
                    </div>
            `;

            if (topicId && topicTitle) {
                markerHtml += `
                    <div class="marker-group topic-marker-group" data-marker-id="${topicMarkerId}">
                        <div class="marker-pulse-ring topic-pulse"></div>
                        <div class="marker-dot topic-dot">
                            <div class="marker-dot-inner">
                                <svg width="7" height="7" viewBox="0 0 10 10" fill="none" xmlns="http://www.w3.org/2000/svg">
                                    <circle cx="5" cy="5" r="4" fill="white" opacity="0.9"/>
                                </svg>
                            </div>
                        </div>
                        <div class="marker-card topic-card">
                            <div class="marker-card-content">
                                <div class="marker-icon">💬</div>
                                <div class="marker-title">${escapeHtml(topicTitle)}</div>
                            </div>
                            <div class="marker-card-glow topic-glow"></div>
                        </div>
                    </div>
                </div>
            `;
            } else {
                markerHtml += `</div>`;
            }

            // Marker boyutlarını hesapla
            const markerWidth = topicId && topicTitle ? 320 : 180;
            const markerHeight = 60;
            
            // Dinamik anchor hesaplama için harita sınırlarını kontrol et
            const calculateAnchor = () => {
                if (!map) return topicId && topicTitle ? [160, 60] : [90, 60];
                
                const point = map.latLngToContainerPoint([lat, lng]);
                const mapSize = map.getSize();
                const padding = 20; // Kenar boşluğu
                
                let anchorX = markerWidth / 2;
                let anchorY = markerHeight;
                
                // Sol kenara yakınsa anchor'u sağa kaydır
                if (point.x < markerWidth / 2 + padding) {
                    anchorX = Math.max(20, point.x - padding);
                }
                // Sağ kenara yakınsa anchor'u sola kaydır
                else if (point.x > mapSize.x - markerWidth / 2 - padding) {
                    anchorX = markerWidth - Math.max(20, mapSize.x - point.x - padding);
                }
                
                // Üst kenara yakınsa anchor'u aşağı kaydır
                if (point.y < markerHeight + padding) {
                    anchorY = Math.max(20, point.y - padding);
                }
                
                return [anchorX, anchorY];
            };
            
            const anchor = calculateAnchor();
            
            const icon = L.divIcon({
                className: 'custom-map-marker responsive-marker',
                html: markerHtml,
                iconSize: [markerWidth, markerHeight],
                iconAnchor: anchor,
                popupAnchor: [0, -anchor[1]]
            });

            const marker = L.marker([lat, lng], { icon }).addTo(markersLayer);
            
            // Harita zoom ve pan değiştiğinde anchor'u yeniden hesapla
            const updateMarkerPosition = () => {
                const newAnchor = calculateAnchor();
                const newIcon = L.divIcon({
                    className: 'custom-map-marker responsive-marker',
                    html: markerHtml,
                    iconSize: [markerWidth, markerHeight],
                    iconAnchor: newAnchor,
                    popupAnchor: [0, -newAnchor[1]]
                });
                marker.setIcon(newIcon);
            };
            
            map.on('moveend', updateMarkerPosition);
            map.on('zoomend', updateMarkerPosition);
            map.on('resize', updateMarkerPosition);

            marker.on('click', (e) => {
                const target = e.originalEvent.target;
                if (target.closest('.topic-marker-group')) {
                    e.originalEvent.stopPropagation();
                    selectedTopic.value = {
                        id: topicId,
                        title: topicTitle
                    };
                    showTopicChatDialog.value = true;
                } else if (target.closest('.room-marker-group')) {
                    selectedRoom.value = {
                        id: roomId,
                        title: title
                    };
                    showChatDialog.value = true;
                }
            });

            // Hover efektleri için
            marker.on('mouseover', () => {
                const markerEl = document.querySelector(`[data-marker-id="${roomMarkerId}"]`);
                if (markerEl) {
                    markerEl.classList.add('marker-hover');
                }
                if (topicMarkerId) {
                    const topicEl = document.querySelector(`[data-marker-id="${topicMarkerId}"]`);
                    if (topicEl) {
                        topicEl.classList.add('marker-hover');
                    }
                }
            });

            marker.on('mouseout', () => {
                const markerEl = document.querySelector(`[data-marker-id="${roomMarkerId}"]`);
                if (markerEl) {
                    markerEl.classList.remove('marker-hover');
                }
                if (topicMarkerId) {
                    const topicEl = document.querySelector(`[data-marker-id="${topicMarkerId}"]`);
                    if (topicEl) {
                        topicEl.classList.remove('marker-hover');
                    }
                }
            });
        }

        const roomIdFromQuery = route.query.roomId;
        if (roomIdFromQuery) {
            const roomIdNum = parseInt(roomIdFromQuery);
            if (!isNaN(roomIdNum)) {
                const targetRoom = rooms.find((r) => (r.id ?? r.Id) === roomIdNum);
                if (targetRoom) {
                    selectedRoom.value = {
                        id: roomIdNum,
                        title: targetRoom.title ?? targetRoom.Title ?? `${t('room.prefix')}${roomIdNum}`
                    };
                    showChatDialog.value = true;

                    const roomLat = Number(targetRoom.locationY ?? targetRoom.LocationY);
                    const roomLng = Number(targetRoom.locationX ?? targetRoom.LocationX);
                    if (!Number.isNaN(roomLat) && !Number.isNaN(roomLng)) {
                        map.setView([roomLat, roomLng], 15);
                    }
                }
            }
        }

        if (validCoords.length > 0) {
            const bounds = L.latLngBounds(validCoords);
            map.fitBounds(bounds, { padding: [50, 50], maxZoom: 12 });
        } else {
            const TURKEY_BOUNDS = [
                [35.8, 25.9],
                [42.2, 44.9]
            ];
            map.fitBounds(TURKEY_BOUNDS, { padding: [50, 50], maxZoom: 7 });
        }
    } catch (e) {
        error.value = t('common.error') + ': ' + (e?.message || String(e));
    } finally {
        loading.value = false;
    }
});

watch(isDarkTheme, () => {
    updateTileLayer();
});

onBeforeUnmount(() => {
    if (map) {
        map.remove();
        map = null;
    }
    markersLayer = null;
    tileLayer = null;
});

function escapeHtml(s) {
    if (s == null) return '';
    const d = document.createElement('div');
    d.textContent = s;
    return d.innerHTML;
}
</script>

<template>
    <div class="room-map-wrapper">
        <div ref="mapContainer" class="room-map" />
        <div v-if="loading" class="loading-overlay">
            <ProgressSpinner style="width: 32px; height: 32px" />
            <span class="ml-2">{{ t('common.loading') }}</span>
        </div>
        <div v-if="error" class="error-overlay">
            <div class="p-3 surface-100 border-round text-red-600">
                {{ error }}
            </div>
        </div>
        <Dialog v-model:visible="showChatDialog" modal :closable="true" :header="`${selectedRoom?.title || t('common.rooms')}`" :style="{ width: '1200px', height: '800px' }" :maximizable="true">
            <Chat v-if="selectedRoom" :roomIdProp="selectedRoom.id" />
        </Dialog>
        <Dialog v-model:visible="showTopicChatDialog" modal :closable="true" :header="`${selectedTopic?.title || t('common.topics')}`" :style="{ width: '1200px', height: '800px' }" :maximizable="true">
            <TopicCommentChat v-if="selectedTopic" :topicIdProp="selectedTopic.id" />
        </Dialog>
    </div>
</template>

<style scoped lang="scss">
.room-map-wrapper {
    position: relative;
    width: 100%;
    height: calc(100vh - 120px);
    min-height: 600px;
}

.room-map {
    width: 100%;
    height: 100%;
    background: var(--surface-100);
    overflow: visible;
}

:deep(.leaflet-container) {
    overflow: visible !important;
}

:deep(.leaflet-pane) {
    overflow: visible !important;
}

:deep(.leaflet-marker-pane) {
    overflow: visible !important;
}

.loading-overlay {
    position: absolute;
    top: 20px;
    left: 50%;
    transform: translateX(-50%);
    z-index: 1000;
    display: flex;
    align-items: center;
    background: rgba(255, 255, 255, 0.95);
    padding: 12px 24px;
    border-radius: 8px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}

.error-overlay {
    position: absolute;
    top: 20px;
    left: 50%;
    transform: translateX(-50%);
    z-index: 1000;
    max-width: 90%;
}

:deep(.custom-map-marker) {
    background: none !important;
    border: none !important;
}

:deep(.responsive-marker) {
    overflow: visible !important;
}

:deep(.marker-container) {
    position: relative !important;
    max-width: 100vw !important;
}

:deep(.marker-container) {
    display: flex !important;
    flex-direction: row !important;
    align-items: flex-start !important;
    gap: 8px !important;
    cursor: pointer !important;
    position: relative !important;
}

:deep(.marker-group) {
    display: flex !important;
    flex-direction: column !important;
    align-items: center !important;
    position: relative !important;
    transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1) !important;
}

:deep(.marker-group.marker-hover) {
    transform: translateY(-6px) scale(1.08) !important;
    z-index: 1000 !important;
}

:deep(.marker-pulse-ring) {
    position: absolute !important;
    top: 50% !important;
    left: 50% !important;
    transform: translate(-50%, -50%) !important;
    width: 32px !important;
    height: 32px !important;
    border-radius: 50% !important;
    background: color-mix(in srgb, var(--primary-color) 30%, transparent) !important;
    animation: pulse-ring 2s ease-out infinite !important;
    pointer-events: none !important;
}

:deep(.topic-pulse) {
    background: color-mix(in srgb, #22c55e 30%, transparent) !important;
    width: 28px !important;
    height: 28px !important;
}

:deep(.marker-dot) {
    width: 24px !important;
    height: 24px !important;
    border-radius: 50% !important;
    position: relative !important;
    z-index: 10 !important;
    display: flex !important;
    align-items: center !important;
    justify-content: center !important;
    border: 3px solid white !important;
    box-shadow: 0 3px 12px rgba(0, 0, 0, 0.3), 0 0 0 0 color-mix(in srgb, var(--primary-color) 40%, transparent) !important;
    animation: dot-pulse 2s ease-out infinite !important;
    transition: all 0.3s ease !important;
}

:deep(.room-dot) {
    background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%) !important;
}

:deep(.topic-dot) {
    width: 20px !important;
    height: 20px !important;
    border: 2px solid white !important;
    background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%) !important;
}

:deep(.marker-dot-inner) {
    display: flex !important;
    align-items: center !important;
    justify-content: center !important;
}

:deep(.marker-group.marker-hover .marker-dot) {
    transform: scale(1.15) !important;
    box-shadow: 0 4px 18px rgba(0, 0, 0, 0.4), 0 0 0 6px color-mix(in srgb, var(--primary-color) 20%, transparent) !important;
}

:deep(.marker-card) {
    margin-top: 6px !important;
    position: relative !important;
    min-width: 120px !important;
    max-width: 180px !important;
    border-radius: 10px !important;
    overflow: hidden !important;
    transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1) !important;
    word-wrap: break-word !important;
    word-break: break-word !important;
}

:deep(.room-card) {
    background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%) !important;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15), 0 0 0 1px rgba(0, 0, 0, 0.05) !important;
}

:deep(.topic-card) {
    background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%) !important;
    box-shadow: 0 6px 18px rgba(34, 197, 94, 0.4), 0 0 0 1px rgba(255, 255, 255, 0.2) !important;
    min-width: 110px !important;
    max-width: 160px !important;
}

:deep(.marker-group.marker-hover .marker-card) {
    transform: translateY(-3px) !important;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2), 0 0 0 1px rgba(0, 0, 0, 0.1) !important;
}

:deep(.marker-group.marker-hover .topic-card) {
    box-shadow: 0 12px 32px rgba(34, 197, 94, 0.5), 0 0 0 1px rgba(255, 255, 255, 0.3) !important;
}

:deep(.marker-card-content) {
    padding: 6px 10px !important;
    display: flex !important;
    align-items: center !important;
    gap: 6px !important;
    position: relative !important;
    z-index: 2 !important;
}

:deep(.marker-icon) {
    font-size: 14px !important;
    line-height: 1 !important;
    filter: drop-shadow(0 1px 3px rgba(0, 0, 0, 0.1)) !important;
}

:deep(.marker-title) {
    font-size: 11px !important;
    font-weight: 700 !important;
    letter-spacing: 0.2px !important;
    white-space: normal !important;
    overflow-wrap: break-word !important;
    word-wrap: break-word !important;
    word-break: break-word !important;
    overflow: hidden !important;
    text-overflow: ellipsis !important;
    flex: 1 !important;
    line-height: 1.3 !important;
    max-height: 2.6em !important;
    display: -webkit-box !important;
    -webkit-line-clamp: 2 !important;
    -webkit-box-orient: vertical !important;
}

:deep(.room-card .marker-title) {
    color: #1f2937 !important;
    background: linear-gradient(135deg, #1f2937 0%, #374151 100%) !important;
    -webkit-background-clip: text !important;
    background-clip: text !important;
    -webkit-text-fill-color: transparent !important;
}

:deep(.topic-card .marker-title) {
    color: white !important;
    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2) !important;
}

:deep(.marker-card-glow) {
    position: absolute !important;
    top: 0 !important;
    left: 0 !important;
    right: 0 !important;
    bottom: 0 !important;
    background: linear-gradient(135deg, transparent 0%, color-mix(in srgb, var(--primary-color) 10%, transparent) 50%, transparent 100%) !important;
    opacity: 0 !important;
    transition: opacity 0.3s ease !important;
    pointer-events: none !important;
    border-radius: 12px !important;
}

:deep(.topic-glow) {
    background: linear-gradient(135deg, rgba(255, 255, 255, 0.2) 0%, transparent 50%, rgba(255, 255, 255, 0.1) 100%) !important;
}

:deep(.marker-group.marker-hover .marker-card-glow) {
    opacity: 1 !important;
    animation: glow-shimmer 2s ease-in-out infinite !important;
}

@keyframes pulse-ring {
    0% {
        transform: translate(-50%, -50%) scale(0.8);
        opacity: 1;
    }
    100% {
        transform: translate(-50%, -50%) scale(2);
        opacity: 0;
    }
}

@keyframes dot-pulse {
    0%,
    100% {
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3), 0 0 0 0 color-mix(in srgb, var(--primary-color) 40%, transparent);
    }
    50% {
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3), 0 0 0 4px color-mix(in srgb, var(--primary-color) 20%, transparent);
    }
}

@keyframes glow-shimmer {
    0%,
    100% {
        opacity: 0.3;
    }
    50% {
        opacity: 0.6;
    }
}

// Dark mode desteği
:deep(.app-dark) {
    .room-card {
        background: linear-gradient(135deg, #1f2937 0%, #111827 100%);
        box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4), 0 0 0 1px rgba(255, 255, 255, 0.1);
    }

    .room-card .marker-title {
        background: linear-gradient(135deg, #f9fafb 0%, #e5e7eb 100%);
        -webkit-background-clip: text;
        background-clip: text;
        -webkit-text-fill-color: transparent;
    }
}
</style>
