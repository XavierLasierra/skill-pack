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
  email: z.string().email(),
  age: z.coerce.number().min(18),
})
type Values = z.infer<typeof schema>   // types derive from the schema — never hand-write them

const { register, handleSubmit, formState: { errors, isSubmitting } } =
  useForm<Values>({ resolver: zodResolver(schema) })

<form onSubmit={handleSubmit(onValid)}>
  <input {...register('email')} aria-invalid={!!errors.email} />
  {errors.email && <p role="alert">{errors.email.message}</p>}
</form>
```

### Rules
- **Schema is the single source of truth.** Don't duplicate rules across UI and types — `z.infer` the types from the schema.
- **Validate on both sides.** Client validation is UX; re-validate with the same schema on the server — frontend checks are bypassable.
- Cross-field / conditional rules → zod `refine`/`superRefine`, not tangled `useEffect`s.
- Show one error per field, tied to the input for a11y (`aria-invalid` + `role="alert"`) — see [[fe-a11y]].
- Disable submit while `isSubmitting`; surface submit failures, don't swallow them.
- Reach for a controlled field (`Controller`) only for inputs that can't be uncontrolled (custom selects, date pickers).

### React Native deltas
- Use `Controller` with `TextInput` (no DOM `register`). Same RHF + zod core.
