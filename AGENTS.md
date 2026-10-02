# Project Guidance

## User Preferences

- Messaging is gated on mutual follow (both users follow each other)

## Verified Commands

[Filled after first successful build]

## Learnings

- Backend is a single monolithic main.mo; new domains can be added as types/lib/mixins modules plus a new migration in the chain.
- Stable state is seeded by a frozen initial migration; new state must be added via a new migration entry.
- A mixin's private helper is included into the actor block, so a same-named helper in main.mo collides with M0051; rename mixin-local helpers.
- Motoko has no triple-quoted strings; use concatenated escaped literals for long text like getApiDoc.
- OQL Entity.manual needs the value-module imports (BoolValue, IntValue, NatValue, PrincipalValue, RecordValue, TextValue) in main.mo for implicit _toRow arguments.
- OQL MapEntity.toEntity iterates values only; nested per-user maps need OQL.Entity.manual with a flattener promoting the outer key into a row field.
- Conversation id is canonical min/max principal ordering via Principal.compare; frontend fallbacks must use compareTo, not string ordering.
- Optimistic infinite-query appends must target pages[0] when the thread flattens newest-first then reverses.
- A definite height chain (h-screen root, min-h-0 flex-1, h-full thread) is required for an inner overflow-y-auto thread with a pinned composer.
- Verified commands: backend mops check --fix / mops build; frontend pnpm typecheck / pnpm fix / pnpm build; bindings pnpm bindgen.
