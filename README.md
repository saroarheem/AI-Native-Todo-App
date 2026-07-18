# ToDo — Todo List App

A lightweight task manager built with Angular. Create, edit, delete, filter, and search todo items through a clean, responsive interface. The app uses standalone components, signals, and Angular's modern control-flow template syntax.

> **Note:** Todos are held in memory only. The list resets to its seed data on every page reload — there is no backend or persistence layer.

## Features

- **Create** todos with a title, description, and status (`due` / `done`).
- **Edit** any existing todo through a dedicated route (`/todo/:id`).
- **Delete** todos directly from the list.
- **Filter** the list by status using sidebar checkboxes (Due / Done).
- **Search** todos by title in real time.
- **Collapsible sidebar** for search and filter controls.
- **404 page** for unknown routes.

## Tech Stack

| Concern          | Choice                                             |
| ---------------- | -------------------------------------------------- |
| Framework        | Angular 22 (standalone components, signals)        |
| Language         | TypeScript                                         |
| Forms            | Reactive Forms + `FormsModule` (`ngModel`)         |
| Build system     | `@angular/build:application` (esbuild)             |
| Unit testing     | [Vitest](https://vitest.dev/) + jsdom              |
| Formatting       | Prettier                                           |
| Icons            | [Boxicons](https://boxicons.com/) (via CDN)        |
| Package manager  | npm                                                |

## Prerequisites

- **Node.js** (a version compatible with Angular 22 — Node 20.x or 22.x recommended)
- **npm** 10+

## Getting Started

Install dependencies:

```bash
npm install
```

Start the development server:

```bash
npm start
# or: ng serve
```

Then open [http://localhost:4200/](http://localhost:4200/). The app reloads automatically when you change source files.

## Available Scripts

| Script            | Description                                         |
| ----------------- | --------------------------------------------------- |
| `npm start`       | Run the dev server (`ng serve`).                    |
| `npm run build`   | Production build; output goes to `dist/`.           |
| `npm run watch`   | Development build in watch mode.                    |
| `npm test`        | Run unit tests with Vitest (`ng test`).             |

## Project Structure

```
src/
├── main.ts                     # Application bootstrap
├── index.html                  # Host page (loads Boxicons CDN)
├── styles.css                  # Global styles
└── app/
    ├── app.ts                  # Root component (Header + RouterOutlet + Footer)
    ├── app.config.ts           # Application providers (router, error listeners)
    ├── app.routes.ts           # Route definitions
    ├── services/
    │   └── data.ts             # Data service + SingleTodo model (in-memory store)
    ├── header/                 # Top navigation bar
    ├── footer/                 # Footer
    ├── todo-list/              # List view: cards, search, filter, sidebar
    ├── create-todo/            # Create form
    ├── edit-todo/              # Edit form (route param :id)
    └── page-not-found/         # 404 view
```

## Routes

| Path         | Component      | Description                          |
| ------------ | -------------- | ------------------------------------ |
| `/list`      | `TodoList`     | Default view — lists all todos.      |
| `/create`    | `CreateTodo`   | Form to add a new todo.              |
| `/todo/:id`  | `EditTodo`     | Edit the todo with the given id.     |
| `` (empty)   | —              | Redirects to `/list`.                |
| `**`         | `PageNotFound` | Fallback 404 for unknown routes.     |

## Testing

Unit tests run on the Vitest runner:

```bash
npm test
```

Spec files live alongside their components (`*.spec.ts`).

## Building for Production

```bash
npm run build
```

Optimized build artifacts are written to the `dist/` directory.

## License

This project is private and not currently published under an open-source license.

## PR bot test

I am dooing a typing misstake
Doing iit foor second tiime
i am doing mistake agaain.