# Multi-stage: the build toolchain never reaches the runtime image.
# Local development only — see docs/fullstack/specs/foundation/infra-docker.md.

FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM node:22-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# output: 'standalone' in next.config.ts produces .next/standalone.
RUN npm run build

FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000
# curl is required by the compose healthcheck, which runs inside this container.
RUN apk add --no-cache curl
# node:alpine already ships a non-root `node` user (uid 1000).
COPY --from=build --chown=node:node /app/.next/standalone ./
COPY --from=build --chown=node:node /app/.next/static ./.next/static
COPY --from=build --chown=node:node /app/public ./public
USER node
EXPOSE 3000
CMD ["node", "server.js"]
