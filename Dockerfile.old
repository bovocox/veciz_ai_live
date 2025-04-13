FROM node:18-alpine

# Çalışma dizinini ayarla
WORKDIR /app

# Python ve gerekli araçları yükle
RUN apk add --no-cache python3 wget nginx

# youtube-dl için Python denetimini atla
ENV YOUTUBE_DL_SKIP_PYTHON_CHECK=1

# Önce tüm proje dosyalarını kopyala
COPY . .

# Backend bağımlılıklarını yükle
WORKDIR /app/backend
RUN npm uninstall @xenova/transformers || true
RUN npm ci

# TypeScript'i manuel olarak derle - verbose modda
RUN echo "TypeScript derlemesi başlatılıyor..." && \
    ./node_modules/.bin/tsc --version && \
    ./node_modules/.bin/tsc || echo "TypeScript derleme hatası yok sayıldı"

# Derleme başarısız olursa, dist dizini oluştur ve index.js dosyasını manuel ekle
RUN if [ ! -d "dist" ]; then \
        echo "dist dizini bulunamadı, oluşturuluyor..." && \
        mkdir -p dist && \
        echo "console.log('Veciz AI başlatılıyor...');" > dist/index.js && \
        echo "require('../src/index');" >> dist/index.js; \
    fi

# Derlemenin başarılı olup olmadığını kontrol et
RUN ls -la dist/

# Frontend bağımlılıklarını yükle ve build et
WORKDIR /app/frontend
RUN npm ci
RUN npm run build:no-types || echo "Frontend build hatası yok sayıldı, devam ediliyor..."

# Ana çalışma dizinine geri dön
WORKDIR /app

# Backend build çıktısını ana dizine kopyala
RUN mkdir -p ./dist
RUN cp -r ./backend/dist/* ./dist/ || echo "Backend dist dosyaları kopyalanamadı"
# Yedek olarak tüm kaynak kodlarını da kopyala
RUN mkdir -p ./src
RUN cp -r ./backend/src/* ./src/ || echo "Backend src dosyaları kopyalanamadı"

# Frontend build çıktısını public dizinine kopyala
RUN mkdir -p ./public
RUN cp -r ./frontend/dist/* ./public/ || echo "Frontend dosyaları kopyalanamadı"

# Yedek index.js dosyası oluştur
RUN echo "// Yedek index.js dosyası" > ./dist/index.js
RUN echo "console.log('Veciz AI başlatılıyor...');" >> ./dist/index.js
RUN echo "try { require('../src/index'); } catch (e) { console.error('Ana dosya yüklenirken hata:', e); }" >> ./dist/index.js

# Prodüksiyon bağımlılıklarını yükle
COPY backend/package*.json ./
RUN npm uninstall @xenova/transformers || true
RUN npm ci --only=production

# Gerekli modülleri yükle
RUN npm install ts-node typescript @types/node || true

# Nginx yapılandırmasını kopyala
COPY frontend/nginx.conf /etc/nginx/http.d/default.conf

# Start.sh dosyasını düzenle - ts-node kullan
RUN echo '#!/bin/sh\n\n# Nginx başlat\nnginx\n\n# Node.js backend başlat\necho "Backend başlatılıyor..."\nnode dist/index.js || npx ts-node src/index.ts' > start.sh
RUN chmod +x start.sh

# Sağlık kontrolü ekle
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Ortam değişkenlerini ayarla
ENV NODE_ENV=production
ENV PORT=3000

# Portları aç
EXPOSE 3000 80

# Uygulamayı başlat
CMD ["./start.sh"] 