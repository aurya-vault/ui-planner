FROM node:22-bookworm-slim AS build

# corepack 拉 pnpm 与依赖都走 npmmirror
ENV COREPACK_NPM_REGISTRY=https://registry.npmmirror.com
RUN corepack enable && pnpm config set registry https://registry.npmmirror.com && pnpm config set fetch-retries 5

WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN --mount=type=cache,id=aurya-pnpm-store,target=/root/.local/share/pnpm/store for i in 1 2 3 4; do pnpm install --frozen-lockfile && break; [ $i = 4 ] && exit 1; echo "pnpm install 重试 $i"; sleep 5; done

COPY . .
RUN pnpm run build


FROM node:22-bookworm-slim AS runtime

# corepack 拉 pnpm 与依赖都走 npmmirror
ENV COREPACK_NPM_REGISTRY=https://registry.npmmirror.com
RUN corepack enable && pnpm config set registry https://registry.npmmirror.com && pnpm config set fetch-retries 5

WORKDIR /app

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN --mount=type=cache,id=aurya-pnpm-store,target=/root/.local/share/pnpm/store for i in 1 2 3 4; do pnpm install --frozen-lockfile --prod && break; [ $i = 4 ] && exit 1; echo "pnpm install 重试 $i"; sleep 5; done

COPY api ./api
COPY --from=build /app/dist ./dist

RUN mkdir -p /app/data/projects

EXPOSE 3000

CMD ["node", "api/server.ts"]
