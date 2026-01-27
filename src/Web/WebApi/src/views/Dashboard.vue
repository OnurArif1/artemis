<script setup>
import { useI18n } from '@/composables/useI18n';

const { t } = useI18n();
</script>

<template>
    <div class="grid">
        <div class="col-12">
            <div class="card">
                <h5>{{ t('common.dashboard') }}</h5>
                <p>Artemis WebApi – Gösterge paneli. Buraya sonraki özellikler eklenecek.</p>
            </div>
        </div>
    </div>
</template>

<style scoped></style>
