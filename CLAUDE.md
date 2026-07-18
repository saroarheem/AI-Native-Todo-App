# CLAUDE.md

Guidance for Claude Code (and other AI assistants) working in this repository.

## Project Overview

**ToDo** is a single-page Angular todo-list application. Users can create, edit,
delete, filter, and search task items. It is a front-end-only learning/demo
project — there is **no backend, database, or API**.

- **Framework:** Angular 22, standalone components (no `NgModule`).
- **State:** Angular signals + a singleton in-memory service.
- **Language:** TypeScript.
- **Build:** `@angular/build:application` (esbuild under the hood).
- **Tests:** Vitest + jsdom.
- **Formatting:** Prettier.
- **Package manager:** npm.

## Key Commands

| Task            | Command          |
| --------------- | ---------------- |
| Install deps    | `npm install`    |
| Dev server      | `npm start`      |
| Production build| `npm run build`  |
| Watch build     | `npm run watch`  |
| Unit tests      | `npm test`       |

The dev server runs at `http://localhost:4200/`.

## Architecture

Bootstrapping flow:

- `src/main.ts` — bootstraps the `App` component with `appConfig`.
- `src/app/app.config.ts` — registers providers: `provideRouter(routes)` and
  `provideBrowserGlobalErrorListeners()`.
- `src/app/app.ts` — root component; composes `Header`, `<router-outlet>`, and
  `Footer` (see `app.html`).
- `src/app/app.routes.ts` — route table.

### Routes

| Path        | Component      | Notes                       |
| ----------- | -------------- | --------------------------- |
| `list`      | `TodoList`     | Default (empty path redirects here). |
| `create`    | `CreateTodo`   | Add form.                   |
| `todo/:id`  | `EditTodo`     | Edit by id.                 |
| `**`        | `PageNotFound` | 404 fallback.               |

### Components (`src/app/`)

- `header/` — app bar with links to `list` and `create`.
- `footer/` — static footer.
- `todo-list/` — main view. Renders todo cards with `@for`, hosts the
  collapsible sidebar, live title **search** (`ngModel` + `onSearch`), and
  status **filter** (reactive `FormGroup` with `due`/`done` checkboxes driven by
  `form.valueChanges`). Holds delete logic.
- `create-todo/` — reactive form (`title`, `description`, `status`); computes the
  next id from the last todo, calls `Data.addTodo`, then navigates to `/list`.
- `edit-todo/` — reads `:id` from the route, patches the form via
  `Data.getTodoById`, and saves through `Data.updateTodo`.
- `page-not-found/` — 404 view.

### Data Layer

`src/app/services/data.ts` is the single source of truth:

- `@Injectable({ providedIn: 'root' })` — one shared instance.
- Holds `todos: SingleTodo[]`, seeded with four sample items.
- Methods: `addTodo`, `getTodos`, `getTodoById`, `updateTodo`. Deletion is done
  in `TodoList` by splicing `data.todos` directly.
- `SingleTodo` interface: `{ id: number; title: string; description: string; status: string }`.
- `status` is a plain string, conventionally `"due"` or `"done"`.

> **Important:** All state lives in memory. Reloading the browser discards every
> change and restores the seed data. Do not assume persistence exists.

### Conventions in this codebase

- Standalone components only — each component declares its own `imports`. There
  are no `NgModule`s.
- Uses modern Angular control flow (`@for`, `@if`) in templates, not the legacy
  `*ngFor` / `*ngIf` structural directives.
- Dependencies are obtained with `inject()` (some components also use
  constructor injection — e.g. `EditTodo`). Match the pattern already in the file
  you edit.
- Filenames are un-suffixed (`app.ts`, `header.ts`, `data.ts`) — this project
  does **not** use the older `.component.ts` / `.service.ts` naming.
- Boxicons is loaded via CDN in `src/index.html`; icons use `bx bx-*` classes.
- Static assets (logo, favicon) live in `public/` and are referenced by name.

## Boundaries — Do NOT

- **Do NOT** commit, push, or create branches/PRs unless the user explicitly
  asks. Leave git operations to the user by default.
- **Do NOT** add a backend, database, HTTP layer, or external persistence
  (localStorage, IndexedDB, a server) unless explicitly requested. The in-memory
  `Data` service is intentional.
- **Do NOT** introduce new dependencies, libraries, or state-management tools
  (NgRx, etc.) without asking first. Keep the stack minimal.
- **Do NOT** migrate the code style — do not convert standalone components back
  to `NgModule`s, do not rewrite `@for`/`@if` into `*ngFor`/`*ngIf`, and do not
  rename files to `.component.ts` / `.service.ts`.
- **Do NOT** upgrade or downgrade Angular, TypeScript, or other package versions
  unless that is the explicit task.
- **Do NOT** reformat or restructure files you were not asked to touch. Keep
  diffs focused on the request.
- **Do NOT** delete the commented-out reference code (e.g. the old `SingleTodo`
  class in `data.ts`) unless asked — it may be kept intentionally.
- **Do NOT** run destructive commands (`git reset --hard`, force pushes, mass
  file deletion) or alter build/CI config without a clear request.
- **Do NOT** invent features, seed data, or requirements. If the task is
  ambiguous, ask before making assumptions.

## When Making Changes

1. Read the surrounding file first and match its existing style, injection
   pattern, and naming.
2. Keep changes scoped to what was asked.
3. If you add or change behavior with a runtime surface, verify it — run
   `npm test` and/or the dev server rather than assuming it works.
4. Prefer editing the `Data` service for anything touching todo state, so all
   components stay consistent.
