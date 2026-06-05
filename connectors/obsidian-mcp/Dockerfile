# Portable Node host image. Works on Render, Fly.io, Railway, Cloud Run, or any
# Docker host. `git` is installed because the server clones/pulls the vault repo.
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
# git is the only system dependency — used to clone/pull the vault.
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
  && rm -rf /var/lib/apt/lists/*
COPY package.json package-lock.json* ./
RUN npm install --omit=dev
COPY --from=build /app/dist ./dist
# Where the vault checkout lives inside the container (clone target). Under /app so
# it is writable on free tiers without a mounted disk (re-cloned on cold start).
ENV VAULT_DIR=/app/vault
# Secrets/config come from the host environment at runtime, never baked in:
#   CONNECTOR_AUTH_TOKEN  (bearer gate for /mcp)
#   VAULT_REPO            (e.g. SchnappAPI/obsidian-vault)
#   GITHUB_TOKEN          (read access to the private vault repo)
#   VAULT_BRANCH          (default: main)
EXPOSE 3000
CMD ["node", "dist/index.js"]
