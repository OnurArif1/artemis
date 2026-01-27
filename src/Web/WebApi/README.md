# Artemis WebApi

Admin ile aynı teknoloji yığınıyla oluşturulmuş Vue 3 SPA.

## Teknolojiler

- **Vue 3** + **Vite**
- **PrimeVue** + **tailwindcss-primeui**
- **Vue Router** + **Pinia**
- **vue-i18n** (tr / en)
- **axios** (API + auth)
- **Sass**

## Geliştirme

```bash
npm install
npm run dev
```

- Dev sunucu: `http://localhost:5175`
- `/api` ve `/identity` istekleri Gateway üzerinden (`http://localhost:5091`) proxy edilir.

## Build

```bash
npm run build
```

Çıktı: `dist/`

## Giriş

- **E-posta:** `admin@artemis.com`
- **Şifre:** `Admin123!`

## Ortam

`.env.development`:

```
VITE_IDENTITY_TOKEN_URL=http://localhost:5091/identity/connect/token
```
