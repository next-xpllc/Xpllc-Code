# docker-compose

when_to_use: |
  User asks about containerization, writes a Dockerfile, writes a
  docker-compose.yml, talks about images, registries, volumes, or
  "why is my container so huge / so slow".

## Dockerfile principles

1. **Start from a specific digest, not a tag.** `python:3.12-slim` moves;
   `python:3.12-slim@sha256:…` doesn't.
2. **Multi-stage or die.** Your runtime image shouldn't have `gcc`, `make`,
   or your package manager's cache.
3. **One concern per image.** No init systems, no supervisord, no
   cron-and-webserver-in-one.
4. **Copy files in increasing volatility order** — dependencies first
   (cacheable), source last (changes every build).
5. **Use `.dockerignore`.** At minimum: `.git`, `node_modules`, `.venv`,
   `target`, `dist`, `*.log`.

## Reference Node.js Dockerfile

```dockerfile
# syntax=docker/dockerfile:1.7
FROM node:20-alpine@sha256:… AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

FROM node:20-alpine@sha256:… AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY . .
RUN npm run build

FROM node:20-alpine@sha256:… AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY --from=deps  /app/node_modules ./node_modules
COPY --from=build /app/dist         ./dist
COPY --from=build /app/package.json ./
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/server.js"]
```

Key points called out:
- `USER node` — never run as root.
- `HEALTHCHECK` — orchestrators need it to decide when traffic can flow.
- `--mount=type=cache` — fast rebuilds without polluting the layer.
- Digest-pinned base images — reproducible builds.

## docker-compose.yml principles

- **Don't use `latest` tags.** Ever. Pin versions or hashes.
- **Declare healthchecks on every service with a dependency arrow.**
  `depends_on: condition: service_healthy` is the difference between
  "works on laptop" and "works in CI".
- **Volumes are named, not bind-mounted**, except for dev-time source code.
  Named volumes survive `docker compose down`, bind mounts leak host state.
- **Secrets via `secrets:` block**, never in `environment:`.
  `environment` ends up in `docker inspect` and in any logs.

## Compose reference

```yaml
services:
  app:
    build: .
    image: myapp:${TAG:-dev}
    ports: ["3000:3000"]
    environment:
      DATABASE_URL: postgres://app:app@db:5432/app
    secrets: [jwt_key]
    depends_on:
      db: { condition: service_healthy }
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:3000/health"]
      interval: 10s
      retries: 3

  db:
    image: postgres:16-alpine
    environment: { POSTGRES_PASSWORD: app, POSTGRES_DB: app, POSTGRES_USER: app }
    volumes: [dbdata:/var/lib/postgresql/data]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app"]
      interval: 5s
      retries: 5

volumes: { dbdata: }
secrets:
  jwt_key: { file: ./secrets/jwt_key.txt }
```

## Common issues the agent should diagnose

| Symptom                                    | Usual cause                                           |
| ------------------------------------------ | ----------------------------------------------------- |
| Huge image (1GB+)                          | No multi-stage; build deps bloat the runtime layer.   |
| Very slow rebuilds                         | Source copied before dependency install; cache miss. |
| "Connection refused" between services      | Container binds to `127.0.0.1` not `0.0.0.0`.         |
| Data lost on `compose down`                | Bind-mount or no volume at all.                       |
| Permission errors on mounted dir           | UID mismatch between container user and host user.    |
| Works on amd64, fails on Apple Silicon     | Missing `platform:` or base image lacks arm64 manifest.|

## Never

- Run the app as root (`USER root` at the end).
- Bake secrets into the image via `ENV` or `COPY`.
- `ADD` a remote URL — fetches at build, no caching, unclear provenance. Use `RUN curl` + verify hash.
- Ship an image that doesn't have a healthcheck.
