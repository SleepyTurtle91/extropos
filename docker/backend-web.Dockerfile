FROM nginx:alpine
COPY build /usr/share/nginx/html
COPY backend-nginx.conf /etc/nginx/nginx.conf
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
