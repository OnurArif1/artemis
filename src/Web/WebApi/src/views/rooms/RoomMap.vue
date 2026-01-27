<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue';
import { useI18n } from '@/composables/useI18n';
import request from '@/service/request';
import RoomService from '@/service/RoomService';

const roomService = new RoomService(request);
const { t } = useI18n();
const mapContainer = ref(null);
const loading = ref(true);
const error = ref('');
let map = null;
let markersLayer = null;

const TURKEY_CENTER = [39, 35.5];
const TURKEY_BOUNDS = [
    [35.8, 25.9],
    [42.2, 44.9]
];

onMounted(async () => {
    if (!mapContainer.value) return;

    // Leaflet index.html'de CDN'den yüklendi, window.L olarak erişilebilir
    const L = window.L;
    
    if (!L || typeof L.map !== 'function') {
        error.value = t('common.error') + ': Leaflet yüklenemedi. Lütfen sayfayı yenileyin.';
        loading.value = false;
        return;
    }

    map = L.map(mapContainer.value).setView(TURKEY_CENTER, 6);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(map);

    map.fitBounds(TURKEY_BOUNDS, { padding: [24, 24], maxZoom: 7 });

    loading.value = true;
    error.value = '';
    try {
        const res = await roomService.getList({ pageIndex: 1, pageSize: 500 });
        const rooms = res?.resultViewModels ?? res?.ResultViewModels ?? [];
        if (!Array.isArray(rooms)) return;

        if (markersLayer) {
            map.removeLayer(markersLayer);
        }
        markersLayer = L.layerGroup().addTo(map);

        for (const r of rooms) {
            const lat = Number(r.locationY ?? r.LocationY);
            const lng = Number(r.locationX ?? r.LocationX);
            if (Number.isNaN(lat) || Number.isNaN(lng)) continue;

            const title = r.title ?? r.Title ?? `Oda #${r.id ?? r.Id}`;
            const icon = L.divIcon({
                className: 'room-marker',
                html: `<span class="room-marker-dot" title="${escapeHtml(title)}"></span>`,
                iconSize: [14, 14],
                iconAnchor: [7, 7]
            });
            const marker = L.marker([lat, lng], { icon }).addTo(markersLayer);
            marker.bindPopup(`<strong>${escapeHtml(title)}</strong>`);
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
    <div class="grid">
        <div class="col-12">
            <div class="card">
                <h5>{{ t('common.rooms') }}</h5>
                <p class="text-color-secondary mb-4">
                    Türkiye haritası üzerinde odaların konumları (LocationX, LocationY).
                </p>
                <div v-if="loading" class="flex align-items-center gap-2 mb-3">
                    <ProgressSpinner style="width: 24px; height: 24px" />
                    <span>{{ t('common.loading') }}</span>
                </div>
                <div v-else-if="error" class="p-3 surface-100 border-round mb-3 text-red-600">
                    {{ error }}
                </div>
                <div
                    ref="mapContainer"
                    class="room-map"
                />
            </div>
        </div>
    </div>
</template>

<style scoped>
.room-map {
    width: 100%;
    height: 520px;
    border-radius: 8px;
    overflow: hidden;
    background: var(--surface-100);
}

:deep(.room-marker) {
    background: none;
    border: none;
}

:deep(.room-marker-dot) {
    display: block;
    width: 14px;
    height: 14px;
    border-radius: 50%;
    background: var(--primary-color);
    border: 2px solid white;
    box-shadow: 0 1px 4px rgba(0, 0, 0, 0.4);
    cursor: pointer;
}

:deep(.room-marker-dot:hover) {
    transform: scale(1.2);
}
</style>
