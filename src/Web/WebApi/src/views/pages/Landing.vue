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
        <header class="fixed top-0 left-0 right-0 z-50 header-nav">
            <nav class="container mx-auto px-6 py-5 flex items-center justify-between">
                <!-- Logo -->
                <div class="flex items-center gap-3 logo-container group cursor-pointer" @click="window.scrollTo({ top: 0, behavior: 'smooth' })">
                    <div class="logo-icon-wrapper">
                        <i class="pi pi-map-marker text-2xl text-electric-purple"></i>
                    </div>
                    <span class="text-xl font-bold text-dark-charcoal logo-text">{{ t('landing.logo') }}</span>
                </div>

                <!-- Navigation Links -->
                <div class="hidden md:flex items-center gap-8">
                    <a @click.prevent="scrollToSection('how-it-works')" href="#how-it-works" class="nav-link">{{ t('landing.navHowItWorks') }}</a>
                    <a @click.prevent="scrollToSection('features')" href="#features" class="nav-link">{{ t('landing.navFeatures') }}</a>
                    <a @click.prevent="scrollToSection('who-its-for')" href="#who-its-for" class="nav-link">{{ t('landing.navWhoItsFor') }}</a>
                    <a @click.prevent="scrollToSection('safety')" href="#safety" class="nav-link">{{ t('landing.navSafety') }}</a>
                    <a @click.prevent="scrollToSection('stories')" href="#stories" class="nav-link">{{ t('landing.navStories') }}</a>
                </div>

                <!-- Header Actions -->
                <div class="flex items-center gap-4">
                    <Button 
                        @click="goToLogin" 
                        :label="t('landing.navGetStarted')" 
                        severity="warning"
                        class="cta-button"
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
                        <div class="relative w-full max-w-md phone-mockup-container">
                            <!-- Floating Elements Background -->
                            <div class="absolute -top-10 -right-10 w-32 h-32 bg-electric-purple/20 rounded-full blur-3xl animate-pulse"></div>
                            <div class="absolute -bottom-10 -left-10 w-40 h-40 bg-electric-purple/10 rounded-full blur-3xl animate-pulse" style="animation-delay: 1s;"></div>
                            
                            <!-- Phone Frame -->
                            <div class="relative phone-frame">
                                <!-- Notch -->
                                <div class="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-6 bg-dark-charcoal rounded-b-2xl z-10"></div>
                                
                                <div class="bg-white rounded-[2.5rem] overflow-hidden relative">
                                    <!-- Status Bar -->
                                    <div class="absolute top-0 left-0 right-0 h-12 bg-gradient-to-b from-white to-transparent z-20 flex items-center justify-between px-6 pt-2">
                                        <span class="text-xs font-semibold text-dark-charcoal">9:41</span>
                                        <div class="flex gap-1">
                                            <div class="w-1 h-1 bg-dark-charcoal rounded-full"></div>
                                            <div class="w-1 h-1 bg-dark-charcoal rounded-full"></div>
                                            <div class="w-1 h-1 bg-dark-charcoal rounded-full"></div>
                                        </div>
                                    </div>

                                    <!-- Phone Screen Content -->
                                    <div class="relative h-[600px] bg-gradient-to-br from-purple-50 via-white to-purple-50 phone-screen">
                                        <!-- Animated Background Pattern -->
                                        <div class="absolute inset-0 opacity-5">
                                            <div class="absolute top-0 left-0 w-full h-full" style="background-image: radial-gradient(circle at 2px 2px, #6300FF 1px, transparent 0); background-size: 40px 40px;"></div>
                                        </div>

                                        <!-- Top Navigation Pills -->
                                        <div class="absolute top-16 left-4 right-4 flex gap-2 z-10">
                                            <div class="nav-pill active">
                                                <i class="pi pi-users text-xs"></i>
                                                <span class="text-xs font-semibold">{{ t('landing.community') }}</span>
                                            </div>
                                            <div class="nav-pill">
                                                <i class="pi pi-heart text-xs"></i>
                                                <span class="text-xs font-semibold">{{ t('landing.friends') }}</span>
                                            </div>
                                            <div class="nav-pill">
                                                <i class="pi pi-calendar text-xs"></i>
                                                <span class="text-xs font-semibold">{{ t('landing.events') }}</span>
                                            </div>
                                        </div>

                                        <!-- Floating Cards -->
                                        <div class="absolute top-32 left-6 right-6 space-y-3">
                                            <!-- Card 1 -->
                                            <div class="floating-card card-1">
                                                <div class="flex items-center gap-3">
                                                    <div class="w-12 h-12 bg-gradient-to-br from-electric-purple to-[#5200CC] rounded-xl flex items-center justify-center shadow-lg">
                                                        <i class="pi pi-coffee text-white text-lg"></i>
                                                    </div>
                                                    <div class="flex-1">
                                                        <h4 class="font-bold text-dark-charcoal text-sm">Kahve Buluşması</h4>
                                                        <p class="text-xs text-gray-500">2 km uzaklıkta</p>
                                                    </div>
                                                    <div class="w-8 h-8 bg-electric-purple/10 rounded-full flex items-center justify-center">
                                                        <i class="pi pi-chevron-right text-electric-purple text-xs"></i>
                                                    </div>
                                                </div>
                                            </div>

                                            <!-- Card 2 -->
                                            <div class="floating-card card-2">
                                                <div class="flex items-center gap-3">
                                                    <div class="w-12 h-12 bg-gradient-to-br from-electric-purple to-[#5200CC] rounded-xl flex items-center justify-center shadow-lg">
                                                        <i class="pi pi-users text-white text-lg"></i>
                                                    </div>
                                                    <div class="flex-1">
                                                        <h4 class="font-bold text-dark-charcoal text-sm">Yoga Grubu</h4>
                                                        <p class="text-xs text-gray-500">5 katılımcı</p>
                                                    </div>
                                                    <div class="w-8 h-8 bg-electric-purple/10 rounded-full flex items-center justify-center">
                                                        <i class="pi pi-chevron-right text-electric-purple text-xs"></i>
                                                    </div>
                                                </div>
                                            </div>

                                            <!-- Card 3 -->
                                            <div class="floating-card card-3">
                                                <div class="flex items-center gap-3">
                                                    <div class="w-12 h-12 bg-gradient-to-br from-electric-purple to-[#5200CC] rounded-xl flex items-center justify-center shadow-lg">
                                                        <i class="pi pi-music text-white text-lg"></i>
                                                    </div>
                                                    <div class="flex-1">
                                                        <h4 class="font-bold text-dark-charcoal text-sm">Müzik Gecesi</h4>
                                                        <p class="text-xs text-gray-500">Yarın 20:00</p>
                                                    </div>
                                                    <div class="w-8 h-8 bg-electric-purple/10 rounded-full flex items-center justify-center">
                                                        <i class="pi pi-chevron-right text-electric-purple text-xs"></i>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- Bottom Floating Action Button -->
                                        <div class="absolute bottom-8 left-1/2 -translate-x-1/2 z-10">
                                            <div class="floating-action-btn">
                                                <i class="pi pi-plus text-white text-xl"></i>
                                            </div>
                                        </div>

                                        <!-- Decorative Elements -->
                                        <div class="absolute top-1/2 left-4 w-2 h-2 bg-electric-purple rounded-full animate-ping" style="animation-delay: 0.5s;"></div>
                                        <div class="absolute top-1/3 right-8 w-3 h-3 bg-electric-purple/30 rounded-full animate-pulse" style="animation-delay: 1s;"></div>
                                        <div class="absolute bottom-1/3 left-8 w-2 h-2 bg-electric-purple/50 rounded-full animate-pulse" style="animation-delay: 1.5s;"></div>
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
                        <div class="feature-card">
                            <div class="feature-icon-wrapper">
                                <div class="feature-icon-bg">
                                    <i class="pi pi-user-plus text-white text-2xl"></i>
                                </div>
                                <span class="feature-number">1</span>
                            </div>
                            <h3 class="text-2xl font-bold text-dark-charcoal mb-4">Hesap Oluştur</h3>
                            <p class="text-gray-600 leading-relaxed">
                                İlgi alanlarınızı ve amaçlarınızı belirleyerek profilinizi oluşturun. Benzer düşünen insanlarla eşleşin.
                            </p>
                        </div>

                        <div class="feature-card">
                            <div class="feature-icon-wrapper">
                                <div class="feature-icon-bg">
                                    <i class="pi pi-map-marker text-white text-2xl"></i>
                                </div>
                                <span class="feature-number">2</span>
                            </div>
                            <h3 class="text-2xl font-bold text-dark-charcoal mb-4">Etkinlikleri Keşfet</h3>
                            <p class="text-gray-600 leading-relaxed">
                                Haritada yakınınızdaki etkinlikleri görüntüleyin. Kategorilere göre filtreleyerek ilginizi çeken buluşmaları bulun.
                            </p>
                        </div>

                        <div class="feature-card">
                            <div class="feature-icon-wrapper">
                                <div class="feature-icon-bg">
                                    <i class="pi pi-comments text-white text-2xl"></i>
                                </div>
                                <span class="feature-number">3</span>
                            </div>
                            <h3 class="text-2xl font-bold text-dark-charcoal mb-4">Bağlan ve Buluş</h3>
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

                    <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
                        <div class="feature-item-card">
                            <div class="feature-item-icon">
                                <i class="pi pi-map text-electric-purple text-xl"></i>
                            </div>
                            <h3 class="text-xl font-bold text-dark-charcoal mb-2">Harita Tabanlı Keşif</h3>
                            <p class="text-gray-600">Yakınınızdaki etkinlikleri görsel harita üzerinde görüntüleyin</p>
                        </div>

                        <div class="feature-item-card">
                            <div class="feature-item-icon">
                                <i class="pi pi-users text-electric-purple text-xl"></i>
                            </div>
                            <h3 class="text-xl font-bold text-dark-charcoal mb-2">İlgi Alanı Eşleştirme</h3>
                            <p class="text-gray-600">Benzer ilgi alanlarına sahip insanlarla otomatik eşleşin</p>
                        </div>

                        <div class="feature-item-card">
                            <div class="feature-item-icon">
                                <i class="pi pi-comments text-electric-purple text-xl"></i>
                            </div>
                            <h3 class="text-xl font-bold text-dark-charcoal mb-2">Gerçek Zamanlı Sohbet</h3>
                            <p class="text-gray-600">Etkinlik katılımcılarıyla anında mesajlaşın</p>
                        </div>

                        <div class="feature-item-card">
                            <div class="feature-item-icon">
                                <i class="pi pi-calendar-plus text-electric-purple text-xl"></i>
                            </div>
                            <h3 class="text-xl font-bold text-dark-charcoal mb-2">Etkinlik Oluşturma</h3>
                            <p class="text-gray-600">Kendi etkinliklerinizi oluşturun ve topluluğunuzu davet edin</p>
                        </div>

                        <div class="feature-item-card">
                            <div class="feature-item-icon">
                                <i class="pi pi-tags text-electric-purple text-xl"></i>
                            </div>
                            <h3 class="text-xl font-bold text-dark-charcoal mb-2">Kategori ve Konular</h3>
                            <p class="text-gray-600">Etkinlikleri kategorilere ve konulara göre organize edin</p>
                        </div>

                        <div class="feature-item-card">
                            <div class="feature-item-icon">
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

                    <div class="grid md:grid-cols-2 gap-6 max-w-4xl mx-auto">
                        <div class="target-card">
                            <div class="flex items-center gap-4 mb-4">
                                <div class="target-icon-wrapper">
                                    <i class="pi pi-users text-white text-xl"></i>
                                </div>
                                <h3 class="text-2xl font-bold text-dark-charcoal">Yeni Şehre Taşınanlar</h3>
                            </div>
                            <p class="text-gray-600 leading-relaxed">
                                Yeni bir şehre taşındınız ve insanlarla tanışmak mı istiyorsunuz? Yerel topluluğunuzla bağlantı kurun ve yeni arkadaşlıklar edinin.
                            </p>
                        </div>

                        <div class="target-card">
                            <div class="flex items-center gap-4 mb-4">
                                <div class="target-icon-wrapper">
                                    <i class="pi pi-briefcase text-white text-xl"></i>
                                </div>
                                <h3 class="text-2xl font-bold text-dark-charcoal">Profesyonel Ağ Kurmak İsteyenler</h3>
                            </div>
                            <p class="text-gray-600 leading-relaxed">
                                İş dünyasında yeni bağlantılar kurmak ve network'ünüzü genişletmek için profesyonel etkinliklere katılın.
                            </p>
                        </div>

                        <div class="target-card">
                            <div class="flex items-center gap-4 mb-4">
                                <div class="target-icon-wrapper">
                                    <i class="pi pi-heart text-white text-xl"></i>
                                </div>
                                <h3 class="text-2xl font-bold text-dark-charcoal">Sosyalleşmek İsteyenler</h3>
                            </div>
                            <p class="text-gray-600 leading-relaxed">
                                Hobilerinizi paylaşan insanlarla buluşun. Spor, müzik, sanat veya başka bir ilgi alanınız olsun, benzer düşünen insanları bulun.
                            </p>
                        </div>

                        <div class="target-card">
                            <div class="flex items-center gap-4 mb-4">
                                <div class="target-icon-wrapper">
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

                    <div class="grid md:grid-cols-3 gap-6 max-w-6xl mx-auto">
                        <div class="story-card">
                            <div class="flex items-center gap-3 mb-4">
                                <div class="story-avatar">
                                    <span class="text-white font-bold text-lg">A</span>
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

                        <div class="story-card">
                            <div class="flex items-center gap-3 mb-4">
                                <div class="story-avatar">
                                    <span class="text-white font-bold text-lg">M</span>
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

                        <div class="story-card">
                            <div class="flex items-center gap-3 mb-4">
                                <div class="story-avatar">
                                    <span class="text-white font-bold text-lg">Z</span>
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

