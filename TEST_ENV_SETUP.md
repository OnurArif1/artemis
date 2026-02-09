# Test Ortamı Kurulum Talimatları

Bu doküman, Artemis projesini test ortamında farklı PC'lerden erişilebilir şekilde ayağa kaldırmak için gerekli adımları içerir.

## Ön Gereksinimler

- Docker ve Docker Compose yüklü olmalı
- Ana PC (test ortamını çalıştıracak PC) ve diğer PC'ler aynı ağda olmalı

## Kurulum Adımları

### 1. Ana PC'nin IP Adresini Öğrenin

Ana PC'de (test ortamını çalıştıracak PC) terminal/komut istemcisini açın ve IP adresinizi öğrenin:

**Windows:**
```cmd
ipconfig
```
IPv4 Address değerini not edin (örnek: 192.168.1.100)

**Linux/Mac:**
```bash
ifconfig
# veya
ip addr show
```

### 2. Docker Compose Dosyasını Güncelleyin

`docker-compose.yml` dosyasında `web-webapi` servisinin build args kısmını ana PC'nin IP adresiyle güncelleyin:

```yaml
web-webapi:
  build:
    context: .
    dockerfile: src/Web/WebApi/Dockerfile
    args:
      # Ana PC'nin IP adresini buraya yazın
      VITE_SIGNALR_HUB_URL: http://ANA_PC_IP:5094/hubs/chat
      VITE_IDENTITY_TOKEN_URL: http://ANA_PC_IP:5091/identity/connect/token
```

**Örnek:**
```yaml
VITE_SIGNALR_HUB_URL: http://192.168.1.100:5094/hubs/chat
VITE_IDENTITY_TOKEN_URL: http://192.168.1.100:5091/identity/connect/token
```

### 3. Firewall Ayarları

Ana PC'de aşağıdaki portların açık olduğundan emin olun:

- **5091** - Gateway API
- **5094** - Artemis API (SignalR için önemli!)
- **5095** - Identity API
- **5175** - Web WebApi (Frontend)
- **5432** - PostgreSQL (opsiyonel, sadece dışarıdan erişim gerekiyorsa)

**Windows Firewall:**
```cmd
netsh advfirewall firewall add rule name="Artemis Gateway" dir=in action=allow protocol=TCP localport=5091
netsh advfirewall firewall add rule name="Artemis API" dir=in action=allow protocol=TCP localport=5094
netsh advfirewall firewall add rule name="Artemis Identity" dir=in action=allow protocol=TCP localport=5095
netsh advfirewall firewall add rule name="Artemis Web" dir=in action=allow protocol=TCP localport=5175
```

**Linux (iptables):**
```bash
sudo iptables -A INPUT -p tcp --dport 5091 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 5094 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 5095 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 5175 -j ACCEPT
```

**Mac:**
System Preferences > Security & Privacy > Firewall > Firewall Options'dan portları ekleyin.

### 4. Servisleri Başlatın

Ana PC'de proje dizininde:

```bash
docker-compose up --build -d
```

### 5. Servislerin Çalıştığını Kontrol Edin

```bash
docker-compose ps
```

Tüm servislerin "Up" durumunda olduğundan emin olun.

### 6. Diğer PC'lerden Erişim

Diğer PC'lerden web tarayıcısında şu adresi açın:

```
http://ANA_PC_IP:5175
```

Örnek: `http://192.168.1.100:5175`

## SignalR Bağlantısı

SignalR anlık mesajlaşma için kullanılır. Farklı PC'lerden giriş yapan kullanıcılar birbirleriyle anında mesajlaşabilir.

**Önemli:** SignalR WebSocket bağlantıları için port 5094'ün açık olması ve ana PC'nin IP adresinin doğru yapılandırılması gereklidir.

## Sorun Giderme

### SignalR Bağlantı Hatası

1. Ana PC'nin IP adresinin doğru olduğundan emin olun
2. Port 5094'ün firewall'da açık olduğundan emin olun
3. Browser console'da hata mesajlarını kontrol edin

### CORS Hatası

CORS ayarları tüm origin'lere izin verecek şekilde yapılandırılmıştır. Eğer hala sorun yaşıyorsanız:

1. `src/Artemis.API/Program.cs` dosyasındaki CORS ayarlarını kontrol edin
2. `src/Artemis.Gateway/Program.cs` dosyasındaki CORS ayarlarını kontrol edin

### Bağlantı Yapılamıyor

1. Ana PC ve diğer PC'lerin aynı ağda olduğundan emin olun
2. Ping ile bağlantıyı test edin: `ping ANA_PC_IP`
3. Portların açık olduğunu kontrol edin: `telnet ANA_PC_IP 5175`

## Notlar

- Test ortamında PostgreSQL veritabanı Docker container içinde çalışmaktadır
- Tüm servisler `artemis-network` adlı bir Docker network'ünde çalışmaktadır
- Production ortamında HTTPS kullanılması önerilir
- SignalR bağlantıları için WebSocket protokolü kullanılır
