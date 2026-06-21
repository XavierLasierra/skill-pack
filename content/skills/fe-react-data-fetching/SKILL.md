---
name: fe-react-data-fetching
description: Fetch and cache server data in React. Use when adding data fetching, wiring useQuery/useMutation, handling loading/error/refetch/caching, or deciding between TanStack Query and a raw useEffect fetch. Pairs with fe-react-effects.
targets: [all]
---
## React Data Fetching

Server state is not component state. Don't hand-roll it in `useEffect`. Pairs with [[fe-react-effects]] (which only covers a bare fetch); this is the scaling answer.

### Default: TanStack Query for server state
Reach for it the moment data comes from an API. It gives you caching, request dedup, refetch-on-focus/reconnect, retries, and stale-while-revalidate for free — all the boilerplate a manual `useEffect` fetch gets wrong.

```tsx
// read
const { data, isPending, isError, error } = useQuery({
  queryKey: ['todo', id],          // stable, serializable, identifies the cache entry
  queryFn: () => fetchTodo(id),
})

// write
const { mutate, isPending } = useMutation({
  mutationFn: updateTodo,
  onSuccess: () => queryClient.invalidateQueries({ queryKey: ['todo', id] }),
})
```

### Rules
- **Query keys** are the cache identity: stable, serializable, include every input the `queryFn` depends on (`['todos', { status, page }]`). Wrong keys = stale or duplicated data.
- **Read with `useQuery`, write with `useMutation`.** After a mutation, `invalidateQueries` the affected keys — don't manually `setState`.
- Render the three states explicitly: pending, error, success — their UX (skeleton/empty/error) is [[fe-ui-states]]. No `data!` before the pending guard.
- Don't copy server data into `useState` — read it from the cache. Mirroring is the same desync bug as [[fe-react-effects]] derived state.
- Set sensible `staleTime` instead of refetching everything constantly.
- Server Components (Next.js App Router): fetch directly in the server component; use TanStack Query for client-side cache/mutations on top.

### Validate the whole response at the boundary
A network response is a trust boundary, and TS types are erased at runtime — a `useQuery<Todo>` is a lie if the backend drifts. Treat the response as an anti-corruption layer: validate the *entire* response in the `queryFn`, not just the data.
- **Status** — `fetch` does **not** throw on non-2xx. Check `res.ok` and `throw` yourself, or the error never reaches the query's error state and a 500's HTML error page gets parsed as your success type.
- **Error shape** — parse the error body with its own zod schema so `error` in the UI is typed, not `any`.
- **Envelope** — validate the wrapper (`{ data, meta, pagination }`), then the payload inside it. Don't assume `data` exists.

```tsx
const Todo = z.object({ id: z.string(), title: z.string(), done: z.boolean() })
const Envelope = z.object({ data: Todo, meta: z.object({ updatedAt: z.string() }) })

queryFn: async () => {
  const res = await fetch(`/todos/${id}`)
  if (!res.ok) throw ApiError.parse(await res.json())   // typed error path
  return Envelope.parse(await res.json())                // typed success path
},
```

Reuse the same schemas as [[fe-react-forms]] where they overlap, and `z.infer` the types so the cache stays correctly typed. Not free — full-parse cost matters on large/hot payloads; prioritize external, third-party, or untyped APIs and critical responses, validate once, and skip it for internal end-to-end-typed endpoints.

### When a raw useEffect fetch is still fine
One-off, uncached, no sharing — e.g. a single localStorage read or a fire-once load with no refetch. Then follow the [[fe-react-effects]] `ignore`-flag pattern to kill races. Anything cached, shared, polled, or refetched → TanStack Query.
