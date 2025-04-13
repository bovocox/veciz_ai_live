FROM node:18-alpine

# Çalışma dizinini ayarla
WORKDIR /app

# Python ve gerekli araçları yükle
RUN apk add --no-cache python3 wget nginx

# youtube-dl için Python denetimini atla
ENV YOUTUBE_DL_SKIP_PYTHON_CHECK=1

# Tüm backend paketlerini kopyala
COPY backend/package*.json ./backend/

# Transformers paketini backend package.json'dan kaldır
WORKDIR /app/backend
RUN npm uninstall @xenova/transformers || true

# Backend bağımlılıklarını yükle
RUN npm ci

# Backend kaynak dosyalarını kopyala
COPY backend .

# Backend TypeScript'i derle
RUN npm run build

# Frontend dosyalarını kopyala
WORKDIR /app
COPY frontend ./frontend

# Frontend bağımlılıklarını yükle ve build et
WORKDIR /app/frontend
RUN npm ci
RUN npm run build:no-types

# Ana çalışma dizinine geri dön
WORKDIR /app

# Backend build çıktısını ana dizine kopyala
RUN cp -r /app/backend/dist ./dist

# Frontend build çıktısını public dizinine kopyala
RUN mkdir -p ./public
RUN cp -r /app/frontend/dist/* ./public/

# Prodüksiyon bağımlılıklarını yükle
COPY backend/package*.json ./
RUN npm uninstall @xenova/transformers || true
RUN npm ci --only=production

# Nginx yapılandırmasını kopyala
COPY frontend/nginx.conf /etc/nginx/http.d/default.conf

# Başlatma scriptini kopyala ve çalıştırılabilir yap
COPY start.sh ./
RUN chmod +x start.sh

# Sağlık kontrolü ekle
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Portları aç
EXPOSE 3000 80

# Uygulamayı başlat
CMD ["./start.sh"] 