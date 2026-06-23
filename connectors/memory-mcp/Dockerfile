# Portable Node host image. Works on Render, Fly.io, Railway, Cloud Run, or any
# Docker host. No filesystem/WASM constraints here (unlike op-mcp), but Node 22 is
# kept for parity and for global fetch.
FROM node:22-slim AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

FROM node:22-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json* ./
RUN npm install --omit=dev
COPY --from=build /app/dist ./dist
# Secrets come from the host environment at runtime, never baked into the image:
#   GITHUB_TOKEN        (contents read/write on the memory repo)
#   MEMORY_MCP_BEARER   (bearer gate for the /mcp endpoint)
EXPOSE 3000
CMD ["node", "dist/index.js"]
