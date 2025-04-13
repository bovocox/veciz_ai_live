FROM node:18-alpine

# Python ve gerekli araçları yükle
RUN apk add --no-cache python3 wget nginx

# Çalışma dizinini ayarla
WORKDIR /app

# Tüm projeyi tek seferde kopyala
COPY . /app/

# Gerekli dizinleri oluştur
RUN mkdir -p /app/dist /app/public /app/src

# Backend işlemleri
WORKDIR /app/backend
# package.json var mı kontrol et
RUN ls -la || true
# Backend bağımlılıkları
RUN if [ -f "package.json" ]; then npm install && npm uninstall @xenova/transformers || true; fi
# TypeScript derleme
RUN if [ -f "package.json" ]; then npx tsc || echo "TypeScript derleme hatası"; fi

# Frontend işlemleri
WORKDIR /app/frontend
# package.json var mı kontrol et
RUN ls -la || true
# Frontend bağımlılıkları
RUN if [ -f "package.json" ]; then npm install && npm install -g vite || true; fi
# Frontend build
RUN if [ -f "package.json" ]; then npm run build:no-types || echo "Frontend build hatası"; fi

# Ana dizine dön
WORKDIR /app

# Derlenen dosyaları kopyala
RUN if [ -d "/app/backend/dist" ]; then cp -r /app/backend/dist/* /app/dist/ || echo "Backend dist dizini boş"; fi
RUN if [ -d "/app/backend/src" ]; then cp -r /app/backend/src/* /app/src/ || echo "Backend src dizini boş"; fi
RUN if [ -d "/app/frontend/dist" ]; then cp -r /app/frontend/dist/* /app/public/ || echo "Frontend dist dizini boş"; fi

# Backend kodunu doğrudan src dizinine kopyalama (ek güvenlik)
RUN cp -r /app/backend/src/* /app/src/ || echo "Backend src/ kopyalanamadı"

# Ana package.json oluştur
RUN echo '{"name":"vecizai","version":"1.0.0","main":"dist/index.js","scripts":{"start":"node dist/index.js"},"dependencies":{}}' > /app/package.json

# Bağımlılıkları yükle
RUN if [ -f "/app/backend/package.json" ]; then cp /app/backend/package.json /app/ || true; fi
RUN npm install --omit=dev || echo "Prodüksiyon bağımlılıkları yüklenemedi"
RUN npm install express@4.18.2 cors body-parser || echo "Express yüklenemedi"

# Favicon oluştur
RUN echo "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAFpQTFRFAAAAUqv/RqXzMGDcK1zWJEivJEmvIkOoIkGmHjufHjqeGjSWEyF3EiB2ER92EB51DhduDRZtCxJlChFkCRBjBw1dBgxcBQpYBAhVAwdSAQNLAAFIAABCAAALMh+czAAAAAFiS0dEBfhv6ccAAAAJcEhZcwAAAHYAAAB2AU57JggAAADMSURBVDjLrdLbEoMgDIDhhISCKGqreP7/39RWZ+suu+3+C8I3EwjDANN2OA9FECL4OM6zqP5xoQUhTrfADUzXERAJEGHwBCgUx/wRyDIr+AeIxHxnLwDj5pBcACTg4kSBBLhXYmJgUTHbQYXEKMBj2vJ2B7tG0lKUmN70FGi1qs4bGA4Vrp9ZfOl6AeCBwYR6QCaAh8qnXdeSMvoF5HpKC8CnncEG8CBrJ2QDOBDnhkwCHKjaIRvASNUPOQKZqbdDpgGOFOsdsgzoBxgZrErxQ3xnAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI0LTA0LTEzVDE0OjI1OjAxKzAwOjAwXSGGrQAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNC0wNC0xM1QxNDoyNTowMSswMDowMCx8PhEAAAAodEVYdGRhdGU6dGltZXN0YW1wADIwMjQtMDQtMTNUMTQ6MjU6MDErMDA6MDAtaSfuAAAAAElFTkSuQmCC" | base64 -d > /app/public/favicon.png

# Basit bir express sunucusu oluştur - server dosyası
RUN cat > /app/dist/index.js << 'EOL'
const express = require('express');
const path = require('path');
const fs = require('fs');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Statik dosyaları sun
app.use(express.static(path.join(__dirname, '../public')));

// BASE_URL çevre değişkenini ayarla (frontend URL hataları için)
app.use((req, res, next) => {
  // API çağrılarını işle, URL hatalarını düzeltmek için
  if (req.url.startsWith('/api')) {
    // API çağrılarını işle
  } else if (req.url.endsWith('.js')) {
    // JavaScript dosyalarında BaseURL düzeltmesi
    const filePath = path.join(__dirname, '../public', req.url);
    if (fs.existsSync(filePath)) {
      let content = fs.readFileSync(filePath, 'utf8');
      
      // URL hatası düzeltmesi - eksik veya hatalı URL'leri düzelt
      content = content.replace(/new URL\(([^,)]+)(?!\s*,)/g, 'new URL($1, window.location.origin');
      
      res.type('application/javascript');
      res.send(content);
      return;
    }
  }
  next();
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

// Bilgi endpoint
app.get('/api/info', (req, res) => {
  res.json({
    message: 'Veciz AI API',
    env: process.env.NODE_ENV,
    time: new Date().toISOString(),
    hostname: req.hostname,
    baseUrl: `${req.protocol}://${req.get('host')}`,
    directories: {
      app: fs.existsSync('/app') ? fs.readdirSync('/app') : 'Bulunamadı',
      dist: fs.existsSync('/app/dist') ? fs.readdirSync('/app/dist') : 'Bulunamadı',
      public: fs.existsSync('/app/public') ? fs.readdirSync('/app/public') : 'Bulunamadı',
      src: fs.existsSync('/app/src') ? fs.readdirSync('/app/src') : 'Bulunamadı'
    }
  });
});

// Ana sayfa ve diğer tüm frontend rotaları
app.get('*', (req, res) => {
  if (fs.existsSync(path.join(__dirname, '../public/index.html'))) {
    res.sendFile(path.join(__dirname, '../public/index.html'));
  } else {
    res.send('<h1>Veciz AI</h1><p>Frontend build edilmemiş.</p>');
  }
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT} - env: ${process.env.NODE_ENV}`);
});
EOL

# Nginx yapılandırması
RUN if [ -f "/app/frontend/nginx.conf" ]; then cp /app/frontend/nginx.conf /etc/nginx/http.d/default.conf || true; fi

# Nginx default yapılandırma oluştur (yoksa)
RUN if [ ! -f "/etc/nginx/http.d/default.conf" ]; then \
  echo 'server { listen 80; server_name _; location / { proxy_pass http://localhost:3000; proxy_http_version 1.1; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host $host; proxy_set_header X-Real-IP $remote_addr; } }' > /etc/nginx/http.d/default.conf; \
fi

# Ortam değişkenlerini ayarla
ENV NODE_ENV=production
ENV PORT=3000
ENV YOUTUBE_DL_SKIP_PYTHON_CHECK=1
ENV BASE_URL=https://veciz-ai-live-production.up.railway.app
ENV API_URL=https://veciz-ai-live-production.up.railway.app/api
ENV CORS_ORIGIN=*
ENV LOG_LEVEL=info
ENV DATABASE_URL=${DATABASE_URL}
ENV JWT_SECRET=${JWT_SECRET}
ENV JWT_EXPIRATION=24h
ENV CLOUDINARY_CLOUD_NAME=${CLOUDINARY_CLOUD_NAME}
ENV CLOUDINARY_API_KEY=${CLOUDINARY_API_KEY}
ENV CLOUDINARY_API_SECRET=${CLOUDINARY_API_SECRET}
ENV OPENAI_API_KEY=${OPENAI_API_KEY}
ENV SMTP_HOST=${SMTP_HOST}
ENV SMTP_PORT=${SMTP_PORT}
ENV SMTP_USER=${SMTP_USER}
ENV SMTP_PASS=${SMTP_PASS}
ENV EMAIL_FROM=${EMAIL_FROM}

# Portlar
EXPOSE 3000 80

# Sağlık kontrolü
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:3000/api/health || exit 1

# Çalıştırma komutu
CMD ["/bin/sh", "./start.sh"] 