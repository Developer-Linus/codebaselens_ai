import from "@jac/runtime" { __doFuncFetch, jacLogout, useNavigate }

# Data hook for CodebaseLens backend endpoints.

def:pub useCodebase() -> dict {
    navigate = useNavigate();

    async def safe_fetch(func_name: str, payload: dict) -> any {
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

    async def get_manifest() -> dict {
        res = await safe_fetch("get_codebase_manifest", {});
        return res if res else {};
    }

    async def set_manifest(manifest: dict) -> bool {
        res = await safe_fetch("set_codebase_manifest", {"manifest": manifest});
        return True if res and res["ok"] else False;
    }

    async def get_graph() -> dict {
        res = await safe_fetch("get_codebase_graph", {});
        return res if res else {};
    }

    async def trace(start: str, goal: str, max_depth: int) -> dict {
        res = await safe_fetch("trace_paths", {"start": start, "goal": goal, "max_depth": max_depth});
        return res if res else {};
    }

    async def clone_repo(repo_url: str, token: str = "") -> dict {
        res = await safe_fetch("clone_repo_to_workspace", {"repo_url": repo_url, "token": token});
        return res if res else {};
    }

    async def analyze_workspace(path: str, repo_url: str = "") -> dict {
        res = await safe_fetch("analyze_repo_workspace", {"path": path, "repo_url": repo_url});
        return res if res else {};
    }

    async def clone_and_analyze(repo_url: str, token: str = "") -> dict {
        res = await safe_fetch("clone_and_analyze_repo", {"repo_url": repo_url, "token": token});
        return res if res else {};
    }

    async def cleanup_repo(path: str) -> dict {
        res = await safe_fetch("cleanup_repo_workspace", {"path": path});
        return res if res else {};
    }

    return {
        "get_manifest": get_manifest,
        "set_manifest": set_manifest,
        "get_graph": get_graph,
        "trace": trace,
        "clone_repo": clone_repo,
        "cleanup_repo": cleanup_repo,
        "analyze_workspace": analyze_workspace,
        "clone_and_analyze": clone_and_analyze
    };
}