/* Header Styles */
.header-nav {
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(20px) saturate(180%);
    -webkit-backdrop-filter: blur(20px) saturate(180%);
    border-bottom: 1px solid rgba(99, 0, 255, 0.1);
    box-shadow: 0 4px 20px rgba(99, 0, 255, 0.08);
    transition: all 0.3s ease;
}

.logo-container {
    transition: transform 0.3s ease;
}

.logo-container:hover {
    transform: translateY(-2px);
}

.logo-icon-wrapper {
    transition: transform 0.3s ease;
}

.logo-container:hover .logo-icon-wrapper {
    transform: scale(1.1) rotate(-5deg);
}

.logo-text {
    background: linear-gradient(135deg, #1A1A1D 0%, #6300FF 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    transition: all 0.3s ease;
}

.nav-link {
    position: relative;
    color: #4b5563;
    font-weight: 500;
    transition: all 0.3s ease;
    padding: 0.5rem 0;
}

.nav-link::after {
    content: '';
    position: absolute;
    bottom: 0;
    left: 0;
    width: 0;
    height: 2px;
    background: linear-gradient(90deg, #6300FF, #5200CC);
    transition: width 0.3s ease;
}

.nav-link:hover {
    color: #6300FF;
}

.nav-link:hover::after {
    width: 100%;
}

.login-btn {
    color: #1A1A1D;
    font-weight: 600;
    padding: 0.5rem 1rem;
    border-radius: 0.5rem;
    transition: all 0.3s ease;
}

.login-btn:hover {
    color: #6300FF;
    background: rgba(99, 0, 255, 0.05);
}

.cta-button {
    background: linear-gradient(135deg, #6300FF 0%, #5200CC 100%) !important;
    border: none !important;
    color: white !important;
    padding: 0.75rem 1.5rem !important;
    border-radius: 9999px !important;
    font-weight: 600 !important;
    box-shadow: 0 4px 15px rgba(99, 0, 255, 0.3) !important;
    transition: all 0.3s ease !important;
}

.cta-button:hover {
    transform: translateY(-2px) !important;
    box-shadow: 0 6px 25px rgba(99, 0, 255, 0.4) !important;
    background: linear-gradient(135deg, #5200CC 0%, #4100AA 100%) !important;
}

/* Feature Cards (How It Works) */
.feature-card {
    background: white;
    border-radius: 1.5rem;
    padding: 2rem;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
    border: 1px solid rgba(99, 0, 255, 0.1);
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
    overflow: hidden;
}

.feature-card::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, #6300FF, #5200CC);
    transform: scaleX(0);
    transition: transform 0.4s ease;
}

.feature-card:hover::before {
    transform: scaleX(1);
}

.feature-card:hover {
    transform: translateY(-8px);
    box-shadow: 0 12px 40px rgba(99, 0, 255, 0.15);
    border-color: rgba(99, 0, 255, 0.3);
}

.feature-icon-wrapper {
    position: relative;
    margin-bottom: 1.5rem;
}

.feature-icon-bg {
    width: 4rem;
    height: 4rem;
    background: linear-gradient(135deg, #6300FF 0%, #5200CC 100%);
    border-radius: 1rem;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 8px 20px rgba(99, 0, 255, 0.3);
    transition: all 0.4s ease;
}

.feature-card:hover .feature-icon-bg {
    transform: scale(1.1) rotate(5deg);
    box-shadow: 0 12px 30px rgba(99, 0, 255, 0.4);
}

.feature-number {
    position: absolute;
    top: -0.5rem;
    right: -0.5rem;
    width: 2rem;
    height: 2rem;
    background: linear-gradient(135deg, #6300FF, #5200CC);
    color: white;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: bold;
    font-size: 0.875rem;
    box-shadow: 0 4px 12px rgba(99, 0, 255, 0.4);
}

/* Feature Item Cards */
.feature-item-card {
    background: white;
    border-radius: 1rem;
    padding: 1.5rem;
    border: 2px solid transparent;
    transition: all 0.3s ease;
    cursor: pointer;
}

.feature-item-card:hover {
    border-color: rgba(99, 0, 255, 0.2);
    box-shadow: 0 8px 25px rgba(99, 0, 255, 0.1);
    transform: translateY(-4px);
}

.feature-item-icon {
    width: 3rem;
    height: 3rem;
    background: linear-gradient(135deg, rgba(99, 0, 255, 0.1), rgba(82, 0, 204, 0.1));
    border-radius: 0.75rem;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 1rem;
    transition: all 0.3s ease;
}

.feature-item-card:hover .feature-item-icon {
    background: linear-gradient(135deg, rgba(99, 0, 255, 0.2), rgba(82, 0, 204, 0.2));
    transform: scale(1.1);
}

/* Target Cards (Who It's For) */
.target-card {
    background: white;
    border-radius: 1.5rem;
    padding: 2rem;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
    border: 1px solid rgba(99, 0, 255, 0.1);
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
    overflow: hidden;
}

.target-card::after {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: linear-gradient(135deg, rgba(99, 0, 255, 0.03), rgba(82, 0, 204, 0.03));
    opacity: 0;
    transition: opacity 0.4s ease;
}

.target-card:hover::after {
    opacity: 1;
}

.target-card:hover {
    transform: translateY(-6px);
    box-shadow: 0 12px 40px rgba(99, 0, 255, 0.15);
    border-color: rgba(99, 0, 255, 0.3);
}

.target-icon-wrapper {
    width: 3rem;
    height: 3rem;
    background: linear-gradient(135deg, #6300FF 0%, #5200CC 100%);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 6px 20px rgba(99, 0, 255, 0.3);
    transition: all 0.4s ease;
    position: relative;
    z-index: 1;
}

.target-card:hover .target-icon-wrapper {
    transform: scale(1.15) rotate(5deg);
    box-shadow: 0 10px 30px rgba(99, 0, 255, 0.4);
}

/* Story Cards */
.story-card {
    background: white;
    border-radius: 1.5rem;
    padding: 2rem;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
    border: 2px solid rgba(99, 0, 255, 0.1);
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
}

.story-card:hover {
    transform: translateY(-8px);
    box-shadow: 0 16px 50px rgba(99, 0, 255, 0.2);
    border-color: rgba(99, 0, 255, 0.4);
    background: linear-gradient(white, rgba(99, 0, 255, 0.02));
}

.story-avatar {
    width: 3rem;
    height: 3rem;
    background: linear-gradient(135deg, #6300FF 0%, #5200CC 100%);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 6px 20px rgba(99, 0, 255, 0.3);
    transition: all 0.4s ease;
}

.story-card:hover .story-avatar {
    transform: scale(1.1);
    box-shadow: 0 10px 30px rgba(99, 0, 255, 0.4);
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

/* Phone Mockup Styles */
.phone-mockup-container {
    perspective: 1000px;
}

.phone-frame {
    background: linear-gradient(135deg, #1A1A1D 0%, #2a2a2d 100%);
    border-radius: 3rem;
    padding: 0.5rem;
    box-shadow: 
        0 20px 60px rgba(99, 0, 255, 0.2),
        0 0 0 1px rgba(99, 0, 255, 0.1),
        inset 0 0 0 1px rgba(255, 255, 255, 0.1);
    transform: rotateY(-5deg) rotateX(5deg);
    transition: all 0.6s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
}

.phone-mockup-container:hover .phone-frame {
    transform: rotateY(0deg) rotateX(0deg) scale(1.02);
    box-shadow: 
        0 30px 80px rgba(99, 0, 255, 0.3),
        0 0 0 1px rgba(99, 0, 255, 0.2),
        inset 0 0 0 1px rgba(255, 255, 255, 0.2);
}

.phone-screen {
    position: relative;
    overflow: hidden;
}

.nav-pill {
    background: rgba(255, 255, 255, 0.9);
    backdrop-filter: blur(10px);
    padding: 0.5rem 1rem;
    border-radius: 9999px;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.75rem;
    color: #6b7280;
    border: 1px solid rgba(99, 0, 255, 0.1);
    transition: all 0.3s ease;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.nav-pill.active {
    background: linear-gradient(135deg, #6300FF, #5200CC);
    color: white;
    border-color: transparent;
    box-shadow: 0 4px 12px rgba(99, 0, 255, 0.3);
    transform: scale(1.05);
}

.nav-pill:not(.active):hover {
    background: rgba(99, 0, 255, 0.1);
    color: #6300FF;
    border-color: rgba(99, 0, 255, 0.2);
}

.floating-card {
    background: white;
    border-radius: 1rem;
    padding: 1rem;
    box-shadow: 
        0 4px 20px rgba(0, 0, 0, 0.08),
        0 0 0 1px rgba(99, 0, 255, 0.05);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(99, 0, 255, 0.1);
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
    animation: float 3s ease-in-out infinite;
}

.floating-card:hover {
    transform: translateY(-4px) scale(1.02);
    box-shadow: 
        0 8px 30px rgba(99, 0, 255, 0.15),
        0 0 0 1px rgba(99, 0, 255, 0.2);
    border-color: rgba(99, 0, 255, 0.3);
}

.card-1 {
    animation-delay: 0s;
}

.card-2 {
    animation-delay: 0.3s;
}

.card-3 {
    animation-delay: 0.6s;
}

@keyframes float {
    0%, 100% {
        transform: translateY(0px);
    }
    50% {
        transform: translateY(-8px);
    }
}

.floating-action-btn {
    width: 3.5rem;
    height: 3.5rem;
    background: linear-gradient(135deg, #6300FF, #5200CC);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 
        0 8px 25px rgba(99, 0, 255, 0.4),
        0 0 0 4px rgba(99, 0, 255, 0.1);
    animation: pulse-glow 2s ease-in-out infinite;
    transition: all 0.3s ease;
    cursor: pointer;
}

.floating-action-btn:hover {
    transform: scale(1.1);
    box-shadow: 
        0 12px 35px rgba(99, 0, 255, 0.5),
        0 0 0 6px rgba(99, 0, 255, 0.15);
}

@keyframes pulse-glow {
    0%, 100% {
        box-shadow: 
            0 8px 25px rgba(99, 0, 255, 0.4),
            0 0 0 4px rgba(99, 0, 255, 0.1);
    }
    50% {
        box-shadow: 
            0 12px 35px rgba(99, 0, 255, 0.5),
            0 0 0 8px rgba(99, 0, 255, 0.2);
    }
}

/* Responsive adjustments */
@media (max-width: 768px) {
    .header-nav {
        padding: 0.75rem 0;
    }
    
    .feature-card,
    .target-card,
    .story-card {
        padding: 1.5rem;
    }
    
    .phone-frame {
        transform: rotateY(0deg) rotateX(0deg);
    }
    
    .floating-card {
        padding: 0.75rem;
    }
}
</style>
