# Project: CodebaseLens
## Status: IN PROGRESS

## Plan
1. [x] Inspect current codebase manifest/graph flow
2. [ ] Add backend endpoint to accept GitHub URL and clone+analyze into manifest
3. [ ] Wire frontend to call new endpoint from Dashboard
4. [ ] Browser validate + one interactive test

## Files
- service/appService.jac — codebase manifest/graph endpoints
- hooks/useCodebase.cl.jac — client API wrapper
- pages/DashboardPage.cl.jac — repo URL input UI

## Issues
- Repo URL is only saved into manifest; no server-side clone/analyze is triggered.

## Learnings
- Backend endpoints must be imported in main.jac to be registered.
- Client calls backend via __doFuncFetch("endpoint_name", payload).

## Last Action
Read existing manifest/graph endpoints and Dashboard repo URL save flow; next add a clone+analyze endpoint.