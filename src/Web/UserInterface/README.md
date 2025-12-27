# Artemis UI

Artemis uygulamasının kullanıcı arayüzü (UI) projesi.

## Kurulum

1. Bağımlılıkları yükleyin:
```bash
cd src/Web/UI
npm install
```

2. Environment değişkenlerini ayarlayın:
`.env` dosyası oluşturuldu (eğer yoksa):
```
VITE_API_BASE_URL=http://localhost:5091
VITE_SIGNALR_HUB_URL=http://localhost:5094/hubs/chat
```

## Çalıştırma

Development modunda çalıştırmak için:
```bash
npm run dev
```

Uygulama `http://localhost:5174` adresinde çalışacaktır.

## Build

Production build için:
```bash
npm run build
```

## Proje Yapısı

```
src/
├── views/          # Sayfa component'leri
│   ├── Login.vue   # Giriş sayfası
│   ├── Register.vue # Kayıt sayfası
│   ├── Main.vue    # Ana sayfa
│   └── Chat.vue    # Chat sayfası
├── service/         # API servisleri
├── stores/         # Pinia store'ları
├── router/         # Vue Router yapılandırması
└── assets/         # Statik dosyalar ve stiller
```

## Özellikler

- ✅ Kullanıcı kaydı (Register)
- ✅ Kullanıcı girişi (Login)
- ✅ Ana sayfa (Oda listesi)
- ✅ Chat sayfası (Real-time mesajlaşma)
- ✅ SignalR entegrasyonu
- ✅ Mention (@kullanıcı) desteği
- ✅ Responsive tasarım

## Backend Gereksinimleri

UI projesinin çalışması için aşağıdaki backend servislerinin çalışıyor olması gerekir:

1. **Identity.Api** (Port: 5095)
   - Kullanıcı kaydı ve authentication

2. **Artemis.API** (Port: 5094)
   - API endpoint'leri
   - SignalR Hub

3. **Artemis.Gateway** (Port: 5091)
   - API Gateway (Ocelot)

## Notlar

- Chat sayfası için bir Party ID'ye ihtiyaç vardır. Bu, kullanıcı kaydından sonra otomatik oluşturulmalıdır (backend'de).
- SignalR bağlantısı için CORS ayarlarının doğru yapılandırıldığından emin olun.

