FROM node:22-bookworm-slim AS build

# corepack 拉 pnpm 与依赖都走 npmmirror
ENV COREPACK_NPM_REGISTRY=https://registry.npmmirror.com
RUN corepack enable && pnpm config set registry https://registry.npmmirror.com

WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm run build


FROM node:22-bookworm-slim AS runtime

# corepack 拉 pnpm 与依赖都走 npmmirror
ENV COREPACK_NPM_REGISTRY=https://registry.npmmirror.com
RUN corepack enable && pnpm config set registry https://registry.npmmirror.com

WORKDIR /app

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile --prod

COPY api ./api
COPY --from=build /app/dist ./dist

RUN mkdir -p /app/data/projects

EXPOSE 3000

CMD ["node", "api/server.ts"]
