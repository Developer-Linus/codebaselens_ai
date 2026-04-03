import from byllm.llm { Model }
import from service.gitUtils { clone_github_repo, cleanup_workspace }
import from service.repoAnalyzer { analyze_workspace }

glob _llm_model: Model = Model(model_name="openai/gpt-4o-mini");

"""Generate a detailed technical summary of a codebase from its modules and dependencies."""
def:priv _generate_summary(
    repo_name: str,
    modules_description: str,
    dependency_description: str
) -> str by _llm_model(
    reason="You are a software architect analyzing a codebase. Write a detailed technical summary covering: what the project does, its main modules and their roles, the dependency architecture, and any notable patterns. Use the repo name, module list, and dependency information provided."
);


glob _projects: dict = {};


def:priv _normalize_repo_url(repo_url: str) -> str {
    if not repo_url {
        return "";
    }
    normalized: str = str(repo_url).strip();
    if normalized.endswith("/") {
        normalized = normalized[:len(normalized) - 1];
    }
    return normalized;
}


def:priv _derive_repo_name(repo_url: str) -> str {
    if not repo_url {
        return "codebase";
    }
    normalized = repo_url.replace(".git", "");
    parts = normalized.split("/");
    for i in range(len(parts) - 1, -1, -1) {
        candidate = str(parts[i]);
        if candidate {
            return candidate;
        }
    }
    return "codebase";
}


def:priv _ensure_project(repo_url: str) -> dict {
    normalized = _normalize_repo_url(repo_url);
    if not normalized {
        return {};
    }
    if normalized not in _projects {
        _projects[normalized] = {
            "repo_url": normalized,
            "name": _derive_repo_name(normalized),
            "manifest": {"name": _derive_repo_name(normalized), "modules": []}
        };
    }
    return _projects[normalized];
}


def:priv _set_project_manifest(repo_url: str, manifest: dict) -> bool {
    project = _ensure_project(repo_url);
    if not project or not manifest {
        return False;
    }

    name = _derive_repo_name(project["repo_url"]);
    if manifest and ("name" in manifest) and manifest["name"] {
        name = str(manifest["name"]);
    }
    project["name"] = name;
    project["manifest"] = manifest if manifest else {"name": name, "modules": []};
    return True;
}


def:pub list_projects() -> dict {
    projects: list[dict] = [];
    for repo_url in _projects {
        entry = _projects[repo_url];
        manifest = entry["manifest"] if entry and ("manifest" in entry) else {};
        modules: list = manifest["modules"] if (manifest and "modules" in manifest) else [];
        projects.append({
            "repo_url": repo_url,
            "name": entry["name"] if entry and ("name" in entry) else _derive_repo_name(repo_url),
            "module_count": len(modules)
        });
    }
    return {"projects": projects};
}


def:pub analyze_project(repo_url: str, token: str = "", force: bool = False) -> dict {
    normalized = _normalize_repo_url(repo_url);
    if not normalized {
        return {"ok": False, "error": "Missing repo_url"};
    }

    entry = _projects.get(normalized);
    if entry and entry["manifest"] and (not force) {
        name = entry["name"] if ("name" in entry and entry["name"]) else _derive_repo_name(normalized);
        return {"ok": True, "cached": True, "name": name};
    }

    clone_res = clone_github_repo(repo_url=normalized, token=token, depth=1);
    if not clone_res or not clone_res["ok"] {
        err = clone_res["error"] if (clone_res and ("error" in clone_res)) else "Clone failed";
        return {"ok": False, "error": err};
    }

    path = clone_res["path"];
    analyze_res = analyze_workspace(workspace_path=path, repo_url=normalized);
    cleanup_workspace(path);

    if not analyze_res or not analyze_res["ok"] {
        err = analyze_res["error"] if (analyze_res and ("error" in analyze_res)) else "Analysis failed";
        return {"ok": False, "error": err};
    }

    manifest = analyze_res["manifest"] if ("manifest" in analyze_res) else {};
    if not manifest {
        return {"ok": False, "error": "Analyzer returned empty manifest"};
    }

    project = _ensure_project(normalized);
    if not _set_project_manifest(normalized, manifest) or not project {
        return {"ok": False, "error": "Failed to persist manifest"};
    }

    return {"ok": True, "cached": False, "name": project["name"] if ("name" in project) else _derive_repo_name(normalized)};
}


