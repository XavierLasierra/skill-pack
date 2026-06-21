---
name: fe-react-testing
description: Write or fix React component tests with React Testing Library. Use when asked to test a component, add/repair RTL tests, choose queries, test user interaction or async UI, or decide what to test. Covers web and React Native (RNTL).
targets: [all]
---
## React Testing

Test the component the way a user uses it. The more a test resembles real usage, the more confidence it gives. Uses React Testing Library (RNTL for React Native — same API).

### Test behavior, not implementation
- Assert on what the user sees and does — rendered text, roles, interaction outcomes. Never on internal state, private functions, or component instance fields.
- A refactor that keeps behavior identical must not break the test. If it does, the test was coupled to implementation.
- Don't snapshot whole components as a substitute for real assertions.

### Query priority (top wins)
1. `getByRole` (+ `name`) — how assistive tech sees it; default choice.
2. `getByLabelText` / `getByPlaceholderText` — form fields.
3. `getByText` — non-interactive content.
4. `getByTestId` — last resort, only when nothing semantic fits.

`getBy*` (must exist) vs `queryBy*` (assert absence) vs `findBy*` (async, returns a promise).

### Interaction & async
- Use `@testing-library/user-event`, not `fireEvent` — it models real key/click sequences. It's async: `await user.click(...)`.
- For anything that appears after a fetch/transition, `await screen.findByRole(...)` — don't add manual sleeps.
- Mock the network at the boundary (e.g. MSW), not the component's own functions.

```tsx
test('submits the entered email', async () => {
  const user = userEvent.setup()
  const onSubmit = vi.fn()
  render(<SignupForm onSubmit={onSubmit} />)

  await user.type(screen.getByLabelText(/email/i), 'a@b.com')
  await user.click(screen.getByRole('button', { name: /sign up/i }))

  expect(onSubmit).toHaveBeenCalledWith({ email: 'a@b.com' })
})
```

### Shape
- Arrange–Act–Assert. One behavior per test; the test name states the behavior.
- Cover the states that break: empty, loading, error, boundary inputs — not just the happy path.
