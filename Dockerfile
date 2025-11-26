# syntax=docker/dockerfile:1

# 1) Dependencies install (uses Node 16 for compatibility with react-scripts 2.x)
FROM node:16-alpine AS deps
WORKDIR /app

# Copy lock files when present to leverage proper install command
COPY package.json .
COPY package-lock.json* yarn.lock* pnpm-lock.yaml* ./

RUN set -eux; \
    if [ -f package-lock.json ]; then \
      npm ci --legacy-peer-deps; \
    elif [ -f yarn.lock ]; then \
      yarn install --frozen-lockfile; \
    elif [ -f pnpm-lock.yaml ]; then \
      corepack enable && pnpm install --frozen-lockfile; \
    else \
      npm install --legacy-peer-deps; \
    fi

# 2) Build stage
FROM node:16-alpine AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Prevent CRA from treating warnings as CI failures and ensure webpack 4 compatibility
ENV CI=false

RUN npm run build

# 3) Runtime stage: Nginx to serve the compiled static site
FROM nginx:alpine AS runner

# Copy built assets
COPY --from=builder /app/build /usr/share/nginx/html

# Replace default server config to support SPA routing (history API fallback)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
