# ==============================
# Stage 1: Install dependencies
# ==============================
FROM node:24.14-alpine AS dependencies

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci


# ==============================
# Stage 2: Build application
# ==============================
FROM node:24.14-alpine AS builder

WORKDIR /app

ARG GOOGLE_MAPS_API_KEY

ENV GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY

COPY --from=dependencies /app/node_modules ./node_modules

COPY . .

RUN npm run build


# ==============================
# Stage 3: Production runtime
# ==============================
FROM node:24.14-alpine AS runtime

WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/package-lock.json ./package-lock.json
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/vite.config.js ./vite.config.js

RUN addgroup -S appgroup \
    && adduser -S appuser -G appgroup \
    && chown -R appuser:appgroup /app

USER appuser

EXPOSE 4173

CMD ["npm", "run", "preview", "--", "--host", "0.0.0.0", "--port", "4173"]