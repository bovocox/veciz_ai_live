FROM node:18-alpine as backend-build

WORKDIR /app/backend

# Python ve diğer gereklilikleri yükle
RUN apk add --no-cache python3 wget

# youtube-dl için Python denetimini atla
ENV YOUTUBE_DL_SKIP_PYTHON_CHECK=1

# Backend bağımlılıklarını kopyala
COPY backend/package*.json ./

# Transformers paketini doğrudan npm'den kaldıralım (safer approach)
RUN npm uninstall @xenova/transformers || true

# Bağımlılıkları yükle
RUN npm ci

# tsconfig.json dosyasını kopyala
COPY backend/tsconfig.json ./

# Backend kaynak kodlarını kopyala (src dizinini)
COPY backend/src ./src

# TypeScript'i derle
RUN npm run build

# Frontend build aşaması
FROM node:18-alpine as frontend-build

WORKDIR /app/frontend

# Frontend bağımlılıklarını kopyala ve yükle
COPY frontend/package*.json ./
RUN npm ci

# Frontend kaynak kodlarını kopyala
COPY frontend/ .

# Frontend build
RUN npm run build:no-types

# Prodüksiyon aşaması
FROM node:18-alpine

WORKDIR /app

# Python ve diğer gereklilikleri yükle (son imajda da gerekli)
RUN apk add --no-cache python3 wget

# youtube-dl için Python denetimini atla
ENV YOUTUBE_DL_SKIP_PYTHON_CHECK=1

# Backend build sonuçlarını kopyala
COPY --from=backend-build /app/backend/dist ./dist
COPY --from=backend-build /app/backend/package*.json ./

# Frontend build sonuçlarını kopyala
COPY --from=frontend-build /app/frontend/dist ./public

# Prodüksiyon modunda transformers paketini doğrudan kaldıralım
RUN npm uninstall @xenova/transformers || true

# Prodüksiyon bağımlılıklarını yükle
RUN npm ci --only=production

# Sağlık kontrolü
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Nginx kurulumu ve yapılandırması
RUN apk add --no-cache nginx
COPY frontend/nginx.conf /etc/nginx/http.d/default.conf

# Başlatma scripti
COPY start.sh ./
RUN chmod +x start.sh

EXPOSE 3000 80

CMD ["./start.sh"] 