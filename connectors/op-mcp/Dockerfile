# Portable Node host image. Works on Fly.io, Render, Railway, Cloudflare
# Containers, Cloud Run, or any Docker host. NOT for the Workers edge runtime
# (the 1Password SDK loads WASM via fs.readFileSync; see decisions/0004).
FROM node:22-slim AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install
COPY tsconfig.json ./
COPY src ./src
COPY scripts ./scripts
RUN npm run build

FROM node:22-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json* ./
RUN npm install --omit=dev
COPY --from=build /app/dist ./dist
# Secrets come from the host environment at runtime, never baked into the image:
#   OP_SERVICE_ACCOUNT_TOKEN  (1Password Service Account)
#   CONNECTOR_AUTH_TOKEN      (bearer gate for the /mcp endpoint)
EXPOSE 3000
CMD ["node", "dist/index.js"]
