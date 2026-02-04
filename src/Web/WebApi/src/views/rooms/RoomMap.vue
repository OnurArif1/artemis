<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from '@/composables/useI18n';
import { useLayout } from '@/layout/composables/layout';
import request from '@/service/request';
import RoomService from '@/service/RoomService';
import TopicService from '@/service/TopicService';
import Chat from '@/views/chat/Chat.vue';
import TopicCommentChat from '@/views/chat/TopicCommentChat.vue';

const route = useRoute();
const roomService = new RoomService(request);
const topicService = new TopicService(request);
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
let cachedRooms = [];
let cachedTopics = [];

const TURKEY_CENTER = [39, 35.5];
const CITY_CLUSTER_DISTANCE_KM = 50; // Şehir bazlı gruplama için mesafe (50km - şehir bazlı)
let currentZoomLevel = 6;
let showingDetailedMarkers = false;

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
        const [roomRes, topicRes] = await Promise.all([
            roomService.getList({ pageIndex: 1, pageSize: 1000 }),
            topicService.getList({ pageIndex: 1, pageSize: 1000 })
        ]);
        
        const rooms = roomRes?.resultViewModels ?? roomRes?.ResultViewModels ?? [];
        const topics = topicRes?.resultViewModels ?? topicRes?.ResultViewModels ?? [];
        
        // Cache'le
        cachedRooms = rooms;
        cachedTopics = topics;
        
        if (!Array.isArray(rooms) || !Array.isArray(topics)) {
            loading.value = false;
            return;
        }

        if (markersLayer) {
            map.removeLayer(markersLayer);
        }
        markersLayer = L.layerGroup().addTo(map);

        // Şehir/bölge bazlı gruplama - odalar ve topic'leri ayrı grupla
        const roomRegions = groupByRegion(rooms, 'room');
        const topicRegions = groupByRegion(topics, 'topic');

        // Tüm şehirleri birleştir ve her şehir için hem oda hem topic sayısını göster
        const allRegions = combineRegions(roomRegions, topicRegions);

        // İlk yüklemede sadece şehir marker'larını göster
        for (const region of allRegions) {
            createCityMarker(region, L, rooms, topics);
        }

        // Zoom değişikliğini dinle
        map.on('zoomend', () => {
            currentZoomLevel = map.getZoom();
            updateMarkersBasedOnZoom(L);
        });

        const validCoords = allRegions.map(r => r.center);

        // Marker'lara göre zoom yap (eğer query'de roomId yoksa)
        // Harita ve marker'lar tam yüklendikten sonra zoom yap
        setTimeout(() => {
            if (!route.query.roomId && validCoords.length > 0) {
                const bounds = L.latLngBounds(validCoords);
                map.fitBounds(bounds, { padding: [50, 50], maxZoom: 10 });
            } else if (!route.query.roomId) {
                // Eğer hiç marker yoksa Türkiye'ye zoom yap
                const TURKEY_BOUNDS = [
                    [35.8, 25.9],
                    [42.2, 44.9]
                ];
                map.fitBounds(TURKEY_BOUNDS, { padding: [20, 20], maxZoom: 8 });
            }
        }, 200);

        const roomIdFromQuery = route.query.roomId;
        if (roomIdFromQuery) {
            const roomIdNum = parseInt(roomIdFromQuery);
            if (!isNaN(roomIdNum)) {
                // Tüm region'larda ara
                let targetRoom = null;
                let targetRegion = null;
                const allRegions = combineRegions(roomRegions, topicRegions);
                
                for (const region of allRegions) {
                    targetRoom = region.roomItems.find((r) => (r.id ?? r.Id) === roomIdNum);
                    if (targetRoom) {
                        targetRegion = region;
                        break;
                    }
                }
                
                if (targetRoom && targetRegion) {
                    selectedRoom.value = {
                        id: roomIdNum,
                        title: targetRoom.title ?? targetRoom.Title ?? `${t('room.prefix')}${roomIdNum}`
                    };
                    showChatDialog.value = true;

                    const roomLat = Number(targetRoom.locationY ?? targetRoom.LocationY);
                    const roomLng = Number(targetRoom.locationX ?? targetRoom.LocationX);
                    if (!Number.isNaN(roomLat) && !Number.isNaN(roomLng)) {
                        map.setView([roomLat, roomLng], 15);
                        // Detaylı marker'ları göster
                        showingDetailedMarkers = true;
                        showDetailedMarkersForRegion(targetRegion, 'room', L, rooms, topics);
                    }
                }
            }
        }

        // Türkiye'ye zoom yap
        const TURKEY_BOUNDS = [
            [35.8, 25.9],
            [42.2, 44.9]
        ];
        map.fitBounds(TURKEY_BOUNDS, { padding: [50, 50], maxZoom: 7 });
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

