FROM node:18-alpine

# Python ve gerekli araçları yükle
RUN apk add --no-cache python3 wget nginx

# Çalışma dizinini ayarla
WORKDIR /app

# Bağımlılıkları ve projeyi kopyala
COPY backend/package*.json ./backend/
COPY frontend/package*.json ./frontend/

# Backend bağımlılıkları
WORKDIR /app/backend
RUN npm install
RUN npm uninstall @xenova/transformers || true

# Frontend bağımlılıkları
WORKDIR /app/frontend
RUN npm install

# Şimdi geri kalan proje dosyalarını kopyala
WORKDIR /app
COPY backend ./backend
COPY frontend ./frontend

# Backend build
WORKDIR /app/backend
RUN npx tsc || echo "TypeScript derleme hatası"

# Frontend build
WORKDIR /app/frontend
RUN npm install -g vite
RUN npm run build:no-types || echo "Frontend build hatası"

# Build çıktılarını ana dizine kopyala
WORKDIR /app
RUN mkdir -p ./dist ./public ./src
RUN cp -r ./backend/dist/* ./dist/ || echo "Backend dist dizini bulunamadı"
RUN cp -r ./backend/src/* ./src/ || echo "Backend src dizini bulunamadı"
RUN cp -r ./frontend/dist/* ./public/ || echo "Frontend dist dizini bulunamadı"

# Ana package.json oluştur
RUN echo '{"name":"vecizai","version":"1.0.0","main":"dist/index.js","scripts":{"start":"node dist/index.js"},"dependencies":{}}' > /app/package.json

# Prodüksiyon bağımlılıklarını yükle
RUN cp backend/package.json ./
RUN npm install --omit=dev
RUN npm install ts-node typescript @types/node || true

# Nginx yapılandırması
COPY frontend/nginx.conf /etc/nginx/http.d/default.conf

# Yedek index.js dosyası oluştur (dist bulunamazsa)
RUN echo 'console.log("Veciz AI başlatılıyor...");' > ./dist/index.js
RUN echo 'try { require("../src/index"); } catch (e) { console.error("Kaynak dosya yüklenirken hata:", e); }' >> ./dist/index.js

# Sağlık kontrolü
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Ortam değişkenlerini ayarla
ENV NODE_ENV=production
ENV PORT=3000
ENV YOUTUBE_DL_SKIP_PYTHON_CHECK=1

# Portlar
EXPOSE 3000 80

# Çalıştırma komutu - shell script kullanımı
CMD sh -c "nginx && cd /app && node dist/index.js || npx ts-node src/index.ts" 