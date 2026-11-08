# Stage 1: Build Flutter Web application
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Cache dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source and compile release web bundle
COPY . .
ARG API_BASE_URL=""
RUN if [ -n "$API_BASE_URL" ]; then \
      flutter build web --release --dart-define=API_BASE_URL="${API_BASE_URL}"; \
    else \
      flutter build web --release; \
    fi

# Stage 2: Production Nginx runtime
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

