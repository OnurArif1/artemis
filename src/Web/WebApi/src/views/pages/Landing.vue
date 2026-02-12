<script setup>
import { useRouter } from 'vue-router';
import { useI18n } from '@/composables/useI18n';
import { onMounted } from 'vue';

const router = useRouter();
const { t } = useI18n();

const goToLogin = () => {
    router.push({ name: 'login' });
};

const scrollToSection = (sectionId) => {
    const element = document.getElementById(sectionId);
    if (element) {
        const headerOffset = 80;
        const elementPosition = element.getBoundingClientRect().top;
        const offsetPosition = elementPosition + window.pageYOffset - headerOffset;
        window.scrollTo({
            top: offsetPosition,
            behavior: 'smooth'
        });
    }
};

onMounted(() => {
    // Smooth scroll için hash değişikliklerini dinle
    const handleHashChange = () => {
        const hash = window.location.hash.substring(1);
        if (hash) {
            setTimeout(() => scrollToSection(hash), 100);
        }
    };
    
    window.addEventListener('hashchange', handleHashChange);
    handleHashChange();
});
</script>

<template>
    <div class="landing-page min-h-screen overflow-hidden">
        <!-- Header Navigation -->
        <header class="fixed top-0 left-0 right-0 z-50 bg-white/80 backdrop-blur-md border-b border-gray-100">
            <nav class="container mx-auto px-6 py-4 flex items-center justify-between">
                <!-- Logo -->
                <div class="flex items-center gap-2">
                    <i class="pi pi-map-marker text-2xl text-electric-purple"></i>
                    <span class="text-xl font-bold text-dark-charcoal">{{ t('landing.logo') }}</span>
                </div>

                <!-- Navigation Links -->
                <div class="hidden md:flex items-center gap-8">
                    <a @click.prevent="scrollToSection('how-it-works')" href="#how-it-works" class="text-gray-700 hover:text-electric-purple transition-colors cursor-pointer">{{ t('landing.navHowItWorks') }}</a>
                    <a @click.prevent="scrollToSection('features')" href="#features" class="text-gray-700 hover:text-electric-purple transition-colors cursor-pointer">{{ t('landing.navFeatures') }}</a>
                    <a @click.prevent="scrollToSection('who-its-for')" href="#who-its-for" class="text-gray-700 hover:text-electric-purple transition-colors cursor-pointer">{{ t('landing.navWhoItsFor') }}</a>
                    <a @click.prevent="scrollToSection('safety')" href="#safety" class="text-gray-700 hover:text-electric-purple transition-colors cursor-pointer">{{ t('landing.navSafety') }}</a>
                    <a @click.prevent="scrollToSection('stories')" href="#stories" class="text-gray-700 hover:text-electric-purple transition-colors cursor-pointer">{{ t('landing.navStories') }}</a>
                </div>

                <!-- Header Actions -->
                <div class="flex items-center gap-4">
                    <button @click="goToLogin" class="text-gray-700 hover:text-electric-purple transition-colors font-medium hidden sm:block">
                        {{ t('landing.navLogin') }}
                    </button>
                    <Button 
                        @click="goToLogin" 
                        :label="t('landing.navGetStarted')" 
                        severity="warning"
                        class="!bg-electric-purple hover:!bg-[#5200CC] !text-white !px-6 !py-2 !rounded-full !font-medium !shadow-lg hover:!shadow-xl"
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
                            <i class="pi pi-users text-electric-purple"></i>
                            <span class="text-gray-700 text-sm font-medium">{{ t('landing.connectCommunity') }}</span>
                        </div>

                        <!-- Main Title -->
                        <h1 class="text-5xl lg:text-6xl font-bold text-dark-charcoal leading-tight">
                            {{ t('landing.mainTitle') }}
                            <span class="text-electric-purple block mt-2">{{ t('landing.mainTitleHighlight') }}</span>
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
                                class="!bg-electric-purple hover:!bg-[#5200CC] !text-white !px-8 !py-3 !rounded-full !text-lg !font-semibold !shadow-lg hover:!shadow-xl"
                            />
                            <Button 
                                @click="scrollToSection('how-it-works')"
                                :label="t('landing.exploreHowItWorks')" 
                                icon="pi pi-arrow-right" 
                                iconPos="right"
                                outlined
                                severity="secondary"
                                class="!px-8 !py-3 !rounded-full !text-lg !font-semibold !border-2 hover:!bg-gray-50 !border-electric-purple !text-electric-purple hover:!bg-purple-50"
                            />
                        </div>
                    </div>

                    <!-- Right Content - Phone Mockup -->
                    <div class="relative flex justify-center lg:justify-end">
                        <div class="relative w-full max-w-md">
                            <!-- Phone Frame -->
                            <div class="relative bg-dark-charcoal rounded-[3rem] p-4 shadow-2xl transform rotate-3 hover:rotate-0 transition-transform duration-300">
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
                                            <div class="bg-electric-purple rounded-full p-3 shadow-lg">
                                                <i class="pi pi-coffee text-white text-xl"></i>
                                            </div>
                                        </div>
                                        <div class="absolute top-40 right-1/4">
                                            <div class="bg-electric-purple rounded-full p-3 shadow-lg">
                                                <i class="pi pi-users text-white text-xl"></i>
                                            </div>
                                        </div>
                                        <div class="absolute top-60 left-1/3">
                                            <div class="bg-electric-purple rounded-full p-3 shadow-lg">
                                                <i class="pi pi-calendar text-white text-xl"></i>
                                            </div>
                                        </div>
                                        <div class="absolute bottom-40 left-1/4">
                                            <div class="bg-electric-purple rounded-full p-3 shadow-lg">
                                                <i class="pi pi-suitcase text-white text-xl"></i>
                                            </div>
                                        </div>
                                        <div class="absolute bottom-60 right-1/3">
                                            <div class="bg-electric-purple rounded-full p-3 shadow-lg">
                                                <i class="pi pi-music text-white text-xl"></i>
                                            </div>
                                        </div>

                                        <!-- Labels -->
                                        <div class="absolute top-8 right-8">
                                            <span class="bg-electric-purple text-white px-3 py-1 rounded-full text-xs font-semibold shadow-md">
                                                {{ t('landing.community') }}
                                            </span>
                                        </div>
                                        <div class="absolute top-32 right-12">
                                            <span class="bg-electric-purple text-white px-3 py-1 rounded-full text-xs font-semibold shadow-md">
                                                {{ t('landing.friends') }}
                                            </span>
                                        </div>
                                        <div class="absolute bottom-32 right-8">
                                            <span class="bg-electric-purple text-white px-3 py-1 rounded-full text-xs font-semibold shadow-md">
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

            <!-- How It Works Section -->
            <section id="how-it-works" class="py-24 scroll-mt-20">
                <div class="container mx-auto px-6">
                    <div class="text-center mb-16">
                        <h2 class="text-4xl lg:text-5xl font-bold text-dark-charcoal mb-4">
                            {{ t('landing.navHowItWorks') }}
                        </h2>
                        <p class="text-xl text-gray-600 max-w-2xl mx-auto">
                            Yerel topluluğunuzla buluşmanın kolay yolu
                        </p>
                    </div>

                    <div class="grid md:grid-cols-3 gap-8">
                        <div class="bg-white rounded-2xl p-8 shadow-lg hover:shadow-xl transition-shadow">
                            <div class="w-16 h-16 bg-gradient-to-br from-electric-purple to-[#5200CC] rounded-xl flex items-center justify-center mb-6">
                                <i class="pi pi-user-plus text-white text-2xl"></i>
                            </div>
                            <h3 class="text-2xl font-bold text-dark-charcoal mb-4">1. Hesap Oluştur</h3>
                            <p class="text-gray-600 leading-relaxed">
                                İlgi alanlarınızı ve amaçlarınızı belirleyerek profilinizi oluşturun. Benzer düşünen insanlarla eşleşin.
                            </p>
                        </div>

                        <div class="bg-white rounded-2xl p-8 shadow-lg hover:shadow-xl transition-shadow">
                            <div class="w-16 h-16 bg-gradient-to-br from-electric-purple to-[#5200CC] rounded-xl flex items-center justify-center mb-6">
                                <i class="pi pi-map-marker text-white text-2xl"></i>
                            </div>
                            <h3 class="text-2xl font-bold text-dark-charcoal mb-4">2. Etkinlikleri Keşfet</h3>
                            <p class="text-gray-600 leading-relaxed">
                                Haritada yakınınızdaki etkinlikleri görüntüleyin. Kategorilere göre filtreleyerek ilginizi çeken buluşmaları bulun.
                            </p>
                        </div>

                        <div class="bg-white rounded-2xl p-8 shadow-lg hover:shadow-xl transition-shadow">
                            <div class="w-16 h-16 bg-gradient-to-br from-electric-purple to-[#5200CC] rounded-xl flex items-center justify-center mb-6">
                                <i class="pi pi-comments text-white text-2xl"></i>
                            </div>
                            <h3 class="text-2xl font-bold text-dark-charcoal mb-4">3. Bağlan ve Buluş</h3>
                            <p class="text-gray-600 leading-relaxed">
                                Etkinliklere katılın, sohbet edin ve yeni insanlarla tanışın. Kendi etkinliğinizi de oluşturabilirsiniz.
                            </p>
                        </div>
                    </div>
                </div>
            </section>

            <!-- Features Section -->
            <section id="features" class="py-24 bg-white scroll-mt-20">
                <div class="container mx-auto px-6">
                    <div class="text-center mb-16">
                        <h2 class="text-4xl lg:text-5xl font-bold text-dark-charcoal mb-4">
                            {{ t('landing.navFeatures') }}
                        </h2>
                        <p class="text-xl text-gray-600 max-w-2xl mx-auto">
                            Topluluğunuzla bağlantı kurmanızı kolaylaştıran özellikler
                        </p>
                    </div>

                    <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
                        <div class="flex flex-col items-start">
                            <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center mb-4">
                                <i class="pi pi-map text-electric-purple text-xl"></i>
                            </div>
                            <h3 class="text-xl font-bold text-dark-charcoal mb-2">Harita Tabanlı Keşif</h3>
                            <p class="text-gray-600">Yakınınızdaki etkinlikleri görsel harita üzerinde görüntüleyin</p>
                        </div>

                        <div class="flex flex-col items-start">
                            <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center mb-4">
                                <i class="pi pi-users text-electric-purple text-xl"></i>
                            </div>
                            <h3 class="text-xl font-bold text-dark-charcoal mb-2">İlgi Alanı Eşleştirme</h3>
                            <p class="text-gray-600">Benzer ilgi alanlarına sahip insanlarla otomatik eşleşin</p>
                        </div>

                        <div class="flex flex-col items-start">
                            <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center mb-4">
                                <i class="pi pi-comments text-electric-purple text-xl"></i>
                            </div>
                            <h3 class="text-xl font-bold text-dark-charcoal mb-2">Gerçek Zamanlı Sohbet</h3>
                            <p class="text-gray-600">Etkinlik katılımcılarıyla anında mesajlaşın</p>
                        </div>

                        <div class="flex flex-col items-start">
                            <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center mb-4">
                                <i class="pi pi-calendar-plus text-electric-purple text-xl"></i>
                            </div>
                            <h3 class="text-xl font-bold text-dark-charcoal mb-2">Etkinlik Oluşturma</h3>
                            <p class="text-gray-600">Kendi etkinliklerinizi oluşturun ve topluluğunuzu davet edin</p>
                        </div>

                        <div class="flex flex-col items-start">
                            <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center mb-4">
                                <i class="pi pi-tags text-electric-purple text-xl"></i>
                            </div>
                            <h3 class="text-xl font-bold text-dark-charcoal mb-2">Kategori ve Konular</h3>
                            <p class="text-gray-600">Etkinlikleri kategorilere ve konulara göre organize edin</p>
                        </div>

                        <div class="flex flex-col items-start">
                            <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center mb-4">
                                <i class="pi pi-shield text-electric-purple text-xl"></i>
                            </div>
                            <h3 class="text-xl font-bold text-dark-charcoal mb-2">Güvenli Platform</h3>
                            <p class="text-gray-600">Güvenli ve moderasyonlu bir ortamda sosyalleşin</p>
                        </div>
                    </div>
                </div>
            </section>

            <!-- Who It's For Section -->
            <section id="who-its-for" class="py-24 scroll-mt-20">
                <div class="container mx-auto px-6">
                    <div class="text-center mb-16">
                        <h2 class="text-4xl lg:text-5xl font-bold text-dark-charcoal mb-4">
                            {{ t('landing.navWhoItsFor') }}
                        </h2>
                        <p class="text-xl text-gray-600 max-w-2xl mx-auto">
                            Herkes için tasarlandı
                        </p>
                    </div>

                    <div class="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto">
                        <div class="bg-white rounded-2xl p-8 shadow-lg">
                            <div class="flex items-center gap-4 mb-4">
                                <div class="w-12 h-12 bg-gradient-to-br from-electric-purple to-[#5200CC] rounded-full flex items-center justify-center">
                                    <i class="pi pi-users text-white text-xl"></i>
                                </div>
                                <h3 class="text-2xl font-bold text-dark-charcoal">Yeni Şehre Taşınanlar</h3>
                            </div>
                            <p class="text-gray-600 leading-relaxed">
                                Yeni bir şehre taşındınız ve insanlarla tanışmak mı istiyorsunuz? Yerel topluluğunuzla bağlantı kurun ve yeni arkadaşlıklar edinin.
                            </p>
                        </div>

                        <div class="bg-white rounded-2xl p-8 shadow-lg">
                            <div class="flex items-center gap-4 mb-4">
                                <div class="w-12 h-12 bg-gradient-to-br from-electric-purple to-[#5200CC] rounded-full flex items-center justify-center">
                                    <i class="pi pi-briefcase text-white text-xl"></i>
                                </div>
                                <h3 class="text-2xl font-bold text-dark-charcoal">Profesyonel Ağ Kurmak İsteyenler</h3>
                            </div>
                            <p class="text-gray-600 leading-relaxed">
                                İş dünyasında yeni bağlantılar kurmak ve network'ünüzü genişletmek için profesyonel etkinliklere katılın.
                            </p>
                        </div>

                        <div class="bg-white rounded-2xl p-8 shadow-lg">
                            <div class="flex items-center gap-4 mb-4">
                                <div class="w-12 h-12 bg-gradient-to-br from-electric-purple to-[#5200CC] rounded-full flex items-center justify-center">
                                    <i class="pi pi-heart text-white text-xl"></i>
                                </div>
                                <h3 class="text-2xl font-bold text-dark-charcoal">Sosyalleşmek İsteyenler</h3>
                            </div>
                            <p class="text-gray-600 leading-relaxed">
                                Hobilerinizi paylaşan insanlarla buluşun. Spor, müzik, sanat veya başka bir ilgi alanınız olsun, benzer düşünen insanları bulun.
                            </p>
                        </div>

                        <div class="bg-white rounded-2xl p-8 shadow-lg">
                            <div class="flex items-center gap-4 mb-4">
                                <div class="w-12 h-12 bg-gradient-to-br from-electric-purple to-[#5200CC] rounded-full flex items-center justify-center">
                                    <i class="pi pi-compass text-white text-xl"></i>
                                </div>
                                <h3 class="text-2xl font-bold text-dark-charcoal">Yeni Deneyimler Arayanlar</h3>
                            </div>
                            <p class="text-gray-600 leading-relaxed">
                                Yeni aktiviteler keşfetmek ve farklı ilgi alanlarını denemek isteyenler için mükemmel bir platform.
                            </p>
                        </div>
                    </div>
                </div>
            </section>

            <!-- Safety Section -->
            <section id="safety" class="py-24 bg-white scroll-mt-20">
                <div class="container mx-auto px-6">
                    <div class="text-center mb-16">
                        <h2 class="text-4xl lg:text-5xl font-bold text-dark-charcoal mb-4">
                            {{ t('landing.navSafety') }}
                        </h2>
                        <p class="text-xl text-gray-600 max-w-2xl mx-auto">
                            Güvenliğiniz bizim önceliğimiz
                        </p>
                    </div>

                    <div class="max-w-4xl mx-auto">
                        <div class="grid md:grid-cols-2 gap-8 mb-12">
                            <div class="flex gap-4">
                                <div class="flex-shrink-0">
                                    <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
                                        <i class="pi pi-check-circle text-green-600 text-xl"></i>
                                    </div>
                                </div>
                                <div>
                                    <h3 class="text-xl font-bold text-dark-charcoal mb-2">Doğrulanmış Hesaplar</h3>
                                    <p class="text-gray-600">Tüm kullanıcılarımızın kimlikleri doğrulanır ve güvenli bir ortam sağlanır.</p>
                                </div>
                            </div>

                            <div class="flex gap-4">
                                <div class="flex-shrink-0">
                                    <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
                                        <i class="pi pi-shield text-green-600 text-xl"></i>
                                    </div>
                                </div>
                                <div>
                                    <h3 class="text-xl font-bold text-dark-charcoal mb-2">Moderasyon</h3>
                                    <p class="text-gray-600">Tüm etkinlikler ve sohbetler aktif olarak moderatörler tarafından izlenir.</p>
                                </div>
                            </div>

                            <div class="flex gap-4">
                                <div class="flex-shrink-0">
                                    <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
                                        <i class="pi pi-ban text-green-600 text-xl"></i>
                                    </div>
                                </div>
                                <div>
                                    <h3 class="text-xl font-bold text-dark-charcoal mb-2">Raporlama Sistemi</h3>
                                    <p class="text-gray-600">Uygunsuz davranışları kolayca raporlayabilirsiniz. Hızlı müdahale garantisi.</p>
                                </div>
                            </div>

                            <div class="flex gap-4">
                                <div class="flex-shrink-0">
                                    <div class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
                                        <i class="pi pi-lock text-green-600 text-xl"></i>
                                    </div>
                                </div>
                                <div>
                                    <h3 class="text-xl font-bold text-dark-charcoal mb-2">Gizlilik</h3>
                                    <p class="text-gray-600">Kişisel bilgileriniz güvende. Verileriniz şifrelenir ve korunur.</p>
                                </div>
                            </div>
                        </div>

                        <div class="bg-purple-50 rounded-2xl p-8 border-2 border-electric-purple/20">
                            <div class="flex items-start gap-4">
                                <i class="pi pi-info-circle text-electric-purple text-2xl mt-1"></i>
                                <div>
                                    <h3 class="text-xl font-bold text-dark-charcoal mb-2">Güvenli Buluşma İpuçları</h3>
                                    <ul class="text-gray-600 space-y-2">
                                        <li>• İlk buluşmalarınızı her zaman halka açık yerlerde yapın</li>
                                        <li>• Bir arkadaşınıza nerede olduğunuzu bildirin</li>
                                        <li>• Kendi ulaşımınızı kullanın</li>
                                        <li>• Rahatsız hissettiğinizde buluşmayı sonlandırın</li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <!-- Stories Section -->
            <section id="stories" class="py-24 scroll-mt-20">
                <div class="container mx-auto px-6">
                    <div class="text-center mb-16">
                        <h2 class="text-4xl lg:text-5xl font-bold text-dark-charcoal mb-4">
                            {{ t('landing.navStories') }}
                        </h2>
                        <p class="text-xl text-gray-600 max-w-2xl mx-auto">
                            Topluluğumuzdan gerçek hikayeler
                        </p>
                    </div>

                    <div class="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
                        <div class="bg-white rounded-2xl p-8 shadow-lg hover:shadow-xl transition-shadow">
                            <div class="flex items-center gap-3 mb-4">
                                <div class="w-12 h-12 bg-gradient-to-br from-electric-purple to-[#5200CC] rounded-full flex items-center justify-center text-white font-bold text-lg">
                                    A
                                </div>
                                <div>
                                    <h4 class="font-bold text-dark-charcoal">Ayşe</h4>
                                    <p class="text-sm text-gray-500">İstanbul</p>
                                </div>
                            </div>
                            <p class="text-gray-600 italic leading-relaxed mb-4">
                                "Yeni şehre taşındığımda kimseyi tanımıyordum. Bu platform sayesinde müzik sever bir grup buldum ve artık haftalık jam session'larımız var!"
                            </p>
                            <div class="flex gap-1 text-electric-purple">
                                <i class="pi pi-star-fill"></i>
                                <i class="pi pi-star-fill"></i>
                                <i class="pi pi-star-fill"></i>
                                <i class="pi pi-star-fill"></i>
                                <i class="pi pi-star-fill"></i>
                            </div>
                        </div>

                        <div class="bg-white rounded-2xl p-8 shadow-lg hover:shadow-xl transition-shadow">
                            <div class="flex items-center gap-3 mb-4">
                                <div class="w-12 h-12 bg-gradient-to-br from-electric-purple to-[#5200CC] rounded-full flex items-center justify-center text-white font-bold text-lg">
                                    M
                                </div>
                                <div>
                                    <h4 class="font-bold text-dark-charcoal">Mehmet</h4>
                                    <p class="text-sm text-gray-500">Ankara</p>
                                </div>
                            </div>
                            <p class="text-gray-600 italic leading-relaxed mb-4">
                                "İş hayatımda network kurmak istiyordum. Profesyonel etkinlikler sayesinde birçok değerli bağlantı edindim ve kariyerimde önemli adımlar attım."
                            </p>
                            <div class="flex gap-1 text-electric-purple">
                                <i class="pi pi-star-fill"></i>
                                <i class="pi pi-star-fill"></i>
                                <i class="pi pi-star-fill"></i>
                                <i class="pi pi-star-fill"></i>
                                <i class="pi pi-star-fill"></i>
                            </div>
                        </div>

                        <div class="bg-white rounded-2xl p-8 shadow-lg hover:shadow-xl transition-shadow">
                            <div class="flex items-center gap-3 mb-4">
                                <div class="w-12 h-12 bg-gradient-to-br from-electric-purple to-[#5200CC] rounded-full flex items-center justify-center text-white font-bold text-lg">
                                    Z
                                </div>
                                <div>
                                    <h4 class="font-bold text-dark-charcoal">Zeynep</h4>
                                    <p class="text-sm text-gray-500">İzmir</p>
                                </div>
                            </div>
                            <p class="text-gray-600 italic leading-relaxed mb-4">
                                "Yoga yapmayı çok seviyorum ama tek başıma yapmak sıkıcıydı. Artık haftada birkaç kez yoga grubumla buluşuyoruz ve harika vakit geçiriyoruz!"
                            </p>
                            <div class="flex gap-1 text-electric-purple">
                                <i class="pi pi-star-fill"></i>
                                <i class="pi pi-star-fill"></i>
                                <i class="pi pi-star-fill"></i>
                                <i class="pi pi-star-fill"></i>
                                <i class="pi pi-star-fill"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <!-- Final CTA Section -->
            <section class="py-24 bg-gradient-to-br from-electric-purple to-[#5200CC] text-white">
                <div class="container mx-auto px-6 text-center">
                    <h2 class="text-4xl lg:text-5xl font-bold mb-6">Hemen Başlayın</h2>
                    <p class="text-xl mb-8 text-purple-100 max-w-2xl mx-auto">
                        Topluluğunuzla buluşmanın kolay yolunu keşfedin. Bugün ücretsiz hesap oluşturun.
                    </p>
                    <Button 
                        @click="goToLogin" 
                        :label="t('landing.getStarted')" 
                        icon="pi pi-arrow-right" 
                        iconPos="right"
                        class="!bg-white !text-electric-purple hover:!bg-gray-100 !px-8 !py-3 !rounded-full !text-lg !font-semibold !shadow-lg hover:!shadow-xl"
                    />
                </div>
            </section>
        </main>
    </div>
</template>

<style scoped>
.landing-page {
    background: linear-gradient(135deg, #f3f0ff 0%, #e8e0ff 50%, #ddd0ff 100%);
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
