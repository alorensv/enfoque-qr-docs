# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Language

Respond to the user in Spanish (per `docs/convenciones.md`). All user-facing UI text is also in Spanish.

## Repository Layout

This repo is a meta-repo containing three sibling directories, each with its own purpose. `backend/` and `front/` each have their own `.git` (they are independent repositories, **not** submodules — `git status` from the root will only show them as modified directories):

- `backend/` — NestJS 10 + TypeORM + MySQL API (port 3001)
- `front/` — Next.js 14 (Pages Router) frontend (port 3000)
- `docker/` — `docker-compose.yml` that wires both apps + MySQL together for local dev. **This is the primary working directory.**
- `docs/` — Numbered design docs (`00_inicio.md` … `25_dashboard.md`) describing each feature/module. `docs/convenciones.md` is the source of truth for conventions and the new-feature checklist.
- `.sdd/agent.md` — Mostly empty agent template; ignore unless explicitly asked.

## Common Commands

### Full stack via Docker (run from `docker/`)
```bash
docker-compose up           # frontend + backend + MySQL 8
docker-compose up --build   # after Dockerfile/package.json changes
docker-compose down -v      # reset DB volume
```
- Compose project name: **`enfoque-qr`** (contenedores `enfoque-qr-*`, aislados de otros proyectos).
- Frontend: http://localhost:3004 (host) → 3000 (contenedor)
- Backend:  http://localhost:3009 (host) → 3001 (contenedor) — Swagger at `/api-docs`
- El front en docker usa `NEXT_PUBLIC_API_URL=http://localhost:3009`; el backend permite el origen `http://localhost:3004` vía `CORS_ORIGINS`.
- MySQL exposed on host port **3310** → container 3306 (user `enfoque` / pass `enfoquepass`, db `enfoqueqr`, root pass `rootpass`)

### Backend only (`cd backend`)
```bash
npm install --legacy-peer-deps   # peer-deps conflicts are expected, always use this flag
npm run start:dev                # nest start --watch
npm run build                    # nest build → dist/
npm start                        # run compiled
```
No test script is configured. There is no lint script.

### Frontend only (`cd front`)
```bash
npm install --legacy-peer-deps
npm run dev      # next dev
npm run build
npm run lint     # next lint (eslint-config-next)
```

## Architecture

### Backend (NestJS feature modules)

Each feature lives in `backend/src/<feature>/` with `<feature>.{module,controller,service}.ts`, plus `dto/` and `entities/`. Current modules: `auth`, `users`, `equipment`, `qr`, `maintenances`, `institutions`, `clients`, plus `core/` (global) and `common/`.

- **Entry**: `src/main.ts` bootstraps Nest, configures Swagger at `/api-docs`, enables `cookie-parser` and CORS with `credentials: true`, and serves `public/` statically. The same file exports a Vercel handler — when `process.env.VERCEL` is set, it skips `listen()` and runs serverless.
- **`CoreModule`** is `@Global()` and provides `LoggerService`, `SlugService`, `S3Service`, and registers `RateLimitGuard` as `APP_GUARD` (applies to every route by default).
- **`AppModule`** wires TypeORM (MySQL, `synchronize: false`, `logging: true`) and registers all entities centrally — **when adding a new entity, register it in both the `TypeOrmModule.forRoot({ entities: [...] })` array and `TypeOrmModule.forFeature([...])`** in `app.module.ts`.
- **Auth**: JWT delivered via **httpOnly cookie named `token`** (not `Authorization: Bearer`). Use `@UseGuards(JwtAuthGuard)` + `@ApiCookieAuth('token')` on protected routes. JWT payload shape: `{ sub, email, institutionId, role }`. Passwords use `bcryptjs`.
- **Multi-tenancy**: Most resources scope by `institutionId` from the JWT. Filter every list query by `req.user.institutionId`.
- **Soft delete**: All entities have `createdAt`, `updatedAt`, `deletedAt`. Always filter `deletedAt IS NULL`; never hard-delete.
- **File storage** is dual-mode: local (`public/`) or AWS S3 via `S3Service`, switched by env. Use `FileInterceptor` + a 20MB `FileSizeInterceptor`.
- **DB naming**: columns are `snake_case` mapped to `camelCase` TS properties via `@Column({ name: 'created_at' })`. Entity table names match feature plural.

### Frontend (Next.js Pages Router — **not** App Router)

- `pages/index.js` — landing/login. `pages/admin/*` — authenticated CRUD pages. `pages/qr/[token].js` — public QR scan view.
- **Auth**: `contexts/AuthContext.js` + `withAuth(Component)` HOC wraps admin pages and redirects to `/` if unauthenticated.
- **API calls**: centralized in `services/api.js` as per-resource objects (e.g. `qrApi`, `equipmentApi`). Uses `fetch` with `credentials: 'include'` so the backend's httpOnly cookie flows automatically. Base URL is `NEXT_PUBLIC_API_URL` (defaults to `http://localhost:3000` in code, but local dev should set `http://localhost:3001/api` — see `front/.env.example`). File uploads use `FormData` multipart.
- **State**: Context API for auth, `useState`/`useEffect` for everything else. No Redux, no SWR, no React Query.
- **Styling**: Tailwind CSS only. Font is Urbanist (Google Fonts). All admin pages should wrap content in `<AdminLayout>` (header + 220px sidebar).
- Components in `components/` use `.js` (not `.jsx`/`.tsx`).

## Conventions (from `docs/convenciones.md`)

When adding a new backend "isla" (feature module), follow this checklist:

1. Entity with `id`, `createdAt`, `updatedAt`, `deletedAt`, `institutionId` + `@Index`, and a `@ManyToOne` to `Institution`.
2. DTO with `class-validator` decorators (`@IsNotEmpty`, `@IsString`, …).
3. Service queries use `createQueryBuilder` and **always** add `.andWhere('x.deleted_at IS NULL')`.
4. Controller routes are plural-lowercase (`/equipments`, `/maintenances`), guarded with `@UseGuards(JwtAuthGuard)` and tagged with `@ApiTags` + `@ApiCookieAuth('token')`.
5. Register the module in `AppModule`, and add the entity to **both** the `forRoot` entities array and the `forFeature` array.
6. On the frontend, add a `xxxApi` object in `services/api.js` and create a page under `pages/admin/` wrapped with `withAuth()` and `AdminLayout`.

Naming: files `kebab-case`, classes `PascalCase`, methods/vars `camelCase`, DB columns `snake_case`, REST routes plural lowercase.

## Environment Variables

**Backend** (`backend/.env`): `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS`, `DB_NAME`, `JWT_SECRET`. In docker-compose `DB_HOST=db`.

**Frontend** (`front/.env`): `NEXT_PUBLIC_API_URL` for the NestJS backend. (`.env.example` also mentions `NEXT_PUBLIC_FASTAPI_URL` but the active backend is NestJS — treat the FastAPI references as legacy.)

## Notes / Gotchas

- `npm install` **must** use `--legacy-peer-deps` in both apps (the Dockerfiles do this).
- TypeORM `synchronize` is **off** — schema changes require manual SQL. Reference dumps live in `docs/bd.sql`, `docs/bd_10032026.sql`, `docs/enfoqueqr_modelo_datos.sql`.
- The backend is deployable to Vercel as a serverless function (see the `process.env.VERCEL` branch in `main.ts` and `vercel.json`); keep that path working when editing bootstrap.
- The root-level `README.md` and the `README.md` files inside `backend/` and `front/` are placeholder stubs — don't rely on them for context; use `docs/` instead.