def:pub get_project_graph(repo_url: str) -> dict {
    normalized = _normalize_repo_url(repo_url);
    if not normalized {
        return {"name": "", "nodes": [], "edges": []};
    }
    project = _projects.get(normalized);
    if not project or ("manifest" not in project) {
        return {"name": "", "nodes": [], "edges": []};
    }

    manifest = project["manifest"];
    modules = manifest["modules"] if (manifest and "modules" in manifest) else [];

    nodes: list[dict] = [];
    edges: list[dict] = [];

    for m in modules {
        if not m {
            continue;
        }
        mid = str(m["id"]) if ("id" in m and m["id"]) else "";
        if not mid {
            continue;
        }
        nodes.append({
            "id": mid,
            "kind": m["kind"] if "kind" in m else "unknown",
            "summary": m["summary"] if "summary" in m else "",
            "tags": m["tags"] if "tags" in m else []
        });
        imps = m["imports"] if ("imports" in m and m["imports"]) else [];
        for imp in imps {
            edges.append({"from": mid, "to": imp, "type": "imports"});
        }
    }

    return {
        "name": project["name"] if ("name" in project and project["name"]) else _derive_repo_name(normalized),
        "nodes": nodes,
        "edges": edges
    };
}


def:pub trace_project_paths(repo_url: str, start: str, goal: str, max_depth: int = 6) -> dict {
    normalized = _normalize_repo_url(repo_url);
    if not normalized or not start or not goal {
        return {"start": start, "goal": goal, "start_exists": False, "goal_exists": False, "paths": []};
    }

    graph = get_project_graph(normalized);
    nodes = graph["nodes"] if (graph and ("nodes" in graph)) else [];
    edges = graph["edges"] if (graph and ("edges" in graph)) else [];

    adj: dict = {};
    ids: list[str] = [];
    for n in nodes {
        if not n or ("id" not in n) {
            continue;
        }
        mid = str(n["id"]);
        ids.append(mid);
    }

    for e in edges {
        if not e or ("from" not in e) or ("to" not in e) {
            continue;
        }
        frm = str(e["from"]);
        to = str(e["to"]);
        if frm not in adj {
            adj[frm] = [];
        }
        adj[frm].append(to);
    }

    paths: list[list[str]] = [];
    queue: list[dict] = [{"path": [start]}];

    while queue {
        cur = queue.pop(0);
        path: list = cur["path"];
        last = path[len(path) - 1];

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

        nexts = adj[last] if (last in adj) else [];
        for n in nexts {
            if n not in path {
                queue.append({"path": path + [n]});
            }
        }
    }

    return {
        "start": start,
        "goal": goal,
        "start_exists": (start in ids),
        "goal_exists": (goal in ids),
        "paths": paths
    };
}


def:pub get_project_summary(repo_url: str) -> dict {
    normalized: str = _normalize_repo_url(repo_url);
    if not normalized {
        return {"ok": False, "error": "Missing repo_url"};
    }

    proj: dict = {};
    if normalized in _projects {
        proj = _projects[normalized];
    }
    if not proj or ("manifest" not in proj) {
        return {"ok": False, "error": "Project not found. Analyze the repo first."};
    }

    if "summary" in proj and proj["summary"] {
        return {"ok": True, "summary": proj["summary"], "cached": True};
    }

    manifest = proj["manifest"] if "manifest" in proj else {};
    modules: list = manifest["modules"] if (manifest and "modules" in manifest) else [];
    repo_name: str = str(proj["name"]) if ("name" in proj and proj["name"]) else _derive_repo_name(normalized);

    mod_lines: list[str] = [];
    dep_lines: list[str] = [];

    for m in modules {
        if not m or ("id" not in m) {
            continue;
        }
        mid: str = str(m["id"]);
        kind: str = str(m["kind"]) if "kind" in m else "module";
        desc: str = str(m["summary"]) if ("summary" in m and m["summary"]) else "no description";
        tags_raw = m["tags"] if ("tags" in m and m["tags"]) else [];
        tags: str = ", ".join([str(t) for t in tags_raw]);

        line: str = f"{mid} ({kind}): {desc}";
        if tags {
            line = f"{line} [{tags}]";
        }
        mod_lines.append(line);

        imps = m["imports"] if ("imports" in m and m["imports"]) else [];
        for imp in imps {
            dep_lines.append(f"{mid} -> {str(imp)}");
        }
    }

    modules_desc: str = "\n".join(mod_lines) if mod_lines else "No modules found";
    deps_desc: str = "\n".join(dep_lines) if dep_lines else "No dependencies";

    try {
        summary_text = _generate_summary(
            repo_name=repo_name,
            modules_description=modules_desc,
            dependency_description=deps_desc
        );
    } except Exception as ex {
        return {"ok": False, "error": f"LLM error: {str(ex)}"};
    }

    proj["summary"] = summary_text;
    return {"ok": True, "summary": summary_text, "cached": False};
}


def:pub set_project_manifest(repo_url: str, manifest: dict) -> dict {
    normalized = _normalize_repo_url(repo_url);
    if not normalized {
        return {"ok": False, "error": "Missing repo_url"};
    }

    if not manifest {
        return {"ok": False, "error": "Missing manifest"};
    }

    if not _set_project_manifest(normalized, manifest) {
        return {"ok": False, "error": "Could not serialize manifest"};
    }

    project = _projects.get(normalized);
    return {"ok": True, "name": project["name"] if project and ("name" in project) else _derive_repo_name(normalized)};
}
