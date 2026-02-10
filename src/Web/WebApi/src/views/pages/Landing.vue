<script setup>
import { useRouter } from 'vue-router';
import { useI18n } from '@/composables/useI18n';

const router = useRouter();
const { t } = useI18n();

const goToLogin = () => {
    router.push({ name: 'login' });
};
</script>

<template>
    <div class="landing-page min-h-screen overflow-hidden">
        <!-- Header Navigation -->
        <header class="fixed top-0 left-0 right-0 z-50 bg-white/80 backdrop-blur-md border-b border-gray-100">
            <nav class="container mx-auto px-6 py-4 flex items-center justify-between">
                <!-- Logo -->
                <div class="flex items-center gap-2">
                    <i class="pi pi-map-marker text-2xl text-orange-500"></i>
                    <span class="text-xl font-bold text-gray-900">{{ t('landing.logo') }}</span>
                </div>

                <!-- Navigation Links -->
                <div class="hidden md:flex items-center gap-8">
                    <a href="#how-it-works" class="text-gray-700 hover:text-orange-500 transition-colors">{{ t('landing.navHowItWorks') }}</a>
                    <a href="#features" class="text-gray-700 hover:text-orange-500 transition-colors">{{ t('landing.navFeatures') }}</a>
                    <a href="#who-its-for" class="text-gray-700 hover:text-orange-500 transition-colors">{{ t('landing.navWhoItsFor') }}</a>
                    <a href="#safety" class="text-gray-700 hover:text-orange-500 transition-colors">{{ t('landing.navSafety') }}</a>
                    <a href="#stories" class="text-gray-700 hover:text-orange-500 transition-colors">{{ t('landing.navStories') }}</a>
                </div>

                <!-- Header Actions -->
                <div class="flex items-center gap-4">
                    <button @click="goToLogin" class="text-gray-700 hover:text-orange-500 transition-colors font-medium hidden sm:block">
                        {{ t('landing.navLogin') }}
                    </button>
                    <Button 
                        @click="goToLogin" 
                        :label="t('landing.navGetStarted')" 
                        severity="warning"
                        class="!bg-orange-500 hover:!bg-orange-600 !text-white !px-6 !py-2 !rounded-full !font-medium !shadow-lg hover:!shadow-xl"
                    />
                </div>
            </nav>
        </header>

        <!-- Main Content -->
        <main class="pt-24 pb-16">
            <div class="container mx-auto px-6">
                <div class="grid lg:grid-cols-2 gap-12 items-center min-h-[calc(100vh-8rem)]">
                    <!-- Left Content -->
                    <div class="space-y-8">
                        <!-- Community Badge -->
                        <div class="inline-flex items-center gap-2 bg-gray-100 px-4 py-2 rounded-full">
                            <i class="pi pi-users text-orange-500"></i>
                            <span class="text-gray-700 text-sm font-medium">{{ t('landing.connectCommunity') }}</span>
                        </div>

                        <!-- Main Title -->
                        <h1 class="text-5xl lg:text-6xl font-bold text-gray-900 leading-tight">
                            {{ t('landing.mainTitle') }}
                            <span class="text-orange-500 block mt-2">{{ t('landing.mainTitleHighlight') }}</span>
                        </h1>

                        <!-- Description -->
                        <p class="text-xl text-gray-600 leading-relaxed max-w-xl">
                            {{ t('landing.description') }}
                        </p>

                        <!-- Legal Note -->
                        <p class="text-sm text-gray-500 italic">
                            {{ t('landing.legalNote') }}
                        </p>

                        <!-- CTA Buttons -->
                        <div class="flex flex-col sm:flex-row gap-4 pt-4">
                            <Button 
                                @click="goToLogin" 
                                :label="t('landing.getStarted')" 
                                icon="pi pi-arrow-right" 
                                iconPos="right"
                                severity="warning"
                                class="!bg-orange-500 hover:!bg-orange-600 !text-white !px-8 !py-3 !rounded-full !text-lg !font-semibold !shadow-lg hover:!shadow-xl"
                            />
                            <Button 
                                :label="t('landing.exploreHowItWorks')" 
                                icon="pi pi-arrow-right" 
                                iconPos="right"
                                outlined
                                severity="secondary"
                                class="!px-8 !py-3 !rounded-full !text-lg !font-semibold !border-2 hover:!bg-gray-50"
                            />
                        </div>
                    </div>

                    <!-- Right Content - Phone Mockup -->
                    <div class="relative flex justify-center lg:justify-end">
                        <div class="relative w-full max-w-md">
                            <!-- Phone Frame -->
                            <div class="relative bg-gray-900 rounded-[3rem] p-4 shadow-2xl transform rotate-3 hover:rotate-0 transition-transform duration-300">
                                <div class="bg-white rounded-[2.5rem] overflow-hidden">
                                    <!-- Phone Screen Content -->
                                    <div class="relative h-[600px] bg-gradient-to-br from-blue-50 to-green-50">
                                        <!-- Map Background -->
                                        <div class="absolute inset-0 opacity-20">
                                            <svg viewBox="0 0 400 600" class="w-full h-full">
                                                <!-- Simplified map lines -->
                                                <path d="M50 100 L350 100 L350 200 L50 200 Z" stroke="#94a3b8" stroke-width="2" fill="none"/>
                                                <path d="M100 150 L300 150 L300 250 L100 250 Z" stroke="#94a3b8" stroke-width="2" fill="none"/>
                                                <path d="M150 300 L250 300 L250 400 L150 400 Z" stroke="#94a3b8" stroke-width="2" fill="none"/>
                                                <!-- Water bodies -->
                                                <ellipse cx="200" cy="500" rx="80" ry="60" fill="#3b82f6" opacity="0.3"/>
                                            </svg>
                                        </div>

                                        <!-- Map Pins/Markers -->
                                        <div class="absolute top-20 left-1/4">
                                            <div class="bg-orange-500 rounded-full p-3 shadow-lg">
                                                <i class="pi pi-coffee text-white text-xl"></i>
                                            </div>
                                        </div>
                                        <div class="absolute top-40 right-1/4">
                                            <div class="bg-green-500 rounded-full p-3 shadow-lg">
                                                <i class="pi pi-users text-white text-xl"></i>
                                            </div>
                                        </div>
                                        <div class="absolute top-60 left-1/3">
                                            <div class="bg-orange-500 rounded-full p-3 shadow-lg">
                                                <i class="pi pi-calendar text-white text-xl"></i>
                                            </div>
                                        </div>
                                        <div class="absolute bottom-40 left-1/4">
                                            <div class="bg-blue-500 rounded-full p-3 shadow-lg">
                                                <i class="pi pi-suitcase text-white text-xl"></i>
                                            </div>
                                        </div>
                                        <div class="absolute bottom-60 right-1/3">
                                            <div class="bg-pink-500 rounded-full p-3 shadow-lg">
                                                <i class="pi pi-music text-white text-xl"></i>
                                            </div>
                                        </div>

                                        <!-- Labels -->
                                        <div class="absolute top-8 right-8">
                                            <span class="bg-orange-500 text-white px-3 py-1 rounded-full text-xs font-semibold shadow-md">
                                                {{ t('landing.community') }}
                                            </span>
                                        </div>
                                        <div class="absolute top-32 right-12">
                                            <span class="bg-green-500 text-white px-3 py-1 rounded-full text-xs font-semibold shadow-md">
                                                {{ t('landing.friends') }}
                                            </span>
                                        </div>
                                        <div class="absolute bottom-32 right-8">
                                            <span class="bg-blue-400 text-white px-3 py-1 rounded-full text-xs font-semibold shadow-md">
                                                {{ t('landing.events') }}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>
</template>

<style scoped>
.landing-page {
    background: linear-gradient(135deg, #fef3c7 0%, #fed7aa 50%, #fdba74 100%);
    min-height: 100vh;
}

/* Smooth scroll behavior */
html {
    scroll-behavior: smooth;
}

/* Custom button styles */
:deep(.p-button) {
    border: none;
}

:deep(.p-button-label) {
    font-weight: inherit;
}
</style>
