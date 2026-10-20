---
name: be-fastapi
description: Build or fix a FastAPI backend. Use when adding a FastAPI endpoint/router, Pydantic v2 schema, dependency, settings, lifespan, SQLAlchemy 2.0 query, Alembic migration, or async tests. Framework idioms only; shared backend rules live in the be- skills.
targets: [all]
---
## FastAPI

Shared principles live in [[be-api-design]], [[be-data-access]], [[be-migrations]], [[be-security]], [[be-reliability]], [[be-observability]]. This skill covers only FastAPI + Pydantic v2 + SQLAlchemy 2.0 idioms.

### Structure
- Package per domain, not per file type: `src/orders/{router,schemas,models,service,dependencies,config,exceptions}.py`. Cross-domain imports use explicit module paths.
- Routers stay thin: parse, call `service`, return. Business logic and DB queries live in `service.py`.
- `async def` route only if every call inside is non-blocking. Blocking SDK or sync DB driver → plain `def` route (runs in threadpool) or `await run_in_threadpool(fn)`. CPU-heavy → worker/queue, never the event loop.

### Idioms
- Pydantic built-ins before custom validators: `Field(min_length=1, max_length=80)`, `EmailStr`, `Annotated[int, Field(gt=0)]`. Config: `model_config = ConfigDict(from_attributes=True)`.
- Separate `OrderCreate` / `OrderUpdate` / `OrderRead`. Set `response_model=OrderRead` so output is an allowlist.
- Dependencies carry validation and ownership checks (`get_owned_order(order_id, user)` raises 404). Cached per request; chain small ones instead of one big one.
- Settings: `pydantic_settings.BaseSettings`, one class per module (`AuthSettings`, `DbSettings`), instantiated once at import.
- Startup/shutdown via `lifespan`, not `@app.on_event`:

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http = httpx.AsyncClient(timeout=5)
    yield
    await app.state.http.aclose()

app = FastAPI(lifespan=lifespan)
```

- Domain exceptions → one handler returning RFC 9457 `application/problem+json`:

```python
@app.exception_handler(OrderNotFound)
async def not_found(request: Request, exc: OrderNotFound):
    return JSONResponse(
        {"type": "about:blank", "title": "Order not found", "status": 404},
        status_code=404, media_type="application/problem+json",
    )
```

### Data & migrations
- SQLAlchemy 2.0 style: `await session.scalars(select(Order).where(Order.id == id))`. No legacy `session.query`.
- One `AsyncSession` per request via a `yield` dependency; commit in the service, not the router.
- `expire_on_commit=False` on the sessionmaker, or attributes raise `MissingGreenlet` on access after commit. Know the trade-off: objects may be stale.
- N+1: async has no lazy loading. Declare `selectinload` (collections) or `joinedload` (to-one) in the query.
- Alembic: set a `naming_convention` on `MetaData` before the first migration so constraints get stable names. Review autogenerate output (misses renames, shows drop+add, ignores some type changes). Run `alembic upgrade head` as a one-off release step, not at app startup.

### Testing
Strategy and naming: [[cq-testing]].
- pytest + `httpx.AsyncClient(transport=ASGITransport(app=app), base_url="http://test")`. `TestClient` is fine for sync tests. Note `ASGITransport` does not run `lifespan`; wrap with `asgi-lifespan`'s `LifespanManager` if needed.
- Swap collaborators with `app.dependency_overrides[get_session] = fake_session`; clear it in fixture teardown.

### Avoid → Use instead
| Avoid | Use instead |
|---|---|
| `async def` route calling `requests` or a sync ORM | plain `def` route, or an async client |
| `@app.on_event("startup")` | `lifespan` |
| One `Order` model for input and output | Create/Update/Read schemas |
| `class Config:` on Pydantic models | `model_config = ConfigDict(...)` |
| Lazy-loaded relationship in async code | `selectinload` / `joinedload` |
