# Multi-stage: the build toolchain never reaches the runtime image.
# Local development only — see docs/fullstack/specs/foundation/infra-docker.md.

FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
# `npm ci` would be the stricter choice, but the lockfile is generated on macOS
# arm64 and npm omits the Linux-only optional packages (@emnapi/*, @swc/helpers)
# that a Linux image then demands — and this image is always built for Linux.
# `npm ci` fails on that mismatch; CI hit exactly this and made the same swap
# (.github/workflows/ci.yml). Revisit if npm fixes cross-platform optional resolution.
RUN npm install --no-audit --no-fund

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
# Docker sets HOSTNAME to the container ID, and the standalone server.js reads
# `process.env.HOSTNAME || '0.0.0.0'` — so without this it binds to the container
# ID alone. The published port still works, but 127.0.0.1 inside the container
# does not, which is exactly what the compose healthcheck curls.
ENV HOSTNAME=0.0.0.0
# curl is required by the compose healthcheck, which runs inside this container.
RUN apk add --no-cache curl
# node:alpine already ships a non-root `node` user (uid 1000).
COPY --from=build --chown=node:node /app/.next/standalone ./
COPY --from=build --chown=node:node /app/.next/static ./.next/static
COPY --from=build --chown=node:node /app/public ./public
USER node
EXPOSE 3000
CMD ["node", "server.js"]
