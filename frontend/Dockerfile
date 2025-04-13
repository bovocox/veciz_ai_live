FROM nginx:alpine

# Nginx yapılandırmasını kopyala
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Önceden oluşturulmuş build dosyalarını kopyala
COPY dist/ /usr/share/nginx/html/

# Ortam değişkenlerini tanımla
ENV NODE_ENV=production

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"] 