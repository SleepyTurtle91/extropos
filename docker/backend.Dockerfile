# Multi-stage build for Flutter Web Backend
FROM google/dart:latest AS builder

WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN dart pub get

# Copy source code
COPY . .

# Build web application
RUN dart run build_runner build --release

FROM google/dart:latest

WORKDIR /app

# Copy built app from builder
COPY --from=builder /app/build/web ./build/web

# Install webdev for serving
RUN dart pub global activate webdev

# Expose port
EXPOSE 8080

# Set environment variables
ENV PORT=8080

# Run web application
CMD ["dart", "run", "shelf:serve", "web"]
