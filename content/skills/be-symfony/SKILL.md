---
name: be-symfony
description: Build or fix a Symfony 7 backend. Use when adding a Symfony controller, #[Route], #[MapRequestPayload] DTO, Voter, service config, Doctrine ORM query/entity/migration, Messenger handler, or PHPUnit WebTestCase. Framework idioms only; shared backend rules live in the be- skills.
targets: [all]
---
## Symfony

Shared principles live in [[be-api-design]], [[be-data-access]], [[be-migrations]], [[be-security]], [[be-reliability]], [[be-observability]]. This skill covers only Symfony 7.x + Doctrine ORM 3 idioms (after symfony.com best practices).

### Structure
- No application bundles; everything under `src/` in the `App\` namespace. Bundles are for reusable third-party code.
- `autowire: true`, `autoconfigure: true`, services private by default. Constructor injection only; never `$container->get()`.
- Controllers thin, extend `AbstractController`, delegate to services. Routing, security, and cache via attributes: `#[Route]`, `#[IsGranted]`, `#[Cache]`.

### Idioms
- Request DTO with validation on the DTO, not in the controller:

```php
#[Route('/orders', methods: ['POST'])]
public function create(#[MapRequestPayload] CreateOrderInput $input): JsonResponse
```

```php
final class CreateOrderInput {
    public function __construct(
        #[Assert\NotBlank, Assert\Length(max: 80)] public string $reference,
        #[Assert\Positive] public int $quantity,
    ) {}
}
```

`#[MapQueryString]` does the same for query params. Failure yields 422 automatically.
- Object-level authz in Voters: `#[IsGranted('EDIT', subject: 'post')]` or `$this->denyAccessUnlessGranted('EDIT', $post)`. `access_control` only covers route-level rules.
- Config: env vars for infra (`DATABASE_URL`), `bin/console secrets:set` vault for credentials, `app.`-prefixed parameters for the rest. Don't scatter `$_ENV`.
- Messenger: route messages to async transports; set `retry_strategy` and a `failure_transport`; handlers must be idempotent (delivery is at-least-once).

### Data & migrations
- Fetch-join in repository QueryBuilder; a plain join only filters:

```php
$this->createQueryBuilder('p')
    ->leftJoin('p.comments', 'c')->addSelect('c')
    ->where('p.id = :id')->setParameter('id', $id)
    ->getQuery()->getOneOrNullResult();
```

Fetch-joining several collections multiplies rows; load the second with a separate query.
- Never `flush()` per item in a loop. Persist in batches, `flush()` then `$em->clear()`.
- Transactions explicit: `$em->wrapInTransaction(fn () => ...)`.
- Bidirectional associations only when queried from both sides; initialize collections in the constructor (`new ArrayCollection()`).
- Migrations: `make:migration`, review the diff (a rename appears as drop+add, losing data), then `doctrine:migrations:migrate --no-interaction` as a release step. MySQL DDL auto-commits, so a failed migration can leave a partial schema.

### Testing
Strategy and naming: [[cq-testing]].
- PHPUnit + `WebTestCase`. Smoke-test every public URL via a data provider asserting `isSuccessful()` or the expected redirect.
- Fixtures via Foundry factories (or DoctrineFixturesBundle); use the `test` env with its own database.
- Messenger: `in-memory://` transport in test env, assert on the transport's sent envelopes.

### Avoid → Use instead
| Avoid | Use instead |
|---|---|
| `$this->container->get(X::class)` | constructor injection |
| `flush()` inside a loop | batch, flush, `clear()` |
| `leftJoin` without `addSelect` to hydrate | add `->addSelect('c')` |
| Role checks in controller bodies | Voter + `#[IsGranted]` |
