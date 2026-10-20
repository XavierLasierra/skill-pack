---
name: be-node
description: Build or fix a Node.js/TypeScript backend. Use when adding an Express, Fastify, or NestJS route, controller, DTO, ValidationPipe, zod schema, error handler, Pino logging, Prisma/drizzle/TypeORM migration, or Vitest/Jest/supertest test. Framework idioms only.
targets: [all]
---
## Node.js / TypeScript

Shared principles live in [[be-api-design]], [[be-data-access]], [[be-migrations]], [[be-security]], [[be-reliability]], [[be-observability]]. This skill covers only Node 22+ / TS idioms for Express, Fastify, and NestJS.

### Structure
- Layer by business component: `orders/{api,domain,data}`. API layer owns HTTP; domain has logic; data layer owns the ORM. `req`/`res` never go past the controller.
- No side effects at module import (connecting, listening, timers). Export a `createApp(deps)` factory so tests build it without I/O.
- Config validated once at startup; crash on invalid:

```ts
const env = z.object({
  DATABASE_URL: z.url(),
  PORT: z.coerce.number().default(3000),
}).parse(process.env);
```

### Idioms
- Validate at the boundary: zod `safeParse` in Express middleware; in Fastify use JSON schema per route (or a type provider such as `fastify-type-provider-zod`) so validation and types share one source.
- Errors: extend `Error` (`class NotFoundError extends AppError`), flag operational (expected, safe to report) vs programmer errors (bugs). One central handler maps them to one error shape. Express: 4-arg middleware registered last; Fastify: `setErrorHandler`.
- `process.on('unhandledRejection')` and `uncaughtException`: log, close server and DB gracefully, exit non-zero. Let the orchestrator restart.
- Never block the event loop: no `crypto.pbkdf2Sync`, `fs.readFileSync` in handlers, huge `JSON.parse`, or tight CPU loops. Use `worker_threads` or a queue.
- Outbound calls always get a deadline: `fetch(url, { signal: AbortSignal.timeout(5000) })`.
- Logging: Pino, JSON to stdout, one logger instance with request-bound child loggers (`pino-http` / Fastify's built-in).
- Express 5 forwards rejected promises from async handlers to the error handler. On Express 4 wrap them.

### NestJS
- Module per domain; providers via constructor injection; no `new Service()`.
- Global pipe in `main.ts`: `app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))`.
- DTOs must be **classes** with `class-validator` decorators. Interfaces and type aliases are erased at runtime, so they validate nothing.
- Authz in guards (`@UseGuards`), not in handlers. Errors: throw `HttpException` subclasses or domain errors mapped by one `@Catch()` exception filter.

### Data & migrations
- Prisma Migrate (`migrate dev` locally, `migrate deploy` in release), drizzle-kit (`generate` then review SQL, `migrate`), or TypeORM migrations. Read the generated SQL before merging.
- Never `synchronize: true` (TypeORM) in production; it can drop columns.
- Prisma N+1: use `include` / `select` in one query instead of per-row lookups. Select only needed fields.

### Testing
Strategy and naming: [[cq-testing]].
- Vitest (or Jest, the Nest default). HTTP tests via `supertest(app)` or `fastify.inject()`; no real port.
- Mock external HTTP at the network edge (MSW or nock), including slow/timeout and 5xx responses.
- Nest: `Test.createTestingModule(...).overrideProvider(X).useValue(fake)`.

### Avoid → Use instead
| Avoid | Use instead |
|---|---|
| DTO as `interface` in Nest | class with decorators |
| `bcrypt.hashSync`, `readFileSync` in a request | async APIs or a worker |
| `fetch` without a signal | `AbortSignal.timeout(ms)` |
| `process.env.X` read all over | one validated config object |
