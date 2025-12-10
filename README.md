# Artemis Projesi

Artemis, mikroservis mimarisi kullanılarak geliştirilmiş bir chat/sohbet platformudur. Proje .NET 9.0 backend servisleri, Vue.js frontend ve PostgreSQL veritabanından oluşmaktadır.

## 📋 İçindekiler

- [Gereksinimler](#gereksinimler)
- [Proje Yapısı](#proje-yapısı)
- [Kurulum](#kurulum)
  - [1. Veritabanı Kurulumu](#1-veritabanı-kurulumu)
  - [2. Backend Servislerinin Kurulumu](#2-backend-servislerinin-kurulumu)
  - [3. Frontend Kurulumu](#3-frontend-kurulumu)
- [Çalıştırma](#çalıştırma)
- [Port Bilgileri](#port-bilgileri)
- [API Dokümantasyonu](#api-dokümantasyonu)
- [SignalR - Gerçek Zamanlı Mesajlaşma](#signalr---gerçek-zamanlı-mesajlaşma)

## 🔧 Gereksinimler

Projeyi çalıştırmak için aşağıdaki yazılımların yüklü olması gerekmektedir:

- **.NET 9.0 SDK** - [İndir](https://dotnet.microsoft.com/download/dotnet/9.0)
- **Node.js** (v18 veya üzeri) - [İndir](https://nodejs.org/)
- **Docker ve Docker Compose** - [İndir](https://www.docker.com/get-started)
- **PostgreSQL** (Opsiyonel - Docker kullanıyorsanız gerekmez)

## 📁 Proje Yapısı

```
artemis/
├── src/
│   ├── Artemis.API/          # Ana API servisi (Port: 5094)
│   ├── Artemis.Gateway/       # API Gateway (Ocelot) (Port: 5091)
│   ├── Identity.Api/          # Identity Server (Port: 5095)
│   └── Web/
│       └── Admin/             # Vue.js Admin Paneli (Port: 5173)
├── docker-compose.yml         # PostgreSQL ve PgAdmin konfigürasyonu
└── README.md                  # Bu dosya
```

## 🚀 Kurulum

### 1. Veritabanı Kurulumu

Proje Docker Compose ile PostgreSQL veritabanını otomatik olarak başlatır.

#### Docker ile Kurulum (Önerilen)

```bash
# Docker Compose ile veritabanını başlat
docker-compose up -d

# Veritabanının çalıştığını kontrol et
docker ps
```

Bu komut aşağıdaki servisleri başlatır:
- **PostgreSQL**: `localhost:5432`
- **PgAdmin**: `http://localhost:8080`

#### Manuel Kurulum

Eğer Docker kullanmak istemiyorsanız, PostgreSQL'i manuel olarak kurup aşağıdaki bilgilerle veritabanını oluşturun:

- **Database**: `artemisdb`
- **Username**: `artemisuser`
- **Password**: `123456`
- **Port**: `5432`

Ayrıca Identity Server için ayrı bir veritabanı oluşturun:
- **Database**: `ArtemisIdentity`

### 2. Backend Servislerinin Kurulumu

#### 2.1. Identity.Api Kurulumu

Identity Server, kimlik doğrulama ve yetkilendirme işlemlerini yönetir.

```bash
# Identity.Api dizinine git
cd src/Identity.Api

# NuGet paketlerini geri yükle
dotnet restore

# Veritabanı migrasyonlarını uygula (otomatik olarak Program.cs'de yapılıyor)
# İlk çalıştırmada otomatik olarak uygulanacak

# Projeyi çalıştır
dotnet run
```

Identity Server şu adreste çalışacak: `http://localhost:5095`

#### 2.2. Artemis.API Kurulumu

Ana API servisi, chat ve mesajlaşma işlemlerini yönetir.

```bash
# Artemis.API dizinine git
cd src/Artemis.API

# NuGet paketlerini geri yükle
dotnet restore

# Veritabanı migrasyonlarını uygula (otomatik olarak Program.cs'de yapılıyor)
# İlk çalıştırmada otomatik olarak uygulanacak

# Projeyi çalıştır
dotnet run
```

API servisi şu adreste çalışacak: `http://localhost:5094`
Swagger dokümantasyonu: `http://localhost:5094/swagger`

#### 2.3. Artemis.Gateway Kurulumu

API Gateway, tüm istekleri yönlendirir ve merkezi bir giriş noktası sağlar.

```bash
# Artemis.Gateway dizinine git
cd src/Artemis.Gateway

# NuGet paketlerini geri yükle
dotnet restore

# Projeyi çalıştır
dotnet run
```

Gateway şu adreste çalışacak: `http://localhost:5091`

### 3. Frontend Kurulumu

Vue.js ile geliştirilmiş admin paneli.

```bash
# Admin dizinine git
cd src/Web/Admin

# Node.js paketlerini yükle
npm install

# Development modunda çalıştır
npm run dev
```

Frontend şu adreste çalışacak: `http://localhost:5173`

## ▶️ Çalıştırma

Projeyi tam olarak çalıştırmak için aşağıdaki sırayı takip edin:

### Adım 1: Veritabanını Başlat

```bash
# Proje kök dizininde
docker-compose up -d
```

### Adım 2: Backend Servislerini Başlat

Her servisi ayrı bir terminal penceresinde çalıştırın:

**Terminal 1 - Identity Server:**
```bash
cd src/Identity.Api
dotnet run
```

**Terminal 2 - API:**
```bash
cd src/Artemis.API
dotnet run
```

**Terminal 3 - Gateway:**
```bash
cd src/Artemis.Gateway
dotnet run
```

### Adım 3: Frontend'i Başlat

**Terminal 4 - Frontend:**
```bash
cd src/Web/Admin
npm run dev
```

## 🔌 Port Bilgileri

| Servis | Port | URL |
|--------|------|-----|
| PostgreSQL | 5432 | `localhost:5432` |
| PgAdmin | 8080 | `http://localhost:8080` |
| Identity Server | 5095 | `http://localhost:5095` |
| Artemis API | 5094 | `http://localhost:5094` |
| API Gateway | 5091 | `http://localhost:5091` |
| Frontend (Admin) | 5173 | `http://localhost:5173` |
| Swagger UI | - | `http://localhost:5094/swagger` |

## 📚 API Dokümantasyonu

API dokümantasyonuna erişmek için:

1. Artemis.API servisini çalıştırın
2. Tarayıcınızda `http://localhost:5094/swagger` adresine gidin

Swagger UI üzerinden tüm endpoint'leri test edebilirsiniz.

## 📡 SignalR - Gerçek Zamanlı Mesajlaşma

Artemis projesi, gerçek zamanlı mesajlaşma için **SignalR** kullanmaktadır. SignalR, sunucu ile istemciler arasında gerçek zamanlı, iki yönlü iletişim sağlar.

### SignalR Nedir?

SignalR, Microsoft tarafından geliştirilmiş bir kütüphanedir ve şu özellikleri sağlar:
- **Gerçek zamanlı iletişim**: Sunucudan istemciye anlık veri gönderimi
- **Otomatik yeniden bağlanma**: Bağlantı koparsa otomatik olarak yeniden bağlanır
- **Group yönetimi**: Kullanıcıları gruplara ekleyip çıkarabilme (oda bazlı mesajlaşma)
- **WebSocket desteği**: Modern tarayıcılarda WebSocket, eski tarayıcılarda fallback protokolleri kullanır

### Backend Tarafı (ChatHub)

SignalR Hub'ı `Artemis.API` projesinde `Hubs/ChatHub.cs` dosyasında tanımlanmıştır.

#### Hub Endpoint Yapılandırması

Hub, `Program.cs` dosyasında yapılandırılmıştır:

```125:126:src/Artemis.API/Program.cs
app.MapControllers();
app.MapHub<ChatHub>("/hubs/chat");
```

Hub'a şu adresten erişilir: `http://localhost:5094/hubs/chat`

### Frontend Tarafı (SignalRService)

Frontend'de SignalR bağlantısı `src/Web/Admin/sakai-vue/src/service/SignalRService.js` dosyasında yönetilir.

#### Bağlantı Kurma

```javascript
// SignalR bağlantısını başlat
await signalRService.startConnection();

// Bağlantı durumunu kontrol et
const isConnected = signalRService.isConnected();
```

#### Odaya Katılma ve Ayrılma

```javascript
// Belirli bir odaya katıl
signalRService.joinRoom(roomId);

// Odadan ayrıl
signalRService.leaveRoom(roomId);
```

#### Mesaj Gönderme

```javascript
// Mesaj gönder
signalRService.sendMessage(partyId, roomId, message, mentionedPartyIds);
```

#### Mesaj Dinleme

```javascript
// Gelen mesajları dinle
signalRService.onReceiveMessage((partyId, partyName, message, roomId) => {
    console.log(`${partyName}: ${message}`);
    // Mesajı UI'a ekle
});

// Hata mesajlarını dinle
signalRService.onReceiveError((errorMessage) => {
    console.error('Hata:', errorMessage);
});
```

### SignalR Nasıl Çalışır?

#### 1. Bağlantı Akışı

```
Frontend                    Backend
   |                          |
   |--- startConnection() ---->|
   |                          |--- OnConnectedAsync()
   |<-- ReceiveConnectionId --|
   |                          |
```

#### 2. Mesaj Gönderme Akışı

```
Kullanıcı A (Frontend)          ChatHub (Backend)          Kullanıcı B (Frontend)
      |                              |                            |
      |--- SendMessage() ----------->|                            |
      |                              |--- Veritabanına kaydet     |
      |                              |--- Group'a mesaj gönder --->|
      |                              |                            |--- ReceiveMessage()
      |                              |                            |
```

#### 3. Oda Yönetimi

```
Kullanıcı                        ChatHub
   |                               |
   |--- JoinRoom(roomId) ---------->|
   |                               |--- Groups.AddToGroupAsync()
   |                               |   (Room_1 grubuna ekle)
   |                               |
   |--- SendMessage() ------------>|
   |                               |--- Clients.Group("Room_1")
   |                               |   .SendAsync()
   |                               |
   |--- LeaveRoom(roomId) ------->|
   |                               |--- Groups.RemoveFromGroupAsync()
```

### Kullanım Örneği (Vue Component)

```javascript
import signalRService from '@/service/SignalRService';

export default {
    async mounted() {
        // SignalR bağlantısını başlat
        await signalRService.startConnection();
        
        // Odaya katıl
        signalRService.joinRoom(this.roomId);
        
        // Mesaj dinleme
        signalRService.onReceiveMessage((partyId, partyName, message, roomId) => {
            this.messages.push({
                partyId,
                partyName,
                content: message,
                timestamp: new Date()
            });
        });
    },
    
    methods: {
        sendMessage() {
            signalRService.sendMessage(
                this.currentPartyId,
                this.roomId,
                this.messageText
            );
        }
    },
    
    beforeUnmount() {
        // Odadan ayrıl
        signalRService.leaveRoom(this.roomId);
    }
}
```

### Önemli Özellikler

1. **Otomatik Yeniden Bağlanma**: Bağlantı koparsa SignalR otomatik olarak yeniden bağlanmaya çalışır
2. **Group Yönetimi**: Her oda bir SignalR grubu olarak yönetilir (`Room_{roomId}`)
3. **ConnectionId**: Her bağlantıya özel bir ID atanır ve takip edilir
4. **Hata Yönetimi**: Mesaj gönderme hataları `ReceiveError` event'i ile frontend'e bildirilir

### SignalR Hub URL Yapılandırması

Frontend'de SignalR Hub URL'i environment variable ile yapılandırılabilir:

```javascript
// .env dosyasında
VITE_SIGNALR_HUB_URL=http://localhost:5094/hubs/chat
```

Eğer environment variable tanımlı değilse, varsayılan olarak `http://localhost:5094/hubs/chat` kullanılır.

### Sorun Giderme

#### SignalR Bağlantı Hatası

- **Backend'in çalıştığından emin olun**: `http://localhost:5094` erişilebilir olmalı
- **CORS ayarlarını kontrol edin**: `Program.cs` dosyasında CORS yapılandırması doğru olmalı
- **Hub URL'ini kontrol edin**: Frontend'deki Hub URL'i backend ile eşleşmeli

#### Mesajlar Görünmüyor

- **Odaya katıldığınızdan emin olun**: `joinRoom()` metodunu çağırdığınızdan emin olun
- **Group adının doğru olduğundan emin olun**: Backend ve frontend'de aynı format kullanılmalı (`Room_{roomId}`)
- **Browser console'u kontrol edin**: Hata mesajları console'da görünecektir

#### Bağlantı Kopuyor

- **Network bağlantısını kontrol edin**: İnternet bağlantınızın stabil olduğundan emin olun
- **Otomatik yeniden bağlanma aktif mi**: `withAutomaticReconnect()` kullanıldığından emin olun
- **Backend loglarını kontrol edin**: Backend'de bağlantı hataları görünecektir

## 🔍 Sorun Giderme

### Veritabanı Bağlantı Hatası

- Docker Compose'un çalıştığından emin olun: `docker ps`
- Connection string'lerin doğru olduğundan emin olun (`appsettings.json` dosyalarında)
- PostgreSQL'in port 5432'de dinlediğinden emin olun

### Port Çakışması

Eğer bir port zaten kullanılıyorsa:

1. `launchSettings.json` dosyalarında port numaralarını değiştirin
2. `ocelot.json` dosyasında gateway route'larını güncelleyin
3. Frontend'deki API endpoint'lerini güncelleyin

### Migrasyon Hataları

- Veritabanının oluşturulduğundan emin olun
- Connection string'lerin doğru olduğundan emin olun
- Manuel olarak migrasyon uygulamak için:
  ```bash
  cd src/Artemis.API
  dotnet ef database update
  ```

### Frontend Bağlantı Sorunları

- Gateway'in çalıştığından emin olun
- CORS ayarlarını kontrol edin
- API endpoint'lerinin doğru olduğundan emin olun

## 📝 Notlar

- İlk çalıştırmada veritabanı migrasyonları otomatik olarak uygulanır
- Identity Server ilk çalıştırmada seed data ile yüklenir
- Development ortamında CORS ayarları tüm origin'lere izin verecek şekilde yapılandırılmıştır
- Production ortamında güvenlik ayarlarını gözden geçirmeyi unutmayın

## 🤝 Katkıda Bulunma

Projeye katkıda bulunmak için:

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje özel bir projedir.

---

**İyi kodlamalar! 🚀**

