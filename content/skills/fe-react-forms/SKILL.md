---
name: fe-react-forms
description: Build or fix React forms and validation. Use when creating a form, wiring React Hook Form, adding zod/schema validation, handling form errors and submission, or deciding controlled vs uncontrolled inputs at scale. Covers web and React Native.
targets: [all]
---
## React Forms

A form is one schema, one source of truth, two-sided validation. Default to React Hook Form + zod for anything past a single trivial field. Extends the brief forms note in [[fe-react-component]].

### Default stack
- **React Hook Form** for state: uncontrolled inputs + refs, so it doesn't re-render on every keystroke — fast by design, unlike per-input `useState`.
- **zod** for the schema, wired via `@hookform/resolvers`. One schema is the source of truth for validation *and* types.

```tsx
const schema = z.object({
  email: z.email(),                      // zod v4: top-level format validators
  age: z.number().min(18, { error: 'Must be 18+' }),   // v4: `error`, not `message`
})
type Values = z.infer<typeof schema>   // types derive from the schema — never hand-write them

const { register, handleSubmit, formState: { errors, isSubmitting } } =
  useForm<Values>({ resolver: zodResolver(schema) })

<form onSubmit={handleSubmit(onValid)}>
  <input {...register('email')} aria-invalid={!!errors.email} />
  {errors.email && <p role="alert">{errors.email.message}</p>}
</form>
```

- `z.coerce.*` makes the schema's input type `unknown`, which fights RHF's types. Avoid it (use `valueAsNumber` on `register`), or type the form with input and output: `useForm<z.input<typeof schema>, unknown, z.output<typeof schema>>`.

### Rules
- **Schema is the single source of truth.** Don't duplicate rules across UI and types — `z.infer` the types from the schema.
- **Validate on both sides.** Client validation is UX; re-validate with the same schema on the server — frontend checks are bypassable.
- Cross-field / conditional rules → zod `refine`/`superRefine`, not tangled `useEffect`s.
- Show one error per field, tied to the input for a11y (`aria-invalid` + `role="alert"`) — see [[fe-a11y]].
- Disable submit while `isSubmitting`; surface submit failures, don't swallow them.
- Reach for a controlled field (`Controller`) only for inputs that can't be uncontrolled (custom selects, date pickers).

### React 19 form Actions
`<form action={fn}>` runs `fn(formData)` in a transition and resets uncontrolled fields on success.
- `useActionState(action, initial)` → `[state, formAction, isPending]` for results/errors.
- `useFormStatus()` in a child of the form → `pending` for a submit button.
- `useOptimistic` for instant UI while the action runs.
- Prefer for server actions, progressive enhancement, and simple forms. Prefer RHF + zod for rich client validation (per-field, on-change, dependent fields). Combine: RHF `handleSubmit` → call the server action, re-validate with the same schema server-side.

### React Native deltas
- Use `Controller` with `TextInput` (no DOM `register`). Same RHF + zod core. Form Actions are web-only.
