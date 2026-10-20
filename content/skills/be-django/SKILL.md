---
name: be-django
description: Build or fix a Django 5 / Django REST Framework backend. Use when adding a Django view, DRF serializer/APIView, service or selector, model constraint, migration, Celery task, or pytest-django test. Framework idioms only; shared backend rules live in the be- skills.
targets: [all]
---
## Django + DRF

Shared principles live in [[be-api-design]], [[be-data-access]], [[be-migrations]], [[be-security]], [[be-reliability]], [[be-observability]]. This skill covers only Django 5.x + DRF idioms (after the HackSoft Django Styleguide).

### Structure
- Business logic in **services** (writes) and **selectors** (reads), plain functions in `app/services.py` / `app/selectors.py`. Not in views, serializers, `save()`, managers, or signals.
- Models = data + DB constraints. Keep `Meta.constraints` (`CheckConstraint`, `UniqueConstraint`) and `Meta.indexes` as the source of truth; app-level checks alone race.
- Services call `instance.full_clean()` before `save()`: Django does not validate on save.
- Settings split `config/settings/{base,local,prod,test}.py`. Read env through one helper (e.g. django-environ), never `os.environ` scattered.

### Idioms
- One `APIView` per operation, with nested `InputSerializer` / `OutputSerializer`. Avoid fat `ModelViewSet`s for business operations; they couple the API to the model.
- Views only: validate input serializer, call service/selector, serialize output.
- One error shape: a custom `EXCEPTION_HANDLER` in `REST_FRAMEWORK` settings that maps `ValidationError`, `PermissionDenied`, domain errors to RFC 9457.
- Services are function-per-use-case with keyword-only args:

```python
def order_create(*, user: User, items: list[ItemInput]) -> Order:
    with transaction.atomic():
        order = Order(user=user)
        order.full_clean()
        order.save()
        OrderItem.objects.bulk_create(...)
        transaction.on_commit(lambda: send_receipt.delay(order.id))
    return order
```

- `transaction.atomic` around multi-write services. Side effects (Celery, email, webhooks) go through `transaction.on_commit`, or the task may run before the row is visible.
- Celery tasks stay thin: load by id, call a service. Pass ids, not model instances.
- Pitfall: `bulk_create()`, `bulk_update()`, and `QuerySet.update()` skip `save()`, `full_clean()`, and `pre/post_save` signals. Don't rely on either for invariants.

### Data & migrations
- Selectors own query shape: `select_related` for FK/1:1, `prefetch_related` for M2M/reverse FK, `only()` / `values()` when the full model isn't needed.
- Review `makemigrations` output before committing; preview with `makemigrations --dry-run -v 3`; inspect SQL with `sqlmigrate <app> <name>`. Renames show as remove+add unless confirmed.
- `RunPython` always gets a reverse (`migrations.RunPython.noop` at minimum). Keep data migrations separate from schema migrations.
- `squashmigrations` sparingly; only after every environment has applied the originals.

### Testing
Strategy and naming: [[cq-testing]].
- pytest-django with `@pytest.mark.django_db`; factory_boy factories instead of fixtures files.
- Test services directly (DB, no HTTP); a few `APIClient` tests per endpoint for wiring and permissions.
- Guard N+1 with `django_assert_num_queries(n)` around selectors.
- Test `on_commit` hooks with `django_capture_on_commit_callbacks(execute=True)`.

### Avoid → Use instead
| Avoid | Use instead |
|---|---|
| Logic in `save()` or `post_save` signal | service function |
| `ModelSerializer` + `ModelViewSet` for a business action | per-operation `APIView` + Input/Output serializers |
| `.delay()` inside `atomic` | `transaction.on_commit` |
| Querying in serializers (`SerializerMethodField`) | `prefetch_related` in selector |
