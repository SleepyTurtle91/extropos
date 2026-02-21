# Dockerfile for Dealer Backend Web Portal
# Multi-stage build for optimized production image

# Stage 1: Build Flutter Web App
FROM debian:bullseye-slim AS builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Configure Flutter
RUN flutter doctor -v
RUN flutter config --enable-web

# Set working directory
WORKDIR /app

# Copy project files
COPY pubspec.yaml pubspec.lock ./
COPY lib ./lib
COPY web ./web
COPY android ./android
COPY ios ./ios

# Get dependencies
RUN flutter pub get

# Build web app (dealer portal)
RUN flutter build web \
    --release \
    --target lib/main_dealer.dart \
    --no-tree-shake-icons

# Stage 2: Nginx production server
FROM nginx:alpine

# Remove default nginx config
RUN rm -rf /usr/share/nginx/html/*

# Copy built web app
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy custom nginx config
COPY docker/nginx/dealer-backend.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Health check
# Use 127.0.0.1 to avoid IPv6/::1 resolution issues inside containers
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
