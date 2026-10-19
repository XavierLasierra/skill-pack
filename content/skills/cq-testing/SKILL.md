---
name: cq-testing
description: Plan and write tests in any language. Use when asked to "write tests", "add tests", "test strategy", "unit vs integration", "e2e test", "Playwright", or "TDD". Not React component tests, see fe-react-testing.
targets: [all]
---
## Testing

Tests exist to let you change code without fear. Test behavior, keep tests fast and deterministic. React component specifics: [[fe-react-testing]].

### Strategy: shape of the suite
- Many unit tests: fast, isolated, pure logic. Milliseconds each.
- Some integration tests: real wiring across modules, DB, HTTP layer. Where most bugs hide.
- Few e2e tests: critical user journeys only (sign up, checkout). Slow and costly to maintain.

Don't invert the pyramid. Bug found at e2e level? Push the regression test down to the lowest level that catches it.

### Write a good test
- Test behavior through the public interface, not implementation. Refactoring without behavior change must not break tests.
- Arrange-Act-Assert, separated by blank lines.
- One behavior per test. Name states it: `rejects_expired_token`, `returns_empty_list_when_no_orders`. Not `test1`, `testLogin`.
- Assert on outcomes (return value, state, emitted event), not on which internals were called.

```
test "applies 10% discount over 100":
  cart = Cart(items=[Item(price=120)])        # arrange
  total = cart.checkout()                     # act
  assert total == 108                         # assert
```

### Deterministic or it doesn't ship
No real time, network, filesystem order, or randomness in unit tests.
- Inject a clock; never call `now()` inside logic.
- Seed RNGs; log the seed on failure.
- Prefer fakes (in-memory repo) over deep mocks. Mock only boundaries you don't own (payment API, email, third-party SDKs), never your own classes.
- Each test creates its own data and cleans up. No order dependence.

### Edge cases to cover
Empty, one, many. Boundaries (0, -1, max, off-by-one). Null/missing. Invalid input. Error paths: timeouts, 4xx/5xx, partial failure. Unicode, large input where relevant.

### Bug fixes: red-green-refactor
1. Red: write a test reproducing the bug. Run it, watch it fail for the right reason.
2. Green: smallest change that passes.
3. Refactor with tests green. Same loop for new features, one behavior at a time.

### E2E with Playwright
- Locators by role and accessible name: `page.getByRole('button', { name: 'Save' })`. Then `getByLabel`, `getByText`. CSS/XPath last; `data-testid` when no semantic hook exists.
- Web-first assertions auto-wait and retry: `await expect(page.getByText('Saved')).toBeVisible()`. Never `waitForTimeout` or sleeps; never assert on a snapshot value like `expect(await el.isVisible())`.
- Isolate: fresh data per test (API or fixture setup, not UI clicks), independent tests, reuse auth via `storageState`.
- Debug with `npx playwright test --trace on`, then `show-trace`.

### Flaky tests
A flaky test is a bug. Reproduce by looping ([[cq-debug]]). Common causes: shared state, real time, race with async work, order dependence. Quarantine it (tag, skip with ticket and owner) to unblock CI, then fix the cause. Never blind-retry to go green.

### Coverage
A signal, not a target. Low coverage on critical code is a hint; 100% with weak assertions is false comfort. Check that tests fail when logic is broken (mutate a line, see red).
