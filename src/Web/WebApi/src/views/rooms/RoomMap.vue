<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue';
import { useI18n } from '@/composables/useI18n';
import request from '@/service/request';
import RoomService from '@/service/RoomService';
import Chat from '@/views/chat/Chat.vue';

const roomService = new RoomService(request);
const { t } = useI18n();
const mapContainer = ref(null);
const loading = ref(true);
const error = ref('');
const showChatDialog = ref(false);
const selectedRoom = ref(null);
let map = null;
let markersLayer = null;

const TURKEY_CENTER = [39, 35.5];

onMounted(async () => {
    if (!mapContainer.value) return;

    const L = window.L;

    if (!L || typeof L.map !== 'function') {
        error.value = t('common.error') + ': Leaflet yüklenemedi. Lütfen sayfayı yenileyin.';
        loading.value = false;
        return;
    }

    map = L.map(mapContainer.value).setView(TURKEY_CENTER, 6);
    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/attributions">CARTO</a>',
        subdomains: 'abcd',
        maxZoom: 19
    }).addTo(map);

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

            const title = r.title ?? r.Title ?? `Oda #${r.id ?? r.Id}`;
            const roomId = r.id ?? r.Id;

            const icon = L.divIcon({
                className: 'room-marker',
                html: `
                    <div style="display: flex; flex-direction: column; align-items: center; cursor: pointer; width: 100%; height: 100%;">
                        <div style="width: 24px; height: 24px; border-radius: 50%; background: #ef4444; border: 3px solid white; box-shadow: 0 2px 8px rgba(0,0,0,0.4); margin-bottom: 4px; flex-shrink: 0;"></div>
                        <div style="background: white; color: #1f2937; padding: 6px 12px; border-radius: 6px; font-size: 13px; font-weight: 600; white-space: nowrap; box-shadow: 0 2px 8px rgba(0,0,0,0.25); border: 1px solid rgba(0,0,0,0.15); max-width: 180px; overflow: hidden; text-overflow: ellipsis; display: block; visibility: visible; opacity: 1;">${escapeHtml(title)}</div>
                    </div>
                `,
                iconSize: [180, 60],
                iconAnchor: [90, 60]
            });

            const marker = L.marker([lat, lng], { icon }).addTo(markersLayer);

            marker.on('click', () => {
                selectedRoom.value = {
                    id: roomId,
                    title: title
                };
                showChatDialog.value = true;
            });
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

onBeforeUnmount(() => {
    if (map) {
        map.remove();
        map = null;
    }
    markersLayer = null;
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
        <Dialog 
            v-model:visible="showChatDialog" 
            modal 
            :closable="true" 
            :header="`${selectedRoom?.title || t('common.rooms')}`" 
            :style="{ width: '1200px', height: '800px' }" 
            :maximizable="true"
        >
            <Chat v-if="selectedRoom" :roomIdProp="selectedRoom.id" />
        </Dialog>
    </div>
</template>

<style scoped>
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

:deep(.room-marker) {
    background: none;
    border: none;
}

:deep(.room-marker-container) {
    display: flex !important;
    flex-direction: column !important;
    align-items: center !important;
    cursor: pointer !important;
    transition: transform 0.2s ease !important;
    width: 100% !important;
    height: 100% !important;
}

:deep(.room-marker-container:hover) {
    transform: scale(1.1);
}

:deep(.room-marker-label) {
    background: rgba(255, 255, 255, 0.98) !important;
    color: #1f2937 !important;
    padding: 6px 12px !important;
    border-radius: 6px !important;
    font-size: 13px !important;
    font-weight: 600 !important;
    white-space: nowrap !important;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.25) !important;
    border: 1px solid rgba(0, 0, 0, 0.15) !important;
    max-width: 180px !important;
    overflow: hidden !important;
    text-overflow: ellipsis !important;
    position: relative !important;
    z-index: 1 !important;
    margin-top: 4px !important;
    display: block !important;
    visibility: visible !important;
    opacity: 1 !important;
}

:deep(.room-marker-dot) {
    width: 24px;
    height: 24px;
    border-radius: 50%;
    background: var(--primary-color);
    border: 3px solid white;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
    position: relative;
    z-index: 2;
}

:deep(.room-marker-container:hover .room-marker-dot) {
    transform: scale(1.1);
    box-shadow: 0 3px 10px rgba(0, 0, 0, 0.5);
}

:deep(.room-marker-container:hover .room-marker-label) {
    background: rgba(255, 255, 255, 1);
    box-shadow: 0 3px 10px rgba(0, 0, 0, 0.3);
}
</style>
