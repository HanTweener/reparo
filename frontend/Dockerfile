# Stage 1: Build Flutter Web application
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Cache dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source and compile release web bundle
COPY . .
RUN flutter build web --release

# Stage 2: Production Nginx runtime
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
