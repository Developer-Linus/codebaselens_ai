# CodebaseLens AI (Jac Fullstack)

CodebaseLens AI is a Jac fullstack app for **cloning a GitHub repository**, **analyzing its Jac codebase**, and **exploring relationships** between files/modules through an interactive dashboard.

It provides:
- A secure, auth-gated UI (`/dashboard`)
- Backend endpoints for cloning + analysis
- A lightweight **codebase graph** (nodes + import edges)
- A **trace** tool to find connection paths between two modules

---

## Quick Start

### Prerequisites
- Jac installed (Jac CLI)
- Git available on the server (for cloning)

### Run
```bash
jac start main.jac
```
Open the URL printed in the terminal.

### Login
Use the app’s signup/login screen (`/login`). After authentication, you’ll be routed to `/dashboard`.

---

## How It Works

### 1) Clone a repository
From the Dashboard, provide a GitHub repo URL and run **Clone & Analyze**.

The backend clones into a temporary workspace:
- `.tmp/repos/<slug>__<uuid>/`

### 2) Analyze the workspace
The analyzer scans the cloned workspace and builds a **manifest**:

- Each entry represents a repo file (e.g., `pages/DashboardPage.cl.jac`)
- Imports are extracted from Jac import statements:
  - `import from ... { ... }`
  - `sv import from ... { ... }`
  - `cl import from ... { ... }`

The backend then derives a **graph**:
- **Nodes**: files/modules
- **Edges**: `imports` relationships

### 3) Explore relationships
The Dashboard uses the graph to show:
- **Imports** (outgoing edges): what a module depends on
- **Imported by** (incoming edges): what depends on a module

### 4) Trace connections
The Trace tool finds paths from a **start** module to a **goal** module using the import graph.

---

## Project Structure

```text
.
├── jac.toml
├── main.jac
├── index.cl.jac
├── pages/
│   ├── LoginPage.cl.jac
│   └── DashboardPage.cl.jac
├── hooks/
│   └── useCodebase.cl.jac
├── components/
│   ├── ModuleList.cl.jac
│   ├── ModuleDetails.cl.jac
│   ├── PathTracer.cl.jac
│   ├── ManifestEditor.cl.jac
│   ├── OnboardingChecklist.cl.jac
│   └── GreetCard.cl.jac
├── service/
│   ├── appService.jac
│   ├── gitUtils.jac
│   └── repoAnalyzer.jac
└── styles/
    └── global.css
```

---

## Key Modules

### Entry point
- **`main.jac`**
  - Imports server-side functions so they are registered and callable
  - Mounts the client app (`ClientApp` from `index.cl.jac`)

### Client routing
- **`index.cl.jac`**
  - Defines routes:
    - `/login` → Login page
    - `/dashboard` → Dashboard (protected by `AuthGuard`)

### Backend services
- **`service/appService.jac`**
  - In-memory session manifest storage
  - Graph construction (nodes + edges)
  - Trace (BFS) over the import graph
  - Exposes clone/analyze endpoints to the client

- **`service/gitUtils.jac`**
  - GitHub clone helpers
  - Temporary workspace cleanup

- **`service/repoAnalyzer.jac`**
  - Workspace scanner
  - Import extraction + resolution to repo-relative file paths
  - Produces a manifest suitable for graph generation

### Client data hook
- **`hooks/useCodebase.cl.jac`**
  - A small client API wrapper around backend functions via `__doFuncFetch`
  - Handles auth failures by logging out and redirecting to `/login`

---

## Backend API (Server Functions)

These functions are imported in `main.jac` and called from the client via `__doFuncFetch`.

### Manifest / Graph
- `set_codebase_manifest(manifest: dict) -> dict`
- `get_codebase_manifest() -> dict`
- `get_codebase_graph() -> dict`

### Trace
- `trace_paths(start: str, goal: str, max_depth: int = 6) -> dict`
  - Returns up to a few shortest paths (BFS)

### Clone / Analyze
- `clone_repo_to_workspace(repo_url: str, token: str = "") -> dict`
- `analyze_repo_workspace(path: str, repo_url: str = "") -> dict`
- `clone_and_analyze_repo(repo_url: str, token: str = "") -> dict`
- `cleanup_repo_workspace(path: str) -> dict`

---

## Import Relationship Model (Cloned Repos)

CodebaseLens focuses on **in-repo relationships**.

### What becomes an edge
An edge is created when an import can be resolved to a file inside the cloned workspace.

Examples the analyzer resolves:
- Relative dot imports: `.Foo`, `..components.Bar`, `...lib.utils`
- Dotted module paths: `a.b.c` → `a/b/c`
- Jac file variants:
  - `X.jac`, `X.cl.jac`, `X.sv.jac`
  - `X/__init__.jac`, `X/__init__.cl.jac`, `X/__init__.sv.jac`

### What is intentionally ignored
To keep the graph repo-focused, the analyzer ignores:
- Runtime/npm imports (e.g., `@jac/runtime`)
- URLs (`http://`, `https://`)

---

## Development Notes

### Configuration
- `jac.toml` contains project metadata, npm dependencies, and the client (Vite + Tailwind) plugin configuration.

### Temporary workspaces
- Cloned repositories are stored under `.tmp/repos/`.
- Use the cleanup endpoint (or the Dashboard action) to remove workspaces when done.

---

## Troubleshooting

### Dashboard is empty or stuck loading
- Confirm you are logged in and routed to `/dashboard`.
- Check the server log output for clone/analyze errors.

### “Imported by” looks empty
- The graph only includes **resolved in-repo imports**.
- If a repo mostly imports runtime/npm modules, it may naturally have few in-repo edges.

---

## License

Add your license here (e.g., MIT, Apache-2.0) depending on your distribution needs.
