FROM node:18-alpine

# Python ve gerekli araçları yükle
RUN apk add --no-cache python3 wget nginx

# Çalışma dizinini ayarla
WORKDIR /app

# Projeyi kopyala
COPY . .

# Ortam değişkenlerini ayarla
ENV NODE_ENV=production
ENV PORT=3000
ENV YOUTUBE_DL_SKIP_PYTHON_CHECK=1

# Backend build
WORKDIR /app/backend
RUN npm uninstall @xenova/transformers || true
RUN npm ci
RUN npx tsc || true

# Frontend build
WORKDIR /app/frontend
RUN npm ci
RUN npm run build:no-types || true

# Derlenen dosyaları doğru konumlara kopyala
WORKDIR /app
RUN mkdir -p ./dist ./public
RUN cp -r ./backend/dist/* ./dist/ || true
RUN cp -r ./frontend/dist/* ./public/ || true

# Prodüksiyon bağımlılıklarını yükle
WORKDIR /app
COPY backend/package*.json ./
RUN npm ci --only=production
RUN npm install ts-node typescript @types/node || true

# Nginx yapılandırması
COPY frontend/nginx.conf /etc/nginx/http.d/default.conf

# Sağlık kontrolü
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Portlar
EXPOSE 3000 80

# Çalıştırma komutu - shell script kullanımı
CMD sh -c "nginx && cd /app && node dist/index.js || npx ts-node src/index.ts" 