# Windows Güvenlik Duvarı - Port 5094 Açma Talimatları

## Yöntem 1: PowerShell (Yönetici Gerekli)

1. **PowerShell'i Yönetici olarak açın:**
   - Windows tuşuna basın
   - "PowerShell" yazın
   - "Windows PowerShell" üzerine **sağ tıklayın**
   - **"Yönetici olarak çalıştır"** seçin

2. **Komutu çalıştırın:**
```powershell
New-NetFirewallRule -DisplayName "Artemis SignalR Port 5094" -Direction Inbound -LocalPort 5094 -Protocol TCP -Action Allow
```

## Yöntem 2: Windows Defender Firewall GUI

1. **Windows Ayarlar** → **Ağ ve İnternet** → **Windows Güvenlik Duvarı**
2. **"Gelişmiş ayarlar"** tıklayın (veya "Windows Defender Firewall ile uygulama veya özellik izni ver")
3. Sol menüden **"Gelen kuralları"** seçin
4. Sağ tarafta **"Yeni kural..."** tıklayın
5. **"Bağlantı noktası"** seçin → **İleri**
6. **TCP** seçin → **"Belirli yerel bağlantı noktaları"** → `5094` yazın → **İleri**
7. **"Bağlantıya izin ver"** seçin → **İleri**
8. Tüm profilleri seçin (Etki Alanı, Özel, Genel) → **İleri**
9. İsim: **"Artemis SignalR Port 5094"** → **Son**

## Yöntem 3: Geçici Test İçin (Sadece Geliştirme)

⚠️ **UYARI:** Bu yöntem sadece test için kullanılmalıdır!

1. Windows Ayarlar → **Ağ ve İnternet** → **Windows Güvenlik Duvarı**
2. **"Windows Defender Firewall'ı aç veya kapat"** tıklayın
3. Her iki ağ için (Özel ve Genel) **"Kapalı"** seçin
4. Test tamamlandıktan sonra **mutlaka tekrar açın!**

## Kontrol

Portun açık olduğunu kontrol etmek için:

```powershell
Get-NetFirewallRule -DisplayName "Artemis SignalR Port 5094"
```

veya

```powershell
netstat -an | findstr 5094
```

Backend çalışırken `0.0.0.0:5094` veya `10.58.2.46:5094` görünmeli.

