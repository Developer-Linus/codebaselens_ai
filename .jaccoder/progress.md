# Project: codebaselens_ai
## Status: IN PROGRESS

## Plan
1. [x] Inspect existing starter structure
2. [x] Add backend service to ingest a lightweight codebase manifest + compute a dependency graph
3. [x] Add hooks to call backend and manage UI state
4. [x] Build onboarding UI: manifest editor, module explorer, relationship details, path tracer, onboarding checklist
5. [ ] Start dev server + browser_validate
6. [ ] Interactive test: load sample manifest and click through graph
7. [ ] Final polish + set Status DONE

## Files
- main.jac — mounts client
- index.cl.jac — routes
- service/appService.jac — backend endpoints (extend)
- pages/DashboardPage.cl.jac — main onboarding UI
- hooks/useCodebase.cl.jac — data hook
- components/* — graph + module details + checklist
- styles/global.css — Tailwind theme tokens + base styles

## Issues
- 

## Learnings
- Endpoints must be imported in main.jac to register and sv-imported in hooks to call.

## Last Action
Inspected current starter; next: review existing service/appService + pages/components to extend for codebase onboarding.