function calculateDistance(lat1, lng1, lat2, lng2) {
    const R = 6371; // Dünya yarıçapı (km)
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLng = (lng2 - lng1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

function groupByRegion(items, type) {
    const regions = [];
    const processed = new Set();
    
    for (let i = 0; i < items.length; i++) {
        if (processed.has(i)) continue;
        
        const item = items[i];
        const lat = Number(item.locationY ?? item.LocationY);
        const lng = Number(item.locationX ?? item.LocationX);
        
        if (Number.isNaN(lat) || Number.isNaN(lng)) continue;
        
        // Yeni bir şehir grubu oluştur
        const region = {
            items: [item],
            center: [lat, lng],
            type: type,
            key: `region_${i}`
        };
        
        processed.add(i);
        
        // Aynı şehirdeki (50km içindeki) diğer öğeleri bul
        for (let j = i + 1; j < items.length; j++) {
            if (processed.has(j)) continue;
            
            const otherItem = items[j];
            const otherLat = Number(otherItem.locationY ?? otherItem.LocationY);
            const otherLng = Number(otherItem.locationX ?? otherItem.LocationX);
            
            if (Number.isNaN(otherLat) || Number.isNaN(otherLng)) continue;
            
            const distance = calculateDistance(lat, lng, otherLat, otherLng);
            
            if (distance <= CITY_CLUSTER_DISTANCE_KM) {
                region.items.push(otherItem);
                processed.add(j);
            }
        }
        
        // Merkez noktasını hesapla
        if (region.items.length > 0) {
            const totalLat = region.items.reduce((sum, it) => sum + Number(it.locationY ?? it.LocationY), 0);
            const totalLng = region.items.reduce((sum, it) => sum + Number(it.locationX ?? it.LocationX), 0);
            region.center = [totalLat / region.items.length, totalLng / region.items.length];
            region.key = `${Math.round(region.center[0] * 10) / 10}_${Math.round(region.center[1] * 10) / 10}`;
        }
        
        regions.push(region);
    }
    
    return regions;
}

function combineRegions(roomRegions, topicRegions) {
    const combined = [];
    const processedRooms = new Set();
    const processedTopics = new Set();
    
    // Tüm region'ları birleştir (mesafe bazlı)
    const allRegions = [
        ...roomRegions.map(r => ({ ...r, isRoom: true })),
        ...topicRegions.map(r => ({ ...r, isRoom: false }))
    ];
    
    for (let i = 0; i < allRegions.length; i++) {
        const region = allRegions[i];
        const isRoom = region.isRoom;
        
        if ((isRoom && processedRooms.has(i)) || (!isRoom && processedTopics.has(i))) continue;
        
        const combinedRegion = {
            key: region.key,
            center: region.center,
            roomCount: isRoom ? region.items.length : 0,
            topicCount: !isRoom ? region.items.length : 0,
            roomItems: isRoom ? [...region.items] : [],
            topicItems: !isRoom ? [...region.items] : []
        };
        
        if (isRoom) processedRooms.add(i);
        else processedTopics.add(i);
        
        // Yakın region'ları bul ve birleştir
        for (let j = i + 1; j < allRegions.length; j++) {
            const otherRegion = allRegions[j];
            const otherIsRoom = otherRegion.isRoom;
            
            if ((otherIsRoom && processedRooms.has(j)) || (!otherIsRoom && processedTopics.has(j))) continue;
            
            const distance = calculateDistance(
                combinedRegion.center[0], combinedRegion.center[1],
                otherRegion.center[0], otherRegion.center[1]
            );
            
            if (distance <= CITY_CLUSTER_DISTANCE_KM) {
                if (otherIsRoom) {
                    combinedRegion.roomCount += otherRegion.items.length;
                    combinedRegion.roomItems.push(...otherRegion.items);
                    processedRooms.add(j);
                } else {
                    combinedRegion.topicCount += otherRegion.items.length;
                    combinedRegion.topicItems.push(...otherRegion.items);
                    processedTopics.add(j);
                }
            }
        }
        
        // Merkez noktasını yeniden hesapla
        const allItems = [...combinedRegion.roomItems, ...combinedRegion.topicItems];
        if (allItems.length > 0) {
            const totalLat = allItems.reduce((sum, it) => sum + Number(it.locationY ?? it.LocationY), 0);
            const totalLng = allItems.reduce((sum, it) => sum + Number(it.locationX ?? it.LocationX), 0);
            combinedRegion.center = [totalLat / allItems.length, totalLng / allItems.length];
            combinedRegion.key = `${Math.round(combinedRegion.center[0] * 10) / 10}_${Math.round(combinedRegion.center[1] * 10) / 10}`;
        }
        
        // Sadece oda veya topic sayısı 0'dan büyükse ekle
        if (combinedRegion.roomCount > 0 || combinedRegion.topicCount > 0) {
            combined.push(combinedRegion);
        }
    }
    
    return combined;
}

function createCityMarker(region, L, allRooms, allTopics) {
    const [lat, lng] = region.center;
    const hasRooms = region.roomCount > 0;
    const hasTopics = region.topicCount > 0;
    
    // Şehir marker HTML - 2 ayrı yuvarlak (oda ve topic)
    const markerHtml = `
        <div class="city-marker-container" data-region-key="${region.key}">
            ${hasRooms ? `
                <div class="city-marker city-room-marker" data-type="room">
                    <div class="city-dot city-room-dot">
                        <div class="city-count">${region.roomCount}</div>
                    </div>
                    <div class="city-pulse-ring city-room-pulse"></div>
                </div>
            ` : ''}
            ${hasTopics ? `
                <div class="city-marker city-topic-marker" data-type="topic">
                    <div class="city-dot city-topic-dot">
                        <div class="city-count">${region.topicCount}</div>
                    </div>
                    <div class="city-pulse-ring city-topic-pulse"></div>
                </div>
            ` : ''}
        </div>
    `;
    
    const icon = L.divIcon({
        className: 'custom-city-marker',
        html: markerHtml,
        iconSize: [hasRooms && hasTopics ? 85 : 42.5, 42.5],
        iconAnchor: [hasRooms && hasTopics ? 42.5 : 21.25, 21.25],
        popupAnchor: [0, -21.25]
    });
    
    const marker = L.marker([lat, lng], { icon }).addTo(markersLayer);
    
    // Oda marker'ına tıklama
    if (hasRooms) {
        marker.on('click', (e) => {
            const target = e.originalEvent.target;
            if (target.closest('.city-room-marker')) {
                e.originalEvent.stopPropagation();
                if (map) {
                    markersLayer.clearLayers();
                    map.setView([lat, lng], 12, {
                        animate: true,
                        duration: 0.5
                    });
                    showingDetailedMarkers = true;
                    showDetailedMarkersForRegion(region, 'room', L, allRooms, allTopics);
                }
            }
        });
    }
    
    // Topic marker'ına tıklama
    if (hasTopics) {
        marker.on('click', (e) => {
            const target = e.originalEvent.target;
            if (target.closest('.city-topic-marker')) {
                e.originalEvent.stopPropagation();
                if (map) {
                    markersLayer.clearLayers();
                    map.setView([lat, lng], 12, {
                        animate: true,
                        duration: 0.5
                    });
                    showingDetailedMarkers = true;
                    showDetailedMarkersForRegion(region, 'topic', L, allRooms, allTopics);
                }
            }
        });
    }
    
    // Hover efektleri
    marker.on('mouseover', () => {
        const markerEl = marker.getElement();
        if (markerEl) {
            markerEl.classList.add('city-marker-hover');
        }
    });
    
    marker.on('mouseout', () => {
        const markerEl = marker.getElement();
        if (markerEl) {
            markerEl.classList.remove('city-marker-hover');
        }
    });
}

function showDetailedMarkersForRegion(region, type, L, allRooms, allTopics) {
    // Bu bölgedeki tüm öğeleri tek tek göster
    const items = type === 'room' ? region.roomItems : region.topicItems;
    
    for (const item of items) {
        const lat = Number(item.locationY ?? item.LocationY);
        const lng = Number(item.locationX ?? item.LocationX);
        
        if (Number.isNaN(lat) || Number.isNaN(lng)) continue;
        
        if (type === 'room') {
            createDetailedRoomMarker(item, lat, lng, L);
        } else {
            createDetailedTopicMarker(item, lat, lng, L);
        }
    }
}

function createDetailedRoomMarker(room, lat, lng, L) {
    const title = room.title ?? room.Title ?? `${t('room.prefix')}${room.id ?? room.Id}`;
    const roomId = room.id ?? room.Id;
    const topicId = room.topicId ?? room.TopicId;
    const topicTitle = room.topicTitle ?? room.TopicTitle;
    
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
    
    const markerWidth = topicId && topicTitle ? 320 : 180;
    const markerHeight = 60;
    
    const icon = L.divIcon({
        className: 'custom-map-marker responsive-marker',
        html: markerHtml,
        iconSize: [markerWidth, markerHeight],
        iconAnchor: [markerWidth / 2, markerHeight],
        popupAnchor: [0, -markerHeight]
    });
    
    const marker = L.marker([lat, lng], { icon }).addTo(markersLayer);
    
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
}

function createDetailedTopicMarker(topic, lat, lng, L) {
    const title = topic.title ?? topic.Title ?? `${t('topic.prefix')}${topic.id ?? topic.Id}`;
    const topicId = topic.id ?? topic.Id;
    const topicMarkerId = `topic-marker-${topicId}`;
    
    const markerHtml = `
        <div class="marker-container" data-marker-id="${topicMarkerId}">
            <div class="marker-group topic-marker-group">
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
                        <div class="marker-title">${escapeHtml(title)}</div>
                    </div>
                    <div class="marker-card-glow topic-glow"></div>
                </div>
            </div>
        </div>
    `;
    
    const markerWidth = 180;
    const markerHeight = 60;
    
    const icon = L.divIcon({
        className: 'custom-map-marker responsive-marker',
        html: markerHtml,
        iconSize: [markerWidth, markerHeight],
        iconAnchor: [markerWidth / 2, markerHeight],
        popupAnchor: [0, -markerHeight]
    });
    
    const marker = L.marker([lat, lng], { icon }).addTo(markersLayer);
    
    marker.on('click', () => {
        selectedTopic.value = {
            id: topicId,
            title: title
        };
        showTopicChatDialog.value = true;
    });
}

function updateMarkersBasedOnZoom(L) {
    // Zoom seviyesi düşükse (uzaktan bakıyorsa) şehir marker'larını göster
    if (currentZoomLevel < 10 && showingDetailedMarkers) {
        showingDetailedMarkers = false;
        markersLayer.clearLayers();
        
        const roomRegions = groupByRegion(cachedRooms, 'room');
        const topicRegions = groupByRegion(cachedTopics, 'topic');
        const allRegions = combineRegions(roomRegions, topicRegions);
        
        for (const region of allRegions) {
            createCityMarker(region, L, cachedRooms, cachedTopics);
        }
    }
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

// City Marker Styles
:deep(.custom-city-marker) {
    background: none !important;
    border: none !important;
}

:deep(.city-marker-container) {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    position: relative;
}

:deep(.city-marker) {
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
}

:deep(.city-dot) {
    width: 35px;
    height: 35px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    z-index: 10;
    border: 2.5px solid white;
    box-shadow:
        0 2px 8px rgba(0, 0, 0, 0.3),
        0 0 0 0 rgba(0, 0, 0, 0.2);
    transition: all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
}

:deep(.city-room-dot) {
    background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
}

:deep(.city-topic-dot) {
    background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
}

:deep(.city-count) {
    font-size: 13px;
    font-weight: 800;
    color: white;
    text-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
    letter-spacing: -0.3px;
}

:deep(.city-pulse-ring) {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 35px;
    height: 35px;
    border-radius: 50%;
    pointer-events: none;
    animation: city-pulse 2s ease-out infinite;
}

:deep(.city-room-pulse) {
    background: color-mix(in srgb, #ef4444 30%, transparent);
}

:deep(.city-topic-pulse) {
    background: color-mix(in srgb, #22c55e 30%, transparent);
}

:deep(.city-marker-container.city-marker-hover .city-room-marker .city-dot) {
    transform: scale(1.2);
    box-shadow:
        0 6px 24px rgba(0, 0, 0, 0.4),
        0 0 0 6px color-mix(in srgb, #ef4444 20%, transparent);
}

:deep(.city-marker-container.city-marker-hover .city-topic-marker .city-dot) {
    transform: scale(1.2);
    box-shadow:
        0 6px 24px rgba(0, 0, 0, 0.4),
        0 0 0 6px color-mix(in srgb, #22c55e 20%, transparent);
}

:deep(.city-marker-container.city-marker-hover) {
    transform: translateY(-4px);
}

:deep(.city-room-marker:hover .city-dot) {
    transform: scale(1.15);
    box-shadow:
        0 6px 24px rgba(0, 0, 0, 0.4),
        0 0 0 6px color-mix(in srgb, #ef4444 20%, transparent);
}

:deep(.city-topic-marker:hover .city-dot) {
    transform: scale(1.15);
    box-shadow:
        0 6px 24px rgba(0, 0, 0, 0.4),
        0 0 0 6px color-mix(in srgb, #22c55e 20%, transparent);
}

@keyframes city-pulse {
    0% {
        transform: translate(-50%, -50%) scale(0.9);
        opacity: 1;
    }
    100% {
        transform: translate(-50%, -50%) scale(1.8);
        opacity: 0;
    }
}
</style>
