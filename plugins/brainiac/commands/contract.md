---
description: Show the contract for a task — what does this task promise to deliver? Reads the task description and contract-publishing keywords to surface the API, schema, or interface this task exposes to other repos.
allowed-tools: Bash, Read, Glob, Grep
---

# Task Contract

$ARGUMENTS

When a task has cross-repo dependencies (`[repo:name]` annotations), other repos
consume its contract. This command shows what contract a specific task publishes
so other developers know what to expect.

## Step 1: Find the task

If `$ARGUMENTS` includes a task ID (e.g., `T-003`), use that. Otherwise, read
`tasks.md` and present tasks that publish contracts (contain keywords: export,
expose, publish, api, endpoint, contract, interface, schema, openapi, grpc,
proto, route, handler, provider). Let the developer choose.

## Step 2: Read the contract

From the task description in `tasks.md`, extract:

- **What it publishes:** the API endpoint, function signature, data schema, or
  interface this task exposes
- **Contract keywords:** which keywords triggered contract detection
- **Consumers:** which tasks in OTHER repos depend on this task (search
  `.references/` for `T-###` combined with the repo name — the dependency
  format is `(depends_on: T-### from <repo>)` but also check variants like
  `[repo:name]` annotations near the task)
- **Format:** the expected input/output format if specified

## Step 3: Report

```text
Contract: T-003 (api) — Kontrakt API lista pracowników

  Publishes: GET /api/employees/active
  Keywords: api, endpoint
  Returns: { employees: [{ id: string, name: string, startDate: string }] }
  Auth: Bearer token (internal)

  Consumers:
    T-004 in billing — depends_on: T-003 from api
    T-006 in billing — depends_on: T-003 from api

  Status: ✓ completed (2026-06-06)
```

## Step 4: Consumer guidance

If the contract is complete, tell consumers what to mock in tests:

> To mock T-003 in billing tests:
>
> ```typescript
> const mockEmployees = [{ id: "123", name: "Jan Kowalski", startDate: "2024-01-15" }];
> ```

If the contract is NOT yet complete, warn consumers that the interface may change.
