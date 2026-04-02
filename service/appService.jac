def:priv greet(name: str) -> dict {
    return {"message": "Hello, " + name + "! Your Jac backend is working."};
}

# === CodebaseLens: lightweight onboarding graph ===
# The client sends a manifest describing modules and their relationships.
# We store it in-memory for the session and compute helpful views.

import from service.gitUtils { clone_github_repo, cleanup_workspace }
import from service.repoAnalyzer { analyze_workspace }

glob _codebase_manifest: dict = {};

# manifest schema (recommended)
# {
#   "name": "repo-name",
#   "modules": [
#     {
#       "id": "service/appService.jac",
#       "kind": "backend|client|config|doc",
#       "summary": "...",
#       "imports": ["index.cl.jac"],
#       "exports": ["greet"],
#       "calls": ["greet"],
#       "tags": ["auth","routing"]
#     }
#   ]
# }


def:priv set_codebase_manifest(manifest: dict) -> dict {
    global _codebase_manifest;

    # Merge to allow incremental updates (e.g., setting repo_url first).
    if _codebase_manifest {
        for k in manifest {
            _codebase_manifest[k] = manifest[k];
        }
    } else {
        _codebase_manifest = manifest;
    }
    return {"ok": True};
}


def:priv get_codebase_manifest() -> dict {
    if _codebase_manifest {
        return _codebase_manifest;
    }

    # Built-in sample so the UI works immediately.
    return {
        "name": "sample-repo",
        "modules": [
            {
                "id": "main.jac",
                "kind": "backend",
                "summary": "Entry point: imports backend endpoints and mounts the client app.",
                "imports": ["service/appService.jac", "index.cl.jac"],
                "exports": ["app"],
                "calls": [],
                "tags": ["entry", "mount"]
            },
            {
                "id": "index.cl.jac",
                "kind": "client",
                "summary": "Client router: /login and /dashboard routes.",
                "imports": ["pages/LoginPage.cl.jac", "pages/DashboardPage.cl.jac"],
                "exports": ["ClientApp"],
                "calls": [],
                "tags": ["routing"]
            },
            {
                "id": "service/appService.jac",
                "kind": "backend",
                "summary": "Backend functions used by the client (e.g., greet).",
                "imports": [],
                "exports": ["greet", "set_codebase_manifest", "get_codebase_manifest", "get_codebase_graph", "trace_paths", "clone_repo_to_workspace"],
                "calls": [],
                "tags": ["service"]
            },
            {
                "id": "pages/LoginPage.cl.jac",
                "kind": "client",
                "summary": "Auth page: sign in / sign up.",
                "imports": ["@jac/runtime"],
                "exports": ["page"],
                "calls": ["jacLogin", "jacSignup"],
                "tags": ["auth"]
            },
            {
                "id": "pages/DashboardPage.cl.jac",
                "kind": "client",
                "summary": "Onboarding dashboard: explore modules and relationships.",
                "imports": ["components/*", "hooks/*"],
                "exports": ["page"],
                "calls": [],
                "tags": ["onboarding"]
            }
        ]
    };
}


def:priv get_codebase_graph() -> dict {
    manifest = get_codebase_manifest();
    modules = manifest["modules"] if manifest and manifest["modules"] else [];

    nodes: list[dict] = [];
    edges: list[dict] = [];

    for m in modules {
        nodes.append({
            "id": m["id"],
            "kind": m["kind"] if "kind" in m else "unknown",
            "summary": m["summary"] if "summary" in m else "",
            "tags": m["tags"] if "tags" in m else []
        });

        imps = m["imports"] if "imports" in m and m["imports"] else [];
        for imp in imps {
            edges.append({"from": m["id"], "to": imp, "type": "imports"});
        }
    }

    return {"name": manifest["name"] if manifest and "name" in manifest else "codebase", "nodes": nodes, "edges": edges};
}


def:priv trace_paths(start: str, goal: str, max_depth: int = 6) -> dict {
    graph = get_codebase_graph();
    nodes = graph["nodes"];
    edges = graph["edges"];

    adj: dict = {};
    for e in edges {
        if e["from"] not in adj {
            adj[e["from"]] = [];
        }
        adj[e["from"]].append(e["to"]);
    }

    # BFS for a few shortest paths
    paths: list[list[str]] = [];
    queue: list[dict] = [{"path": [start]}];

    while queue {
        cur = queue.pop(0);
        path = cur["path"];
        last = path[-1];

        if len(path) > max_depth {
            continue;
        }

        if last == goal {
            paths.append(path);
            if len(paths) >= 5 {
                break;
            }
            continue;
        }

        nexts = adj[last] if last in adj else [];
        for n in nexts {
            if n in path {
                continue;
            }
            queue.append({"path": path + [n]});
        }
    }

    # Ensure start/goal exist (helpful UX)
    ids: list[str] = [];
    for n in nodes {
        ids.append(n["id"]);
    }

    return {
        "start": start,
        "goal": goal,
        "start_exists": (start in ids),
        "goal_exists": (goal in ids),
        "paths": paths
    };
}


# --- Git utilities exposed to the client ---

def:priv clone_repo_to_workspace(repo_url: str, token: str = "") -> dict {
    # Clones into .tmp/repos/<slug>__<uuid>/ and returns the workspace path.
    # The caller can later cleanup via cleanup_repo_workspace.
    res = clone_github_repo(repo_url=repo_url, token=token, depth=1);
    if not res or not res["ok"] {
        return res;
    }

    # Store minimal session state for later analysis steps.
    set_codebase_manifest({
        "repo_url": repo_url,
        "workspace": {"path": res["path"], "workspace_id": res["workspace_id"]}
    });

    return res;
}


def:priv cleanup_repo_workspace(path: str) -> dict {
    return cleanup_workspace(path);
}


def:priv analyze_repo_workspace(path: str, repo_url: str = "") -> dict {
    res = analyze_workspace(workspace_path=path, repo_url=repo_url);
    if not res or not res["ok"] {
        return res;
    }

    manifest = res["manifest"] if ("manifest" in res) else {};
    if not manifest {
        return {"ok": False, "error": "Analyzer returned empty manifest"};
    }

    # Preserve any existing workspace info in the session manifest.
    ws = _codebase_manifest["workspace"] if (_codebase_manifest and ("workspace" in _codebase_manifest)) else {};
    if ws {
        manifest["workspace"] = ws;
    }

    set_codebase_manifest(manifest);
    return {"ok": True, "name": manifest["name"], "module_count": len(manifest["modules"]) if ("modules" in manifest and manifest["modules"]) else 0};
}


def:priv clone_and_analyze_repo(repo_url: str, token: str = "") -> dict {
    clone_res = clone_repo_to_workspace(repo_url=repo_url, token=token);
    if not clone_res or not clone_res["ok"] {
        return clone_res;
    }

    path = clone_res["path"];
    analyze_res = analyze_repo_workspace(path=path, repo_url=repo_url);
    if not analyze_res or not analyze_res["ok"] {
        # Cleanup on failure to avoid leaking temp dirs.
        cleanup_repo_workspace(path);
        return analyze_res;
    }

    return {
        "ok": True,
        "repo_url": repo_url,
        "path": path,
        "workspace_id": clone_res["workspace_id"],
        "analysis": analyze_res
    };
}
