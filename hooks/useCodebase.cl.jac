import from "@jac/runtime" { __doFuncFetch, jacLogout, useNavigate }

# Data hook for CodebaseLens backend endpoints.

def:pub useCodebase() -> dict {
    navigate = useNavigate();

    async def safe_fetch(func_name: str, payload: dict) -> object {
        try {
            return await __doFuncFetch(func_name, payload);
        } except Exception as ex {
            msg = str(ex);
            if "UNAUTHORIZED" in msg {
                jacLogout();
                navigate("/login");
                return None;
            }
            raise ex;
        }
    }

    async def list_projects() -> object {
        res = await safe_fetch("list_projects", {});
        return res if res else {"projects": []};
    }

    async def analyze_project(repo_url: str, token: str = "", force: bool = False) -> object {
        res = await safe_fetch("analyze_project", {"repo_url": repo_url, "token": token, "force": force});
        return res if res else {"ok": False, "error": "No response"};
    }

    async def get_graph(repo_url: str) -> object {
        if not repo_url {
            return {"name": "", "nodes": [], "edges": []};
        }
        res = await safe_fetch("get_project_graph", {"repo_url": repo_url});
        return res if res else {"name": "", "nodes": [], "edges": []};
    }

    async def trace(repo_url: str, start: str, goal: str, max_depth: int) -> object {
        if not repo_url {
            return {"start": start, "goal": goal, "start_exists": False, "goal_exists": False, "paths": []};
        }
        res = await safe_fetch("trace_project_paths", {"repo_url": repo_url, "start": start, "goal": goal, "max_depth": max_depth});
        return res if res else {"start": start, "goal": goal, "start_exists": False, "goal_exists": False, "paths": []};
    }

    async def set_manifest(repo_url: str, manifest: dict) -> object {
        res = await safe_fetch("set_project_manifest", {"repo_url": repo_url, "manifest": manifest});
        return True if res and res["ok"] else False;
    }

    async def get_summary(repo_url: str) -> object {
        res = await safe_fetch("get_project_summary", {"repo_url": repo_url});
        return res if res else {"ok": False, "error": "No response"};
    }

    return {
        "list_projects": list_projects,
        "analyze_project": analyze_project,
        "get_graph": get_graph,
        "trace": trace,
        "set_manifest": set_manifest,
        "get_summary": get_summary
    };
}
