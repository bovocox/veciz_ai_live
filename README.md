# Veciz AI Railway Deployment Rehberi

Bu belge, Veciz AI uygulamasını Railway'de çalıştırmak için gerekli adımları içerir.

## Gereksinimler

- [Railway CLI](https://docs.railway.app/develop/cli) kurulu olmalı
- Railway hesabı
- Docker yüklü olmalı
- Supabase hesabı (https://supabase.com)
- Upstash Redis hesabı (https://upstash.com)

## Railway'e Deploy Etmek İçin Adımlar

1. Railway CLI ile giriş yapın:
   ```
   railway login
   ```

2. Yeni bir Railway projesi oluşturun:
   ```
   railway init
   ```

3. Projeyi Railway'e deploy edin:
   ```
   railway up
   ```

4. Ortam değişkenlerini ayarlayın:
   - Railway Dashboard'a gidin
   - Environment Variables sekmesine tıklayın
   - Backend için gereken .env.production dosyasındaki değişkenleri ekleyin
   - Frontend için gereken .env.production dosyasındaki değişkenleri ekleyin
   - **Supabase ve Upstash Redis değişkenlerini ekleyin:**
     - `SUPABASE_URL`: Supabase projenizin URL'si
     - `SUPABASE_KEY`: Supabase projenizin API anahtarı
     - `UPSTASH_REDIS_URL`: Upstash Redis URL'si
     - `UPSTASH_REDIS_TOKEN`: Upstash Redis token'ı

5. Servisleri yapılandırın:
   - Railway Dashboard'dan "Settings" > "Networking" menüsünden frontend servisinize bir domain atayın
   - Backend servisinizin erişilebilir olduğundan emin olun

## Supabase ve Upstash Redis Yapılandırması

1. **Supabase:**
   - Supabase projenizin URL ve API anahtarını Railway ortam değişkenlerine ekleyin
   - Supabase veritabanınızın güvenlik duvarı ayarlarını kontrol edin ve Railway'in IP adreslerinden erişime izin verin
   - Supabase'de oluşturduğunuz tabloların ve ilişkilerin doğru olduğundan emin olun

2. **Upstash Redis:**
   - Upstash Redis URL ve token bilgilerinizi Railway ortam değişkenlerine ekleyin
   - Upstash Redis konsolundan Railway'in IP adreslerinden erişime izin verin
   - Redis bağlantınızın çalışıp çalışmadığını test edin

## Notlar

- Railway, docker-compose.yml dosyasını kullanarak servisleri deploy eder
- Servislerin tamamen başlatılması birkaç dakika sürebilir
- İlk deploy işlemi daha uzun sürebilir çünkü Docker imajları oluşturulacaktır
- Supabase ve Upstash Redis gibi harici servisler kullanıldığında, ortam değişkenlerinin doğru şekilde yapılandırıldığından emin olun
- Railway, GitHub reponuza bağlanarak otomatik CI/CD kurmayı kolaylaştırabilir 